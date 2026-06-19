import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 2 — Vidros
class StepVidros extends StatelessWidget {
  const StepVidros({super.key});

  static const List<Map<String, String>> _itensPrincipais = [
    {'id': 'vidro_dianteiro_direito', 'label': 'Vidro Dianteiro Direito'},
    {'id': 'vidro_dianteiro_esquerdo', 'label': 'Vidro Dianteiro Esquerdo'},
    {'id': 'vidro_frontal', 'label': 'Vidro Frontal (Parabrisa)'},
    {'id': 'vidro_traseiro', 'label': 'Vidro Traseiro (Vigia)'},
    {'id': 'vidro_traseiro_direito', 'label': 'Vidro Traseiro Direito'},
    {'id': 'vidro_traseiro_esquerdo', 'label': 'Vidro Traseiro Esquerdo'},
  ];

  static const List<String> _statusOpcoes = [
    'Original',
    'Dentro dos padrões',
    'Não original',
    'Substituído',
    'Gravação ausente',
    'Divergente',
    'Não analisado',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final vidrosExtrasIds = state.vidrosExtrasIds;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepHeader(
          icon: Icons.window_rounded,
          title: 'Gravações dos Vidros',
          subtitle: 'Registre as gravações encontradas em cada vidro',
        ),
        const SizedBox(height: 16),
        ..._itensPrincipais.map((item) => InspecaoItemWidget(
              itemId: item['id']!,
              label: item['label']!,
              statusOptions: _statusOpcoes,
              obrigatoria: false,
            )),
        
        if (vidrosExtrasIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Vidros Adicionais',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...vidrosExtrasIds.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final id = entry.value;
            return Stack(
              children: [
                InspecaoItemWidget(
                  itemId: id,
                  label: 'Vidro Adicional $idx',
                  statusOptions: _statusOpcoes,
                  obrigatoria: false,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.naoConforme),
                    onPressed: () => state.removeVidroExtra(id),
                  ),
                ),
              ],
            );
          }),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => state.addVidroExtra(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar Vidro Extra'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF757575))),
            ],
          ),
        ),
      ],
    );
  }
}
