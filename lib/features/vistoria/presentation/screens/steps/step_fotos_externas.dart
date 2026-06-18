import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 3 — Fotos Externas Obrigatórias
class StepFotosExternas extends StatelessWidget {
  const StepFotosExternas({super.key});

  static const List<Map<String, dynamic>> _itens = [
    {'id': 'frente_direita', 'label': 'Frente Direita', 'icon': Icons.north_east},
    {'id': 'frente_esquerda', 'label': 'Frente Esquerda', 'icon': Icons.north_west},
    {'id': 'traseira_direita', 'label': 'Traseira Direita', 'icon': Icons.south_east},
    {'id': 'traseira_esquerda', 'label': 'Traseira Esquerda', 'icon': Icons.south_west},
    {'id': 'lateral_direita', 'label': 'Lateral Direita', 'icon': Icons.east},
    {'id': 'lateral_esquerda', 'label': 'Lateral Esquerda', 'icon': Icons.west},
    {'id': 'placa_dianteira', 'label': 'Placa Dianteira', 'icon': Icons.subtitles_rounded},
    {'id': 'placa_traseira', 'label': 'Placa Traseira', 'icon': Icons.subtitles_outlined},
    {'id': 'compartimento_motor', 'label': 'Compartimento do Motor', 'icon': Icons.settings_rounded},
  ];

  static const List<String> _statusOpcoes = [
    'Em perfeito estado',
    'Dentro dos padrões',
    'Possui avaria',
    'Com observação',
    'Não analisado',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final faltando = _itens.where((i) => !state.hasFoto(i['id'])).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header com contador ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_camera_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fotos Externas Obrigatórias',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      faltando == 0
                          ? '✅ Todas as fotos capturadas!'
                          : '📸 $faltando foto(s) ainda não capturada(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Contador circular
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_itens.length - faltando}/${_itens.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Itens de foto ─────────────────────────────────────────────────
        ..._itens.map((item) => InspecaoItemWidget(
              itemId: item['id'],
              label: item['label'],
              statusOptions: _statusOpcoes,
              obrigatoria: true,
            )),

        const SizedBox(height: 32),
      ],
    );
  }
}
