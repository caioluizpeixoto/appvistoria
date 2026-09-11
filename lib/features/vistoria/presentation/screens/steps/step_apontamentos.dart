import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/apontamento_avaria.dart';
import '../../../domain/vistoria_wizard_state.dart';

/// Etapa dedicada de Apontamentos e Avarias.
/// Os itens cadastrados aqui são a base exclusiva para o cálculo e orçamento de peças por IA.
class StepApontamentos extends StatefulWidget {
  const StepApontamentos({super.key});

  @override
  State<StepApontamentos> createState() => _StepApontamentosState();
}

class _StepApontamentosState extends State<StepApontamentos> {
  final _imagePicker = ImagePicker();

  // ── Dados Pré-definidos por Categoria ───────────────────────────────────────

  static const Map<String, List<String>> _pecasPorCategoria = {
    'Estrutural': [
      'Longarina Dianteira Esquerda',
      'Longarina Dianteira Direita',
      'Longarina Centro Esquerda',
      'Longarina Centro Direita',
      'Longarina Traseira Esquerda',
      'Longarina Traseira Direita',
      'Coluna Dianteira Esquerda (A)',
      'Coluna Dianteira Direita (A)',
      'Coluna Central Esquerda (B)',
      'Coluna Central Direita (B)',
      'Coluna Traseira Esquerda (C)',
      'Coluna Traseira Direita (C)',
      'Caixa de Roda Dianteira Esquerda',
      'Caixa de Roda Dianteira Direita',
      'Caixa de Roda Traseira Esquerda',
      'Caixa de Roda Traseira Direita',
      'Torre do Amortecedor Esquerda',
      'Torre do Amortecedor Direita',
      'Painel Frontal',
      'Painel Corta-Fogo',
      'Painel Traseiro',
      'Caixa do Estepe',
      'Assoalho Esquerdo',
      'Assoalho Direito',
      'Caixa de Ar Esquerda',
      'Caixa de Ar Direita',
      'Outra peça estrutural...',
    ],
    'Pintura e Lataria': [
      'Capô Dianteiro',
      'Para-choque Dianteiro',
      'Para-choque Traseiro',
      'Para-lama Dianteiro Esquerdo',
      'Para-lama Dianteiro Direito',
      'Porta Dianteira Esquerda',
      'Porta Dianteira Direita',
      'Porta Traseira Esquerda',
      'Porta Traseira Direita',
      'Lateral Traseira Esquerda',
      'Lateral Traseira Direita',
      'Teto',
      'Tampa Traseira / Porta-malas',
      'Retrovisor Esquerdo',
      'Retrovisor Direito',
      'Grade Dianteira',
      'Friso / Moldura Lateral',
      'Outra peça de lataria/pintura...',
    ],
    'Vidros e Iluminação': [
      'Para-brisa Dianteiro',
      'Vigia Traseiro (Vidro Traseiro)',
      'Vidro Porta Dianteira Esquerda',
      'Vidro Porta Dianteira Direita',
      'Vidro Porta Traseira Esquerda',
      'Vidro Porta Traseira Direita',
      'Vidro Lateral Fixo Esquerdo',
      'Vidro Lateral Fixo Direito',
      'Farol Dianteiro Esquerdo',
      'Farol Dianteiro Direito',
      'Farol de Milha / Neblina Esquerdo',
      'Farol de Milha / Neblina Direito',
      'Lanterna Traseira Esquerda',
      'Lanterna Traseira Direita',
      'Lanterna Tampa Traseira',
      'Outro vidro / iluminação...',
    ],
    'Mecânica / Motor': [
      'Bloco do Motor',
      'Cabeçote / Tampa de Válvulas',
      'Câmbio / Transmissão',
      'Radiador / Arrefecimento',
      'Alternador / Motor de Partida',
      'Caixa de Direção',
      'Suspensão Dianteira',
      'Suspensão Traseira',
      'Amortecedor / Mola',
      'Escapamento / Catalisador',
      'Cárter de Óleo',
      'Bateria',
      'Sistema de Freios',
      'Outro componente mecânico...',
    ],
    'Interior / Segurança': [
      'Pneu Dianteiro Esquerdo',
      'Pneu Dianteiro Direito',
      'Pneu Traseiro Esquerdo',
      'Pneu Traseiro Direito',
      'Pneu Estepe',
      'Roda Dianteira Esquerda',
      'Roda Dianteira Direita',
      'Roda Traseira Esquerda',
      'Roda Traseira Direita',
      'Painel de Instrumentos',
      'Volante / Airbag Volante',
      'Airbag Passageiro / Cortina',
      'Bancos Dianteiros',
      'Bancos Traseiros',
      'Cinto de Segurança',
      'Forro de Teto / Tapeçaria',
      'Central Multimídia / Som',
      'Outro item de interior/segurança...',
    ],
    'Outro': [
      'Outra avaria / peça personalizada...',
    ],
  };

