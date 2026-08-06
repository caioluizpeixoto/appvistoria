import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

class StepPinturaCaminhao extends StatefulWidget {
  const StepPinturaCaminhao({super.key});

  @override
  State<StepPinturaCaminhao> createState() => _StepPinturaCaminhaoState();
}

class _StepPinturaCaminhaoState extends State<StepPinturaCaminhao>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const List<String> _statusOpcoes = [
    'Padrão do fabricante',
    'Repintura',
    'Repintura e/ou massa',
    'Substitu\u00eddo',
    'Envelopado',
    'Danificado',
    'Amassado',
    'Riscado',
  ];

  static const Map<String, String> _labels = {
    'peca_cam_capo': 'Cap\u00f4',
    'peca_cam_teto': 'Teto da cabine',
    'peca_cam_painel_tras': 'Painel traseiro da cabine',
    'peca_cam_parachoque_dian': 'Para-choque dianteiro (se pintado)',
    'peca_cam_grade': 'Grade',
    'peca_cam_porta_esq': 'Porta dianteira esquerda',
    'peca_cam_paralama_esq': 'Para-lama dianteiro esquerdo',
    'peca_cam_coluna_a_esq': 'Coluna A esquerda',
    'peca_cam_coluna_b_esq': 'Coluna B esquerda',
    'peca_cam_lat_esq': 'Lateral esquerda da cabine',
    'peca_cam_saia_esq': 'Saia lateral esquerda',
    'peca_cam_paralama_tras_esq': 'Para-lama traseiro esquerdo',
    'peca_cam_porta_dir': 'Porta dianteira direita',
    'peca_cam_paralama_dir': 'Para-lama dianteiro direito',
    'peca_cam_coluna_a_dir': 'Coluna A direita',
    'peca_cam_coluna_b_dir': 'Coluna B direita',
    'peca_cam_lat_dir': 'Lateral direita da cabine',
    'peca_cam_saia_dir': 'Saia lateral direita',
    'peca_cam_paralama_tras_dir': 'Para-lama traseiro direito',
    'peca_cam_parachoque_tras': 'Para-choque traseiro',
  };

  static const Map<String, List<String>> _categoriasVistoria = {
    'CABINE E FRENTE': [
      'peca_cam_capo',
      'peca_cam_teto',
      'peca_cam_painel_tras',
      'peca_cam_parachoque_dian',
      'peca_cam_grade',
    ],
    'LATERAL ESQUERDA': [
      'peca_cam_porta_esq',
      'peca_cam_paralama_esq',
      'peca_cam_coluna_a_esq',
      'peca_cam_coluna_b_esq',
      'peca_cam_lat_esq',
      'peca_cam_saia_esq',
      'peca_cam_paralama_tras_esq',
    ],
    'LATERAL DIREITA': [
      'peca_cam_porta_dir',
      'peca_cam_paralama_dir',
      'peca_cam_coluna_a_dir',
      'peca_cam_coluna_b_dir',
      'peca_cam_lat_dir',
      'peca_cam_saia_dir',
      'peca_cam_paralama_tras_dir',
    ],
    'TRASEIRA': [
      'peca_cam_parachoque_tras',
    ],
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = context.watch<VistoriaWizardState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Realizar Avalia\u00e7\u00e3o de Pintura?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se ativado, as informa\u00e7\u00f5es preenchidas constar\u00e3o na se\u00e7\u00e3o de pintura no PDF gerado.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: AppTheme.primary,
                  value: state.realizarAvaliacaoPintura,
                  onChanged: (val) {
                    setState(() {
                      state.realizarAvaliacaoPintura = val;
                    });
                  },
                )
              ],
            ),
          ),
          if (state.realizarAvaliacaoPintura) ...[
            const SizedBox(height: 16),
            ..._categoriasVistoria.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((id) => InspecaoItemWidget(
                        itemId: id,
                        label: _labels[id]!,
                        statusOptions: _statusOpcoes,
                        obrigatoria: false,
                      )),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ]
        ],
      ),
    );
  }
}
