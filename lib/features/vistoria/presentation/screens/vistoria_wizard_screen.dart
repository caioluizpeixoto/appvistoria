import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/daos/autocred_dao.dart';
import '../../../../database/app_database.dart';
import '../../../../core/utils/veiculo_parser.dart';
import 'package:drift/drift.dart' as drift;

import '../../domain/vistoria_wizard_state.dart';
import '../../../consulta_bin/data/services/radar_service.dart';
import '../../../consulta_bin/data/repositories/radar_repository.dart';
import '../../../consulta_bin/domain/entities/radar_veiculo.dart';
import 'steps/step_dados_gerais.dart';
import 'steps/step_dados_veiculo.dart';
import 'steps/step_fotos_externas.dart';
import 'steps/step_painel_hodometro.dart';
import 'steps/step_chassi_motor.dart';
import 'steps/step_etiquetas_vidros_placas.dart';
import 'steps/step_estrutura.dart';
import 'steps/step_pintura.dart';
import 'steps/step_fotos_extras.dart';
import 'steps/step_checklist_opcional.dart';
import 'steps/step_checklist_medidas.dart';
import 'steps/step_pintura_caminhao.dart';
import 'steps/step_checklist_inspecao.dart';
import 'steps/step_conclusao.dart';

/// Tela principal do wizard de Vistoria Cautelar Automotiva.
/// Gerencia o PageView com 14 etapas e persiste dados automaticamente.
class VistoriaWizardScreen extends StatefulWidget {
  final String vistoriaId;
  final Map<String, dynamic>? dadosIniciais;

  const VistoriaWizardScreen({
    super.key,
    required this.vistoriaId,
    this.dadosIniciais,
  });

  @override
  State<VistoriaWizardScreen> createState() => _VistoriaWizardScreenState();
}

class _VistoriaWizardScreenState extends State<VistoriaWizardScreen> {
  late VistoriaWizardState _wizardState;
  late PageController _pageController;
  final _dao = sl<VistoriaDao>();
  final _autocredDao = sl<AutocredDao>();
  bool _isSaving = false;
  bool _isPollingRadar = false;
  
  StreamSubscription? _veiculoSub;
  StreamSubscription? _consultaSub;

  List<_StepInfo> get _activeSteps {
    final isChecklist = _wizardState.isChecklist;
    final isChecklistPesado = _wizardState.isChecklistPesado;

    if (isChecklist) {
      return [
        const _StepInfo(
            titulo: 'Dados Gerais', icone: Icons.assignment_rounded),
        const _StepInfo(
            titulo: 'Dados do Veículo', icone: Icons.directions_car_rounded),
        if (isChecklistPesado)
          const _StepInfo(
              titulo: 'Medidas e Complementos',
              icone: Icons.straighten_rounded),
        const _StepInfo(
            titulo: 'Inspeção do Checklist', icone: Icons.fact_check_rounded),
        const _StepInfo(titulo: 'Conclusão', icone: Icons.verified_rounded),
      ];
    }

    final temCroqui = _wizardState.temCroqui;

    return [
      const _StepInfo(titulo: 'Dados Gerais', icone: Icons.assignment_rounded),
      const _StepInfo(
          titulo: 'Fotos Externas', icone: Icons.photo_camera_rounded),
      const _StepInfo(titulo: 'Vidros', icone: Icons.window_rounded),
      const _StepInfo(titulo: 'Painel / Hodômetro', icone: Icons.speed_rounded),
      const _StepInfo(titulo: 'Motor / Câmbio', icone: Icons.settings_rounded),
      const _StepInfo(
          titulo: 'Etiquetas / Chassi', icone: Icons.qr_code_rounded),
      if (temCroqui)
        const _StepInfo(titulo: 'Estrutura', icone: Icons.minor_crash_rounded),
      if (temCroqui && !_wizardState.isCaminhao)
        const _StepInfo(titulo: 'Pintura', icone: Icons.format_paint_rounded),
      if (_wizardState.isCaminhao)
        const _StepInfo(titulo: 'Pintura (Caminhão)', icone: Icons.color_lens_rounded),
      const _StepInfo(
          titulo: 'Fotos Extras', icone: Icons.add_photo_alternate_rounded),
      const _StepInfo(
          titulo: 'Dados do Veículo', icone: Icons.directions_car_rounded),
      const _StepInfo(
          titulo: 'Checklist Opcional', icone: Icons.checklist_rounded),
      const _StepInfo(titulo: 'Conclusão', icone: Icons.verified_rounded),
    ];
  }

