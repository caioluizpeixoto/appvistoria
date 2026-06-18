import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 4 — Painel e Hodômetro
class StepPainelHodometro extends StatefulWidget {
  const StepPainelHodometro({super.key});
  @override
  State<StepPainelHodometro> createState() => _StepPainelHodometroState();
}

class _StepPainelHodometroState extends State<StepPainelHodometro> {
  final _kmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kmCtrl.text = context.read<VistoriaWizardState>().km;
    });
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Dica OCR
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dica: Após capturar a foto do painel, tente ler a quilometragem pela câmera. Você pode editar manualmente abaixo.',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),

        InspecaoItemWidget(
          itemId: 'painel_hodometro',
          label: 'Painel e Hodômetro',
          obrigatoria: true,
          statusOptions: const [
            'Em perfeito estado',
            'Com avaria',
            'Hodômetro ilegível',
            'Divergente',
            'Não analisado',
          ],
        ),

        // Campo KM editável
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Quilometragem (KM)',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KM / Hodômetro',
                  hintText: 'Ex: 45.000',
                  prefixIcon: Icon(Icons.speed_rounded),
                  suffixText: 'km',
                ),
                onChanged: (v) {
                  state.km = v;
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  state.notifyListeners();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
