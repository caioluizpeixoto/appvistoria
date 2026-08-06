import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/app_database.dart';
import '../../features/vistoria/domain/vistoria_type.dart';
import '../../features/vistoria/domain/vistoria_wizard_state.dart';
import '../../features/vistoria/domain/checklist_definitions.dart';
import '../../injection_container.dart';
import '../../database/daos/vistoria_dao.dart';

Future<String?> generateChecklistPdf({
  required Vistoria vistoria,
  required Veiculo veiculo,
  VistoriaWizardState? wizardState,
}) async {
  // Se wizardState for nulo ou estiver sem checklistStatus, recarrega do banco de dados local (Drift)
  if (wizardState == null || wizardState.checklistStatus.isEmpty) {
    try {
      final vistoriaDao = sl<VistoriaDao>();
      wizardState ??= VistoriaWizardState(vistoriaId: vistoria.id);

      wizardState.numeroLaudo = vistoria.numeroLaudo;
      wizardState.clienteNome = vistoria.clienteNome ?? '';
      wizardState.clienteEmail = vistoria.clienteEmail ?? '';
      wizardState.clienteCpf = vistoria.clienteCpf ?? '';
      wizardState.clienteTelefone = vistoria.clienteTelefone ?? '';
      wizardState.vistoriadorNome = vistoria.vistoriadorNome ?? '';
      wizardState.vistoriadorCpf = vistoria.vistoriadorCpf ?? '';
      wizardState.unidade = vistoria.unidade ?? '';
      wizardState.assinaturaPath = vistoria.assinaturaPath;
      wizardState.assinaturaClientePath = vistoria.assinaturaClientePath;
      wizardState.observacoesVistoriador = vistoria.observacoesGerais ?? '';
      wizardState.parecerTecnico = vistoria.parecerTecnico ?? '';
      wizardState.resultadoFinal = vistoria.statusFinal ?? '';
      wizardState.status = vistoria.status;
      if (vistoria.tipoVistoria != null) {
        wizardState.tipoVistoria = vistoria.tipoVistoria!;
      }

      final itens = await vistoriaDao.listarItensPorVistoria(vistoria.id);
      for (final item in itens) {
        if (item.etapa == 'checklist_opcional') {
          wizardState.realizarChecklistOpcional = true;
          wizardState.checklistOpcional[item.nome] = item.status;
        } else {
          wizardState.checklistStatus[item.nome] = item.status;
          wizardState.checklistObs[item.nome] = item.observacao ?? '';
        }
      }

      final fotos = await vistoriaDao.listarFotosPorVistoria(vistoria.id);
      for (final foto in fotos) {
        if (foto.etapa == 'extra') {
          if (foto.pathLocal != null && foto.pathLocal!.isNotEmpty) {
            wizardState.fotosExtras.add({
              'pathLocal': foto.pathLocal ?? '',
              'url': foto.urlSupabase,
              'obs': foto.observacao ?? '',
              'titulo': 'Foto Extra',
              'categoria': 'Outro',
            });
          }
        } else {
          if (foto.pathLocal != null) {
            final itemId = foto.itemId ?? 'desconhecido';
            wizardState.fotosLocais
                .putIfAbsent(itemId, () => [])
                .add(foto.pathLocal!);
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do checklist do banco para o PDF: $e');
    }
  }

  final pdf = pw.Document(
    title: 'Checklist Veicular - ${veiculo.placa}',
    author: vistoria.vistoriadorNome ?? 'Sistema',
  );

  final tipoEnum = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
  final isPesado = tipoEnum == TipoVistoria.checklistPesado;
  final isOnibus = tipoEnum == TipoVistoria.checklistOnibus;
  final isMicroOnibus = tipoEnum == TipoVistoria.checklistMicroOnibus;
  final isChecklistPasseio = tipoEnum == TipoVistoria.checklistPasseio;
  final isChecklist = isPesado ||
      isChecklistPasseio ||
      isOnibus ||
      isMicroOnibus ||
      tipoEnum == TipoVistoria.vistoriaEntrada;
  final isDynamicChecklist = isPesado || isOnibus || isMicroOnibus;

  pw.ImageProvider? logoImage;
  try {
    final logoBytes = await rootBundle.load('assets/images/topo.pdf.png');
    logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
  } catch (_) {}

  pw.ImageProvider? rodapeImage;
  try {
    final rodapeBytes = await rootBundle.load('assets/images/rodape.pdf.png');
    rodapeImage = pw.MemoryImage(rodapeBytes.buffer.asUint8List());
  } catch (_) {}

  pw.ImageProvider? assinaturaImage;
  if (wizardState?.assinaturaPath != null) {
    try {
      final file = File(wizardState!.assinaturaPath!);
      if (file.existsSync()) {
        assinaturaImage = pw.MemoryImage(file.readAsBytesSync());
      }
    } catch (_) {}
  }

  pw.ImageProvider? assinaturaClienteImage;
  if (wizardState?.assinaturaClientePath != null) {
    try {
      final file = File(wizardState!.assinaturaClientePath!);
      if (file.existsSync()) {
        assinaturaClienteImage = pw.MemoryImage(file.readAsBytesSync());
      }
    } catch (_) {}
  }

  // Cores
  const primaryColor = PdfColor.fromInt(0xFF003366);
  const secondaryColor = PdfColor.fromInt(0xFF4A4A4A);
  const lightBg = PdfColor.fromInt(0xFFF5F7FA);
  const conformeColor = PdfColor.fromInt(0xFF4CAF50);
  const naoConformeColor = PdfColor.fromInt(0xFFF44336);
  const naoPossuiColor = PdfColor.fromInt(0xFF9E9E9E);

  // Fonte
  final fontRegular = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();

  // Helper para construir grupos de itens

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Stack(
      alignment: pw.Alignment.centerRight,
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('EAEAEA'),
            border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('F39C12'), width: 3)),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 140,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('PÁGINA ${context.pageNumber}', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey700)),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('SUMARÉ VISTORIAS VEICULARES LTDA', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey800)),
                    pw.SizedBox(height: 2),
                    pw.Text('11.977.969/0001-33 - AV REBOUÇAS 1989 - SUMARÉ - SP - CEP 13170-275 - TEL 19 3306.8604', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 6, color: PdfColors.grey800)),
                    pw.SizedBox(height: 2),
                    pw.Text('SUMARE@ULTRAVISAO.COM.BR - CREDENCIAMENTO 06/2025-3651- DETRAN SP', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 6, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.SizedBox(width: 140),
            ],
          ),
        ),
        if (rodapeImage != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 16),
            child: pw.Image(rodapeImage!, width: 120),
          ),
      ],
    );
  }

  List<pw.Widget> buildItemCategory(String title, Map<String, String> items) {
    if (wizardState == null) return [];
    final wState = wizardState!;

    // Filtra os itens que têm algum status
    final validItems = items.entries
        .where((e) => wState.getStatus(e.key).isNotEmpty)
        .toList();
    if (validItems.isEmpty) return [];

    return [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: primaryColor,
        width: double.infinity,
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
              font: fontBold, color: PdfColors.white, fontSize: 12),
        ),
      ),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
        },
        children: validItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final mapEntry = entry.value;
          final itemId = mapEntry.key;
          final itemLabel = mapEntry.value;
          final status = wState.getStatus(itemId);

          PdfColor statusColor = PdfColors.black;
          if (status == 'Conforme' ||
              status == 'Sim' ||
              status == 'Funcionando' ||
              status == 'Possui / Escritório')
            statusColor = conformeColor;
          if (status == 'Não Conforme' || status == 'Danificado')
            statusColor = naoConformeColor;
          if (status == 'Não Possui' ||
              status == 'Não' ||
              status == 'Inexistente' ||
              status == 'Não Tem') statusColor = naoPossuiColor;
          if (status == 'Está com Cliente')
            statusColor = PdfColor.fromInt(0xFFFFA500);

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: idx % 2 == 0 ? PdfColors.white : lightBg,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Text(itemLabel,
                    style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 10,
                        color: secondaryColor)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Text(
                  status.toUpperCase(),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 10, color: statusColor),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      pw.SizedBox(height: 15),
    ];
  }

  // Página 1: Relatório e Checklist
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (context) => _buildPdfFooter(context),
    header: (context) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Column(
          children: [
            if (logoImage != null)
              pw.Container(
                width: double.infinity,
                height: 120, // Limite de altura
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(logoImage == null ? 'LOGO' : '',
                    style: pw.TextStyle(font: fontBold, fontSize: 24)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('CHECKLIST VEICULAR',
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 18, color: primaryColor)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        'Data: ${vistoria.dataHora.day.toString().padLeft(2, '0')}/${vistoria.dataHora.month.toString().padLeft(2, '0')}/${vistoria.dataHora.year}',
                        style:
                            pw.TextStyle(fontSize: 10, color: secondaryColor)),
                    pw.Text('Laudo: ${vistoria.numeroLaudo}',
                        style:
                            pw.TextStyle(fontSize: 10, color: secondaryColor)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    },
    build: (context) {
      return [
        // Informações do Veículo
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: primaryColor, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DADOS DO VEÍCULO',
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 12, color: primaryColor)),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      child: pw.Text(
                          'PLACA: ${wizardState?.placa.isNotEmpty == true ? wizardState!.placa : (veiculo.placa ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                  pw.Expanded(
                      child: pw.Text(
                          'MARCA/MODELO: ${wizardState?.marca.isNotEmpty == true ? wizardState!.marca : (veiculo.marca ?? '')} ${wizardState?.modelo.isNotEmpty == true ? wizardState!.modelo : (veiculo.modelo ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                  pw.Expanded(
                      child: pw.Text(
                          'COR: ${wizardState?.cor.isNotEmpty == true ? wizardState!.cor : (veiculo.cor ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      child: pw.Text(
                          'CHASSI: ${wizardState?.chassiVeiculo.isNotEmpty == true ? wizardState!.chassiVeiculo : (veiculo.chassiVeiculo ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                  pw.Expanded(
                      child: pw.Text(
                          'RENAVAM: ${wizardState?.renavam.isNotEmpty == true ? wizardState!.renavam : (veiculo.renavam ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                  pw.Expanded(
                      child: pw.Text(
                          'KM: ${wizardState?.km.isNotEmpty == true ? wizardState!.km : (veiculo.km ?? '')}',
                          style: pw.TextStyle(font: fontBold, fontSize: 11))),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Medidas e Complementos (Caminhões)
        if (isPesado &&
            wizardState != null &&
            wizardState.medidasComplementos.values
                .any((v) => v.isNotEmpty)) ...[
          pw.Text('MEDIDAS E COMPLEMENTOS',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 12, color: primaryColor)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300)),
            child: pw.Wrap(
              spacing: 20,
              runSpacing: 8,
              children: wizardState.medidasComplementos.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((e) {
                return pw.SizedBox(
                  width: 200,
                  child: pw.Text('${_formatKey(e.key)}: ${e.value}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 20),
        ],

        // Listas de Checklist
        if (isDynamicChecklist)
          ...getChecklistCategories(tipoEnum).entries.expand((cat) {
            return buildItemCategory(cat.key, cat.value);
          }).toList()
        else ...[
          ...buildItemCategory(
              'Itens Externos e Equipamentos', _getItensVeiculo(isPesado)),
          ...buildItemCategory(
              isPesado ? 'Descrição Cabine' : 'Interior do Veículo',
              _getItensCabine(isPesado)),
          if (isPesado) ...buildItemCategory('Itens Carreta', _getItensCarreta()),
          if (isPesado) ...buildItemCategory('Baterias', _getBaterias()),
          ...buildItemCategory('Itens Escritório', _getItensEscritorio(isPesado)),
        ],

        pw.SizedBox(height: 30),

        // Assinaturas
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Column(
              children: [
                if (assinaturaImage != null)
                  pw.Container(
                    height: 50,
                    width: 150,
                    child: pw.Image(assinaturaImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 50),
                pw.Container(width: 200, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('VISTORIADOR: ${vistoria.vistoriadorNome ?? ''}',
                    style: pw.TextStyle(font: fontBold, fontSize: 10)),
              ],
            ),
            if (!isChecklist)
              pw.Column(
                children: [
                  if (assinaturaClienteImage != null)
                    pw.Container(
                      height: 50,
                      width: 150,
                      child: pw.Image(assinaturaClienteImage,
                          fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 50),
                  pw.Container(width: 200, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('CLIENTE: ${vistoria.clienteNome ?? ''}',
                      style: pw.TextStyle(font: fontBold, fontSize: 10)),
                ],
              ),
          ],
        ),
      ];
    },
  ));

  // Anexos (Fotos)
  if (wizardState != null) {
    final fotosComImagens = wizardState.fotosLocais.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (fotosComImagens.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => _buildPdfFooter(context),
    header: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('ANEXOS FOTOGRÁFICOS',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 16, color: primaryColor)),
          );
        },
        build: (context) {
          List<pw.Widget> photoWidgets = [];

          for (final entry in fotosComImagens) {
            final item = entry.key;
            for (final path in entry.value) {
              try {
                final file = File(path);
                if (file.existsSync()) {
                  final image = pw.MemoryImage(file.readAsBytesSync());
                  photoWidgets.add(
                    pw.Container(
                      width: 200,
                      margin: const pw.EdgeInsets.only(bottom: 15),
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 150,
                            width: 200,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey300),
                            ),
                            child: pw.Image(image, fit: pw.BoxFit.cover),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(item.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }
              } catch (_) {}
            }
          }

          if (photoWidgets.isEmpty) {
            photoWidgets.add(pw.Text(
                'Nenhuma foto encontrada para esta vistoria.',
                style: pw.TextStyle(color: PdfColors.grey)));
          }

          return [
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: photoWidgets,
            )
          ];
        },
      ));
    }
  }

  // Salvar o arquivo
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/checklist_${widgetId(vistoria)}.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    print('Erro ao gerar checklist PDF: $e');
    return null;
  }
}

