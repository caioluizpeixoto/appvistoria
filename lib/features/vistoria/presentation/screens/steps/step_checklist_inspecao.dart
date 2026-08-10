import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_vistoria/core/utils/speech_recognizer.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../../domain/vistoria_type.dart';
import '../../../domain/checklist_definitions.dart';

class ChecklistOption {
  final String title;
  final String fullTitle;
  final String value;
  final Color selectedColor;

  const ChecklistOption({
    required this.title,
    required this.fullTitle,
    required this.value,
    required this.selectedColor,
  });
}

class ChecklistItemDef {
  final String id;
  final String label;
  final List<ChecklistOption> options;
  final bool hasTextField;

  const ChecklistItemDef({
    required this.id,
    required this.label,
    required this.options,
    this.hasTextField = true,
  });
}

class StepChecklistInspecao extends StatelessWidget {
  const StepChecklistInspecao({super.key});


  static const List<ChecklistOption> optionsSimNao = [
    ChecklistOption(
        title: 'SIM',
        fullTitle: 'Sim',
        value: 'Sim',
        selectedColor: AppTheme.conforme),
    ChecklistOption(
        title: 'NÃO',
        fullTitle: 'Não',
        value: 'Não',
        selectedColor: Colors.grey),
  ];

  static const List<ChecklistOption> optionsEscritorio = [
    ChecklistOption(
        title: 'P/E',
        fullTitle: 'Possui / Escritório',
        value: 'Possui / Escritório',
        selectedColor: AppTheme.conforme),
    ChecklistOption(
        title: 'E/C',
        fullTitle: 'Está com Cliente',
        value: 'Está com Cliente',
        selectedColor: Colors.orange),
    ChecklistOption(
        title: 'N',
        fullTitle: 'Não Tem',
        value: 'Não Tem',
        selectedColor: Colors.grey),
  ];

