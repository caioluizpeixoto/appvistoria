import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 10 — Estrutura / Longarinas
class StepEstrutura extends StatelessWidget {
  const StepEstrutura({super.key});

  static const List<String> _itens = [
    // Frente
    'painel_frontal',
    'painel_corta_fogo',
    // Frente Esquerda
    'torre_amortecedor_esquerda',
    'longarina_dianteira_esquerda',
    'caixa_roda_dianteira_esquerda',
    // Lateral Esquerda
    'coluna_dianteira_esquerda',
    'caixa_ar_esquerda',
    'assoalho_esquerdo',
    'coluna_central_esquerda',
    'longarina_centro_esquerda',
    'coluna_traseira_esquerda',
    // Traseira Esquerda
    'caixa_roda_traseira_esquerda',
    'longarina_traseira_esquerda',
    // Traseira
    'painel_traseiro',
    'caixa_estepe',
    // Traseira Direita
    'longarina_traseira_direita',
    'caixa_roda_traseira_direita',
    // Lateral Direita
    'coluna_traseira_direita',
    'longarina_centro_direita',
    'coluna_central_direita',
    'assoalho_direito',
    'caixa_ar_direita',
    'coluna_dianteira_direita',
    // Frente Direita
    'caixa_roda_dianteira_direita',
    'longarina_dianteira_direita',
    'torre_amortecedor_direita',
  ];

  static const Map<String, String> _labels = {
    'painel_frontal': 'Painel Frontal',
    'painel_corta_fogo': 'Painel Corta Fogo',
    'torre_amortecedor_esquerda': 'Torre de Amortecedor Esquerda',
    'longarina_dianteira_esquerda': 'Longarina Dianteira Esquerda',
    'caixa_roda_dianteira_esquerda': 'Caixa de Roda Dianteira Esquerda',
    'coluna_dianteira_esquerda': 'Coluna Dianteira Esquerda',
    'caixa_ar_esquerda': 'Caixa de Ar Esquerda',
    'assoalho_esquerdo': 'Assoalho Esquerdo',
    'coluna_central_esquerda': 'Coluna Central Esquerda',
    'longarina_centro_esquerda': 'Longarina Centro Esquerda',
    'coluna_traseira_esquerda': 'Coluna Traseira Esquerda',
    'caixa_roda_traseira_esquerda': 'Caixa de Roda Traseira Esquerda',
    'longarina_traseira_esquerda': 'Longarina Traseira Esquerda',
    'painel_traseiro': 'Painel Traseiro',
    'caixa_estepe': 'Caixa do Estepe',
    'longarina_traseira_direita': 'Longarina Traseira Direita',
    'caixa_roda_traseira_direita': 'Caixa de Roda Traseira Direita',
    'coluna_traseira_direita': 'Coluna Traseira Direita',
    'longarina_centro_direita': 'Longarina Centro Direita',
    'coluna_central_direita': 'Coluna Central Direita',
    'assoalho_direito': 'Assoalho Direito',
    'caixa_ar_direita': 'Caixa de Ar Direita',
    'coluna_dianteira_direita': 'Coluna Dianteira Direita',
    'caixa_roda_dianteira_direita': 'Caixa de Roda Dianteira Direita',
    'longarina_dianteira_direita': 'Longarina Dianteira Direita',
    'torre_amortecedor_direita': 'Torre de Amortecedor Direita',
  };

  static const List<String> _statusOpcoes = [
    'Dentro dos padrões de fábrica',
    'Não aplicável',
    'Possui reparo',
    'Soldado',
    'Substituído',
    'Danificado',
    'Alongado',
    'Obstruído',
    'Consideração sobre coluna e longarina',
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
        if (comAlerta > 0) ...[
          _Header(comAlerta: comAlerta),
          const SizedBox(height: 16),
        ],
        ..._itens.map((id) => InspecaoItemWidget(
              itemId: id,
              label: _labels[id]!,
              statusOptions: _statusOpcoes,
              obrigatoria: false,
            )),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _buildVideoSection(context, state),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildVideoSection(BuildContext context, VistoriaWizardState state) {
    if (state.videoEstruturalPath != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vídeo de Avaria Gravado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'O vídeo será enviado para a base, mas não aparecerá no PDF gerado.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      OpenFile.open(state.videoEstruturalPath);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reproduzir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    state.clearVideoEstrutural();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () async {
        final picker = ImagePicker();
        final xFile = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(seconds: 30),
        );
        if (xFile != null) {
          state.setVideoEstrutural(xFile.path);
        }
      },
      icon: const Icon(Icons.videocam),
      label: const Text('Gravar Vídeo de Avaria (Máx 30s)'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppTheme.primary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        color:
            comAlerta > 0 ? AppTheme.naoConformeLight : AppTheme.conformeLight,
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
            Icons.minor_crash_rounded,
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