  static const Map<String, List<String>> _motivosPorCategoria = {
    'Estrutural': [
      'Recuperado / Soldado',
      'Amassado / Deformado',
      'Corte / Emenda Estrutural',
      'Trincado / Fissura',
      'Corrosão / Ferrugem',
      'Reparo com Massa Plástica',
      'Desalinhado / Indício de Colisão',
      'Perfurado / Rasgado',
      'Substituído / Não Original',
      'Sem Acesso / Obstruído',
      'Outro motivo estrutural...',
    ],
    'Pintura e Lataria': [
      'Repintura / Retoque',
      'Excesso de Massa / Alta Espessura',
      'Amassado / Pique',
      'Riscado / Arranhado',
      'Queimado de Sol / Verniz Descascado',
      'Desalinhado / Fresta Irregular',
      'Trincado / Quebrado',
      'Ponto de Ferrugem / Corrosão',
      'Diferença de Tonalidade',
      'Micro-ondulação / Batida de Pedra',
      'Outro motivo de lataria...',
    ],
    'Vidros e Iluminação': [
      'Trincado / Fissura',
      'Quebrado / Estilhaçado',
      'Pique de Pedra (Olho de Boi)',
      'Riscado / Arranhado',
      'Numeração / Gravação Divergente',
      'Numeração / Gravação Ilegível',
      'Não Original / Substituído',
      'Opaco / Amarelado',
      'Infiltração de Água / Condensação',
      'Lâmpada / Led Inoperante',
      'Faltante / Ausente',
      'Outro motivo de vidros/iluminação...',
    ],
    'Mecânica / Motor': [
      'Vazamento de Óleo / Fluído',
      'Ruído Anormal / Batendo',
      'Folga Excessiva / Desgaste',
      'Oxidação / Corrosão',
      'Trincado / Quebrado',
      'Gravação Ilegível / Sem Acesso',
      'Plaqueta Ausente / Danificada',
      'Modificado / Não Original',
      'Nível Baixo de Fluído',
      'Faltante / Ausente',
      'Outro motivo mecânico...',
    ],
    'Interior / Segurança': [
      'Pneu Desgastado (Abaixo TWI / Careca)',
      'Pneu com Bolha / Deformação / Rasgo',
      'Roda Amassada / Ralada / Trincada',
      'Rasgado / Descosturado / Furo',
      'Desgastado / Queimado de Sol',
      'Manchado / Sujeira Excessiva',
      'Cinto Travado / Desfiado',
      'Luz de Airbag / Injeção Acesa',
      'Trava / Mecanismo Quebrado',
      'Faltante / Ausente',
      'Outro motivo de interior...',
    ],
    'Outro': [
      'Amassado',
      'Riscado / Arranhado',
      'Trincado / Quebrado',
      'Desgastado / Danificado',
      'Corrosão / Ferrugem',
      'Faltante / Ausente',
      'Outro motivo...',
    ],
  };

