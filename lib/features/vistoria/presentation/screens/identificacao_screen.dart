import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/vistoria_type.dart';
import 'placa_camera_screen.dart';

import '../../../../injection_container.dart';
import '../../../../features/consulta_bin/data/services/radar_service.dart';
import '../../../../features/consulta_bin/data/repositories/radar_repository.dart';
import '../../../../features/consulta_bin/domain/entities/radar_veiculo.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/daos/autocred_dao.dart';
import '../../../../database/app_database.dart';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class IdentificacaoScreen extends StatefulWidget {
  final TipoVistoria tipo;
  final Map<String, dynamic>? dadosIniciais;
  const IdentificacaoScreen(
      {super.key, required this.tipo, this.dadosIniciais});

  @override
  State<IdentificacaoScreen> createState() => _IdentificacaoScreenState();
}

class _IdentificacaoScreenState extends State<IdentificacaoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Campo de busca
  final _buscaCtrl = TextEditingController();
  final _buscaFocus = FocusNode();

  // Campos do veículo editáveis
  final _placaEditCtrl = TextEditingController();
  final _chassiEditCtrl = TextEditingController();
  final _motorEditCtrl = TextEditingController();
  final _marcaEditCtrl = TextEditingController();
  final _modeloEditCtrl = TextEditingController();
  final _anoFabEditCtrl = TextEditingController();
  final _anoModEditCtrl = TextEditingController();
  final _corEditCtrl = TextEditingController();
  final _renavamEditCtrl = TextEditingController();
  final _municipioEditCtrl = TextEditingController();
  final _ufEditCtrl = TextEditingController();
  final _restricoesEditCtrl = TextEditingController();

  final _laudoCtrl = TextEditingController();

  bool _veiculoEncontrado = false;
  bool _modoOffline = false;
  bool _buscandoVeiculo = false;
  bool _buscandoRadarHistorico = false;
  bool _buscandoLaudo = false;
  String _mensagemCarregamento = '';
  String? _arquivoPesquisaUrl;
  String? _situacaoVeiculo;

  // Modo de entrada da busca: 'placa', 'chassi', ou 'motor'
  String _modoEntrada = 'placa';
  bool _somentePesquisa = false;

  // Tipos de consulta disponíveis (Radar Consultas)
  final List<Map<String, dynamic>> _tiposConsulta = [
    {'nome': 'AUTO BIN', 'codigo': 'auto_bin'},
    {'nome': 'AUTO PERÍCIA', 'codigo': 'auto_pericia'},
    {'nome': 'AUTO PERÍCIA HRF', 'codigo': 'auto_pericia_hrf'},
    {'nome': 'AUTO COMPLETA', 'codigo': 'auto_completa'},
    {'nome': 'AUTO LEILÃO', 'codigo': 'auto_leilao'},
    {'nome': 'AUTO BASE ESTADUAL', 'codigo': 'auto_base_estadual'},
    {'nome': 'AUTO DÉBITOS E RECALL', 'codigo': 'auto_debitos_recall'},
  ];
  String _produtoSelecionado = 'auto_bin';

  @override
  void initState() {
    super.initState();
    if (widget.dadosIniciais != null && widget.dadosIniciais!.isNotEmpty) {
      if (widget.dadosIniciais!.containsKey('produtoSelecionado')) {
        _produtoSelecionado = widget.dadosIniciais!['produtoSelecionado'];
      }
      if (widget.dadosIniciais!.containsKey('somentePesquisa')) {
        _somentePesquisa = widget.dadosIniciais!['somentePesquisa'] == true;
      }
      if (widget.dadosIniciais!.containsKey('placa')) {
        _veiculoEncontrado = true;
        _placaEditCtrl.text = widget.dadosIniciais!['placa'] ?? '';
        _chassiEditCtrl.text = widget.dadosIniciais!['chassi'] ?? '';
        _motorEditCtrl.text = widget.dadosIniciais!['motor'] ?? '';
        _marcaEditCtrl.text = widget.dadosIniciais!['marca'] ?? '';
        _modeloEditCtrl.text = widget.dadosIniciais!['modelo'] ?? '';
        _anoFabEditCtrl.text = widget.dadosIniciais!['anoFabricacao'] ?? '';
        _anoModEditCtrl.text = widget.dadosIniciais!['anoModelo'] ?? '';
        _corEditCtrl.text = widget.dadosIniciais!['cor'] ?? '';
        _renavamEditCtrl.text = widget.dadosIniciais!['renavam'] ?? '';
        _municipioEditCtrl.text = widget.dadosIniciais!['municipio'] ?? '';
        _ufEditCtrl.text = widget.dadosIniciais!['uf'] ?? '';
        _restricoesEditCtrl.text = widget.dadosIniciais!['restricoes'] ?? '';
        _situacaoVeiculo = widget.dadosIniciais!['situacao'];
      }
    }
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _placaEditCtrl.dispose();
    _chassiEditCtrl.dispose();
    _motorEditCtrl.dispose();
    _marcaEditCtrl.dispose();
    _modeloEditCtrl.dispose();
    _anoFabEditCtrl.dispose();
    _anoModEditCtrl.dispose();
    _corEditCtrl.dispose();
    _renavamEditCtrl.dispose();
    _municipioEditCtrl.dispose();
    _ufEditCtrl.dispose();
    _restricoesEditCtrl.dispose();
    _laudoCtrl.dispose();
    _buscaFocus.dispose();
    super.dispose();
  }

  // ── Câmera OCR ────────────────────────────────────────────────────────────

  Future<void> _abrirCamera() async {
    final placa = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const PlacaCameraScreen()),
    );
    if (placa != null && mounted) {
      setState(() {
        _modoEntrada = 'placa';
        _buscaCtrl.text = _formatarPlaca(placa);
      });
      _buscarVeiculo();
    } else {
      _buscaFocus.requestFocus();
    }
  }

  // ── Busca veículo (AutoCredCar) ──────────────────────────────────────────

  void _preencherDados(RadarVeiculo veiculo) {
    setState(() {
      _mensagemCarregamento = 'Consulta carregada com sucesso';
      _veiculoEncontrado = true;

      _placaEditCtrl.text = veiculo.placa;
      _chassiEditCtrl.text = veiculo.chassi;
      _motorEditCtrl.text = veiculo.motor;

      final mm = veiculo.marcaModelo.split('/');
      _marcaEditCtrl.text = mm.isNotEmpty ? mm[0].trim() : '';
      _modeloEditCtrl.text = mm.length > 1 ? mm[1].trim() : '';

      _anoFabEditCtrl.text = veiculo.anoFabricacao;
      _anoModEditCtrl.text = veiculo.anoModelo;
      _corEditCtrl.text = veiculo.cor;
      _renavamEditCtrl.text = veiculo.renavam;
      _municipioEditCtrl.text = veiculo.municipio;
      _ufEditCtrl.text = veiculo.estado;
      _restricoesEditCtrl.text = veiculo.restricoes1.isNotEmpty
          ? veiculo.restricoes1
          : veiculo.informacoesRelevantes;
      _arquivoPesquisaUrl = veiculo.arquivoPesquisaUrl;
      _situacaoVeiculo = veiculo.situacao;
    });
  }

  Future<Map<String, dynamic>?> _verificarNuvem(String valor) async {
    final repo = sl<RadarRepository>();
    final service = sl<RadarService>();

    // Mostra loading rápido de busca
    setState(() {
      _buscandoVeiculo = true;
      _mensagemCarregamento = 'Buscando histórico na nuvem...';
    });

    final hasPending = await repo.existeConsultaPendente(_modoEntrada, valor);
    if (hasPending) {
      if (!mounted) return null;
      setState(() { _buscandoVeiculo = false; });
      final querForcar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Pesquisa em Andamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: const Text('Já existe uma pesquisa em andamento para este veículo.\n\nSe a tentativa anterior falhou ou travou, você pode forçar uma nova consulta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Aguardar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Forçar Nova'),
            )
          ],
        )
      );

      if (querForcar != true) {
        return {'forcarNova': false, 'fonte': 'local', 'dados_tratados': null};
      }
      // Se forçar nova, ignoramos que está pendente e o fluxo continua para as concluídas ou nova.
    }

    List<Map<String, dynamic>> consultasNuvem = [];
    if (_modoEntrada == 'placa') {
      consultasNuvem = await repo.buscarConsultasRecentesNuvem('placa', valor);
    } else if (_modoEntrada == 'chassi') {
      consultasNuvem = await repo.buscarConsultasRecentesNuvem('chassi', valor);
    } else if (_modoEntrada == 'motor') {
      consultasNuvem = await repo.buscarConsultasRecentesNuvem('motor', valor);
    }

    // Marca como local
    final combinadas =
        consultasNuvem.map((c) => {...c, 'fonte': 'local'}).toList();

    // Busca na API da Radar
    try {
      final radarConsultas = await service.listarConsultasRadar(
        param: _modoEntrada,
        value: valor,
      );
      for (var c in radarConsultas) {
        combinadas.add({
          'fonte': 'radar',
          'tokenConsulta': c['token'],
          'titulo': c['titulo'],
          'created_at': c['data_hora'] ?? c['ctime'],
        });
      }
    } catch (e) {
      print('Erro ao buscar histórico radar: $e');
    }

    if (combinadas.isEmpty) {
      if (!mounted) {
        setState(() { _buscandoVeiculo = false; });
        return {'forcarNova': true};
      }
      final querNova = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nenhuma Pesquisa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Não encontramos nenhuma pesquisa anterior para este veículo.\n\nDeseja realizar uma NOVA consulta na base de dados agora? (Sujeito a cobrança de saldo).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Continuar Sem Pesquisa',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Realizar Consulta'),
            ),
          ],
        ),
      );
      if (querNova == null) return null; // Cancelou
      return {'forcarNova': querNova};
    }
    // Ordenar por data mais recente
    combinadas.sort((a, b) {
      try {
        final da = DateTime.parse(a['created_at'].toString());
        final db = DateTime.parse(b['created_at'].toString());
        return db.compareTo(da);
      } catch (_) {
        return 0;
      }
    });

    final total = combinadas.length;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pesquisas Encontradas ($total)',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identificamos $total pesquisa(s) realizada(s) anteriormente para este veículo. Deseja utilizar uma pesquisa anterior ou realizar uma nova consulta?',
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: combinadas.length,
                  itemBuilder: (context, index) {
                    final item = combinadas[index];
                    final isRadar = item['fonte'] == 'radar';
                    final dataString = item['created_at'].toString();
                    DateTime? createdAt;
                    try {
                      createdAt = DateTime.parse(dataString);
                    } catch (_) {}

                    final dateFormatted = createdAt != null
                        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} às ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                        : dataString;

                    final prefix = isRadar ? '[Nuvem]' : '[Local]';
                    final title = item['titulo'] != null
                        ? '$prefix ${item['titulo']}'
                        : '$prefix Pesquisa';
                    final subtitle = 'Realizada em: $dateFormatted';

                    return Card(
                      elevation: 0,
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isRadar
                              ? Icons.cloud_sync_rounded
                              : Icons.history_rounded,
                          color: AppTheme.primary,
                        ),
                        title: Text(title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(item),
                          icon: const Icon(Icons.check_rounded, size: 14),
                          label: const Text('Utilizar'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.comObs),
            onPressed: () => Navigator.of(ctx).pop({'forcarNova': true}),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text('Realizar Nova Consulta',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _buscarVeiculo() async {
    if (_buscandoVeiculo) return false;

    final valor = _buscaCtrl.text.trim();
    if (valor.isEmpty) return false;

    final escolhida = await _verificarNuvem(valor);
    if (escolhida == null) {
      setState(() { _buscandoVeiculo = false; });
      return false; // Cancelou
    }

    String? tokenConsulta;

    if (escolhida['forcarNova'] != true) {
      if (escolhida['fonte'] == 'local') {
        if (escolhida['dados_tratados'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A pesquisa ainda está em andamento. Aguarde a conclusão ou acesse pelo histórico.')));
          setState(() { _buscandoVeiculo = false; });
          return false;
        }
        // Reaproveitar dados antigos locais/nuvem supabase
        try {
          final veiculo = RadarVeiculo.fromJson(escolhida['dados_tratados']);
          _preencherDados(veiculo);
          return true;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao carregar dados antigos: $e')));
          return false;
        }
      } else if (escolhida['fonte'] == 'radar') {
        // Obteve o token da Radar e vai consultar os detalhes
        tokenConsulta = escolhida['tokenConsulta'];
      }
    }

    setState(() {
      _buscandoVeiculo = true;
      _veiculoEncontrado = false;
      _mensagemCarregamento = tokenConsulta != null
          ? 'Puxando detalhes da base...'
          : 'Consultando veículo...';
    });

    try {
      final service = sl<RadarService>();
      final veiculo = await service.consultarVeiculo(
        produto: _produtoSelecionado,
        param: _modoEntrada,
        value: valor,
        vistoriaId: '',
        forcarNova: escolhida['forcarNova'] == true,
        tokenConsulta: tokenConsulta,
      );

      if (mounted) {
        _preencherDados(veiculo);
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensagemCarregamento = 'Erro na consulta';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        // Aguarda 1s para o usuário ler "Consulta realizada com sucesso"
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _buscandoVeiculo = false;
          _mensagemCarregamento = '';
        });
      }
    }
  }

  // ── Retomar laudo ─────────────────────────────────────────────────────────

  Future<void> _buscarLaudo() async {
    final codigo = _laudoCtrl.text.trim().toUpperCase();
    if (codigo.isEmpty) return;
    setState(() => _buscandoLaudo = true);
    try {
      final dao = sl<VistoriaDao>();
      final vistoria = await dao.buscarPorNumeroLaudoOuId(codigo);

      if (vistoria != null) {
        if (mounted) {
          if (vistoria.status == 'concluido') {
            final diff = DateTime.now().difference(vistoria.updatedAt);
            if (diff.inHours > 72) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Laudo concluído há mais de 72h. Prazo de retificação expirado.'),
                  backgroundColor: AppTheme.naoConforme,
                ),
              );
              return;
            }
            // Retificar (dentro das 72h)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Modo Retificação ativado. (${72 - diff.inHours}h restantes)'),
                backgroundColor: AppTheme.comObs,
              ),
            );
          }
          context.push('/vistoria-wizard/${vistoria.id}');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Laudo "$codigo" não encontrado.'),
              backgroundColor: AppTheme.comObs,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar laudo: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoLaudo = false);
    }
  }

  Future<void> _iniciarVistoria() async {
    if (_placaEditCtrl.text.isEmpty || _chassiEditCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Placa e Chassi são obrigatórios.'),
          backgroundColor: AppTheme.naoConforme,
        ),
      );
      return;
    }

    try {
      final dao = sl<VistoriaDao>();
      final veiculoExistente =
          await dao.buscarVeiculoPorPlaca(_placaEditCtrl.text);
      String vistoriaId;
      bool reuse = false;

      if (veiculoExistente != null) {
        final vistoriaAnterior =
            await dao.buscarPorId(veiculoExistente.vistoriaId);
        if (vistoriaAnterior != null) {
          final diff = DateTime.now().difference(vistoriaAnterior.createdAt);
          if (diff.inHours <= 72) {
            reuse = true;
          }
        }
      }

      if (reuse) {
        vistoriaId = veiculoExistente!.vistoriaId;
        await dao.atualizarVeiculo(VeiculosCompanion(
          id: drift.Value(veiculoExistente.id),
          vistoriaId: drift.Value(veiculoExistente.vistoriaId),
          placa: drift.Value(_placaEditCtrl.text),
          chassiVeiculo: drift.Value(_chassiEditCtrl.text),
          motorVeiculo: drift.Value(_motorEditCtrl.text),
          marca: drift.Value(_marcaEditCtrl.text),
          modelo: drift.Value(_modeloEditCtrl.text),
          anoFabricacao: drift.Value(int.tryParse(_anoFabEditCtrl.text)),
          anoModelo: drift.Value(int.tryParse(_anoModEditCtrl.text)),
          cor: drift.Value(_corEditCtrl.text),
          renavam: drift.Value(_renavamEditCtrl.text),
        ));
      } else {
        vistoriaId = const Uuid().v4();
        final shortCode = vistoriaId.substring(0, 8).toUpperCase();
        final currentUserId = Supabase.instance.client.auth.currentUser?.id ??
            'usuario-deslogado';

        await dao.inserirVistoria(VistoriasCompanion.insert(
          id: vistoriaId,
          numeroLaudo: 'VST-$shortCode',
          vistoriadorId: currentUserId,
          tipoVistoria: drift.Value(widget.tipo.titulo),
        ));

        await dao.inserirVeiculo(VeiculosCompanion.insert(
          id: vistoriaId, // Usando o mesmo ID pro veículo localmente
          vistoriaId: vistoriaId,
          placa: _placaEditCtrl.text,
          chassiVeiculo: drift.Value(_chassiEditCtrl.text.isNotEmpty
              ? _chassiEditCtrl.text
              : (veiculoExistente?.chassiVeiculo ?? '')),
          motorVeiculo: drift.Value(_motorEditCtrl.text.isNotEmpty
              ? _motorEditCtrl.text
              : (veiculoExistente?.motorVeiculo ?? '')),
          marca: drift.Value(_marcaEditCtrl.text.isNotEmpty
              ? _marcaEditCtrl.text
              : (veiculoExistente?.marca ?? '')),
          modelo: drift.Value(_modeloEditCtrl.text.isNotEmpty
              ? _modeloEditCtrl.text
              : (veiculoExistente?.modelo ?? '')),
          anoFabricacao: drift.Value(int.tryParse(_anoFabEditCtrl.text) ??
              veiculoExistente?.anoFabricacao),
          anoModelo: drift.Value(int.tryParse(_anoModEditCtrl.text) ??
              veiculoExistente?.anoModelo),
          cor: drift.Value(_corEditCtrl.text.isNotEmpty
              ? _corEditCtrl.text
              : (veiculoExistente?.cor ?? '')),
          renavam: drift.Value(_renavamEditCtrl.text.isNotEmpty
              ? _renavamEditCtrl.text
              : (veiculoExistente?.renavam ?? '')),
          combustivel: drift.Value(veiculoExistente?.combustivel ?? ''),
        ));
      }

      if (mounted) {
        context.push('/vistoria-wizard/$vistoriaId', extra: {
          'dadosIniciais': {
            'placa': _placaEditCtrl.text,
            'chassi': _chassiEditCtrl.text,
            'motor': _motorEditCtrl.text,
            'marca': _marcaEditCtrl.text,
            'modelo': _modeloEditCtrl.text,
            'anoFabricacao': _anoFabEditCtrl.text,
            'anoModelo': _anoModEditCtrl.text,
            'cor': _corEditCtrl.text,
            'renavam': _renavamEditCtrl.text,
            'municipio': _municipioEditCtrl.text,
            'uf': _ufEditCtrl.text,
          },
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar vistoria: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  // ── Iniciar vistoria em background ────────────────────────────────────────

  Future<void> _iniciarVistoriaEmBackground() async {
    final valor = _buscaCtrl.text.trim();
    if (valor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a Placa, Chassi ou Motor para iniciar.'),
          backgroundColor: AppTheme.naoConforme,
        ),
      );
      return;
    }

    try {
      final dao = sl<VistoriaDao>();
      String vistoriaId;
      Veiculo? veiculoExistente;
      bool reuse = false;

      if (_modoEntrada == 'placa' && valor.isNotEmpty) {
        veiculoExistente = await dao.buscarVeiculoPorPlaca(valor);
      }

      bool forcarNova = false;
      String? tokenConsulta;
      Map<String, dynamic>? dadosReaproveitados;

      final escolhida = await _verificarNuvem(valor);
      if (escolhida == null) {
        setState(() { _buscandoVeiculo = false; });
        return; // Cancela se o usuário fechar o Dialog
      }

      if (escolhida['forcarNova'] == true) {
        forcarNova = true;
      } else {
        if (escolhida['fonte'] == 'local') {
          dadosReaproveitados = escolhida;
          reuse = true; // trata como reuso para pular a chamada à Radar API
        } else if (escolhida['fonte'] == 'radar') {
          // Se for via buscar histórico radar, a gente força nova local para bater na API com token
          forcarNova = true;
          tokenConsulta = escolhida['tokenConsulta'];
        }
      }

      if (reuse && dadosReaproveitados == null) {
        // Reuso local puro
        vistoriaId = veiculoExistente!.vistoriaId;
      } else {
        // Nova vistoria local, mas com ou sem dados da nuvem
        vistoriaId = DateTime.now().millisecondsSinceEpoch.toString();
        final shortCode = const Uuid().v4().substring(0, 8).toUpperCase();

        await dao.inserirVistoria(VistoriasCompanion.insert(
          id: vistoriaId,
          numeroLaudo: 'VST-$shortCode',
          vistoriadorId: 'local-user', // TODO: obter ID real do usuário
          tipoVistoria: drift.Value(widget.tipo.titulo),
        ));

        // Prepara objeto com dados que o usuário digitou ou que vieram da nuvem
        String chassi = _modoEntrada == 'chassi'
            ? valor
            : (veiculoExistente?.chassiVeiculo ?? '');
        String motor = _modoEntrada == 'motor'
            ? valor
            : (veiculoExistente?.motorVeiculo ?? '');
        String placa =
            _modoEntrada == 'placa' ? valor : (veiculoExistente?.placa ?? '');

        String combustivel = (veiculoExistente?.combustivel ?? '');

        if (dadosReaproveitados != null &&
            dadosReaproveitados['dados_tratados'] != null) {
          try {
            final veiculoNuvem =
                RadarVeiculo.fromJson(dadosReaproveitados['dados_tratados']);
            if (veiculoNuvem.placa.isNotEmpty) placa = veiculoNuvem.placa;
            if (veiculoNuvem.chassi.isNotEmpty) chassi = veiculoNuvem.chassi;
            if (veiculoNuvem.motor.isNotEmpty) motor = veiculoNuvem.motor;
            if (veiculoNuvem.combustivel.isNotEmpty) combustivel = veiculoNuvem.combustivel;
          } catch (_) {}
        }

        await dao.inserirVeiculo(VeiculosCompanion.insert(
          id: vistoriaId,
          vistoriaId: vistoriaId,
          placa: placa,
          chassiVeiculo: drift.Value(chassi),
          motorVeiculo: drift.Value(motor),
          combustivel: drift.Value(combustivel),
        ));
      }

      // Inicia consulta em segundo plano sem await apenas se for nova!
      if (!reuse && forcarNova) {
        final service = sl<RadarService>();
        service
            .consultarVeiculo(
          produto: _produtoSelecionado,
          param: _modoEntrada,
          value: valor,
          vistoriaId: vistoriaId,
          forcarNova: forcarNova,
          tokenConsulta: tokenConsulta,
        )
            .then((veiculoApi) async {
          final veiculoDb = await dao.buscarVeiculoPorVistoria(vistoriaId);
          if (veiculoDb != null) {
            final mm = veiculoApi.marcaModelo.split('/');
            final marca = mm.isNotEmpty ? mm[0].trim() : '';
            final modelo = mm.length > 1 ? mm[1].trim() : '';

            await dao.atualizarVeiculo(VeiculosCompanion(
              id: drift.Value(veiculoDb.id),
              vistoriaId: drift.Value(veiculoDb.vistoriaId),
              placa: drift.Value(veiculoApi.placa.isNotEmpty
                  ? veiculoApi.placa
                  : veiculoDb.placa),
              chassiVeiculo: drift.Value(veiculoApi.chassi.isNotEmpty
                  ? veiculoApi.chassi
                  : veiculoDb.chassiVeiculo),
              motorVeiculo: drift.Value(veiculoApi.motor.isNotEmpty
                  ? veiculoApi.motor
                  : veiculoDb.motorVeiculo),
              marca: drift.Value(marca.isNotEmpty ? marca : veiculoDb.marca),
              modelo:
                  drift.Value(modelo.isNotEmpty ? modelo : veiculoDb.modelo),
              anoFabricacao: drift.Value(
                  int.tryParse(veiculoApi.anoFabricacao) ??
                      veiculoDb.anoFabricacao),
              anoModelo: drift.Value(
                  int.tryParse(veiculoApi.anoModelo) ?? veiculoDb.anoModelo),
              cor: drift.Value(
                  veiculoApi.cor.isNotEmpty ? veiculoApi.cor : veiculoDb.cor),
              renavam: drift.Value(veiculoApi.renavam.isNotEmpty
                  ? veiculoApi.renavam
                  : veiculoDb.renavam),
              chassiBin: drift.Value(veiculoApi.chassi.isNotEmpty
                  ? veiculoApi.chassi
                  : veiculoDb.chassiBin),
              motorBin: drift.Value(veiculoApi.motor.isNotEmpty
                  ? veiculoApi.motor
                  : veiculoDb.motorBin),
              municipio: drift.Value(veiculoApi.municipio.isNotEmpty
                  ? veiculoApi.municipio
                  : veiculoDb.municipio),
              uf: drift.Value(veiculoApi.estado.isNotEmpty
                  ? veiculoApi.estado
                  : veiculoDb.uf),
              combustivel: drift.Value(veiculoApi.combustivel.isNotEmpty
                  ? veiculoApi.combustivel
                  : veiculoDb.combustivel),
            ));
          }
        }).catchError((_) {
          // Erros de background não interrompem a vistoria
        });
      }

      if (mounted) {
        context.push('/vistoria-wizard/$vistoriaId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao iniciar vistoria: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatarPlaca(String raw) {
    final limpo = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (limpo.length >= 7) {
      return '${limpo.substring(0, 3)}-${limpo.substring(3, 7)}';
    }
    return limpo;
  }

  bool _mostrarDetalhesPesquisa = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title:
            Text(_somentePesquisa ? 'Pesquisa Veicular' : widget.tipo.titulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Pesquisas Realizadas',
            onPressed: () => context.push('/historico-consultas'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown Tipo de Consulta
              DropdownButtonFormField<String>(
                initialValue: _produtoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Consulta',
                  prefixIcon: Icon(Icons.api_rounded, color: AppTheme.primary),
                ),
                items: _tiposConsulta.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['codigo'],
                    child: Text('${tipo['nome']}',
                        style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _produtoSelecionado = val);
                },
              ),
              const SizedBox(height: 14),

              // Toggle Placa / Chassi
              _ModoToggle2(
                modo: _modoEntrada,
                onChanged: (v) => setState(() {
                  _modoEntrada = v;
                  _buscaCtrl.clear();
                  _veiculoEncontrado = false;
                  _modoOffline = false;
                }),
              ),
              const SizedBox(height: 14),

              // Campo de busca
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buscaCtrl,
                      focusNode: _buscaFocus,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        if (_modoEntrada == 'placa') ...[
                          PlacaInputFormatter(),
                        ] else ...[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9\-]')),
                          LengthLimitingTextInputFormatter(25),
                        ]
                      ],
                      decoration: InputDecoration(
                        hintText: _modoEntrada == 'placa'
                            ? 'Ex: ABC-1234'
                            : 'Ex: 9BWZZZ...',
                        prefixIcon: Icon(
                          _modoEntrada == 'placa'
                              ? Icons.credit_card_rounded
                              : Icons.tag_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      onFieldSubmitted: (_) => _buscarVeiculo(),
                    ),
                  ),
                  if (_modoEntrada == 'placa') ...[
                    const SizedBox(width: 8),
                    _CameraButton(onTap: _abrirCamera),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Botão Iniciar / Pesquisar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _buscandoVeiculo
                      ? null
                      : () async {
                          if (_somentePesquisa) {
                            await _buscarVeiculo();
                          } else {
                            setState(() => _buscandoVeiculo = true);
                            await _iniciarVistoriaEmBackground();
                            if (mounted)
                              setState(() => _buscandoVeiculo = false);
                          }
                        },
                  icon: _buscandoVeiculo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(_somentePesquisa
                          ? Icons.search_rounded
                          : Icons.play_arrow_rounded),
                  label: Text(_buscandoVeiculo
                      ? (_somentePesquisa
                          ? 'Consultando...'
                          : 'Iniciando Vistoria...')
                      : (_somentePesquisa
                          ? 'Realizar Pesquisa'
                          : 'Consultar Veículo e Iniciar')),
                ),
              ),
              const SizedBox(height: 12),

              // Funcionalidade Preencher Manualmente / Offline removida a pedido do usuário

              if (!_veiculoEncontrado && !_modoOffline) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          color: AppTheme.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Dica de Vistoria',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'A consulta buscará automaticamente os dados oficiais do veículo, restrições e histórico para preencher o laudo com segurança.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_veiculoEncontrado || _modoOffline) ...[
                if (_somentePesquisa && !_modoOffline) ...[
                  const SizedBox(height: 28),
                  const _SectionHeader(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Pesquisa Concluída',
                    subtitle: 'A consulta veicular foi realizada com sucesso.',
                  ),
                  const SizedBox(height: 20),

                  // 2 BOTÕES DE AÇÃO: Acessar a Pesquisa & Baixar a Pesquisa
                  Row(
                    children: [
                      // Botão 1: Acessar a Pesquisa
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _mostrarDetalhesPesquisa =
                                  !_mostrarDetalhesPesquisa;
                            });
                          },
                          icon: Icon(
                            _mostrarDetalhesPesquisa
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _mostrarDetalhesPesquisa
                                ? 'Ocultar Pesquisa'
                                : 'Acessar a Pesquisa',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Botão 2: Baixar a Pesquisa
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.conforme,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (_arquivoPesquisaUrl != null &&
                                _arquivoPesquisaUrl!.isNotEmpty) {
                              final uri = Uri.parse(_arquivoPesquisaUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Não foi possível abrir o PDF.'),
                                    ),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'O relatório PDF da pesquisa está sendo processado.'),
                                  backgroundColor: AppTheme.comObs,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'Baixar a Pesquisa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dados da Pesquisa exibidos/acessados
                  if (_mostrarDetalhesPesquisa) ...[
                    _buildFormularioEditavel(),
                    const SizedBox(height: 16),
                  ],
                ] else ...[
                  const SizedBox(height: 32),
                  _SectionHeader(
                    icon: Icons.directions_car_rounded,
                    title: 'Dados da Vistoria',
                    subtitle: _modoOffline
                        ? 'Preencha os dados manualmente (Modo Offline)'
                        : 'Revise e edite os dados retornados',
                  ),
                  const SizedBox(height: 16),

                  // Formulário de Dados Retornados (Editáveis)
                  _buildFormularioEditavel(),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.conforme,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _iniciarVistoria,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text(
                        'Iniciar Vistoria',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ]
              ],

              // Opção para Retomar Laudo Existente removida a pedido do usuário
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioEditavel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_situacaoVeiculo != null && _situacaoVeiculo!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _situacaoVeiculo!.toLowerCase() == 'ok' ||
                        _situacaoVeiculo!.toLowerCase().contains('conforme')
                    ? AppTheme.conforme.withValues(alpha: 0.1)
                    : AppTheme.naoConforme.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _situacaoVeiculo!.toLowerCase() == 'ok' ||
                          _situacaoVeiculo!.toLowerCase().contains('conforme')
                      ? AppTheme.conforme
                      : AppTheme.naoConforme,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _situacaoVeiculo!.toLowerCase() == 'ok' ||
                            _situacaoVeiculo!.toLowerCase().contains('conforme')
                        ? Icons.check_circle_outline_rounded
                        : Icons.warning_amber_rounded,
                    color: _situacaoVeiculo!.toLowerCase() == 'ok' ||
                            _situacaoVeiculo!.toLowerCase().contains('conforme')
                        ? AppTheme.conforme
                        : AppTheme.naoConforme,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Situação do Veículo',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary),
                        ),
                        Text(
                          _situacaoVeiculo!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _situacaoVeiculo!.toLowerCase() == 'ok' ||
                                    _situacaoVeiculo!
                                        .toLowerCase()
                                        .contains('conforme')
                                ? AppTheme.conforme
                                : AppTheme.naoConforme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_arquivoPesquisaUrl != null &&
                      _arquivoPesquisaUrl!.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(_arquivoPesquisaUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Baixar Laudo',
                          style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                  child: TextFormField(
                controller: _placaEditCtrl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [PlacaInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Placa',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField('Renavam', _renavamEditCtrl,
                      icon: Icons.confirmation_num_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Chassi', _chassiEditCtrl, icon: Icons.tag_rounded),
          const SizedBox(height: 12),
          _buildField('Motor', _motorEditCtrl,
              icon: Icons.settings_applications_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField('Marca', _marcaEditCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Modelo', _modeloEditCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField('Ano Fab', _anoFabEditCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Ano Mod', _anoModEditCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildField('Cor', _corEditCtrl,
                      icon: Icons.color_lens_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _buildField('UF', _ufEditCtrl, icon: Icons.map_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField('Município', _municipioEditCtrl,
              icon: Icons.location_city_rounded),
          const SizedBox(height: 12),
          _buildField('Restrições', _restricoesEditCtrl,
              icon: Icons.warning_amber_rounded, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {IconData? icon, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppTheme.textSecondary, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.3),
        prefixIcon: icon != null
            ? Icon(icon,
                size: 20, color: AppTheme.primary.withValues(alpha: 0.7))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppTheme.surfaceVariant.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _TipoChip extends StatelessWidget {
  final TipoVistoria tipo;
  const _TipoChip({required this.tipo});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tipo.icone, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(tipo.titulo,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModoToggle2 extends StatelessWidget {
  final String modo;
  final ValueChanged<String> onChanged;
  const _ModoToggle2({required this.modo, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(label: 'Placa', value: 'placa', current: modo, onTap: onChanged),
          _Tab(
              label: 'Chassi',
              value: 'chassi',
              current: modo,
              onTap: onChanged),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _Tab(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CameraButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Fotografar placa',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SearchButton({required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.search_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class PlacaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.length > 7) text = text.substring(0, 7);

    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3) formatted += '-';
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