String widgetId(Vistoria vistoria) => vistoria.id;

String _formatKey(String key) {
  switch (key) {
    case 'dataTrocaOleo':
      return 'Data Troca Óleo';
    case 'kmTrocaOleo':
      return 'KM Troca Óleo';
    case 'tipoTrocaMotor':
      return 'Troca Motor';
    case 'tipoTrocaCambio':
      return 'Troca Câmbio';
    case 'tipoTrocaDiferencial':
      return 'Troca Diferencial';
    case 'implementoDescricao':
      return 'Desc. Implemento';
    case 'implementoMarca':
      return 'Marca Implemento';
    case 'implementoEntreEixo':
      return 'Entre Eixos';
    case 'implementoComprimento':
      return 'Comprimento';
    case 'implementoLargura':
      return 'Largura';
    case 'implementoAltura':
      return 'Altura';
    default:
      return key;
  }
}

Map<String, String> _getItensVeiculo(bool isPesado) {
  if (isPesado) {
    return {
      'alternador': '3.1 Alternador',
      'macanetas_externas': '3.2 Maçanetas Externas',
      'espelho_retrovisor_d': '3.3 Espelho Retrovisor (D)',
      'espelho_retrovisor_e': '3.4 Espelho Retrovisor (E)',
      'lanternas': '3.5 Lanternas',
      'farol_baixo': '3.6 Farol Baixo',
      'farol_alto': '3.7 Farol Alto',
      'farol_milha': '3.8 Farol de Milha',
      'seta_direita': '3.9 Seta Direita',
      'seta_esquerda': '3.10 Seta Esquerda',
      'pisca_alerta': '3.11 Pisca Alerta',
      'arla': '3.12 Arla',
      'chave_tanque': '3.13 Chave do Tanque',
      'tampa_tanque': '3.14 Tampa do Tanque',
      'tanque_suplementar': '3.15 Tanque Suplementar',
      'rodo_ar': '3.16 Rodo Ar',
      'step': '3.17 Step',
      'placa_mercosul': '3.18 Placa Mercosul?',
      'luz_re': '3.19 Luz de Ré',
      'luz_freio': '3.20 Luz de Freio',
      'macaco': '3.21 Macaco',
      'triangulo': '3.22 Triângulo',
      'chave_roda': '3.23 Chave de Roda',
    };
  } else {
    return {
      'macanetas_externas': 'Maçanetas Externas',
      'espelho_retrovisor_d': 'Espelho Retrovisor (D)',
      'espelho_retrovisor_e': 'Espelho Retrovisor (E)',
      'lanternas_dianteiras': 'Lanternas Dianteiras',
      'lanternas_traseiras': 'Lanternas Traseiras',
      'farol_baixo': 'Farol Baixo',
      'farol_alto': 'Farol Alto',
      'farol_milha': 'Farol de Milha',
      'seta_direita': 'Seta Direita',
      'seta_esquerda': 'Seta Esquerda',
      'pisca_alerta': 'Pisca Alerta',
      'tampa_tanque': 'Tampa do Tanque',
      'step': 'Estepe',
      'placa_mercosul': 'Placa Mercosul?',
      'luz_re': 'Luz de Ré',
      'luz_freio': 'Luz de Freio',
      'macaco': 'Macaco',
      'triangulo': 'Triângulo',
      'chave_roda': 'Chave de Roda',
      'antena': 'Antena',
    };
  }
}