  @override
  void initState() {
    super.initState();
    _wizardState = VistoriaWizardState(vistoriaId: widget.vistoriaId);
    if (widget.dadosIniciais != null) {
      _wizardState.preencherDadosVeiculo(widget.dadosIniciais!);
    }
    _pageController = PageController();
    _carregarEtapaAnterior();

    _veiculoSub =
        _dao.watchVeiculoPorVistoria(widget.vistoriaId).listen((veiculo) {
      if (veiculo != null && mounted) {
        bool changed = false;
        final s = _wizardState;
        if (veiculo.placa.isNotEmpty) {
          s.placa = veiculo.placa;
          changed = true;
        }
        if (veiculo.chassiVeiculo != null &&
            veiculo.chassiVeiculo!.isNotEmpty) {
          s.chassiVeiculo = veiculo.chassiVeiculo!;
          changed = true;
        }
        if (veiculo.chassiBin != null && veiculo.chassiBin!.isNotEmpty) {
          s.chassiBin = veiculo.chassiBin!;
          changed = true;
        }
        if (veiculo.motorVeiculo != null && veiculo.motorVeiculo!.isNotEmpty) {
          s.motorVeiculo = veiculo.motorVeiculo!;
          changed = true;
        }
        if (veiculo.motorBin != null && veiculo.motorBin!.isNotEmpty) {
          s.motorBin = veiculo.motorBin!;
          changed = true;
        }
        if (veiculo.cambioVeiculo != null &&
            veiculo.cambioVeiculo!.isNotEmpty) {
          s.cambioVeiculo = veiculo.cambioVeiculo!;
          changed = true;
        }
        if (veiculo.cambioBin != null && veiculo.cambioBin!.isNotEmpty) {
          s.cambioBin = veiculo.cambioBin!;
          changed = true;
        }
        if (veiculo.marca != null && veiculo.marca!.isNotEmpty) {
          s.marca = veiculo.marca!;
          changed = true;
        }
        if (veiculo.modelo != null && veiculo.modelo!.isNotEmpty) {
          s.modelo = veiculo.modelo!;
          changed = true;
        }
        if (veiculo.anoFabricacao != null &&
            veiculo.anoFabricacao!.toString().isNotEmpty) {
          s.anoFabricacao = veiculo.anoFabricacao!.toString();
          changed = true;
        }
        if (veiculo.anoModelo != null &&
            veiculo.anoModelo!.toString().isNotEmpty) {
          s.anoModelo = veiculo.anoModelo!.toString();
          changed = true;
        }
        if (veiculo.cor != null && veiculo.cor!.isNotEmpty) {
          s.cor = veiculo.cor!;
          changed = true;
        }
        if (veiculo.renavam != null && veiculo.renavam!.isNotEmpty) {
          s.renavam = veiculo.renavam!;
          changed = true;
        }
        if (veiculo.municipio != null && veiculo.municipio!.isNotEmpty) {
          s.municipio = veiculo.municipio!;
          changed = true;
        }
        if (veiculo.uf != null && veiculo.uf!.isNotEmpty) {
          s.uf = veiculo.uf!;
          changed = true;
        }
        if (veiculo.km != null && veiculo.km!.toString().isNotEmpty) {
          s.km = veiculo.km!.toString();
          changed = true;
        }
        if (veiculo.numeroGrv != null && veiculo.numeroGrv!.isNotEmpty) {
          s.numeroGrv = veiculo.numeroGrv!;
          changed = true;
        }
        if (veiculo.combustivel != null && veiculo.combustivel!.isNotEmpty) {
          s.combustivel = veiculo.combustivel!;
          changed = true;
        }
        if (veiculo.aiImage3dBase64 != null &&
            veiculo.aiImage3dBase64!.isNotEmpty &&
            veiculo.aiImage3dBase64 != s.aiImage3dBase64) {
          s.aiImage3dBase64 = veiculo.aiImage3dBase64!;
          changed = true;
        }
        if (changed) {
          s.forceUpdate();
        }
      }
    });

    _consultaSub = _autocredDao
        .watchConsultaPorVistoria(widget.vistoriaId)
        .listen((consulta) {
      if (consulta != null && mounted) {
        _wizardState.arquivoPesquisaUrl = consulta.arquivoPesquisaUrl ?? '';
        var novoStatus = consulta.status;
        final retornoBruto = consulta.retornoBruto ?? "";

        // Se no banco tá erro mas a msg for de andamento, tratamos visualmente como andamento
        if (novoStatus == 'erro' &&
            retornoBruto.contains('já está em andamento')) {
          novoStatus = 'andamento';
        }

        if (_wizardState.statusConsulta == 'pendente' && novoStatus == 'concluida') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('✅ Pesquisa concluída! Os dados foram preenchidos.'),
              backgroundColor: AppTheme.conforme,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (_wizardState.statusConsulta == 'pendente' && novoStatus == 'erro') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro na consulta: $retornoBruto'),
              backgroundColor: AppTheme.naoConforme,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        if (_wizardState.statusConsulta != novoStatus) {
          setState(() {
            _wizardState.setStatusConsulta(novoStatus);
          });
        }
      }
    });
  }

