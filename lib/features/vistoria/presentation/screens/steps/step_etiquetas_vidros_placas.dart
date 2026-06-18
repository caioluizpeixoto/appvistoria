import 'package:flutter/material.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 7 — Etiquetas VIS
class StepEtiquetasVis extends StatelessWidget {
  const StepEtiquetasVis({super.key});

  static const List<String> _statusOpcoes = [
    'Dentro dos padrões',
    'Original',
    'Ausente',
    'Danificada',
    'Divergente',
    'Com indício de adulteração',
    'Não localizado',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepHeader(
          icon: Icons.qr_code_rounded,
          title: 'Etiquetas VIS',
          subtitle: 'Verifique as etiquetas de identificação do veículo',
        ),
        const SizedBox(height: 16),
        const InspecaoItemWidget(
          itemId: 'etiqueta_vis_motor',
          label: 'Etiqueta VIS — Compartimento do Motor',
          obrigatoria: true,
          statusOptions: _statusOpcoes,
        ),
        const InspecaoItemWidget(
          itemId: 'etiqueta_vis_porta',
          label: 'Etiqueta VIS — Porta / Coluna',
          obrigatoria: true,
          statusOptions: _statusOpcoes,
        ),
        const InspecaoItemWidget(
          itemId: 'etiquetas_outras',
          label: 'Outras Etiquetas de Identificação',
          obrigatoria: false,
          statusOptions: _statusOpcoes,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Step 8 — Vidros
class StepVidros extends StatelessWidget {
  const StepVidros({super.key});

  static const List<Map<String, String>> _itens = [
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepHeader(
          icon: Icons.window_rounded,
          title: 'Gravações dos Vidros',
          subtitle: 'Registre as gravações encontradas em cada vidro',
        ),
        const SizedBox(height: 16),
        ..._itens.map((item) => InspecaoItemWidget(
              itemId: item['id']!,
              label: item['label']!,
              statusOptions: _statusOpcoes,
              obrigatoria: false,
            )),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Step 9 — Placas
class StepPlacas extends StatelessWidget {
  const StepPlacas({super.key});

  static const List<String> _statusOpcoes = [
    'Em perfeito estado',
    'Dentro dos padrões',
    'Lacre / identificação regular',
    'Divergente',
    'Danificada',
    'Não localizada',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _StepHeader(
          icon: Icons.subtitles_rounded,
          title: 'Placas',
          subtitle: 'Registre e compare as placas com a consulta',
        ),
        const SizedBox(height: 16),
        const InspecaoItemWidget(
          itemId: 'placa_dianteira',
          label: 'Placa Dianteira',
          obrigatoria: true,
          showCodigoField: true,
          codigoLabel: 'Placa lida / informada',
          codigoHint: 'Ex: ABC-1234',
          showDivergenciaAlert: true,
          statusOptions: _statusOpcoes,
        ),
        const InspecaoItemWidget(
          itemId: 'placa_traseira',
          label: 'Placa Traseira',
          obrigatoria: true,
          showCodigoField: true,
          codigoLabel: 'Placa lida / informada',
          codigoHint: 'Ex: ABC-1234',
          showDivergenciaAlert: true,
          statusOptions: _statusOpcoes,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared header ─────────────────────────────────────────────────────────────

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