Map<String, String> _getItensCabine(bool isPesado) {
  if (isPesado) {
    return {
      'alarme_outros': '3.33 Alarme / Outros',
      'rastreador': '3.34 Rastreador',
      'travas_portas': '3.35 Travas Portas',
      'caixa_fusiveis': '3.36 Caixa Fusível',
      'comutador_chave': '3.37 Comutador Chave (Ignição)',
      'motor_arranque': '3.38 Motor de Arranque',
      'freio_motor': '3.39 Freio Motor',
      'luzes_painel': '3.40 Luzes do Painel',
      'luz_diagnostico': '3.41 Luz Diagnóstico',
      'conta_giros': '3.42 Conta Giros',
      'buzina_eletrica': '3.43 Buzina Elétrica',
      'buzina_pneumatica': '3.44 Buzina Pneumática',
      'para_brisas': '3.45 Para-brisas',
      'esguicho_agua': '3.46 Esguicho de Água do Para-brisa',
      'limpador_para_brisas': '3.47 Limpador do Para-brisa',
      'acendedor_eletrico': '3.48 Acendedor Elétrico',
      'piloto_automatico': '3.49 Piloto Automático',
      'som': '3.50 Som FM / MP3 / USB',
      'ar_condicionado': '3.51 Ar Condicionado',
      'ventilador': '3.52 Ventilador',
      'interclima': '3.53 Interclima',
      'vidro_eletrico': '3.54 Vidro Elétrico',
      'manivela_vidros': '3.55 Manivela Vidros',
      'macanetas_internas': '3.56 Maçanetas Internas',
      'tapecaria_bancos': '3.57 Tapeçaria Bancos',
      'tapecaria_cama': '3.58 Tapeçaria Cama',
      'cinto_motorista': '3.59 Cinto de Segurança Motorista',
      'cinto_passageiro': '3.60 Cinto de Segurança Passageiro',
    };
  } else {
    return {
      'alarme_outros': 'Alarme / Outros',
      'travas_portas': 'Travas Portas',
      'comutador_chave': 'Comutador Chave (Ignição)',
      'motor_arranque': 'Motor de Arranque',
      'luzes_painel': 'Luzes do Painel',
      'luz_diagnostico': 'Luz Diagnóstico',
      'conta_giros': 'Conta Giros',
      'buzina': 'Buzina',
      'para_brisas': 'Para-Brisas',
      'esguicho_agua': 'Esguicho de Água',
      'limpador_dianteiro': 'Limpador Dianteiro',
      'limpador_traseiro': 'Limpador Traseiro',
      'acendedor_eletrico': 'Acendedor Elétrico / 12V',
      'som': 'Som / Multimídia',
      'ar_condicionado': 'Ar Condicionado',
      'ventilador': 'Ventilador',
      'vidro_eletrico': 'Vidro Elétrico',
      'manivela_vidros': 'Manivela Vidros',
      'macanetas_internas': 'Maçanetas Internas',
      'tapecaria_bancos': 'Tapeçaria Bancos',
      'tapecaria_teto': 'Tapeçaria Teto',
      'cinto_dianteiro': 'Cinto Segurança Dianteiros',
      'cinto_traseiro': 'Cinto Segurança Traseiros',
      'luz_interna': 'Luz Interna',
      'retrovisor_interno': 'Retrovisor Interno',
      'quebra_sol_d': 'Quebra Sol (D)',
      'quebra_sol_e': 'Quebra Sol (E)',
    };
  }
}

Map<String, String> _getItensCarreta() {
  return {
    'tomada_forca': '3.24 Tomada de Força',
    'lanternas_carreta': '3.25 Lanternas',
    'seta_direita_carreta': '3.26 Seta Direita',
    'seta_esquerda_carreta': '3.27 Seta Esquerda',
    'pisca_alerta_carreta': '3.28 Pisca Alerta',
    'luz_re_carreta': '3.29 Luz de Ré',
    'luz_freio_carreta': '3.30 Luz de Freio',
    'pistao_1': '3.31 Pistão Hidráulico 1',
    'pistao_2': '3.32 Pistão Hidráulico 2',
  };
}

Map<String, String> _getBaterias() {
  return {
    'bateria_a': '(A) Bateria',
    'bateria_b': '(B) Bateria',
  };
}

Map<String, String> _getItensEscritorio(bool isPesado) {
  return {
    'doc_rodar': 'Documento CRLV',
    'doc_recibo': 'Documento Recibo',
    'manual': 'Manual',
    'chave_reserva': 'Chave Reserva',
  };
}
