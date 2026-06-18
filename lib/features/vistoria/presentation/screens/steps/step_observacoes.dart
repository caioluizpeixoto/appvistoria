import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

/// Step 13 — Observações Gerais
class StepObservacoes extends StatefulWidget {
  const StepObservacoes({super.key});
  @override
  State<StepObservacoes> createState() => _StepObservacoesState();
}

class _StepObservacoesState extends State<StepObservacoes> {
  final _veiculoCtrl = TextEditingController();
  final _vistoriadorCtrl = TextEditingController();
  final _divergenciasCtrl = TextEditingController();
  final _recomendacoesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<VistoriaWizardState>();
      _veiculoCtrl.text = s.observacoesVeiculo;
      _vistoriadorCtrl.text = s.observacoesVistoriador;
      _divergenciasCtrl.text = s.divergenciasEncontradas;
      _recomendacoesCtrl.text = s.recomendacoes;
    });
  }

  @override
  void dispose() {
    _veiculoCtrl.dispose();
    _vistoriadorCtrl.dispose();
    _divergenciasCtrl.dispose();
    _recomendacoesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final divs = state.itensDivergentes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divergências automáticas detectadas
          if (divs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.naoConformeLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.naoConforme.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_rounded, color: AppTheme.naoConforme, size: 20),
                      SizedBox(width: 8),
                      Text('Divergências Detectadas',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.naoConforme)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...divs.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${d.replaceAll('_', ' ')}',
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.naoConforme)),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Observações do veículo
          _buildTextArea(
            controller: _veiculoCtrl,
            label: 'Observações do Veículo',
            hint: 'Descreva condições gerais do veículo, estado de conservação...',
            icon: Icons.directions_car_rounded,
            onChanged: (v) => state.observacoesVeiculo = v,
          ),
          const SizedBox(height: 14),

          // Observações do vistoriador
          _buildTextArea(
            controller: _vistoriadorCtrl,
            label: 'Observações do Vistoriador',
            hint: 'Observações técnicas do responsável pela inspeção...',
            icon: Icons.engineering_rounded,
            onChanged: (v) => state.observacoesVistoriador = v,
          ),
          const SizedBox(height: 14),

          // Divergências encontradas
          _buildTextArea(
            controller: _divergenciasCtrl,
            label: 'Divergências Encontradas',
            hint: 'Descreva todas as divergências identificadas durante a vistoria...',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.naoConforme,
            onChanged: (v) => state.divergenciasEncontradas = v,
          ),
          const SizedBox(height: 14),

          // Recomendações
          _buildTextArea(
            controller: _recomendacoesCtrl,
            label: 'Recomendações',
            hint: 'Recomendações técnicas, ações necessárias...',
            icon: Icons.recommend_rounded,
            color: AppTheme.conforme,
            onChanged: (v) => state.recomendacoes = v,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color? color,
    required ValueChanged<String> onChanged,
  }) {
    final c = color ?? AppTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: c, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
