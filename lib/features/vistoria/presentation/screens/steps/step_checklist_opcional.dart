import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

class StepChecklistOpcional extends StatefulWidget {
  const StepChecklistOpcional({super.key});

  @override
  State<StepChecklistOpcional> createState() => _StepChecklistOpcionalState();
}

class _StepChecklistOpcionalState extends State<StepChecklistOpcional> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Map<String, List<String>> _categoriasCaminhao = {
    'PNEUS/RODAS': [
      'PNEU DIANTEIRO ESQUERDO', 'RODA DIANTEIRA ESQUERDA', 'CALOTA DIANTEIRA ESQUERDA',
      'PNEU TRASEIRO ESQUERDO', 'RODA TRASEIRA ESQUERDA', 'CALOTA TRASEIRA ESQUERDA',
      'PNEU ESTEPE', 'RODA ESTEPE',
      'PNEU TRASEIRO DIREITO', 'RODA TRASEIRA DIREITA', 'CALOTA TRASEIRA DIREITA',
      'PNEU DIANTEIRO DIREITO', 'RODA DIANTEIRA DIREITA', 'CALOTA DIANTEIRA DIREITA'
    ],
    'PARTE DIANTEIRA': [
      'CAPÔ', 'FAROL DIREITO', 'LANTERNA DIREITA', 'FAROL DE MILHA DIR.',
      'PARA-CHOQUE', 'GRADE', 'PARA-BRISA', 'FAROL ESQUERDO', 'LANTERNA ESQUERDA', 'FAROL DE MILHA ESQUERDO'
    ],
    'LATERAL ESQUERDA': [
      'LATERAL', 'VIDRO VIGIA', 'VIDRO TRASEIRO', 'PORTA TRASEIRA', 'VIDRO DIANTEIRO',
      'PORTA DIANTEIRA', 'ESPELHO RETROVISOR', 'PARA-LAMA'
    ],
    'LATERAL DIREITA': [
      'LATERAL', 'VIDRO VIGIA', 'VIDRO TRASEIRO', 'PORTA TRASEIRA', 'VIDRO DIANTEIRO',
      'PORTA DIANTEIRA', 'ESPELHO RETROVISOR', 'PARA-LAMA'
    ],
    'TRASEIRA': [
      'LANTERNA DE NEBLINA ESQ.', 'LANTERNA DE NEBLINA DIR.', 'CAPÔ TRASEIRO/TAMPA',
      'LUZ DA PLACA', 'VIDRO VIGIA', 'LIMPADOR TRASEIRO', 'LANTERNA ESQUERDA', 'LANTERNA DIREITA',
      'PARA-CHOQUE', 'TETO'
    ],
    'EQUIPAMENTOS': [
      'AR CONDICIONADO', 'VIDROS ELÉTRICOS', 'TRAVAS ELÉTRICAS', 'ALARME', 'PAINEL DE INSTRUMENTOS',
      'PRESENÇA DE ODOR ?', 'VOLANTE', 'ANTENA', 'ALTO-FALANTES', 'RÁDIO CD PLAYER', 'RÁDIO DVD', 'TELAS AUXILIARES ?'
    ],
    'BANCOS E REVESTIMENTOS': [
      'BANCO TRASEIRO', 'BANCO D.D.', 'BANCO D.E.', 'TAPETES', 'REVESTIMENTO DO TETO',
      'REVESTIMENTO PORTA D.D.', 'REVESTIMENTO PORTA T.D.', 'REVESTIMENTO PORTA T.E.', 'REVESTIMENTO PORTA D.E.'
    ],
    'EQUIPAMENTOS OBRIGATÓRIOS (SEGURANÇA)': [
      'LAVADOR', 'LIMPADOR PARA-BRISA', 'FAROL DE NEBLINA', 'LUZ DE RÉ', 'LUZ DE FREIO',
      'LANTERNA', 'FAROL', 'MANUAL DO PROPRIETÁRIO', 'CHAVE RESERVA', 'BLINDAGEM', 'TRIÂNGULO',
      'MACACO', 'CHAVE DE RODA', 'ESTEPE', 'EXTINTOR'
    ],
    'ACIONAMENTO DO MOTOR': [
      'BATERIA', 'NÍVEL DO ÓLEO', 'PARTIDA / ACIONAMENTO DO MOTOR'
    ]
  };

  final Map<String, List<String>> _categoriasCarro = {
    'ITENS DE INSPEÇÃO': [
      'Buzina',
      'Lanterna',
      'Farol Baixo',
      'Farol Alto',
      'Luz de Freio',
      'Break Light',
      'Pisca Alerta',
      'Setas de Direção',
      'Luzes Internas',
      'Luzes de Placa',
      'Luzes de Ré',
      'Limpador de Para-brisa',
      'Retrovisores',
      'Macaco',
      'Triângulo de Sinalização',
      'Chave de Roda',
      'Estepe (Calibragem e Condições)',
      'Cintos de Segurança',
      'Maçanetas e Fechaduras',
      'Escapamento',
      'Adesivos (Refletivos e Identificação, quando aplicável)',
      'Condições dos Bancos',
      'Quebra-sol (Motorista e Passageiro)',
      'Ar-condicionado',
      'Tapetes e Forros',
      'Pneus (Calibragem e Condições)',
      'Profundidade dos Sulcos dos Pneus (TWI)',
      'Óleo do Motor (Nível)',
      'Fluido de Freio (Nível)',
      'Água do Limpador',
      'Fluido de Arrefecimento (Radiador)',
      'Freios (Inclusive o Freio de Estacionamento)',
      'Painel de Instrumentos (Luzes de Advertência)',
      'Para-brisa (Trincas e Condições)',
      'Vidros e Películas',
      'Vidros Elétricos',
      'Travas Elétricas',
      'Bateria (Fixação e Polos)',
      'Ausência de Vazamentos (Óleo, Água, Combustível)'
    ]
  };

  Map<String, List<String>> _getCategorias(VistoriaWizardState state) {
    if (state.tipoVistoria.toLowerCase().contains('caminh')) {
      return _categoriasCaminhao;
    }
    return _categoriasCarro;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = context.watch<VistoriaWizardState>();
    final categorias = _getCategorias(state);

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
                        'Realizar Checklist Opcional?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se ativado, as informações preenchidas constarão em uma nova página no PDF gerado.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: AppTheme.primary,
                  value: state.realizarChecklistOpcional,
                  onChanged: (val) {
                    setState(() {
                      state.realizarChecklistOpcional = val;
                      if (val) {
                        for (var cat in categorias.values) {
                          for (var item in cat) {
                            if (!state.checklistOpcional.containsKey(item)) {
                              state.checklistOpcional[item] = 'OK';
                            }
                          }
                        }
                      }
                    });
                  },
                )
              ],
            ),
          ),
          
          if (state.realizarChecklistOpcional) ...[
            const SizedBox(height: 16),
            ...categorias.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          border: const Border(bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      ...entry.value.map((item) {
                        final val = state.checklistOpcional[item] ?? 'OK';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: val,
                                          style: const TextStyle(fontSize: 13, color: Colors.black),
                                          items: ['OK', 'NÃO OK', 'NÃO POSSUI'].map((st) {
                                            return DropdownMenuItem(
                                              value: st,
                                              child: Text(st),
                                            );
                                          }).toList(),
                                          onChanged: (newVal) {
                                            if (newVal != null) {
                                              setState(() {
                                                state.checklistOpcional[item] = newVal;
                                                if (newVal != 'NÃO OK') {
                                                  state.checklistOpcionalMotivos.remove(item);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (val == 'NÃO OK')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextFormField(
                                    initialValue: state.checklistOpcionalMotivos[item] ?? '',
                                    decoration: const InputDecoration(
                                      labelText: 'Motivo',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (text) {
                                      state.checklistOpcionalMotivos[item] = text;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }
}