  static List<String> _obterMotivosDisponiveis(String categoria, String peca) {
    final pecaLower = peca.toLowerCase();

    if (pecaLower.contains('pneu')) {
      return [
        'Pneu Desgastado (Abaixo TWI / Careca)',
        'Pneu com Bolha / Deformação',
        'Pneu Rasgado / Corte na Banda',
        'Pneu com Desgaste Irregular / Escariado',
        'Medida / Modelo Divergente',
        'Pneu Vencido (DOT Antigo)',
        'Outro motivo para pneu...',
      ];
    }

    if (pecaLower.contains('roda')) {
      return [
        'Roda Amassada / Torta',
        'Roda Ralada / Esfolada',
        'Roda Trincada / Quebrada',
        'Roda Soldada / Recuperada',
        'Pintura Descascada / Corrosão',
        'Parafuso / Prisioneiro Faltante',
        'Outro motivo para roda...',
      ];
    }

    if (pecaLower.contains('vidro') ||
        pecaLower.contains('para-brisa') ||
        pecaLower.contains('vigia')) {
      return [
        'Trincado / Fissura',
        'Pique de Pedra (Olho de Boi)',
        'Riscado / Arranhado',
        'Quebrado / Estilhaçado',
        'Numeração VIS Divergente',
        'Numeração VIS Ilegível / Ausente',
        'Não Original / Sem Logomarca',
        'Película / Insulfilm Danificado',
        'Outro motivo para vidro...',
      ];
    }

    if (pecaLower.contains('farol') ||
        pecaLower.contains('lanterna') ||
        pecaLower.contains('milha')) {
      return [
        'Lente Trincada / Quebrada',
        'Lente Riscada / Fosca / Amarelada',
        'Infiltração de Água / Condensação',
        'Suporte / Fixação Quebrada',
        'Lâmpada / LED Queimado',
        'Foco Desalinhado / Quebrado',
        'Não Original / Paralelo',
        'Faltante / Ausente',
        'Outro motivo para iluminação...',
      ];
    }

    if (pecaLower.contains('airbag') || pecaLower.contains('volante')) {
      return [
        'Luz do Airbag Acesa no Painel',
        'Tampa do Airbag Deformada / Aberta',
        'Volante Desgastado / Rasgado',
        'Indício de Disparo / Acionamento',
        'Outro motivo para airbag/volante...',
      ];
    }

    if (pecaLower.contains('cinto')) {
      return [
        'Cinto Travado / Não Recolhe',
        'Cinto Desfiado / Rasgado',
        'Fecho / Fivela com Defeito',
        'Etiqueta de Data Ausente / Ilegível',
        'Outro motivo para cinto...',
      ];
    }

    return _motivosPorCategoria[categoria] ??
        _motivosPorCategoria['Outro']!;
  }

  static const Map<String, IconData> _categoriaIcones = {
    'Estrutural': Icons.minor_crash_rounded,
    'Pintura e Lataria': Icons.format_paint_rounded,
    'Vidros e Iluminação': Icons.visibility_rounded,
    'Mecânica / Motor': Icons.build_circle_rounded,
    'Interior / Segurança': Icons.airline_seat_recline_extra_rounded,
    'Outro': Icons.more_horiz_rounded,
  };

  static const Map<String, Color> _categoriaCores = {
    'Estrutural': Colors.deepOrange,
    'Pintura e Lataria': Colors.indigo,
    'Vidros e Iluminação': Colors.teal,
    'Mecânica / Motor': Colors.brown,
    'Interior / Segurança': Colors.blueGrey,
    'Outro': Colors.purple,
  };

  // ── Ações de Foto ──────────────────────────────────────────────────────────

