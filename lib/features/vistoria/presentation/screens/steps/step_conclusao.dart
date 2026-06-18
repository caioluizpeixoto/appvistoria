import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

/// Step 14 — Conclusão (Resultado Final + Assinatura Digital)
class StepConclusao extends StatefulWidget {
  const StepConclusao({super.key});
  @override
  State<StepConclusao> createState() => _StepConclusaoState();
}

class _StepConclusaoState extends State<StepConclusao> {
  final _parecerCtrl = TextEditingController();
  late SignatureController _signatureController;

  final List<String> _resultados = [
    'Conforme',
    'Conforme com observações',
    'Reprovado',
    'Necessita análise complementar',
  ];

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppTheme.textPrimary,
      exportBackgroundColor: Colors.white,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<VistoriaWizardState>();
      _parecerCtrl.text = s.parecerTecnico;
      if (s.resultadoFinal.isEmpty) {
        s.resultadoFinal = s.statusSugerido;
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        s.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _parecerCtrl.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _salvarAssinatura(VistoriaWizardState state) async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, assine no campo abaixo antes de salvar.'),
          backgroundColor: AppTheme.comObs,
        ),
      );
      return;
    }

    final Uint8List? imageBytes = await _signatureController.toPngBytes();
    if (imageBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/assinatura_${state.vistoriaId}.png');
    await file.writeAsBytes(imageBytes);

    state.assinaturaPath = file.path;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    state.notifyListeners();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Assinatura salva com sucesso!'),
          backgroundColor: AppTheme.conforme,
        ),
      );
    }
  }

  Color _resultadoColor(String resultado) {
    switch (resultado) {
      case 'Conforme':
        return AppTheme.conforme;
      case 'Conforme com observações':
        return AppTheme.comObs;
      case 'Reprovado':
        return AppTheme.naoConforme;
      case 'Necessita análise complementar':
        return AppTheme.emAndamento;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _resultadoIcon(String resultado) {
    switch (resultado) {
      case 'Conforme':
        return Icons.check_circle_rounded;
      case 'Conforme com observações':
        return Icons.warning_amber_rounded;
      case 'Reprovado':
        return Icons.cancel_rounded;
      case 'Necessita análise complementar':
        return Icons.help_outline_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status sugerido ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Sugerido pelo Sistema',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                        state.statusSugerido,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _resultadoColor(state.statusSugerido)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Resultado final ──────────────────────────────────────────────
          const Text('Resultado Final do Laudo',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),

          ...(_resultados.map((r) {
            final isSelected = state.resultadoFinal == r;
            final color = _resultadoColor(r);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  state.resultadoFinal = r;
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  state.notifyListeners();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_resultadoIcon(r), color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected ? color : AppTheme.textPrimary,
                            )),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                    ],
                  ),
                ),
              ),
            );
          })),

          const SizedBox(height: 20),

          // ── Parecer técnico ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded,
                          color: AppTheme.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Parecer Técnico',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: TextFormField(
                    controller: _parecerCtrl,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Descreva o parecer técnico detalhado sobre o estado do veículo...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    onChanged: (v) => state.parecerTecnico = v,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Assinatura digital ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.assinaturaPath != null
                    ? AppTheme.conforme
                    : AppTheme.border,
                width: state.assinaturaPath != null ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        state.assinaturaPath != null
                            ? Icons.verified_rounded
                            : Icons.draw_rounded,
                        color: state.assinaturaPath != null
                            ? AppTheme.conforme
                            : AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.assinaturaPath != null
                            ? 'Assinatura Digital ✅'
                            : 'Assinatura Digital (obrigatória)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: state.assinaturaPath != null
                              ? AppTheme.conforme
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (state.assinaturaPath == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.naoConformeLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Pendente',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.naoConforme),
                          ),
                        ),
                    ],
                  ),
                ),

                // Se já tem assinatura salva, mostra preview
                if (state.assinaturaPath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(state.assinaturaPath!),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Canvas de assinatura
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assine abaixo:',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Signature(
                            controller: _signatureController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                side: const BorderSide(color: AppTheme.naoConforme),
                              ),
                              onPressed: () => _signatureController.clear(),
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.naoConforme, size: 18),
                              label: const Text('Limpar',
                                  style: TextStyle(color: AppTheme.naoConforme)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                backgroundColor: AppTheme.conforme,
                              ),
                              onPressed: () => _salvarAssinatura(state),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Confirmar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // Dados do vistoriador (somente leitura)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Responsável Técnico',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  state.vistoriadorNome.isEmpty
                      ? 'Não informado'
                      : state.vistoriadorNome,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                if (state.vistoriadorCpf.isNotEmpty)
                  Text('CPF: ${state.vistoriadorCpf}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