  static const List<ChecklistOption> optionsCNC = [
    ChecklistOption(
        title: 'C',
        fullTitle: 'Conforme',
        value: 'Conforme',
        selectedColor: AppTheme.conforme),
    ChecklistOption(
        title: 'NC',
        fullTitle: 'Não Conforme',
        value: 'Não Conforme',
        selectedColor: AppTheme.naoConforme),
    ChecklistOption(
        title: 'NP',
        fullTitle: 'Não Possui',
        value: 'Não Possui',
        selectedColor: Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<VistoriaWizardState>(
      builder: (ctx, state, _) {
        final isPesado = state.isChecklistPesado;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inspeção do Checklist',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Marque a opção correspondente para cada item. Você também pode adicionar uma foto opcional para qualquer item clicando no ícone de câmera.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildLegend(),
              const SizedBox(height: 24),
              if (state.tipoEnum == TipoVistoria.checklistPesado ||
                  state.tipoEnum == TipoVistoria.checklistOnibus ||
                  state.tipoEnum == TipoVistoria.checklistMicroOnibus)
                ...getChecklistCategories(state.tipoEnum).entries.map((cat) {
                  return _buildCategoryGroup(
                    cat.key,
                    cat.value.entries
                        .map((e) => ChecklistItemDef(
                              id: e.key,
                              label: e.value,
                              options: optionsCNC,
                            ))
                        .toList(),
                    state,
                    context,
                  );
                }).toList()
              else ...[
                _buildCategoryGroup('Itens Externos',
                    _getItensVeiculo(isPesado), state, context),
                _buildCategoryGroup(
                    isPesado ? 'Descrição Cabine' : 'Interior do Veículo',
                    _getItensCabine(isPesado),
                    state,
                    context),
                if (isPesado)
                  _buildCategoryGroup(
                      'Itens Carreta', _getItensCarreta(), state, context),
                if (isPesado)
                  _buildCategoryGroup(
                      'Baterias', _getBaterias(), state, context),
                _buildCategoryGroup('Itens de Escritório',
                    _getItensEscritorio(isPesado), state, context),
              ],
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Legendas do Veículo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('C = Conforme | NC = Não Conforme | NP = Não Possui',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          const Text('P/E = Possui/Escritório | E/C = Está com Cliente | N = Não Tem',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(String title, List<ChecklistItemDef> items,
      VistoriaWizardState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildChecklistItem(item, state, context)),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildChecklistItem(
      ChecklistItemDef item, VistoriaWizardState state, BuildContext context) {
    return _ChecklistItemWidget(key: Key(item.id), item: item, state: state, parentContext: context);
  }

  Future<void> _tirarFoto(
      String itemId, VistoriaWizardState state, BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (xfile != null) {
      state.addFotoLocal(itemId, xfile.path);
    }
  }

  // --- Listas de itens ---

  List<ChecklistItemDef> _getItensVeiculo(bool isPesado) {
    if (isPesado) {
      return [
        const ChecklistItemDef(
            id: 'alternador', label: '3.1 Alternador', options: optionsCNC),
        const ChecklistItemDef(
            id: 'macanetas_externas',
            label: '3.2 Maçanetas Externas',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'espelho_retrovisor_d',
            label: '3.3 Espelho Retrovisor (D)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'espelho_retrovisor_e',
            label: '3.4 Espelho Retrovisor (E)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'lanternas', label: '3.5 Lanternas', options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_baixo', label: '3.6 Farol Baixo', options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_alto', label: '3.7 Farol Alto', options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_milha',
            label: '3.8 Farol de Milha',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'seta_direita', label: '3.9 Seta Direita', options: optionsCNC),
        const ChecklistItemDef(
            id: 'seta_esquerda',
            label: '3.10 Seta Esquerda',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'pisca_alerta',
            label: '3.11 Pisca Alerta',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'arla', label: '3.12 Arla', options: optionsCNC),
        const ChecklistItemDef(
            id: 'chave_tanque',
            label: '3.13 Chave do Tanque',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tampa_tanque',
            label: '3.14 Tampa do Tanque',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tanque_suplementar',
            label: '3.15 Tanque Suplementar',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'rodo_ar', label: '3.16 Rodo Ar', options: optionsCNC),
        const ChecklistItemDef(
            id: 'step', label: '3.17 Step', options: optionsCNC),
        const ChecklistItemDef(
            id: 'placa_mercosul',
            label: '3.18 Placa Mercosul?',
            options: optionsSimNao),
        const ChecklistItemDef(
            id: 'luz_re', label: '3.19 Luz de Ré', options: optionsCNC),
        const ChecklistItemDef(
            id: 'luz_freio', label: '3.20 Luz de Freio', options: optionsCNC),
        const ChecklistItemDef(
            id: 'macaco', label: '3.21 Macaco', options: optionsCNC),
        const ChecklistItemDef(
            id: 'triangulo', label: '3.22 Triângulo', options: optionsCNC),
        const ChecklistItemDef(
            id: 'chave_roda', label: '3.23 Chave de Roda', options: optionsCNC),
      ];
    } else {
      return [
        const ChecklistItemDef(
            id: 'macanetas_externas',
            label: 'Maçanetas Externas',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'espelho_retrovisor_d',
            label: 'Espelho Retrovisor (D)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'espelho_retrovisor_e',
            label: 'Espelho Retrovisor (E)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'lanternas_dianteiras',
            label: 'Lanternas Dianteiras',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'lanternas_traseiras',
            label: 'Lanternas Traseiras',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_baixo', label: 'Farol Baixo', options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_alto', label: 'Farol Alto', options: optionsCNC),
        const ChecklistItemDef(
            id: 'farol_milha', label: 'Farol de Milha', options: optionsCNC),
        const ChecklistItemDef(
            id: 'seta_direita', label: 'Seta Direita', options: optionsCNC),
        const ChecklistItemDef(
            id: 'seta_esquerda', label: 'Seta Esquerda', options: optionsCNC),
        const ChecklistItemDef(
            id: 'pisca_alerta', label: 'Pisca Alerta', options: optionsCNC),
        const ChecklistItemDef(
            id: 'tampa_tanque', label: 'Tampa do Tanque', options: optionsCNC),
        const ChecklistItemDef(
            id: 'step', label: 'Estepe', options: optionsCNC),
        const ChecklistItemDef(
            id: 'placa_mercosul',
            label: 'Placa Mercosul?',
            options: optionsSimNao),
        const ChecklistItemDef(
            id: 'luz_re', label: 'Luz de Ré', options: optionsCNC),
        const ChecklistItemDef(
            id: 'luz_freio', label: 'Luz de Freio', options: optionsCNC),
        const ChecklistItemDef(
            id: 'macaco', label: 'Macaco', options: optionsCNC),
        const ChecklistItemDef(
            id: 'triangulo', label: 'Triângulo', options: optionsCNC),
        const ChecklistItemDef(
            id: 'chave_roda', label: 'Chave de Roda', options: optionsCNC),
        const ChecklistItemDef(
            id: 'antena', label: 'Antena', options: optionsCNC),
      ];
    }
  }

  List<ChecklistItemDef> _getItensCabine(bool isPesado) {
    if (isPesado) {
      return [
        const ChecklistItemDef(
            id: 'alarme_outros',
            label: '3.33 Alarme / Outros',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'rastreador', label: '3.34 Rastreador', options: optionsSimNao),
        const ChecklistItemDef(
            id: 'travas_portas',
            label: '3.35 Travas Portas',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'caixa_fusiveis',
            label: '3.36 Caixa Fusível',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'comutador_chave',
            label: '3.37 Comutador Chave (Ignição)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'motor_arranque',
            label: '3.38 Motor de Arranque',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'freio_motor', label: '3.39 Freio Motor', options: optionsCNC),
        const ChecklistItemDef(
            id: 'luzes_painel',
            label: '3.40 Luzes do Painel',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'luz_diagnostico',
            label: '3.41 Luz Diagnóstico',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'conta_giros', label: '3.42 Conta Giros', options: optionsCNC),
        const ChecklistItemDef(
            id: 'buzina_eletrica',
            label: '3.43 Buzina Elétrica',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'buzina_pneumatica',
            label: '3.44 Buzina Pneumática',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_brisas', label: '3.45 Para-brisas', options: optionsCNC),
        const ChecklistItemDef(
            id: 'esguicho_agua',
            label: '3.46 Esguicho de Água do Para-brisa',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'limpador_para_brisas',
            label: '3.47 Limpador do Para-brisa',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'acendedor_eletrico',
            label: '3.48 Acendedor Elétrico',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'piloto_automatico',
            label: '3.49 Piloto Automático',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'som', label: '3.50 Som FM / MP3 / USB', options: optionsCNC),
        const ChecklistItemDef(
            id: 'ar_condicionado',
            label: '3.51 Ar Condicionado',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'ventilador', label: '3.52 Ventilador', options: optionsCNC),
        const ChecklistItemDef(
            id: 'interclima', label: '3.53 Interclima', options: optionsCNC),
        const ChecklistItemDef(
            id: 'vidro_eletrico',
            label: '3.54 Vidro Elétrico',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'manivela_vidros',
            label: '3.55 Manivela Vidros',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'macanetas_internas',
            label: '3.56 Maçanetas Internas',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tapecaria_bancos',
            label: '3.57 Tapeçaria Bancos',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tapecaria_cama',
            label: '3.58 Tapeçaria Cama',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'cinto_motorista',
            label: '3.59 Cinto de Segurança Motorista',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'cinto_passageiro',
            label: '3.60 Cinto de Segurança Passageiro',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'portas_veiculo',
            label: '3.61 Portas do Veículo',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_choque_dianteiro',
            label: '3.62 Para-choque Dianteiro',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_choque_traseiro',
            label: '3.63 Para-choque Traseiro',
            options: optionsCNC),
      ];
    } else {
      return [
        const ChecklistItemDef(
            id: 'alarme_outros', label: 'Alarme / Outros', options: optionsCNC),
        const ChecklistItemDef(
            id: 'travas_portas', label: 'Travas Portas', options: optionsCNC),
        const ChecklistItemDef(
            id: 'comutador_chave',
            label: 'Comutador Chave (Ignição)',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'motor_arranque',
            label: 'Motor de Arranque',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'luzes_painel', label: 'Luzes do Painel', options: optionsCNC),
        const ChecklistItemDef(
            id: 'luz_diagnostico',
            label: 'Luz Diagnóstico',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'conta_giros', label: 'Conta Giros', options: optionsCNC),
        const ChecklistItemDef(
            id: 'buzina', label: 'Buzina', options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_brisas', label: 'Para-Brisas', options: optionsCNC),
        const ChecklistItemDef(
            id: 'esguicho_agua',
            label: 'Esguicho de Água',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'limpador_dianteiro',
            label: 'Limpador Dianteiro',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'limpador_traseiro',
            label: 'Limpador Traseiro',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'acendedor_eletrico',
            label: 'Acendedor Elétrico / 12V',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'som', label: 'Som / Multimídia', options: optionsCNC),
        const ChecklistItemDef(
            id: 'ar_condicionado',
            label: 'Ar Condicionado',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'ventilador', label: 'Ventilador', options: optionsCNC),
        const ChecklistItemDef(
            id: 'vidro_eletrico', label: 'Vidro Elétrico', options: optionsCNC),
        const ChecklistItemDef(
            id: 'manivela_vidros',
            label: 'Manivela Vidros',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'macanetas_internas',
            label: 'Maçanetas Internas',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tapecaria_bancos',
            label: 'Tapeçaria Bancos',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'tapecaria_teto', label: 'Tapeçaria Teto', options: optionsCNC),
        const ChecklistItemDef(
            id: 'cinto_dianteiro',
            label: 'Cinto Segurança Dianteiros',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'cinto_traseiro',
            label: 'Cinto Segurança Traseiros',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'luz_interna', label: 'Luz Interna', options: optionsCNC),
        const ChecklistItemDef(
            id: 'retrovisor_interno',
            label: 'Retrovisor Interno',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'quebra_sol_d', label: 'Quebra Sol (D)', options: optionsCNC),
        const ChecklistItemDef(
            id: 'quebra_sol_e', label: 'Quebra Sol (E)', options: optionsCNC),
        const ChecklistItemDef(
            id: 'portas_veiculo',
            label: 'Portas do Veículo',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_choque_dianteiro',
            label: 'Para-choque Dianteiro',
            options: optionsCNC),
        const ChecklistItemDef(
            id: 'para_choque_traseiro',
            label: 'Para-choque Traseiro',
            options: optionsCNC),
      ];
    }
  }

  List<ChecklistItemDef> _getItensCarreta() {
    return [
      const ChecklistItemDef(
          id: 'tomada_forca',
          label: '3.24 Tomada de Força',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'lanternas_carreta',
          label: '3.25 Lanternas',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'seta_direita_carreta',
          label: '3.26 Seta Direita',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'seta_esquerda_carreta',
          label: '3.27 Seta Esquerda',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'pisca_alerta_carreta',
          label: '3.28 Pisca Alerta',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'luz_re_carreta', label: '3.29 Luz de Ré', options: optionsCNC),
      const ChecklistItemDef(
          id: 'luz_freio_carreta',
          label: '3.30 Luz de Freio',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'pistao_1',
          label: '3.31 Pistão Hidráulico 1',
          options: optionsCNC),
      const ChecklistItemDef(
          id: 'pistao_2',
          label: '3.32 Pistão Hidráulico 2',
          options: optionsCNC),
    ];
  }

  List<ChecklistItemDef> _getBaterias() {
    return [
      const ChecklistItemDef(
          id: 'bateria_a',
          label: '(A) Bateria',
          options: [],
          hasTextField: true),
      const ChecklistItemDef(
          id: 'bateria_b',
          label: '(B) Bateria',
          options: [],
          hasTextField: true),
    ];
  }

  List<ChecklistItemDef> _getItensEscritorio(bool isPesado) {
    return [
      const ChecklistItemDef(
          id: 'doc_rodar', label: 'Documento CRLV', options: optionsEscritorio),
      const ChecklistItemDef(
          id: 'doc_recibo',
          label: 'Documento Recibo',
          options: optionsEscritorio),
      const ChecklistItemDef(
          id: 'manual', label: 'Manual', options: optionsEscritorio),
      const ChecklistItemDef(
          id: 'chave_reserva',
          label: 'Chave Reserva',
          options: optionsEscritorio),
    ];
  }
}

class _OptionButton extends StatelessWidget {
  final String title;
  final String fullTitle;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _OptionButton({
    required this.title,
    required this.fullTitle,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : AppTheme.border;
    final textColor = isSelected ? Colors.white : AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: fullTitle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItemWidget extends StatefulWidget {
  final ChecklistItemDef item;
  final VistoriaWizardState state;
  final BuildContext parentContext;

  const _ChecklistItemWidget({
    Key? key,
    required this.item,
    required this.state,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<_ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<_ChecklistItemWidget> {
  bool _isObsAberto = false;
  bool _isListening = false;
  late TextEditingController _obsController;
  late FocusNode _obsFocus;

  @override
  void initState() {
    super.initState();
    final obs = widget.state.getObs(widget.item.id);
    _obsController = TextEditingController(text: obs);
    _obsFocus = FocusNode();
  }

  @override
  void didUpdateWidget(_ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller text if obs changed externally
    final obs = widget.state.getObs(widget.item.id);
    if (_obsController.text != obs) {
      _obsController.text = obs;
      _obsController.selection = TextSelection.collapsed(offset: obs.length);
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    _obsFocus.dispose();
    super.dispose();
  }


  Future<void> _tirarFoto(String itemId, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 40,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (xfile != null) {
      widget.state.addFotoLocal(itemId, xfile.path);
    }
  }

  void _onMicLongPress() async {
    setState(() => _isListening = true);
    await SpeechRecognizer.startListening();
  }

  void _onMicLongPressEnd(LongPressEndDetails details) async {
    setState(() => _isListening = false);
    
    String rawText = await SpeechRecognizer.stopListening();
    
    if (rawText.isNotEmpty) {
      final currentText = _obsController.text;
      final newText = currentText.isEmpty ? rawText : '$currentText $rawText';
      _obsController.text = newText;
      widget.state.setObs(widget.item.id, newText);
      
      // Also try to set status if it matches an option
      List<String> searchableOptions = widget.item.options.map((e) => e.fullTitle).toList();
      String? matched = SpeechRecognizer.matchChecklistOption(rawText, searchableOptions);
      if (matched != null) {
        final opt = widget.item.options.firstWhere((e) => e.fullTitle == matched);
        widget.state.setStatus(widget.item.id, opt.value);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui captar o áudio. Tente novamente.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.state.getStatus(widget.item.id);
    final obs = widget.state.getObs(widget.item.id);
    final temFoto = widget.state.hasFoto(widget.item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening ? Colors.redAccent : AppTheme.border,
          width: _isListening ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onLongPress: _onMicLongPress,
                onLongPressEnd: _onMicLongPressEnd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic,
                    color: _isListening ? Colors.red : AppTheme.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.note_add_outlined,
                  color: (_isObsAberto || obs.isNotEmpty) ? AppTheme.primary : AppTheme.textSecondary,
                ),
                onPressed: () {
                  setState(() => _isObsAberto = !_isObsAberto);
                  if (_isObsAberto) {
                    // opening
                    WidgetsBinding.instance.addPostFrameCallback((_) { if (_obsFocus.canRequestFocus) _obsFocus.requestFocus(); });
                  }
                },
                tooltip: 'Adicionar Observação',
              ),
              IconButton(
                icon: Icon(
                  temFoto
                      ? Icons.camera_alt_rounded
                      : Icons.camera_alt_outlined,
                  color: temFoto ? AppTheme.primary : AppTheme.textSecondary,
                ),
                onPressed: () => _tirarFoto(widget.item.id, ImageSource.camera),
                tooltip: 'Adicionar Foto (Câmera)',
              ),
              IconButton(
                icon: Icon(
                  temFoto
                      ? Icons.photo_library_rounded
                      : Icons.photo_library_outlined,
                  color: temFoto ? AppTheme.primary : AppTheme.textSecondary,
                ),
                onPressed: () => _tirarFoto(widget.item.id, ImageSource.gallery),
                tooltip: 'Adicionar Foto (Galeria)',
              ),
            ],
          ),
          if (_isListening)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Ouvindo...',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          if (temFoto) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    widget.state.getFotosLocais(widget.item.id).asMap().entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(entry.value)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => widget.state.removeFoto(widget.item.id, entry.key),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (widget.item.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: widget.item.options.map((opt) {
                final isSelected = status == opt.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _OptionButton(
                      title: opt.title,
                      fullTitle: opt.fullTitle,
                      isSelected: isSelected,
                      selectedColor: opt.selectedColor,
                      onTap: () => widget.state.setStatus(widget.item.id, opt.value),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_isObsAberto || obs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextField(
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Adicionar observação (opcional)',
                  hintStyle: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: _obsController,
                focusNode: _obsFocus,
                autofocus: _isObsAberto && obs.isEmpty,
                onChanged: (val) => widget.state.setObs(widget.item.id, val),
              ),
            )
          ],
        ],
      ),
    );
  }
}
