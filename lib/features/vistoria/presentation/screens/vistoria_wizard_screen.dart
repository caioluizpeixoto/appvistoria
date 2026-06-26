import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/daos/autocred_dao.dart';
import '../../../../database/app_database.dart';
import 'package:drift/drift.dart' as drift;

import '../../domain/vistoria_wizard_state.dart';
import '../../../consulta_bin/data/services/radar_service.dart';
import 'steps/step_dados_gerais.dart';
import 'steps/step_dados_veiculo.dart';
import 'steps/step_fotos_externas.dart';
import 'steps/step_painel_hodometro.dart';
import 'steps/step_chassi_motor.dart';
import 'steps/step_etiquetas_vidros_placas.dart';
import 'steps/step_estrutura.dart';
import 'steps/step_pintura.dart';
import 'steps/step_fotos_extras.dart';
import 'steps/step_observacoes.dart';
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
  String _statusConsulta = 'nenhuma'; // 'pendente', 'concluida', 'erro', ou 'nenhuma'
  StreamSubscription? _veiculoSub;
  StreamSubscription? _consultaSub;

  List<_StepInfo> get _activeSteps {
    final temCroqui = _wizardState.temCroqui;
    final temAvarias = _wizardState.temAvarias;
    
    return [
      const _StepInfo(titulo: 'Dados Gerais', icone: Icons.assignment_rounded),
      const _StepInfo(titulo: 'Fotos Externas', icone: Icons.photo_camera_rounded),
      const _StepInfo(titulo: 'Vidros', icone: Icons.window_rounded),
      const _StepInfo(titulo: 'Hodômetro', icone: Icons.speed_rounded),
      const _StepInfo(titulo: 'Motor e Câmbio', icone: Icons.settings_rounded),
      const _StepInfo(titulo: 'Etiquetas e Chassi', icone: Icons.qr_code_rounded),
      if (temCroqui) const _StepInfo(titulo: 'Estrutura', icone: Icons.car_repair_rounded),
      if (temAvarias) const _StepInfo(titulo: 'Pintura', icone: Icons.format_paint_rounded),
      const _StepInfo(titulo: 'Observações', icone: Icons.notes_rounded),
      const _StepInfo(titulo: 'Fotos Extras', icone: Icons.add_photo_alternate_rounded),
      const _StepInfo(titulo: 'Dados do Veículo', icone: Icons.directions_car_rounded),
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

    _veiculoSub = _dao.watchVeiculoPorVistoria(widget.vistoriaId).listen((veiculo) {
      if (veiculo != null && mounted) {
        bool changed = false;
        final s = _wizardState;
        if (veiculo.placa.isNotEmpty) { s.placa = veiculo.placa; changed = true; }
        if (veiculo.chassiVeiculo != null && veiculo.chassiVeiculo!.isNotEmpty) { s.chassiVeiculo = veiculo.chassiVeiculo!; changed = true; }
        if (veiculo.chassiBin != null && veiculo.chassiBin!.isNotEmpty) { s.chassiBin = veiculo.chassiBin!; changed = true; }
        if (veiculo.motorVeiculo != null && veiculo.motorVeiculo!.isNotEmpty) { s.motorVeiculo = veiculo.motorVeiculo!; changed = true; }
        if (veiculo.motorBin != null && veiculo.motorBin!.isNotEmpty) { s.motorBin = veiculo.motorBin!; changed = true; }
        if (veiculo.cambioVeiculo != null && veiculo.cambioVeiculo!.isNotEmpty) { s.cambioVeiculo = veiculo.cambioVeiculo!; changed = true; }
        if (veiculo.cambioBin != null && veiculo.cambioBin!.isNotEmpty) { s.cambioBin = veiculo.cambioBin!; changed = true; }
        if (veiculo.marca != null && veiculo.marca!.isNotEmpty) { s.marca = veiculo.marca!; changed = true; }
        if (veiculo.modelo != null && veiculo.modelo!.isNotEmpty) { s.modelo = veiculo.modelo!; changed = true; }
        if (veiculo.anoFabricacao != null && veiculo.anoFabricacao!.toString().isNotEmpty) { s.anoFabricacao = veiculo.anoFabricacao!.toString(); changed = true; }
        if (veiculo.anoModelo != null && veiculo.anoModelo!.toString().isNotEmpty) { s.anoModelo = veiculo.anoModelo!.toString(); changed = true; }
        if (veiculo.cor != null && veiculo.cor!.isNotEmpty) { s.cor = veiculo.cor!; changed = true; }
        if (veiculo.renavam != null && veiculo.renavam!.isNotEmpty) { s.renavam = veiculo.renavam!; changed = true; }
        if (veiculo.municipio != null && veiculo.municipio!.isNotEmpty) { s.municipio = veiculo.municipio!; changed = true; }
        if (veiculo.uf != null && veiculo.uf!.isNotEmpty) { s.uf = veiculo.uf!; changed = true; }
        if (veiculo.km != null && veiculo.km!.toString().isNotEmpty) { s.km = veiculo.km!.toString(); changed = true; }
        if (veiculo.numeroGrv != null && veiculo.numeroGrv!.isNotEmpty) { s.numeroGrv = veiculo.numeroGrv!; changed = true; }
        if (veiculo.combustivel != null && veiculo.combustivel!.isNotEmpty) { s.combustivel = veiculo.combustivel!; changed = true; }
        if (changed) {
          s.forceUpdate();
        }
      }
    });

    _consultaSub = _autocredDao.watchConsultaPorVistoria(widget.vistoriaId).listen((consulta) {
      if (consulta != null && mounted) {
        _wizardState.arquivoPesquisaUrl = consulta.arquivoPesquisaUrl ?? '';
        final novoStatus = consulta.status;
        if (_statusConsulta == 'pendente' && novoStatus == 'concluida') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Pesquisa Radar Consultas concluída! Os dados foram preenchidos.'),
              backgroundColor: AppTheme.conforme,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (_statusConsulta == 'pendente' && novoStatus == 'erro') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Radar: ${consulta.retornoBruto ?? "Falha na pesquisa"}'),
              backgroundColor: AppTheme.naoConforme,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        if (_statusConsulta != novoStatus) {
          setState(() {
            _statusConsulta = novoStatus;
          });
        }
      }
    });
  }

  Future<void> _retryRadarConsulta() async {
    final placa = _wizardState.placa;
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A placa precisa estar preenchida para consultar.'), backgroundColor: AppTheme.naoConforme),
      );
      return;
    }

    final produto = await _showSelectProdutoDialog();
    if (produto == null) return;

    setState(() {
      _statusConsulta = 'pendente';
    });

    try {
      final service = sl<RadarService>();
      final veiculoApi = await service.consultarVeiculo(
        produto: produto,
        param: 'placa',
        value: placa,
        vistoriaId: widget.vistoriaId,
        forcarNova: true,
      ).timeout(const Duration(seconds: 90), onTimeout: () {
        throw Exception("Tempo limite de pesquisa excedido.");
      });
      
      // Atualizar o banco de dados com os dados retornados
      final veiculoDb = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
      if (veiculoDb != null) {
        await _dao.atualizarVeiculo(VeiculosCompanion(
          id: drift.Value(veiculoDb.id),
          vistoriaId: drift.Value(veiculoDb.vistoriaId),
          placa: drift.Value(veiculoApi.placa.isNotEmpty ? veiculoApi.placa : veiculoDb.placa),
          chassiVeiculo: drift.Value(veiculoApi.chassi.isNotEmpty ? veiculoApi.chassi : veiculoDb.chassiVeiculo),
          motorVeiculo: drift.Value(veiculoApi.motor.isNotEmpty ? veiculoApi.motor : veiculoDb.motorVeiculo),
          marca: drift.Value(veiculoApi.marcaModelo.isNotEmpty ? veiculoApi.marcaModelo.split(' ')[0] : veiculoDb.marca),
          modelo: drift.Value(veiculoApi.marcaModelo.isNotEmpty ? veiculoApi.marcaModelo : veiculoDb.modelo),
          anoFabricacao: drift.Value(int.tryParse(veiculoApi.anoFabricacao) ?? veiculoDb.anoFabricacao),
          anoModelo: drift.Value(int.tryParse(veiculoApi.anoModelo) ?? veiculoDb.anoModelo),
          cor: drift.Value(veiculoApi.cor.isNotEmpty ? veiculoApi.cor : veiculoDb.cor),
          renavam: drift.Value(veiculoApi.renavam.isNotEmpty ? veiculoApi.renavam : veiculoDb.renavam),
          chassiBin: drift.Value(veiculoApi.chassi.isNotEmpty ? veiculoApi.chassi : veiculoDb.chassiBin),
          motorBin: drift.Value(veiculoApi.motor.isNotEmpty ? veiculoApi.motor : veiculoDb.motorBin),
          municipio: drift.Value(veiculoApi.municipio.isNotEmpty ? veiculoApi.municipio : veiculoDb.municipio),
          uf: drift.Value(veiculoApi.estado.isNotEmpty ? veiculoApi.estado : veiculoDb.uf),
        ));
      }
      
      if (mounted) {
        setState(() {
          _statusConsulta = 'concluida';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pesquisa Radar Consultas atualizada!'), backgroundColor: AppTheme.conforme),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusConsulta = 'erro';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao re-consultar: $e'), backgroundColor: AppTheme.naoConforme),
        );
      }
    }
  }

  Future<String?> _showSelectProdutoDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nova Consulta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Qual pesquisa deseja realizar?'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('AUTO BIN (Simples)'),
                onTap: () => Navigator.pop(ctx, 'auto_bin'),
              ),
              ListTile(
                title: const Text('AUTO PERÍCIA'),
                onTap: () => Navigator.pop(ctx, 'auto_pericia'),
              ),
              ListTile(
                title: const Text('AUTO COMPLETA'),
                onTap: () => Navigator.pop(ctx, 'auto_completa'),
              ),
              ListTile(
                title: const Text('AUTO LEILÃO'),
                onTap: () => Navigator.pop(ctx, 'auto_leilao'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }



  Future<void> _carregarEtapaAnterior() async {
    final vistoria = await _dao.buscarPorId(widget.vistoriaId);
    if (vistoria != null) {
      _wizardState.numeroLaudo = vistoria.numeroLaudo;
      _wizardState.clienteNome = vistoria.clienteNome ?? '';
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
      }
    }

    // Carregar Itens
    final itens = await _dao.listarItensPorVistoria(widget.vistoriaId);
    for (final item in itens) {
      _wizardState.checklistStatus[item.nome] = item.status;
      _wizardState.checklistObs[item.nome] = item.observacao ?? '';
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
      } else {
        if (foto.pathLocal != null) {
          final itemId = foto.itemId ?? 'desconhecido';
          _wizardState.fotosLocais.putIfAbsent(itemId, () => []).add(foto.pathLocal!);
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

  Future<void> _proximo() async {
    // Salvar automaticamente ao avançar
    await _salvar();
    if (!mounted) return;

    if (_wizardState.isLastStep) {
      _confirmarFinalizar();
    } else {
      _wizardState.nextStep();
      _pageController.animateToPage(
        _wizardState.currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _voltar() {
    if (_wizardState.isFirstStep) {
      _confirmarSair();
    } else {
      _wizardState.prevStep();
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
        title: Text('Vistoria: ${_wizardState.tipoVistoria}', style: const TextStyle(fontSize: 16)),
        content: const Text(
            'O progresso foi salvo. Você pode retomar depois pelo histórico.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.naoConforme),
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

  void _confirmarFinalizar() {
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
                child: const Text('Gerar mesmo assim', style: TextStyle(color: Colors.red)),
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

    // Tudo ok — vai para a revisão
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
                if (_statusConsulta == 'pendente')
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Tooltip(
                        message: 'Pesquisando na base Radar Consultas...',
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    ),
                  )
                else if (_statusConsulta == 'concluida')
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Tooltip(
                        message: 'Pesquisa Radar Consultas concluída. Clique para atualizar novamente.',
                        child: InkWell(
                          onTap: _retryRadarConsulta,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 22),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_statusConsulta == 'erro')
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Tooltip(
                        message: 'Erro na pesquisa Radar Consultas. Tocar para tentar novamente.',
                        child: InkWell(
                          onTap: _retryRadarConsulta,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const StepDadosGerais(),
                      const StepFotosExternas(),
                      const StepVidros(),
                      const StepPainelHodometro(),
                      const StepMotorCambio(),
                      const StepEtiquetasChassi(),
                      if (_wizardState.temCroqui) const StepEstrutura(),
                      if (_wizardState.temAvarias) const StepPintura(),
                      const StepObservacoes(),
                      const StepFotosExtras(),
                      const StepDadosVeiculo(),
                      const StepConclusao(),
                    ],
                  ),
                ),
              ],
            ),

            // ── Botões de navegação ───────────────────────────────────────
            bottomNavigationBar: _WizardNavBar(
              isFirst: state.isFirstStep,
              isLast: state.isLastStep,
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
              padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 10, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primary
                      : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.steps[i].icone,
                    size: 18,
                    color: isActive
                        ? Colors.white
                        : AppTheme.textSecondary,
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
                backgroundColor:
                    isLast ? AppTheme.conforme : AppTheme.primary,
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
