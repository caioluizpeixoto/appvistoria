import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 5 — Motor e Câmbio
class StepMotorCambio extends StatelessWidget {
  const StepMotorCambio({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final motorDivergente = state.motorBin.isNotEmpty &&
        state.motorVeiculo.isNotEmpty &&
        state.motorBin != state.motorVeiculo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.motorBin.isNotEmpty)
          _InfoBadge(
            icon: Icons.cloud_done_rounded,
            label: 'Motor na BIN / Consulta',
            value: state.motorBin,
            color: AppTheme.primary,
          ),

        if (motorDivergente)
          _DivergenciaAlert(
            'O motor da BIN (${state.motorBin}) difere do informado no veículo (${state.motorVeiculo}).',
          ),

        const SizedBox(height: 12),

        const InspecaoItemWidget(
          itemId: 'compartimento_motor',
          label: 'Compartimento do Motor',
          obrigatoria: true,
          statusOptions: [
            'Em perfeito estado',
            'Dentro dos padrões',
            'Possui avaria',
            'Com observação',
            'Não analisado',
          ],
        ),

        InspecaoItemWidget(
          itemId: 'motor_gravacao',
          label: 'Gravação do Motor',
          obrigatoria: true,
          showCodigoField: true,
          codigoLabel: 'Motor encontrado no veículo',
          codigoHint: 'Ex: EA823...',
          infoTexto: state.motorBin.isNotEmpty
              ? 'BIN/Consulta: ${state.motorBin}'
              : null,
          showDivergenciaAlert: true,
          statusOptions: const [
            'Dentro dos padrões',
            'Original',
            'Divergente',
            'Remarcado',
            'Não localizado',
            'Ilegível',
            'Com indício de adulteração',
          ],
        ),

        const InspecaoItemWidget(
          itemId: 'cambio_gravacao',
          label: 'Gravação do Câmbio',
          obrigatoria: true,
          statusOptions: [
            'Dentro dos padrões',
            'Original',
            'Divergente',
            'Remarcado',
            'Não localizado',
            'Ilegível',
            'Com indício de adulteração',
          ],
        ),

        const InspecaoItemWidget(
          itemId: 'etiqueta_vis_motor',
          label: 'Etiqueta VIS — Compartimento do Motor',
          obrigatoria: true,
          statusOptions: [
            'Dentro dos padrões',
            'Original',
            'Ausente',
            'Danificada',
            'Divergente',
            'Com indício de adulteração',
            'Não localizado',
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

/// Step 6 — Etiquetas e Chassi
class StepEtiquetasChassi extends StatelessWidget {
  const StepEtiquetasChassi({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final chaveDivergente = state.chassiBin.isNotEmpty &&
        state.chassiVeiculo.isNotEmpty &&
        state.chassiBin != state.chassiVeiculo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InspecaoItemWidget(
          itemId: 'etiqueta_vis_porta',
          label: 'Etiqueta VIS — Porta / Coluna',
          obrigatoria: true,
          statusOptions: [
            'Dentro dos padrões',
            'Original',
            'Ausente',
            'Danificada',
            'Divergente',
            'Com indício de adulteração',
            'Não localizado',
          ],
        ),

        const SizedBox(height: 16),

        // Info: chassi da BIN
        if (state.chassiBin.isNotEmpty)
          _InfoBadge(
            icon: Icons.cloud_done_rounded,
            label: 'Chassi na BIN / Consulta',
            value: state.chassiBin,
            color: AppTheme.primary,
          ),

        if (chaveDivergente)
          _DivergenciaAlert(
            'O chassi da BIN (${state.chassiBin}) difere do informado no veículo (${state.chassiVeiculo}). Registre como DIVERGENTE.',
          ),

        const SizedBox(height: 12),

        InspecaoItemWidget(
          itemId: 'chassi_gravacao',
          label: 'Gravação do Chassi',
          obrigatoria: true,
          showCodigoField: true,
          codigoLabel: 'Chassi encontrado no veículo',
          codigoHint: 'Ex: 9BWZZZ377VT...',
          infoTexto: state.chassiBin.isNotEmpty
              ? 'BIN/Consulta: ${state.chassiBin}'
              : null,
          showDivergenciaAlert: true,
          statusOptions: const [
            'Dentro dos padrões',
            'Divergente',
            'Remarcado',
            'Não localizado',
            'Ilegível',
            'Com indício de adulteração',
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoBadge({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DivergenciaAlert extends StatelessWidget {
  final String msg;
  const _DivergenciaAlert(this.msg);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.naoConformeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.naoConforme.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded,
              color: AppTheme.naoConforme, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.naoConforme,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