  Future<String?> _capturarOuSelecionarFoto(ImageSource source) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (xFile == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: xFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Editar Foto da Avaria',
          toolbarColor: AppTheme.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Editar Foto da Avaria',
        ),
      ],
    );
    if (croppedFile == null) return null;

    final tempFile = File(croppedFile.path);
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'apontamento_foto_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempFile.path)}';
    final savedFile = await tempFile.copy('${appDir.path}/$fileName');
    return savedFile.path;
  }

  // ── Modal de Criação / Edição de Apontamento ────────────────────────────────

  Future<void> _abrirDialogApontamento({
    ApontamentoAvaria? apontamentoExistente,
    int? indexExistente,
  }) async {
    final state = context.read<VistoriaWizardState>();
    final isEditing = apontamentoExistente != null;

    String categoriaSelecionada =
        apontamentoExistente?.categoria ?? 'Pintura e Lataria';
    String pecaSelecionada = apontamentoExistente?.peca ?? '';
    
    final pecaCustomCtrl = TextEditingController();
    final motivoCustomCtrl = TextEditingController();
    final obsCtrl =
        TextEditingController(text: apontamentoExistente?.observacao ?? '');

    bool isPecaCustom = false;
    bool isMotivoCustom = false;

    final List<String> pecasDisponiveis =
        _pecasPorCategoria[categoriaSelecionada] ?? [];

    if (pecaSelecionada.isNotEmpty) {
      if (pecasDisponiveis.contains(pecaSelecionada)) {
        // Encontrado na lista
      } else {
        isPecaCustom = true;
        pecaCustomCtrl.text = pecaSelecionada;
      }
    } else {
      pecaSelecionada = pecasDisponiveis.first;
    }

    final motivosIniciais = _obterMotivosDisponiveis(
        categoriaSelecionada, isPecaCustom ? pecaCustomCtrl.text : pecaSelecionada);

    String motivoSelecionado =
        apontamentoExistente?.motivoAvaria ?? motivosIniciais.first;

    if (motivoSelecionado.isNotEmpty) {
      if (motivosIniciais.contains(motivoSelecionado)) {
        // Encontrado na lista
      } else {
        isMotivoCustom = true;
        motivoCustomCtrl.text = motivoSelecionado;
      }
    } else {
      motivoSelecionado = motivosIniciais.first;
    }

    List<String> fotosTemporarias =
        List<String>.from(apontamentoExistente?.fotosLocais ?? []);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final pecasAtuais =
                _pecasPorCategoria[categoriaSelecionada] ?? ['Outro...'];

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.90,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Cabeçalho do Modal
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEditing
                              ? Icons.edit_note_rounded
                              : Icons.add_circle_outline_rounded,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEditing
                                ? 'Editar Apontamento de Avaria'
                                : 'Novo Apontamento de Avaria',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Corpo do Formulário
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // 1. Categoria (Onde foi a avaria?)
                        const Text(
                          '1. Onde ocorreu a avaria? (Seção)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _pecasPorCategoria.keys.map((cat) {
                            final isSel = cat == categoriaSelecionada;
                            final cor = _categoriaCores[cat] ?? AppTheme.primary;
                            final icone =
                                _categoriaIcones[cat] ?? Icons.category_rounded;

                            return ChoiceChip(
                              avatar: Icon(
                                icone,
                                size: 16,
                                color: isSel ? Colors.white : cor,
                              ),
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: cor,
                              backgroundColor: AppTheme.surfaceVariant,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppTheme.textPrimary,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setStateModal(() {
                                    categoriaSelecionada = cat;
                                    final novasPecas =
                                        _pecasPorCategoria[cat] ?? [];
                                    pecaSelecionada = novasPecas.isNotEmpty
                                        ? novasPecas.first
                                        : '';
                                    isPecaCustom = pecaSelecionada
                                        .contains('Outra');
                                    final novosMotivos = _obterMotivosDisponiveis(
                                        cat, pecaSelecionada);
                                    if (!novosMotivos.contains(motivoSelecionado) &&
                                        !isMotivoCustom) {
                                      motivoSelecionado = novosMotivos.first;
                                    }
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // 2. Seleção de Peça / Componente
                        Row(
                          children: [
                            const Text(
                              '2. Qual é a peça / componente?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (!isPecaCustom)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Digitar outra',
                                    style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  setStateModal(() {
                                    isPecaCustom = true;
                                    pecaCustomCtrl.clear();
                                    final novosMotivos = _obterMotivosDisponiveis(
                                        categoriaSelecionada, '');
                                    if (!novosMotivos.contains(motivoSelecionado) &&
                                        !isMotivoCustom) {
                                      motivoSelecionado = novosMotivos.first;
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (isPecaCustom) ...[
                          TextField(
                            controller: pecaCustomCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Nome da Peça / Local',
                              hintText: 'Ex: Friso da coluna traseira direita',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.list_alt_rounded),
                                tooltip: 'Voltar para lista pré-definida',
                                onPressed: () {
                                  setStateModal(() {
                                    isPecaCustom = false;
                                    pecaSelecionada = pecasAtuais.first;
                                    final novosMotivos = _obterMotivosDisponiveis(
                                        categoriaSelecionada, pecaSelecionada);
                                    if (!novosMotivos.contains(motivoSelecionado) &&
                                        !isMotivoCustom) {
                                      motivoSelecionado = novosMotivos.first;
                                    }
                                  });
                                },
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (text) {
                              setStateModal(() {
                                final novosMotivos = _obterMotivosDisponiveis(
                                    categoriaSelecionada, text);
                                if (!novosMotivos.contains(motivoSelecionado) &&
                                    !isMotivoCustom) {
                                  motivoSelecionado = novosMotivos.first;
                                }
                              });
                            },
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: pecasAtuais.contains(pecaSelecionada)
                                ? pecaSelecionada
                                : (pecasAtuais.isNotEmpty
                                    ? pecasAtuais.first
                                    : null),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Selecione a Peça Pré-definida',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(Icons.directions_car_rounded),
                            ),
                            items: pecasAtuais.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontStyle: p.contains('Outra')
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                if (v.contains('Outra')) {
                                  setStateModal(() {
                                    isPecaCustom = true;
                                    pecaCustomCtrl.clear();
                                    final novosMotivos = _obterMotivosDisponiveis(
                                        categoriaSelecionada, '');
                                    if (!novosMotivos.contains(motivoSelecionado) &&
                                        !isMotivoCustom) {
                                      motivoSelecionado = novosMotivos.first;
                                    }
                                  });
                                } else {
                                  setStateModal(() {
                                    pecaSelecionada = v;
                                    final novosMotivos = _obterMotivosDisponiveis(
                                        categoriaSelecionada, v);
                                    if (!novosMotivos.contains(motivoSelecionado) &&
                                        !isMotivoCustom) {
                                      motivoSelecionado = novosMotivos.first;
                                    }
                                  });
                                }
                              }
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // 3. Motivo da Avaria / Tipo de Dano
                        Row(
                          children: [
                            const Text(
                              '3. Motivo / Tipo da Avaria',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (!isMotivoCustom)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('Digitar outro',
                                    style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  setStateModal(() {
                                    isMotivoCustom = true;
                                    motivoCustomCtrl.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (isMotivoCustom) ...[
                          TextField(
                            controller: motivoCustomCtrl,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Descreva o motivo da avaria',
                              hintText: 'Ex: Fissura profunda com oxidação',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.list_alt_rounded),
                                tooltip: 'Voltar para opções pré-definidas',
                                onPressed: () {
                                  setStateModal(() {
                                    isMotivoCustom = false;
                                    final motivosAtuais = _obterMotivosDisponiveis(
                                        categoriaSelecionada,
                                        isPecaCustom
                                            ? pecaCustomCtrl.text
                                            : pecaSelecionada);
                                    motivoSelecionado = motivosAtuais.first;
                                  });
                                },
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ] else ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _obterMotivosDisponiveis(
                                    categoriaSelecionada,
                                    isPecaCustom
                                        ? pecaCustomCtrl.text
                                        : pecaSelecionada)
                                .map((motivo) {
                              final isSel = motivo == motivoSelecionado;
                              return ChoiceChip(
                                label: Text(motivo),
                                selected: isSel,
                                selectedColor: AppTheme.naoConforme,
                                backgroundColor: AppTheme.surfaceVariant,
                                labelStyle: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    if (motivo.contains('Outro')) {
                                      setStateModal(() {
                                        isMotivoCustom = true;
                                        motivoCustomCtrl.clear();
                                      });
                                    } else {
                                      setStateModal(() {
                                        motivoSelecionado = motivo;
                                      });
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // 4. Fotos da Avaria
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '4. Fotos do Apontamento / Avaria',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.camera_alt_rounded,
                                      color: AppTheme.primary),
                                  tooltip: 'Tirar Foto',
                                  onPressed: () async {
                                    final path = await _capturarOuSelecionarFoto(
                                        ImageSource.camera);
                                    if (path != null) {
                                      setStateModal(() {
                                        fotosTemporarias.add(path);
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.photo_library_rounded,
                                      color: AppTheme.primary),
                                  tooltip: 'Escolher da Galeria',
                                  onPressed: () async {
                                    final path = await _capturarOuSelecionarFoto(
                                        ImageSource.gallery);
                                    if (path != null) {
                                      setStateModal(() {
                                        fotosTemporarias.add(path);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (fotosTemporarias.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.border,
                                  style: BorderStyle.solid),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.photo_camera_back_outlined,
                                    color: AppTheme.textSecondary),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Nenhuma foto anexada. Use os botões acima para fotografar o dano.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: fotosTemporarias.length,
                              itemBuilder: (ctx, fIdx) {
                                final fPath = fotosTemporarias[fIdx];
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppTheme.border),
                                        image: DecorationImage(
                                          image: FileImage(File(fPath)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setStateModal(() {
                                            fotosTemporarias.removeAt(fIdx);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // 5. Observações Complementares
                        const Text(
                          '5. Observações / Detalhes (Opcional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: obsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText:
                                'Ex: Profundidade aproximada de 1cm, sem trinca na pintura...',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // Botão de Salvar Apontamento
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border:
                          Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, color: Colors.white),
                        label: Text(
                          isEditing
                              ? 'Atualizar Apontamento'
                              : 'Salvar Apontamento',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          final pecaFinal = isPecaCustom
                              ? pecaCustomCtrl.text.trim()
                              : pecaSelecionada;
                          final motivoFinal = isMotivoCustom
                              ? motivoCustomCtrl.text.trim()
                              : motivoSelecionado;

                          if (pecaFinal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor, informe a peça/local.'),
                                backgroundColor: AppTheme.naoConforme,
                              ),
                            );
                            return;
                          }

                          if (motivoFinal.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Por favor, informe o motivo da avaria.'),
                                backgroundColor: AppTheme.naoConforme,
                              ),
                            );
                            return;
                          }

                          if (isEditing && indexExistente != null) {
                            final atualizado = apontamentoExistente.copyWith(
                              categoria: categoriaSelecionada,
                              peca: pecaFinal,
                              motivoAvaria: motivoFinal,
                              observacao: obsCtrl.text.trim(),
                              fotosLocais: fotosTemporarias,
                            );
                            state.updateApontamento(indexExistente, atualizado);
                          } else {
                            final novo = ApontamentoAvaria(
                              id: 'apontamento_${DateTime.now().millisecondsSinceEpoch}',
                              categoria: categoriaSelecionada,
                              peca: pecaFinal,
                              motivoAvaria: motivoFinal,
                              observacao: obsCtrl.text.trim(),
                              fotosLocais: fotosTemporarias,
                            );
                            state.addApontamento(novo);
                          }

                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build Principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final apontamentos = state.apontamentos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Card Informativo Superior ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.12),
                AppTheme.primary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apontamentos para Cálculo por IA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Apenas as avarias adicionadas aqui serão orçadas pela IA.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      '${apontamentos.length} avaria(s) apontada(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Adicionar Avaria'),
                    onPressed: () => _abrirDialogApontamento(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Lista de Apontamentos ─────────────────────────────────────────────
        if (apontamentos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 54,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nenhum apontamento de avaria adicionado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Caso o veículo possua avarias em peças que necessitam de cálculo/orçamento, clique no botão acima para registrar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                  icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
                  label: const Text(
                    '+ Adicionar Primeiro Apontamento',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                  onPressed: () => _abrirDialogApontamento(),
                ),
              ],
            ),
          )
        else
          ...apontamentos.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final catCor =
                _categoriaCores[item.categoria] ?? AppTheme.primary;
            final catIcone =
                _categoriaIcones[item.categoria] ?? Icons.report_problem_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Faixa superior do Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      color: catCor.withValues(alpha: 0.08),
                      child: Row(
                        children: [
                          Icon(catIcone, size: 16, color: catCor),
                          const SizedBox(width: 8),
                          Text(
                            item.categoria.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: catCor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          // Botão Editar
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: AppTheme.textSecondary,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Editar',
                            onPressed: () => _abrirDialogApontamento(
                              apontamentoExistente: item,
                              indexExistente: idx,
                            ),
                          ),
                          // Botão Excluir
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            color: AppTheme.naoConforme,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Excluir',
                            onPressed: () {
                              state.removeApontamento(idx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Apontamento removido.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Conteúdo do Card
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.peca,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.naoConforme.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.naoConforme
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  item.motivoAvaria,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.naoConforme,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (item.observacao.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.observacao,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Fotos anexadas
                          if (item.fotosLocais.isNotEmpty) ...[
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: item.fotosLocais.length,
                                itemBuilder: (ctx, fIdx) {
                                  final fotoPath = item.fotosLocais[fIdx];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppTheme.border),
                                      image: DecorationImage(
                                        image: FileImage(File(fotoPath)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(Icons.no_photography_outlined,
                                    size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                const Text(
                                  'Sem fotos anexadas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.add_a_photo_outlined,
                                      size: 14),
                                  label: const Text('Anexar foto',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () => _abrirDialogApontamento(
                                    apontamentoExistente: item,
                                    indexExistente: idx,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }
}