  Future<void> _iniciarAguardarPesquisa(String placa) async {
    if (_isPollingRadar) return;
    _isPollingRadar = true;

    setState(() {
      _wizardState.setStatusConsulta('andamento');
    });
    _wizardState.forceUpdate();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Aguardando conclusão da pesquisa na base de dados...')),
          ],
        ),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 4),
      ),
    );

    try {
      final service = sl<RadarService>();
      bool concluiu = false;
      int tentativas = 0;
      const maxTentativas = 24; // 24 * 5s = 120 segundos

      while (!concluiu && tentativas < maxTentativas && mounted) {
        tentativas++;
        await Future.delayed(const Duration(seconds: 5));
        if (!mounted) break;

        // 1. Checa na API da Radar se já há consultas finalizadas com token
        try {
          final radarConsultas = await service.listarConsultasRadar(param: 'placa', value: placa);
          if (radarConsultas.isNotEmpty) {
            final pronta = radarConsultas.firstWhere(
              (c) => c['token'] != null && c['token'].toString().isNotEmpty,
              orElse: () => null,
            );
            if (pronta != null) {
              await _aplicarDadosConsulta(
                fonte: 'radar',
                tokenConsulta: pronta['token'],
                produto: pronta['codigo_produto'] ?? 'auto_bin',
                placa: placa,
              );
              concluiu = true;
              break;
            }
          }
        } catch (_) {}

        // 2. Checa se o banco local/supabase já concluiu
        try {
          final consultaDb = await _autocredDao.buscarConsultaPorVistoria(widget.vistoriaId);
          if (consultaDb != null && consultaDb.status == 'concluida') {
            concluiu = true;
            if (mounted) {
              setState(() {
                _wizardState.setStatusConsulta('concluida');
              });
              _wizardState.forceUpdate();
            }
            break;
          }
        } catch (_) {}
      }

      if (!concluiu && mounted && (_wizardState.statusConsulta == 'andamento' || _wizardState.statusConsulta == 'pendente')) {
        setState(() {
          _wizardState.setStatusConsulta('timeout');
        });
        _wizardState.forceUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Tempo limite excedido ao aguardar pesquisa. Toque na nuvem para verificar novamente.'),
            backgroundColor: AppTheme.comObs,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted && (_wizardState.statusConsulta == 'andamento' || _wizardState.statusConsulta == 'pendente')) {
        setState(() {
          _wizardState.setStatusConsulta('erro');
        });
        _wizardState.forceUpdate();
      }
    } finally {
      _isPollingRadar = false;
    }
  }

  Future<void> _aplicarDadosConsulta({
    required String fonte,
    String? tokenConsulta,
    Map<String, dynamic>? dadosTratados,
    required String produto,
    required String placa,
  }) async {
    final service = sl<RadarService>();
    RadarVeiculo veiculoApi;

    if (fonte == 'local' && dadosTratados != null && dadosTratados.isNotEmpty) {
      veiculoApi = RadarVeiculo.fromJson(dadosTratados);
    } else {
      veiculoApi = await service.consultarVeiculo(
        produto: produto,
        param: 'placa',
        value: placa,
        vistoriaId: widget.vistoriaId,
        forcarNova: false,
        tokenConsulta: tokenConsulta,
      );
    }

    // Atualizar Veiculo no Banco de Dados
    final veiculoDb = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
    final mm = VeiculoParser.extrairMarcaModelo(veiculoApi.marcaModelo);
    if (veiculoDb != null) {
      await _dao.atualizarVeiculo(VeiculosCompanion(
        id: drift.Value(veiculoDb.id),
        vistoriaId: drift.Value(veiculoDb.vistoriaId),
        placa: drift.Value(
            veiculoApi.placa.isNotEmpty ? veiculoApi.placa : veiculoDb.placa),
        chassiVeiculo: drift.Value(veiculoApi.chassi.isNotEmpty
            ? veiculoApi.chassi
            : veiculoDb.chassiVeiculo),
        motorVeiculo: drift.Value(veiculoApi.motor.isNotEmpty
            ? veiculoApi.motor
            : veiculoDb.motorVeiculo),
        marca: drift.Value(
            mm.marca.isNotEmpty ? mm.marca : veiculoDb.marca),
        modelo: drift.Value(
            mm.modelo.isNotEmpty ? mm.modelo : veiculoDb.modelo),
        anoFabricacao: drift.Value(int.tryParse(veiculoApi.anoFabricacao) ??
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
        uf: drift.Value(
            veiculoApi.estado.isNotEmpty ? veiculoApi.estado : veiculoDb.uf),
        combustivel: drift.Value(veiculoApi.combustivel.isNotEmpty
            ? veiculoApi.combustivel
            : veiculoDb.combustivel),
      ));
    }

    if (mounted) {
      // Atualiza o estado em memória para a tela reagir imediatamente
      _wizardState.placa = veiculoApi.placa.isNotEmpty ? veiculoApi.placa : _wizardState.placa;
      _wizardState.chassiVeiculo = veiculoApi.chassi.isNotEmpty ? veiculoApi.chassi : _wizardState.chassiVeiculo;
      _wizardState.motorVeiculo = veiculoApi.motor.isNotEmpty ? veiculoApi.motor : _wizardState.motorVeiculo;
      _wizardState.marca = mm.marca.isNotEmpty ? mm.marca : _wizardState.marca;
      _wizardState.modelo = mm.modelo.isNotEmpty ? mm.modelo : _wizardState.modelo;
      _wizardState.anoFabricacao = veiculoApi.anoFabricacao.isNotEmpty ? veiculoApi.anoFabricacao : _wizardState.anoFabricacao;
      _wizardState.anoModelo = veiculoApi.anoModelo.isNotEmpty ? veiculoApi.anoModelo : _wizardState.anoModelo;
      _wizardState.cor = veiculoApi.cor.isNotEmpty ? veiculoApi.cor : _wizardState.cor;
      _wizardState.renavam = veiculoApi.renavam.isNotEmpty ? veiculoApi.renavam : _wizardState.renavam;
      _wizardState.chassiBin = veiculoApi.chassi.isNotEmpty ? veiculoApi.chassi : _wizardState.chassiBin;
      _wizardState.motorBin = veiculoApi.motor.isNotEmpty ? veiculoApi.motor : _wizardState.motorBin;
      _wizardState.municipio = veiculoApi.municipio.isNotEmpty ? veiculoApi.municipio : _wizardState.municipio;
      _wizardState.uf = veiculoApi.estado.isNotEmpty ? veiculoApi.estado : _wizardState.uf;
      _wizardState.combustivel = veiculoApi.combustivel.isNotEmpty ? veiculoApi.combustivel : _wizardState.combustivel;
      if (veiculoApi.arquivoPesquisaUrl != null && veiculoApi.arquivoPesquisaUrl!.isNotEmpty) {
        _wizardState.arquivoPesquisaUrl = veiculoApi.arquivoPesquisaUrl!;
      }

      setState(() {
        _wizardState.setStatusConsulta('concluida');
      });
      _wizardState.forceUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pesquisa vinculada e dados preenchidos com sucesso!'),
          backgroundColor: AppTheme.conforme,
        ),
      );
    }
  }

  Future<void> _retryRadarConsulta({bool blockUI = false}) async {
    final placa = _wizardState.placa.trim();
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A placa precisa estar preenchida para consultar.'),
          backgroundColor: AppTheme.naoConforme,
        ),
      );
      return;
    }

    // Se já estiver em andamento/pendente
    if (_wizardState.statusConsulta == 'pendente' || _wizardState.statusConsulta == 'andamento') {
      final forcar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Pesquisa em Andamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Já existe uma pesquisa em andamento para este veículo no momento.\n\nO aplicativo continuará aguardando a conclusão. Se a consulta anterior travou, você pode forçar uma nova pesquisa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuar Aguardando'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.naoConforme,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Forçar Nova Consulta'),
            ),
          ],
        ),
      );

      if (forcar == true) {
        final result = await _showSelectProdutoDialog(hideForcarNova: true);
        if (result != null) {
          final produto = result['produto'] as String;
          await _executarNovaConsulta(produto: produto, placa: placa, blockUI: blockUI);
        }
      }
      return;
    }

    // Modal de busca de pesquisas existentes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Buscando pesquisas existentes...'),
          ],
        ),
      ),
    );

    List<Map<String, dynamic>> combinadas = [];
    try {
      final repo = sl<RadarRepository>();
      final service = sl<RadarService>();

      final consultasNuvem = await repo.buscarConsultasRecentesNuvem('placa', placa);
      for (final c in consultasNuvem) {
        combinadas.add({...c, 'fonte': 'local'});
      }

      final radarConsultas = await service.listarConsultasRadar(param: 'placa', value: placa);
      for (final c in radarConsultas) {
        combinadas.add({
          'fonte': 'radar',
          'tokenConsulta': c['token'],
          'titulo': c['titulo'],
          'created_at': c['data_hora'] ?? c['ctime'],
          'codigo_produto': c['codigo_produto'],
        });
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
    } catch (e) {
      print('Erro ao buscar histórico: $e');
    } finally {
      if (mounted) Navigator.pop(context); // fecha loading
    }

    if (!mounted) return;

    if (combinadas.isNotEmpty) {
      final total = combinadas.length;
      final escolhida = await showDialog<Map<String, dynamic>>(
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
                child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pesquisas Encontradas ($total)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  'Identificamos $total pesquisa(s) pronta(s) para este veículo. Deseja utilizar uma pesquisa existente ou realizar uma nova consulta?',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
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
                            isRadar ? Icons.cloud_sync_rounded : Icons.history_rounded,
                            color: AppTheme.primary,
                          ),
                          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.naoConforme),
              onPressed: () => Navigator.of(ctx).pop({'forcarNova': true}),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: const Text('Realizar Nova Consulta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (escolhida == null) return; // Cancelou

      if (escolhida['forcarNova'] == true) {
        final result = await _showSelectProdutoDialog(hideForcarNova: true);
        if (result != null) {
          final produto = result['produto'] as String;
          await _executarNovaConsulta(produto: produto, placa: placa, blockUI: blockUI);
        }
        return;
      }

      // Utilizar pesquisa existente sem custo
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Puxando dados da pesquisa...'),
            ],
          ),
        ),
      );

      try {
        await _aplicarDadosConsulta(
          fonte: escolhida['fonte'] ?? 'radar',
          tokenConsulta: escolhida['tokenConsulta'],
          dadosTratados: escolhida['dados_tratados'],
          produto: escolhida['codigo_produto'] ?? 'auto_bin',
          placa: placa,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao aplicar dados da pesquisa: $e'), backgroundColor: AppTheme.naoConforme),
          );
        }
      } finally {
        if (mounted) Navigator.pop(context); // fecha loading
      }
    } else {
      // NÃO ENCONTROU PESQUISAS PRONTAS
      final acao = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 24),
              SizedBox(width: 10),
              Text('Pesquisa Veicular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Ainda não há pesquisa pronta no sistema para este veículo.\n\nDeseja aguardar a conclusão ou realizar uma nova pesquisa?',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancelar'),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'aguardar'),
              child: const Text('Aguardar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.naoConforme,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, 'nova'),
              child: const Text('Realizar Nova Pesquisa'),
            ),
          ],
        ),
      );

      if (acao == 'aguardar') {
        _iniciarAguardarPesquisa(placa);
      } else if (acao == 'nova') {
        final result = await _showSelectProdutoDialog(hideForcarNova: true);
        if (result != null) {
          final produto = result['produto'] as String;
          await _executarNovaConsulta(produto: produto, placa: placa, blockUI: blockUI);
        }
      }
    }
  }

  Future<void> _executarNovaConsulta({
    required String produto,
    required String placa,
    bool blockUI = false,
  }) async {
    setState(() {
      _wizardState.setStatusConsulta('pendente');
    });

    if (blockUI) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Consultando base de dados...'),
            ],
          ),
        ),
      );
    }

    try {
      final service = sl<RadarService>();
      final veiculoApi = await service.consultarVeiculo(
        produto: produto,
        param: 'placa',
        value: placa,
        vistoriaId: widget.vistoriaId,
        forcarNova: true,
      );

      if (blockUI && mounted) Navigator.pop(context);

      await _aplicarDadosConsulta(
        fonte: 'radar',
        tokenConsulta: veiculoApi.resultadoCompleto['token-consulta']?.toString(),
        produto: produto,
        placa: placa,
      );
    } catch (e) {
      if (blockUI && mounted) Navigator.pop(context);
      if (mounted) {
        String cleanError = e.toString().replaceAll('Exception: ', '').trim();
        if (cleanError.contains('já está em andamento')) {
          setState(() {
            _wizardState.setStatusConsulta('andamento');
          });
          _iniciarAguardarPesquisa(placa);
        } else {
          setState(() {
            _wizardState.setStatusConsulta('erro');
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanError),
            backgroundColor: cleanError.contains('já está em andamento')
                ? Colors.orange[800]
                : AppTheme.naoConforme,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showSelectProdutoDialog({bool hideForcarNova = false}) async {
    bool forcarNova = false;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateBuilder) {
          return AlertDialog(
            title: const Text('Consultar Base',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hideForcarNova)
                  const Text(
                      'Dica: Para apenas atualizar/puxar o resultado de uma consulta demorada, deixe a caixa abaixo DESMARCADA.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (hideForcarNova)
                  const Text(
                      'Selecione a base para realizar a nova consulta.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('AUTO BIN (Simples)'),
                  onTap: () => Navigator.pop(
                      ctx, {'produto': 'auto_bin', 'forcarNova': forcarNova}),
                ),
                ListTile(
                  title: const Text('AUTO PERÍCIA'),
                  onTap: () => Navigator.pop(ctx,
                      {'produto': 'auto_pericia', 'forcarNova': forcarNova}),
                ),
                ListTile(
                  title: const Text('AUTO PERÍCIA HRF'),
                  onTap: () => Navigator.pop(ctx,
                      {'produto': 'auto_pericia_hrf', 'forcarNova': forcarNova}),
                ),
                ListTile(
                  title: const Text('AUTO COMPLETA'),
                  onTap: () => Navigator.pop(ctx,
                      {'produto': 'auto_completa', 'forcarNova': forcarNova}),
                ),
                ListTile(
                  title: const Text('AUTO LEILÃO'),
                  onTap: () => Navigator.pop(ctx,
                      {'produto': 'auto_leilao', 'forcarNova': forcarNova}),
                ),
                if (!hideForcarNova) ...[
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('Forçar NOVA consulta',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                        'Faz uma nova busca na base (Pode demorar mais)',
                        style: TextStyle(fontSize: 11)),
                    value: forcarNova,
                    onChanged: (val) {
                      setStateBuilder(() {
                        forcarNova = val ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _carregarEtapaAnterior() async {
    final vistoria = await _dao.buscarPorId(widget.vistoriaId);
    if (vistoria != null) {
      _wizardState.numeroLaudo = vistoria.numeroLaudo;
      _wizardState.clienteNome = vistoria.clienteNome ?? '';
      _wizardState.clienteEmail = vistoria.clienteEmail ?? '';
      _wizardState.clienteCpf = vistoria.clienteCpf ?? '';
      _wizardState.clienteTelefone = vistoria.clienteTelefone ?? '';
      _wizardState.vistoriadorNome = vistoria.vistoriadorNome ?? '';
      _wizardState.vistoriadorCpf = vistoria.vistoriadorCpf ?? '';
      _wizardState.unidade = vistoria.unidade ?? '';
      _wizardState.assinaturaPath = vistoria.assinaturaPath;
      _wizardState.observacoesVistoriador = vistoria.observacoesGerais ?? '';
      _wizardState.parecerTecnico = vistoria.parecerTecnico ?? '';
      _wizardState.resultadoFinal = vistoria.statusFinal ?? '';
      _wizardState.status = vistoria.status;
      if (vistoria.tipoVistoria != null) {
        if (vistoria.tipoVistoria == 'cautelar_carro') {
          _wizardState.tipoVistoria = 'Vistoria Cautelar Automotiva';
        } else {
          _wizardState.tipoVistoria = vistoria.tipoVistoria!;
        }
      }
    }

    // Carregar veículo (caso venha do histórico sem dadosIniciais)
    if (widget.dadosIniciais == null) {
      final veiculo = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
      if (veiculo != null) {
        _wizardState.placa = veiculo.placa;
        _wizardState.chassiVeiculo = veiculo.chassiVeiculo ?? '';
        _wizardState.motorVeiculo = veiculo.motorVeiculo ?? '';
        _wizardState.marca = veiculo.marca ?? '';
        _wizardState.modelo = veiculo.modelo ?? '';
        _wizardState.anoFabricacao = veiculo.anoFabricacao?.toString() ?? '';
        _wizardState.anoModelo = veiculo.anoModelo?.toString() ?? '';
        _wizardState.cor = veiculo.cor ?? '';
        _wizardState.renavam = veiculo.renavam ?? '';
        _wizardState.chassiBin = veiculo.chassiBin ?? '';
        _wizardState.motorBin = veiculo.motorBin ?? '';
        _wizardState.cambioVeiculo = veiculo.cambioVeiculo ?? '';
        _wizardState.cambioBin = veiculo.cambioBin ?? '';
        _wizardState.km = veiculo.km?.toString() ?? '';
        _wizardState.numeroGrv = veiculo.numeroGrv ?? '';
        _wizardState.municipio = veiculo.municipio ?? '';
        _wizardState.uf = veiculo.uf ?? '';
        _wizardState.combustivel = veiculo.combustivel ?? '';
        _wizardState.aiImage3dBase64 = veiculo.aiImage3dBase64;
      }
    }

    // Carregar Itens
    final itens = await _dao.listarItensPorVistoria(widget.vistoriaId);
    bool temPinturaPreenchida = false;
    for (final item in itens) {
      if (item.etapa == 'checklist_opcional') {
        _wizardState.realizarChecklistOpcional = true;
        _wizardState.checklistOpcional[item.nome] = item.status;
      } else {
        _wizardState.checklistStatus[item.nome] = item.status;
        _wizardState.checklistObs[item.nome] = item.observacao ?? '';
        if (item.nome.startsWith('peca_') && (item.status.isNotEmpty || (item.observacao ?? '').isNotEmpty)) {
          temPinturaPreenchida = true;
        }
      }
    }
    if (temPinturaPreenchida) {
      _wizardState.realizarAvaliacaoPintura = true;
    }
    if (_wizardState.checklistStatus.containsKey('consulta_leilao')) {
      _wizardState.statusLeilao = _wizardState.checklistStatus['consulta_leilao']!;
    }
    if (_wizardState.checklistStatus.containsKey('consulta_sinistro')) {
      _wizardState.statusSinistro = _wizardState.checklistStatus['consulta_sinistro']!;
    }
    if (_wizardState.checklistStatus.containsKey('consulta_roubo')) {
      _wizardState.statusRoubo = _wizardState.checklistStatus['consulta_roubo']!;
    }
    if (_wizardState.checklistStatus.containsKey('consulta_renajud')) {
      _wizardState.statusRenajud = _wizardState.checklistStatus['consulta_renajud']!;
    }
    if (_wizardState.checklistStatus.containsKey('consulta_alerta_indicio')) {
      _wizardState.statusAlertaIndicio = _wizardState.checklistStatus['consulta_alerta_indicio']!;
    }

    // Carregar Fotos
    final fotos = await _dao.listarFotosPorVistoria(widget.vistoriaId);
    for (final foto in fotos) {
      if (foto.etapa == 'extra') {
        _wizardState.fotosExtras.add({
          'pathLocal': foto.pathLocal ?? '',
          'url': foto.urlSupabase,
          'obs': foto.observacao ?? '',
          'titulo': 'Foto Extra',
          'categoria': 'Outro',
        });
      } else if (foto.etapa == 'video_estrutural') {
        _wizardState.videoEstruturalPath = foto.pathLocal;
        _wizardState.videoEstruturalUrl = foto.urlSupabase;
      } else {
        if (foto.pathLocal != null) {
          final itemId = foto.itemId ?? 'desconhecido';
          _wizardState.fotosLocais
              .putIfAbsent(itemId, () => [])
              .add(foto.pathLocal!);
        }
      }
    }
    // Refresh UI
    // To update listeners, we should call a method on the state, or wait for next build since setState is called somewhere.
    // We can just call a dummy method on wizard state if needed, or create forceUpdate.
    _wizardState.forceUpdate();

    if (vistoria != null && vistoria.etapaAtual > 0) {
      _wizardState.currentStep = vistoria.etapaAtual;
      if (_wizardState.currentStep >= _wizardState.totalSteps) {
        _wizardState.currentStep = _wizardState.totalSteps - 1;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(_wizardState.currentStep);
      });
    }
  }

  @override
  void dispose() {
    _veiculoSub?.cancel();
    _consultaSub?.cancel();
    _pageController.dispose();
    _wizardState.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final s = _wizardState;

      // Atualiza dados gerais na vistoria
      await _dao.atualizarVistoria(VistoriasCompanion(
        id: drift.Value(widget.vistoriaId),
        clienteNome: drift.Value(s.clienteNome),
        clienteEmail: drift.Value(s.clienteEmail),
        clienteCpf: drift.Value(s.clienteCpf),
        clienteTelefone: drift.Value(s.clienteTelefone),
        unidade: drift.Value(s.unidade),
        tipoVistoria: drift.Value(s.tipoVistoria),
        vistoriadorNome: drift.Value(s.vistoriadorNome),
        vistoriadorCpf: drift.Value(s.vistoriadorCpf),
        observacoesGerais: drift.Value(s.observacoesVeiculo),
        etapaAtual: drift.Value(s.currentStep),
        updatedAt: drift.Value(DateTime.now()),
      ));

      // Atualiza veículo
      final veiculo = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
      if (veiculo != null) {
        await _dao.atualizarVeiculo(VeiculosCompanion(
          id: drift.Value(veiculo.id),
          vistoriaId: drift.Value(widget.vistoriaId),
          placa: drift.Value(s.placa),
          chassiBin: drift.Value(s.chassiBin),
          chassiVeiculo: drift.Value(s.chassiVeiculo),
          motorBin: drift.Value(s.motorBin),
          motorVeiculo: drift.Value(s.motorVeiculo),
          cambioBin: drift.Value(s.cambioBin),
          cambioVeiculo: drift.Value(s.cambioVeiculo),
          renavam: drift.Value(s.renavam),
          marca: drift.Value(s.marca),
          modelo: drift.Value(s.modelo),
          anoFabricacao: drift.Value(int.tryParse(s.anoFabricacao)),
          anoModelo: drift.Value(int.tryParse(s.anoModelo)),
          cor: drift.Value(s.cor),
          combustivel: drift.Value(s.combustivel),
          km: drift.Value(int.tryParse(s.km)),
          municipio: drift.Value(s.municipio),
          uf: drift.Value(s.uf),
          numeroGrv: drift.Value(s.numeroGrv),
          aiImage3dBase64: drift.Value(s.aiImage3dBase64),
        ));
      }

      // Salvar Itens do Checklist
      await _dao.deletarItensPorVistoria(widget.vistoriaId);
      for (final entry in s.checklistStatus.entries) {
        final itemId = entry.key;
        final status = entry.value;
        final obs = s.checklistObs[itemId] ?? '';

        await _dao.inserirOuAtualizarItem(ItensVistoriaCompanion(
          id: drift.Value('${widget.vistoriaId}_$itemId'),
          vistoriaId: drift.Value(widget.vistoriaId),
          etapa: const drift.Value('wizard'),
          categoria: const drift.Value('item'),
          nome: drift.Value(itemId),
          status: drift.Value(status),
          observacao: drift.Value(obs),
        ));
      }

      // Salvar Checklist Opcional se habilitado
      if (s.realizarChecklistOpcional || s.realizarAvaliacaoPintura) {
        for (final entry in s.checklistOpcional.entries) {
          final obs = s.checklistOpcionalMotivos[entry.key] ?? '';
          await _dao.inserirOuAtualizarItem(ItensVistoriaCompanion(
            id: drift.Value('${widget.vistoriaId}_checklist_${entry.key}'),
            vistoriaId: drift.Value(widget.vistoriaId),
            etapa: const drift.Value('checklist_opcional'),
            categoria: const drift.Value('opcional'),
            nome: drift.Value(entry.key),
            status: drift.Value(entry.value),
            observacao: drift.Value(obs),
          ));
        }
      }

      // Salvar Fotos
      await _dao.deletarFotosPorVistoria(widget.vistoriaId);
      for (final entry in s.fotosLocais.entries) {
        final itemId = entry.key;
        for (int i = 0; i < entry.value.length; i++) {
          final path = entry.value[i];
          await _dao.inserirFoto(FotosVistoriaCompanion.insert(
            id: '${widget.vistoriaId}_${itemId}_$i',
            vistoriaId: widget.vistoriaId,
            legenda: itemId.replaceAll('_', ' ').toUpperCase(),
            etapa: drift.Value('wizard'),
            itemId: drift.Value(itemId),
            pathLocal: drift.Value(path),
            ordem: drift.Value(i),
            obrigatoria: drift.Value(s.fotosObrigatorias.contains(itemId)),
          ));
        }
      }

      // Fotos Extras
      for (int i = 0; i < s.fotosExtras.length; i++) {
        final extra = s.fotosExtras[i];
        await _dao.inserirFoto(FotosVistoriaCompanion.insert(
          id: '${widget.vistoriaId}_extra_$i',
          vistoriaId: widget.vistoriaId,
          legenda: extra['titulo'] ?? 'Foto Extra',
          etapa: const drift.Value('extra'),
          itemId: drift.Value('extra_$i'),
          pathLocal: drift.Value(extra['pathLocal'] as String?),
          urlSupabase: drift.Value(extra['url'] as String?),
          observacao: drift.Value(extra['obs'] as String?),
          ordem: drift.Value(i),
          obrigatoria: const drift.Value(false),
        ));
      }

      // Vídeo Estrutural
      if (s.videoEstruturalPath != null) {
        await _dao.inserirFoto(FotosVistoriaCompanion.insert(
          id: '${widget.vistoriaId}_video_estrutural',
          vistoriaId: widget.vistoriaId,
          legenda: 'Vídeo Estrutural',
          etapa: const drift.Value('video_estrutural'),
          itemId: const drift.Value('video_estrutural'),
          pathLocal: drift.Value(s.videoEstruturalPath),
          urlSupabase: drift.Value(s.videoEstruturalUrl),
          ordem: const drift.Value(0),
          obrigatoria: const drift.Value(false),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Vistoria salva!'),
            backgroundColor: AppTheme.conforme,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _salvarESair() async {
    await _salvar();
    if (mounted) {
      context.go('/home');
    }
  }

  bool _validarFotosComStatus() {
    final fotosComStatusVazio = <String>[];
    for (final entry in _wizardState.fotosLocais.entries) {
      final id = entry.key;
      final fileList = entry.value;
      if (fileList.isNotEmpty) {
        final status = _wizardState.checklistStatus[id];
        if (status == null || status.trim().isEmpty) {
          fotosComStatusVazio.add(id);
        }
      }
    }

    if (fotosComStatusVazio.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Status Obrigatório', style: TextStyle(color: Colors.red)),
          content: const Text('Você adicionou fotos em alguns itens, mas esqueceu de preencher o status deles. Por favor, selecione um status antes de avançar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _proximo() async {
    if (!_validarFotosComStatus()) return;

    // Salvar automaticamente ao avançar
    await _salvar();
    if (!mounted) return;

    if (_wizardState.currentStep >= _activeSteps.length - 1) {
      _confirmarFinalizar();
    } else {
      _wizardState.goToStep(_wizardState.currentStep + 1);
      _pageController.animateToPage(
        _wizardState.currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _voltar() {
    if (_wizardState.currentStep <= 0) {
      _confirmarSair();
    } else {
      _wizardState.goToStep(_wizardState.currentStep - 1);
      _pageController.animateToPage(
        _wizardState.currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _confirmarSair() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vistoria: ${_wizardState.tipoVistoria}',
            style: const TextStyle(fontSize: 16)),
        content: const Text(
            'O progresso foi salvo. Você pode retomar depois pelo histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.naoConforme),
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _confirmarFinalizar() async {
    if (!_wizardState.isChecklist && (_wizardState.statusConsulta == 'pendente' || _wizardState.statusConsulta == 'andamento')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pesquisa em Andamento', style: TextStyle(color: Colors.orange)),
          content: const Text('PESQUISA AINDA EM ANDAMENTO aguarde até que seja concluída.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }
    final faltando = _wizardState.fotasObrigatoriasFaltando;
    final semAssinatura = _wizardState.assinaturaPath == null;
    final semResultado = _wizardState.resultadoFinal.isEmpty;

    // TEMPORÁRIO PARA TESTES: Ignora todas as validações de fotos, assinatura e resultado
    if (false && (faltando.isNotEmpty || semAssinatura || semResultado)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Pendências encontradas'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (faltando.isNotEmpty) ...[
                  const Text('Fotos obrigatórias faltando:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  ...faltando.map((f) => Text('• ${f.replaceAll('_', ' ')}',
                      style: const TextStyle(fontSize: 13))),
                  const SizedBox(height: 8),
                ],
                if (semAssinatura)
                  const Text('• Assinatura digital obrigatória',
                      style: TextStyle(fontSize: 13)),
                if (semResultado)
                  const Text('• Resultado final não selecionado',
                      style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          actions: [
            if (faltando.isNotEmpty && !semAssinatura && !semResultado)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/revisao/${widget.vistoriaId}', extra: {
                    'wizardState': _wizardState,
                  });
                },
                child: const Text('Gerar mesmo assim',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Corrigir'),
            ),
          ],
        ),
      );
      return;
    }

    // Tudo ok, verifica se já fez pesquisa (exceto para Checklists, que são manuais)
    if (!_wizardState.isChecklist &&
        (_wizardState.statusConsulta == 'nenhuma' || _wizardState.statusConsulta == 'erro')) {
      final querPesquisar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pesquisa de Veículo'),
          content: const Text(
              'Você não realizou a pesquisa na base para este veículo. Deseja selecionar o estilo de pesquisa antes de gerar o laudo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ir sem pesquisa',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Selecionar Pesquisa'),
            ),
          ],
        ),
      );

      if (querPesquisar == true) {
        await _retryRadarConsulta(blockUI: true);
      }
    }

    // Pergunta sobre a Ficha Técnica com IA antes de gerar o laudo
    final desejaFichaIa = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 24),
            SizedBox(width: 10),
            Text('Ficha Técnica com IA',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Deseja realizar a Ficha Técnica Inteligente com IA (especificações e estimativa de valores) para este veículo?',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.textSecondary),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sim, Gerar com IA',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (desejaFichaIa != null) {
      _wizardState.gerarFichaTecnicaComIa = desejaFichaIa;
    }

    if (!mounted) return;

    // Vai para a revisão
    context.push('/revisao/${widget.vistoriaId}', extra: {
      'wizardState': _wizardState,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VistoriaWizardState>.value(
      value: _wizardState,
      child: Consumer<VistoriaWizardState>(
        builder: (ctx, state, _) {
          final step = state.currentStep;
          final info = _activeSteps[step];
          final progress = (step + 1) / _activeSteps.length;

          return Scaffold(
            backgroundColor: AppTheme.background,
            // ── AppBar com progresso ──────────────────────────────────────
            appBar: AppBar(
              backgroundColor: AppTheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _voltar,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.titulo,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(
                    'Etapa ${step + 1} de ${_activeSteps.length}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              actions: [
                if (!_wizardState.isChecklist) ...[
                  if (_wizardState.statusConsulta == 'pendente' || _wizardState.statusConsulta == 'andamento')
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message: 'Pesquisando na base... (Toque para opções)',
                          child: InkWell(
                            onTap: _retryRadarConsulta,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_wizardState.statusConsulta == 'concluida')
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message:
                              'Pesquisa concluída. Clique para atualizar novamente.',
                          child: InkWell(
                            onTap: _retryRadarConsulta,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.cloud_done_rounded,
                                  color: Colors.greenAccent, size: 22),
                            ),
                          ),
                        ),
                      ),
                    )

                  else if (_wizardState.statusConsulta == 'erro')
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message:
                              'Erro na pesquisa. Tocar para tentar novamente.',
                          child: InkWell(
                            onTap: _retryRadarConsulta,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.cloud_off_rounded,
                                  color: Colors.redAccent, size: 22),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_wizardState.statusConsulta == 'timeout')
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message:
                              'A pesquisa está demorando. Toque para puxar os dados atualizados.',
                          child: InkWell(
                            onTap: _retryRadarConsulta,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.schedule_rounded,
                                  color: Colors.amber, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                IconButton(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  tooltip: 'Salvar e Sair',
                  onPressed: _salvarESair,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: _WizardProgressBar(progress: progress),
              ),
            ),

            // ── Stepper rápido (toque para navegar) ──────────────────────
            body: Column(
              children: [
                _StepIndicatorRow(
                  steps: _activeSteps,
                  currentStep: step,
                  onTap: (i) {
                    state.goToStep(i);
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),

                // ── Conteúdo das etapas ───────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeSteps.length,
                    itemBuilder: (ctx, idx) {
                      final titulo = _activeSteps[idx].titulo;
                      if (titulo == 'Dados Gerais')
                        return const StepDadosGerais();
                      if (titulo == 'Fotos Externas')
                        return const StepFotosExternas();
                      if (titulo == 'Vidros') return const StepVidros();
                      if (titulo == 'Painel / Hodômetro')
                        return const StepPainelHodometro();
                      if (titulo == 'Motor / Câmbio')
                        return const StepMotorCambio();
                      if (titulo == 'Etiquetas / Chassi')
                        return const StepEtiquetasChassi();
                      if (titulo == 'Estrutura') return const StepEstrutura();
                      if (titulo == 'Pintura') return const StepPintura();
                      if (titulo == 'Pintura (Caminhão)') return const StepPinturaCaminhao();
                      if (titulo == 'Fotos Extras')
                        return const StepFotosExtras();
                      if (titulo == 'Dados do Veículo')
                        return const StepDadosVeiculo();
                      if (titulo == 'Checklist Opcional')
                        return const StepChecklistOpcional();
                      if (titulo == 'Medidas e Complementos')
                        return const StepChecklistMedidas();
                      if (titulo == 'Inspeção do Checklist')
                        return const StepChecklistInspecao();
                      return const StepConclusao();
                    },
                  ),
                ),
              ],
            ),

            // ── Botões de navegação ───────────────────────────────────────
            bottomNavigationBar: _WizardNavBar(
              isFirst: state.currentStep <= 0,
              isLast: state.currentStep >= _activeSteps.length - 1,
              isSaving: _isSaving,
              onVoltar: _voltar,
              onSalvar: _salvar,
              onProximo: _proximo,
            ),
          );
        },
      ),
    );
  }
}

// ── Barra de progresso ────────────────────────────────────────────────────────

class _WizardProgressBar extends StatelessWidget {
  final double progress;
  const _WizardProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white.withValues(alpha: 0.3),
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      minHeight: 4,
    );
  }
}

// ── Indicador de etapas (scrollable) ─────────────────────────────────────────

class _StepIndicatorRow extends StatefulWidget {
  final List<_StepInfo> steps;
  final int currentStep;
  final ValueChanged<int> onTap;
  const _StepIndicatorRow(
      {required this.steps, required this.currentStep, required this.onTap});

  @override
  State<_StepIndicatorRow> createState() => _StepIndicatorRowState();
}

class _StepIndicatorRowState extends State<_StepIndicatorRow> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant _StepIndicatorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollToCurrent();
    }
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    // O item inativo tem aproximadamente 46px de largura + 12px de margem = 58px.
    // Tenta centralizar a etapa atual subtraindo metade da largura da tela.
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (widget.currentStep * 58.0) - (screenWidth / 2) + 50;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = offset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      color: AppTheme.surface,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: widget.steps.length,
        itemBuilder: (ctx, i) {
          final isActive = i == widget.currentStep;
          final isDone = i < widget.currentStep;
          return GestureDetector(
            onTap: () => widget.onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 10, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.steps[i].icone,
                    size: 18,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.steps[i].titulo,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Barra de navegação inferior ───────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isSaving;
  final VoidCallback onVoltar;
  final VoidCallback onSalvar;
  final VoidCallback onProximo;

  const _WizardNavBar({
    required this.isFirst,
    required this.isLast,
    required this.isSaving,
    required this.onVoltar,
    required this.onSalvar,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Voltar
          SizedBox(
            width: 80,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.border),
              ),
              onPressed: onVoltar,
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Salvar (médio)
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isSaving ? null : onSalvar,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Salvar'),
            ),
          ),
          const SizedBox(width: 8),

          // Próximo / Finalizar
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: isLast ? AppTheme.conforme : AppTheme.primary,
              ),
              onPressed: isSaving ? null : onProximo,
              icon: Icon(
                isLast
                    ? Icons.picture_as_pdf_rounded
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(isLast ? 'Gerar Laudo' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dado de uma etapa ─────────────────────────────────────────────────────────

class _StepInfo {
  final String titulo;
  final IconData icone;
  const _StepInfo({required this.titulo, required this.icone});
}
