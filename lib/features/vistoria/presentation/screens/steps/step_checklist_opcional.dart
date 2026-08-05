import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

class StepChecklistOpcional extends StatefulWidget {
  const StepChecklistOpcional({super.key});

  @override
  State<StepChecklistOpcional> createState() => _StepChecklistOpcionalState();
}

class _StepChecklistOpcionalState extends State<StepChecklistOpcional>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<String> _obsAbertas = {};

  final Map<String, List<String>> _categoriasVistoria = {
    'PNEUS/RODAS': [
      'PNEU DIANTEIRO ESQUERDO',
      'RODA DIANTEIRA ESQUERDA',
      'CALOTA DIANTEIRA ESQUERDA',
      'PNEU TRASEIRO ESQUERDO',
      'RODA TRASEIRA ESQUERDA',
      'CALOTA TRASEIRA ESQUERDA',
      'PNEU ESTEPE',
      'RODA ESTEPE',
      'PNEU TRASEIRO DIREITO',
      'RODA TRASEIRA DIREITA',
      'CALOTA TRASEIRA DIREITA',
      'PNEU DIANTEIRO DIREITO',
      'RODA DIANTEIRA DIREITA',
      'CALOTA DIANTEIRA DIREITA'
    ],
    'PARTE DIANTEIRA': [
      'CAPÔ',
      'FAROL DIREITO',
      'LANTERNA DIREITA',
      'FAROL DE MILHA DIR.',
      'PARA-CHOQUE',
      'GRADE',
      'PARA-BRISA',
      'FAROL ESQUERDO',
      'LANTERNA ESQUERDA',
      'FAROL DE MILHA ESQUERDO'
    ],
    'LATERAL ESQUERDA': [
      'LATERAL',
      'VIDRO VIGIA',
      'VIDRO TRASEIRO',
      'PORTA TRASEIRA',
      'VIDRO DIANTEIRO',
      'PORTA DIANTEIRA',
      'ESPELHO RETROVISOR',
      'PARA-LAMA'
    ],
    'LATERAL DIREITA': [
      'LATERAL',
      'VIDRO VIGIA',
      'VIDRO TRASEIRO',
      'PORTA TRASEIRA',
      'VIDRO DIANTEIRO',
      'PORTA DIANTEIRA',
      'ESPELHO RETROVISOR',
      'PARA-LAMA'
    ],
    'TRASEIRA': [
      'LANTERNA DE NEBLINA ESQ.',
      'LANTERNA DE NEBLINA DIR.',
      'CAPÔ TRASEIRO/TAMPA',
      'LUZ DA PLACA',
      'VIDRO VIGIA',
      'LIMPADOR TRASEIRO',
      'LANTERNA ESQUERDA',
      'LANTERNA DIREITA',
      'PARA-CHOQUE',
      'TETO'
    ],
    'EQUIPAMENTOS': [
      'AR CONDICIONADO',
      'VIDROS ELÉTRICOS',
      'TRAVAS ELÉTRICAS',
      'ALARME',
      'PAINEL DE INSTRUMENTOS',
      'PRESENÇA DE ODOR ?',
      'VOLANTE',
      'ANTENA',
      'ALTO-FALANTES',
      'RÁDIO CD PLAYER',
      'RÁDIO DVD',
      'TELAS AUXILIARES ?'
    ],
    'BANCOS E REVESTIMENTOS': [
      'BANCO TRASEIRO',
      'BANCO D.D.',
      'BANCO D.E.',
      'TAPETES',
      'REVESTIMENTO DO TETO',
      'REVESTIMENTO PORTA D.D.',
      'REVESTIMENTO PORTA T.D.',
      'REVESTIMENTO PORTA T.E.',
      'REVESTIMENTO PORTA D.E.'
    ],
    'EQUIPAMENTOS OBRIGATÓRIOS (SEGURANÇA)': [
      'LAVADOR',
      'LIMPADOR PARA-BRISA',
      'FAROL DE NEBLINA',
      'LUZ DE RÉ',
      'LUZ DE FREIO',
      'LANTERNA',
      'FAROL',
      'MANUAL DO PROPRIETÁRIO',
      'CHAVE RESERVA',
      'BLINDAGEM',
      'TRIÂNGULO',
      'MACACO',
      'CHAVE DE RODA',
      'ESTEPE',
      'EXTINTOR'
    ],
    'ACIONAMENTO DO MOTOR': [
      'BATERIA',
      'NÍVEL DO ÓLEO',
      'PARTIDA / ACIONAMENTO DO MOTOR'
    ]
  };

  Map<String, List<String>> _getCategorias(VistoriaWizardState state) {
    return _categoriasVistoria;
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          border: const Border(
                              bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ),
                      ...entry.value.map((item) {
                        final val = state.checklistOpcional[item] ?? 'OK';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(item,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: val,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black),
                                          items: VistoriaWizardState
                                              .statusChecklistOpcional
                                              .map((st) {
                                            return DropdownMenuItem(
                                              value: st,
                                              child: Text(st),
                                            );
                                          }).toList(),
                                          onChanged: (newVal) {
                                            if (newVal != null) {
                                              setState(() {
                                                state.checklistOpcional[item] =
                                                    newVal;
                                                if ([
                                                  'OK',
                                                  'NÃO POSSUI',
                                                  'POSSUI E FUNCIONA',
                                                  'FUNCIONA',
                                                  'SEM DESGASTE',
                                                  'MANUAL'
                                                ].contains(newVal)) {
                                                  state.checklistOpcionalMotivos
                                                      .remove(item);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.note_add_outlined,
                                      color: _obsAbertas.contains(item) || (state.checklistOpcionalMotivos[item]?.isNotEmpty ?? false) ? AppTheme.primary : Colors.grey,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    splashRadius: 20,
                                    onPressed: () {
                                      setState(() {
                                        if (_obsAbertas.contains(item)) {
                                          _obsAbertas.remove(item);
                                        } else {
                                          _obsAbertas.add(item);
                                        }
                                      });
                                    }
                                  )
                                ],
                              ),
                              if (_obsAbertas.contains(item) || ![
                                'OK',
                                'NÃO POSSUI',
                                'POSSUI E FUNCIONA',
                                'FUNCIONA',
                                'SEM DESGASTE',
                                'MANUAL'
                              ].contains(val))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextFormField(
                                    initialValue:
                                        state.checklistOpcionalMotivos[item] ??
                                            '',
                                    decoration: InputDecoration(
                                      labelText: 'Observação',
                                      hintText: 'Adicionar observação (opcional)',
                                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.7)),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: Colors.grey.withOpacity(0.08),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (text) {
                                      state.checklistOpcionalMotivos[item] =
                                          text;
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
