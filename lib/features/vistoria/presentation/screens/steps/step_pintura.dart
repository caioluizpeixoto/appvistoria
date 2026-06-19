import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 11 — Pintura e Lataria
class StepPintura extends StatelessWidget {
  const StepPintura({super.key});

  static const List<String> _pecas = [
    'peca_capo_dianteiro',
    'peca_paralama_dianteiro_esquerdo',
    'peca_porta_dianteira_esquerda',
    'peca_porta_traseira_esquerda',
    'peca_lateral_traseira_esquerda',
    'peca_tampa_traseira',
    'peca_teto',
    'peca_lateral_traseira_direita',
    'peca_porta_traseira_direita',
    'peca_porta_dianteira_direita',
    'peca_paralama_dianteiro_direito',
  ];

  static const Map<String, String> _labels = {
    'peca_capo_dianteiro': 'Capô Dianteiro',
    'peca_paralama_dianteiro_esquerdo': 'Para-lama Dianteiro Esquerdo',
    'peca_porta_dianteira_esquerda': 'Porta Dianteira Esquerda',
    'peca_porta_traseira_esquerda': 'Porta Traseira Esquerda',
    'peca_lateral_traseira_esquerda': 'Lateral Traseira Esquerda',
    'peca_tampa_traseira': 'Capô Traseiro / Porta-malas',
    'peca_teto': 'Teto',
    'peca_lateral_traseira_direita': 'Lateral Traseira Direita',
    'peca_porta_traseira_direita': 'Porta Traseira Direita',
    'peca_porta_dianteira_direita': 'Porta Dianteira Direita',
    'peca_paralama_dianteiro_direito': 'Para-lama Dianteiro Direito',
  };

  static const List<String> _statusOpcoes = [
    'Pintura original',
    'Repintura',
    'Repintura e/ou massa',
    'Substituído',
    'Envelopado',
    'Danificado',
    'Amassado',
    'Riscado',
    'Não analisado',
  ];

  Color _statusColor(String status) {
    if (status.isEmpty || status == 'Não analisado') return AppTheme.naoAplicavel;
    final s = status.toLowerCase();
    if (s.contains('original')) return AppTheme.conforme;
    if (s.contains('repintura') || s.contains('amassado') || s.contains('riscado') || s.contains('envelopado')) return AppTheme.comObs;
    if (s.contains('substituído') || s.contains('danificado')) return AppTheme.naoConforme;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();

    // Resumo de status
    final repinturas = _pecas
        .where((id) => state.getStatus(id).toLowerCase().contains('repintura'))
        .length;
    final originais = _pecas
        .where((id) => state.getStatus(id) == 'Pintura original')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Resumo visual ──────────────────────────────────────────────────
        _PinturaResumoCard(originais: originais, repinturas: repinturas, total: _pecas.length),
        const SizedBox(height: 8),

        // ── Diagrama simplificado ──────────────────────────────────────────
        _DiagramaPintura(pecas: _pecas, labels: _labels, statusFn: state.getStatus, colorFn: _statusColor),
        const SizedBox(height: 16),

        // ── Lista de itens ─────────────────────────────────────────────────
        ..._pecas.map((id) => InspecaoItemWidget(
              itemId: id,
              label: _labels[id]!,
              statusOptions: _statusOpcoes,
              obrigatoria: false,
            )),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PinturaResumoCard extends StatelessWidget {
  final int originais;
  final int repinturas;
  final int total;
  const _PinturaResumoCard({required this.originais, required this.repinturas, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_paint_rounded, color: AppTheme.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Análise de Pintura e Lataria',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$originais originais · $repinturas repinturas · ${total - originais - repinturas} outros',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagrama simplificado de pintura (grid visual)
class _DiagramaPintura extends StatelessWidget {
  final List<String> pecas;
  final Map<String, String> labels;
  final String Function(String) statusFn;
  final Color Function(String) colorFn;

  const _DiagramaPintura({
    required this.pecas,
    required this.labels,
    required this.statusFn,
    required this.colorFn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text('Mapa de Pintura',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pecas.map((id) {
              final status = statusFn(id);
              final color = colorFn(status);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  labels[id]!.replaceAll('Para-lama', 'P-lama')
                      .replaceAll('Dianteiro', 'Diant.')
                      .replaceAll('Traseiro', 'Tras.')
                      .replaceAll(' Direito', ' D.')
                      .replaceAll(' Esquerdo', ' E.'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: status.isEmpty ? AppTheme.textHint : color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legenda(color: AppTheme.conforme, label: 'Original'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.comObs, label: 'Repintura'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.naoConforme, label: 'Danificado'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.naoAplicavel, label: 'N/A'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Legenda({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }
}
