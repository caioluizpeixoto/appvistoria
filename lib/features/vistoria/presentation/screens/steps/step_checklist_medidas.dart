import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

class StepChecklistMedidas extends StatelessWidget {
  const StepChecklistMedidas({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VistoriaWizardState>(
      builder: (ctx, state, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medidas e Complementos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha as informações adicionais do veículo pesado.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Óleo
              _buildSectionTitle('Troca de Óleo'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: state.medidasComplementos['dataTrocaOleo'],
                      decoration: const InputDecoration(
                          labelText: 'Data da Troca',
                          hintText: 'Ex: 10/05/2023'),
                      onChanged: (val) {
                        state.medidasComplementos['dataTrocaOleo'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: state.medidasComplementos['kmTrocaOleo'],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'KM', hintText: 'Ex: 150000'),
                      onChanged: (val) {
                        state.medidasComplementos['kmTrocaOleo'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.medidasComplementos['tipoTrocaMotor'],
                decoration:
                    const InputDecoration(labelText: 'Tipo de Troca (Motor)'),
                onChanged: (val) {
                  state.medidasComplementos['tipoTrocaMotor'] = val;
                  state.forceUpdate();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['tipoTrocaCambio'],
                      decoration: const InputDecoration(labelText: 'Câmbio'),
                      onChanged: (val) {
                        state.medidasComplementos['tipoTrocaCambio'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['tipoTrocaDiferencial'],
                      decoration:
                          const InputDecoration(labelText: 'Diferencial'),
                      onChanged: (val) {
                        state.medidasComplementos['tipoTrocaDiferencial'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Implemento
              _buildSectionTitle('Implemento'),
              TextFormField(
                initialValue: state.medidasComplementos['implementoDescricao'],
                decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex: Baú Frigorífico, Carroceria Aberta, etc.'),
                onChanged: (val) {
                  state.medidasComplementos['implementoDescricao'] = val;
                  state.forceUpdate();
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.medidasComplementos['implementoMarca'],
                decoration: const InputDecoration(labelText: 'Marca'),
                onChanged: (val) {
                  state.medidasComplementos['implementoMarca'] = val;
                  state.forceUpdate();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['implementoEntreEixo'],
                      decoration: const InputDecoration(
                          labelText: 'Entre Eixo', hintText: 'Ex: 3,50m'),
                      onChanged: (val) {
                        state.medidasComplementos['implementoEntreEixo'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['implementoComprimento'],
                      decoration: const InputDecoration(
                          labelText: 'Comprimento', hintText: 'Ex: 6,00m'),
                      onChanged: (val) {
                        state.medidasComplementos['implementoComprimento'] =
                            val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['implementoLargura'],
                      decoration: const InputDecoration(
                          labelText: 'Largura', hintText: 'Ex: 2,50m'),
                      onChanged: (val) {
                        state.medidasComplementos['implementoLargura'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          state.medidasComplementos['implementoAltura'],
                      decoration: const InputDecoration(
                          labelText: 'Altura', hintText: 'Ex: 2,80m'),
                      onChanged: (val) {
                        state.medidasComplementos['implementoAltura'] = val;
                        state.forceUpdate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
