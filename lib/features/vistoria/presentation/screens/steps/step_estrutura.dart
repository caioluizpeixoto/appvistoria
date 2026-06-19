import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 10 — Estrutura / Longarinas
class StepEstrutura extends StatelessWidget {
  const StepEstrutura({super.key});

  static const List<String> _itens = [
    'longarina_dianteira_esquerda',
    'longarina_dianteira_direita',
    'longarina_centro_esquerda',
    'longarina_centro_direita',
    'longarina_traseira_esquerda',
    'longarina_traseira_direita',
  ];

  static const Map<String, String> _labels = {
    'longarina_dianteira_esquerda': 'Longarina Dianteira Esquerda',
    'longarina_dianteira_direita': 'Longarina Dianteira Direita',
    'longarina_centro_esquerda': 'Longarina Centro Esquerda',
    'longarina_centro_direita': 'Longarina Centro Direita',
    'longarina_traseira_esquerda': 'Longarina Traseira Esquerda',
    'longarina_traseira_direita': 'Longarina Traseira Direita',
  };

  static const List<String> _statusOpcoes = [
    'Sem reparo aparente',
    'Possui reparo',
    'Soldado',
    'Substituído',
    'Danificado',
    'Indício de colisão',
    'Não analisado',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final comAlerta = _itens.where((id) {
      final s = state.getStatus(id).toLowerCase();
      return s.contains('colisão') ||
          s.contains('soldado') ||
          s.contains('substituído');
    }).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(comAlerta: comAlerta),
        const SizedBox(height: 16),
        ..._itens.map((id) => InspecaoItemWidget(
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

class _Header extends StatelessWidget {
  final int comAlerta;
  const _Header({required this.comAlerta});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: comAlerta > 0
            ? AppTheme.naoConformeLight
            : AppTheme.conformeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comAlerta > 0
              ? AppTheme.naoConforme.withValues(alpha: 0.3)
              : AppTheme.conforme.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.car_repair_rounded,
            color: comAlerta > 0 ? AppTheme.naoConforme : AppTheme.conforme,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Análise Estrutural',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                Text(
                  comAlerta > 0
                      ? '⚠️ $comAlerta item(ns) com alerta estrutural'
                      : '✅ Nenhum alerta estrutural',
                  style: TextStyle(
                      fontSize: 12,
                      color: comAlerta > 0
                          ? AppTheme.naoConforme
                          : AppTheme.conforme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
