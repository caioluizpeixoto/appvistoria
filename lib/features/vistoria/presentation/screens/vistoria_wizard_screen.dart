import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';
import 'package:drift/drift.dart' as drift;

import '../../domain/vistoria_wizard_state.dart';
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
  bool _isSaving = false;

  List<_StepInfo> get _activeSteps {
    final temCroqui = _wizardState.tipoVistoria.toLowerCase().contains('croqui');
    return [
      const _StepInfo(titulo: 'Dados Gerais', icone: Icons.assignment_rounded),
      const _StepInfo(titulo: 'Dados do Veículo', icone: Icons.directions_car_rounded),
      const _StepInfo(titulo: 'Fotos Externas', icone: Icons.photo_camera_rounded),
      const _StepInfo(titulo: 'Painel / Hodômetro', icone: Icons.speed_rounded),
      const _StepInfo(titulo: 'Chassi', icone: Icons.tag_rounded),
      const _StepInfo(titulo: 'Motor', icone: Icons.settings_rounded),
      const _StepInfo(titulo: 'Etiquetas VIS', icone: Icons.qr_code_rounded),
      const _StepInfo(titulo: 'Vidros', icone: Icons.window_rounded),
      const _StepInfo(titulo: 'Placas', icone: Icons.subtitles_rounded),
      if (temCroqui) const _StepInfo(titulo: 'Estrutura', icone: Icons.car_repair_rounded),
      if (temCroqui) const _StepInfo(titulo: 'Pintura', icone: Icons.format_paint_rounded),
      const _StepInfo(titulo: 'Fotos Extras', icone: Icons.add_photo_alternate_rounded),
      const _StepInfo(titulo: 'Observações', icone: Icons.notes_rounded),
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
  }

  Future<void> _carregarEtapaAnterior() async {
    final vistoria = await _dao.buscarPorId(widget.vistoriaId);
    if (vistoria != null && vistoria.tipoVistoria != null) {
      _wizardState.tipoVistoria = vistoria.tipoVistoria!;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(_wizardState.currentStep);
      });
    }
  }

  @override
  void dispose() {
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
            obrigatoria: drift.Value(VistoriaWizardState.fotosObrigatorias.contains(itemId)),
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
        title: const Text('Sair da Vistoria?'),
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
                IconButton(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  tooltip: 'Salvar',
                  onPressed: _salvar,
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
                      const StepDadosVeiculo(),
                      const StepFotosExternas(),
                      const StepPainelHodometro(),
                      const StepChassi(),
                      const StepMotor(),
                      const StepEtiquetasVis(),
                      const StepVidros(),
                      const StepPlacas(),
                      if (_wizardState.tipoVistoria.toLowerCase().contains('croqui')) const StepEstrutura(),
                      if (_wizardState.tipoVistoria.toLowerCase().contains('croqui')) const StepPintura(),
                      const StepFotosExtras(),
                      const StepObservacoes(),
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

class _StepIndicatorRow extends StatelessWidget {
  final List<_StepInfo> steps;
  final int currentStep;
  final ValueChanged<int> onTap;
  const _StepIndicatorRow(
      {required this.steps, required this.currentStep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: steps.length,
        itemBuilder: (ctx, i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : isDone
                        ? AppTheme.conformeLight
                        : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primary
                      : isDone
                          ? AppTheme.conforme.withValues(alpha: 0.4)
                          : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.check_rounded : steps[i].icone,
                    size: 14,
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? AppTheme.conforme
                            : AppTheme.textSecondary,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 5),
                    Text(
                      steps[i].titulo,
                      style: const TextStyle(
                          fontSize: 11,
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
