import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/app_database.dart';
import '../../features/vistoria/domain/vistoria_wizard_state.dart';

// ── Paleta PDF ──────────────────────────────────────────────────────────────
const _kBlack = PdfColor.fromInt(0xFF222222);
const _kWhite = PdfColors.white;
const _kGreyLight = PdfColor.fromInt(0xFFF5F5F5);
const _kGreyDark = PdfColor.fromInt(0xFF666666);
const _kGreen = PdfColor.fromInt(0xFF8BC34A);
const _kOrange = PdfColor.fromInt(0xFFFFCA28);
const _kRed = PdfColor.fromInt(0xFFEF5350);

class PdfGeneratorService {
  Future<File> generateLaudoPdf({
    required Vistoria vistoria,
    required Veiculo veiculo,
    required Map<String, String> uploadedPhotos,
    required Map<String, String> ocrResults,
  }) async {
    return generateLaudoCompleto(
      vistoria: vistoria,
      veiculo: veiculo,
    ) as Future<File>;
  }

  Future<String?> generateLaudoCompleto({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? wizardState,
  }) async {
    final pdf = pw.Document(
      title: 'Laudo Cautelar - ${veiculo.placa}',
      author: vistoria.vistoriadorNome ?? 'UltraVisão',
    );

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final styles = _PdfStyles(regular: fontRegular, bold: fontBold);

    // Carregar logo se existir (senão usa placeholder)
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/app_icon.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pw.ImageProvider? carroEstruturaImage;
    pw.ImageProvider? caminhaoEstruturaImage;
    try {
      final bytes = await rootBundle.load('assets/images/carro_estrutura.png');
      carroEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final bytes = await rootBundle.load('assets/images/caminhao_estrutura.png');
      caminhaoEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
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

    // Página 1 — Dados Gerais
    pdf.addPage(await _buildPage1(vistoria: vistoria, veiculo: veiculo, state: wizardState, styles: styles, logo: logoImage, assinatura: assinaturaImage));

    final temCroqui = vistoria.tipoVistoria?.toLowerCase().contains('cautelar') ?? false;
    final isCaminhao = vistoria.tipoVistoria?.toLowerCase().contains('caminh') ?? false;
    final bgImage = isCaminhao ? caminhaoEstruturaImage : carroEstruturaImage;

    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    final orderedFotoIds = [
      'foto_placa',
      'frente_esquerda',
      'frente_direita',
      'traseira_esquerda',
      'traseira_direita',
      'vidro_para_brisa',
      'vidro_traseiro',
      'vidro_lateral_direito',
      'vidro_lateral_esquerdo',
      if (wizardState != null) ...wizardState.vidrosExtrasIds,
      'painel_hodometro',
      'compartimento_motor',
      'motor_gravacao',
      'cambio_gravacao',
      'etiqueta_vis_motor',
      'etiqueta_vis_porta',
      'chassi_gravacao',
    ];

    if (temCroqui) {
      orderedFotoIds.addAll([
        'longarina_dianteira_esquerda',
        'longarina_dianteira_direita',
        'longarina_centro_esquerda',
        'longarina_centro_direita',
        'longarina_traseira_esquerda',
        'longarina_traseira_direita',
        'peca_capo_dianteiro',
        'peca_paralama_dianteiro_esquerdo',
        'peca_porta_dianteira_esquerda',
        'peca_porta_traseira_esquerda',
        'peca_lateral_traseira_esquerda',
        'peca_tampa_traseira',
        'peca_teto',
        'peca_lateral_traseira_direita',
        'peca_porta_traseira_direita',
        'peca_porta_dianteira_direita',
        'peca_paralama_dianteiro_direito',
      ]);
    }

    // Montar a lista completa de fotos (principais + extras)
    final todasFotos = <Map<String, dynamic>>[];
    if (wizardState != null) {
      for (final id in orderedFotoIds) {
        final locals = wizardState.getFotosLocais(id);
        // O usuário pediu "múltiplas fotos por avaria" e itens normais também
        // Então pegamos TODAS as fotos salvas para aquele ID, não só a primeira.
        for (final localPath in locals) {
          final f = File(localPath);
          if (f.existsSync()) {
            todasFotos.add({
              'path': localPath,
              'label': id.replaceAll('_', ' ').toUpperCase(),
            });
          }
        }
      }
      
      // Adicionar Fotos Extras (T2)
      for (final extra in wizardState.fotosExtras) {
        final path = extra['pathLocal'] as String?;
        final titulo = extra['titulo'] as String? ?? 'FOTO EXTRA';
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            todasFotos.add({
              'path': path,
              'label': titulo.toUpperCase(),
            });
          }
        }
      }
    }

    // Dividir em chunks de 15 fotos por página (3x5)
    final chunkSize = 15;
    if (todasFotos.isEmpty) {
      pdf.addPage(_buildPageFotosGrid(
        titulo: 'FOTOS DA VISTORIA',
        fotos: [],
        vistoria: vistoria,
        styles: styles,
        logo: logoImage,
        assinatura: assinaturaImage,
      ));
    } else {
      for (var i = 0; i < todasFotos.length; i += chunkSize) {
        final end = (i + chunkSize < todasFotos.length) ? i + chunkSize : todasFotos.length;
        final chunk = todasFotos.sublist(i, end);
        pdf.addPage(_buildPageFotosGrid(
          titulo: i == 0 ? 'FOTOS PRINCIPAIS' : 'FOTOS PRINCIPAIS (CONT.)',
          fotos: chunk,
          vistoria: vistoria,
          styles: styles,
          logo: logoImage,
          assinatura: assinaturaImage,
        ));
      }
    }

    if (temCroqui) {
      // Página 4 — Análise Estrutural (Tabela até ter o Croqui)
      pdf.addPage(_buildPageAnalise(
        titulo: 'ANÁLISE ESTRUTURAL',
        itens: const [
          'longarina_dianteira_direita', 'longarina_dianteira_esquerda',
          'longarina_centro_direita', 'longarina_centro_esquerda',
          'longarina_traseira_direita', 'longarina_traseira_esquerda',
          'painel_frontal', 'painel_traseiro', 'assoalho', 'caixa_roda',
        ],
        labels: const {
          'longarina_dianteira_direita': 'Longarina Dianteira Direita',
          'longarina_dianteira_esquerda': 'Longarina Dianteira Esquerda',
          'longarina_centro_direita': 'Longarina Centro Direita',
          'longarina_centro_esquerda': 'Longarina Centro Esquerda',
          'longarina_traseira_direita': 'Longarina Traseira Direita',
          'longarina_traseira_esquerda': 'Longarina Traseira Esquerda',
          'painel_frontal': 'Painel Frontal',
          'painel_traseiro': 'Painel Traseiro',
          'assoalho': 'Assoalho',
          'caixa_roda': 'Caixa de Roda',
        },
        state: wizardState, vistoria: vistoria, styles: styles, logo: logoImage, backgroundImage: bgImage, assinatura: assinaturaImage,
      ));

      // Página 5 — Análise de Pintura (Tabela até ter o Croqui)
      pdf.addPage(_buildPageAnalise(
        titulo: 'ANÁLISE DE PINTURA',
        itens: const [
          'peca_capo_dianteiro', 'peca_paralama_dianteiro_direito',
          'peca_paralama_dianteiro_esquerdo', 'peca_porta_dianteira_direita',
          'peca_porta_dianteira_esquerda', 'peca_porta_traseira_direita',
          'peca_porta_traseira_esquerda', 'peca_lateral_traseira_direita',
          'peca_lateral_traseira_esquerda', 'peca_teto', 'peca_tampa_traseira',
        ],
        labels: const {
          'peca_capo_dianteiro': 'Capô Dianteiro',
          'peca_paralama_dianteiro_direito': 'Para-lama Dianteiro Direito',
          'peca_paralama_dianteiro_esquerdo': 'Para-lama Dianteiro Esquerdo',
          'peca_porta_dianteira_direita': 'Porta Dianteira Direita',
          'peca_porta_dianteira_esquerda': 'Porta Dianteira Esquerda',
          'peca_porta_traseira_direita': 'Porta Traseira Direita',
          'peca_porta_traseira_esquerda': 'Porta Traseira Esquerda',
          'peca_lateral_traseira_direita': 'Lateral Traseira Direita',
          'peca_lateral_traseira_esquerda': 'Lateral Traseira Esquerda',
          'peca_teto': 'Teto',
          'peca_tampa_traseira': 'Tampa Traseira',
        },
        isPintura: true, state: wizardState, vistoria: vistoria, styles: styles, logo: logoImage, assinatura: assinaturaImage,
      ));
    }

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laudo_${vistoria.numeroLaudo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file.path;
  }

  // ── Seções Compartilhadas ────────────────────────────────────────────────

  pw.Widget _buildHeader(Vistoria vistoria, _PdfStyles styles, pw.ImageProvider? logo) {
    final statusFinal = vistoria.statusFinal ?? 'CONFORME';
    final isConforme = statusFinal.toUpperCase() == 'CONFORME';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          pw.Container(
            width: 70, height: 70,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _kGreyLight,
            ),
            child: logo != null 
                ? pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover))
                : pw.Center(child: pw.Text('Logo', style: pw.TextStyle(color: _kGreyDark, fontSize: 10))),
          ),
          pw.SizedBox(width: 20),
          // Numero do Laudo
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Número do Laudo:', style: pw.TextStyle(font: styles.bold, fontSize: 10)),
                pw.Text(vistoria.numeroLaudo, style: pw.TextStyle(font: styles.bold, fontSize: 11, color: _kRed)),
              ],
            ),
          ),
          // Status Pill
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: isConforme ? _kGreen : _kRed,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Row(
              children: [
                // Car icon placeholder using text for now, or just empty
                pw.Text('🚗 ', style: pw.TextStyle(fontSize: 12)),
                pw.Text(statusFinal.toUpperCase(), style: pw.TextStyle(font: styles.bold, fontSize: 12, color: _kWhite)),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          // QR Code
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: 'https://vistorias.com.br/laudo/${vistoria.numeroLaudo}',
            width: 50, height: 50,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBlackBar(String text, _PdfStyles styles) {
    return pw.Container(
      width: double.infinity,
      color: _kBlack,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kWhite)),
    );
  }

  pw.Widget _buildFooter(Vistoria vistoria, _PdfStyles styles, pw.Context ctx, pw.ImageProvider? assinatura) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  if (assinatura != null)
                    pw.Container(
                      height: 30,
                      child: pw.Image(assinatura, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 30),
                  pw.Container(width: 150, height: 1, color: _kBlack),
                  pw.SizedBox(height: 4),
                  pw.Text(vistoria.vistoriadorNome?.toUpperCase() ?? 'ANALISTA', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('CPF: ${_maskCpf(vistoria.vistoriadorCpf)}', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('Analista', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                ],
              ),
              pw.Column(
                children: [
                  if (assinatura != null)
                    pw.Container(
                      height: 30,
                      child: pw.Image(assinatura, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 30),
                  pw.Container(width: 150, height: 1, color: _kBlack),
                  pw.SizedBox(height: 4),
                  pw.Text(vistoria.vistoriadorNome?.toUpperCase() ?? 'EXAMINADOR', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('CPF: ${_maskCpf(vistoria.vistoriadorCpf)}', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('Examinador', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Isenção informada: declaro ter recebido a segunda via e EXAME VISTORIA VEICULAR... [Texto de isenção placeholder]... Qualquer dúvida estamos à disposição.',
            style: pw.TextStyle(font: styles.regular, fontSize: 5, color: _kGreyDark),
            textAlign: pw.TextAlign.justify,
          ),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
            height: 1, color: _kBlack,
          ),
          pw.Text('NULL', style: pw.TextStyle(font: styles.regular, fontSize: 6, color: _kGreyDark)),
        ],
      ),
    );
  }

  // ── Página 1 ─────────────────────────────────────────────────────────────

  Future<pw.Page> _buildPage1({
    required Vistoria vistoria,
    required Veiculo veiculo,
    required VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
  }) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo),
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            
            // Dados Gerais
            _buildBlackBar('DADOS GERAIS:', styles),
            pw.Table(
              border: pw.TableBorder.all(color: _kBlack, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _kGreyLight),
                  children: [
                    _th('DATA:', styles), _td(_formatDate(vistoria.dataHora), styles),
                    _th('STATUS:', styles), _td(vistoria.statusFinal ?? 'CONFORME', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('CLIENTE:', styles), _td(vistoria.clienteNome ?? 'NÃO INFORMADO', styles),
                    _th('Nº DO LAUDO:', styles), _td(vistoria.numeroLaudo, styles),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _kGreyLight),
                  children: [
                    _th('UNIDADE:', styles), _td(vistoria.unidade ?? 'NÃO INFORMADA', styles),
                    _th('VISTORIADOR:', styles), _td(vistoria.vistoriadorNome ?? 'NÃO INFORMADO', styles),
                  ],
                ),
              ]
            ),
            pw.SizedBox(height: 6),

            // Dados do Veículo
            _buildBlackBar('DADOS DO VEÍCULO:', styles),
            pw.Table(
              border: pw.TableBorder.all(color: _kBlack, width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    _th('FABRICANTE/MARCA:', styles, dark: true), _td(veiculo.marca ?? 'NÃO INFORMADO', styles),
                    _th('MODELO/VERSÃO:', styles, dark: true), _td(veiculo.modelo ?? 'NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('ANO FAB/MODELO:', styles, dark: true), _td('${veiculo.anoFabricacao ?? ""}/${veiculo.anoModelo ?? ""}', styles),
                    _th('COR:', styles, dark: true), _td(veiculo.cor ?? 'NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('PLACA:', styles, dark: true), _td(veiculo.placa, styles),
                    _th('CIDADE/UF:', styles, dark: true), _td(veiculo.municipio ?? 'NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('Nº DO CHASSI NO VEÍC.:', styles, dark: true), _td(veiculo.chassiVeiculo ?? 'NÃO INFORMADO', styles),
                    _th('Nº DO MOTOR NO VEÍC.:', styles, dark: true), _td(veiculo.motorVeiculo ?? 'NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('Nº DO CHASSI NA BIN:', styles, dark: true), _td(veiculo.chassiBin ?? 'NÃO INFORMADO', styles),
                    _th('Nº DO MOTOR NA BIN:', styles, dark: true), _td(veiculo.motorBin ?? 'NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('Nº DO RENAVAM:', styles, dark: true), _td(veiculo.renavam ?? 'NÃO INFORMADO', styles),
                    _th('Nº DO CRV:', styles, dark: true), _td('NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('Nº DO CÂMBIO NO VEÍC.:', styles, dark: true), _td(veiculo.cambioVeiculo ?? 'NÃO INFORMADO', styles),
                    _th('COMBUSTÍVEL:', styles, dark: true), _td('NÃO INFORMADO', styles),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _th('Nº DO CÂMBIO NA BIN:', styles, dark: true), _td('NÃO INFORMADO', styles),
                    _th('KM:', styles, dark: true), _td(veiculo.km?.toString() ?? 'NÃO INFORMADO', styles),
                  ],
                ),
              ]
            ),
            pw.SizedBox(height: 6),

            // Itens Analisados (2 colunas)
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _buildChecklistCol(state, styles, 1)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: _buildChecklistCol(state, styles, 2)),
                ],
              ),
            ),

            // Observações
            _buildBlackBar('OBSERVAÇÕES DO VEÍCULO:', styles),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _kBlack, width: 0.5)),
              child: pw.Text(state?.observacoesVeiculo.isEmpty == true ? 'NENHUMA OBSERVAÇÃO' : (state?.observacoesVeiculo ?? 'NENHUMA OBSERVAÇÃO'), style: pw.TextStyle(font: styles.regular, fontSize: 8)),
            ),
            pw.SizedBox(height: 6),

            _buildBlackBar('DESCRIÇÃO DO TIPO DE VISTORIA:', styles),
            pw.Text('VISTORIA CAUTELAR AUTOMOTIVA', style: pw.TextStyle(font: styles.bold, fontSize: 7)),
            pw.SizedBox(height: 10),

            _buildFooter(vistoria, styles, ctx, assinatura),
          ],
        );
      },
    );
  }

  pw.Widget _th(String text, _PdfStyles styles, {bool dark = false}) {
    return pw.Container(
      color: dark ? _kGreyDark : null,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(font: styles.bold, fontSize: 7, color: dark ? _kWhite : _kBlack)),
    );
  }

  pw.Widget _td(String text, _PdfStyles styles) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(font: styles.regular, fontSize: 7, color: _kBlack)),
    );
  }

  pw.Widget _buildChecklistCol(VistoriaWizardState? state, _PdfStyles styles, int colIndex) {
    final itens = [
      'compartimento_motor', 'etiqueta_vis_motor',
      'etiqueta_vis_porta', 'frente_direita',
      'frente_esquerda', 'chassi_gravacao',
      'motor_gravacao', 'vidro_dianteiro_direito',
      'vidro_dianteiro_esquerdo', 'vidro_frontal',
      'vidro_traseiro', 'vidro_traseiro_direito',
      'vidro_traseiro_esquerdo', 'painel_hodometro',
      'placa_dianteira', 'traseira_direita',
      'traseira_esquerda'
    ];
    
    final labels = {
      'compartimento_motor': 'COMPARTIMENTO DO MOTOR',
      'etiqueta_vis_motor': 'ETIQUETA VIS COMPARTIMENTO MOTOR',
      'etiqueta_vis_porta': 'ETIQUETA VIS PORTA',
      'frente_direita': 'FRENTE DIREITA',
      'frente_esquerda': 'FRENTE ESQUERDA',
      'chassi_gravacao': 'GRAVAÇÃO DO CHASSI',
      'motor_gravacao': 'GRAVAÇÃO DO MOTOR',
      'vidro_dianteiro_direito': 'GRAVAÇÃO Nº VIDRO DIANTEIRO DIREITO',
      'vidro_dianteiro_esquerdo': 'GRAVAÇÃO Nº VIDRO DIANTEIRO ESQUERDO',
      'vidro_frontal': 'GRAVAÇÃO Nº VIDRO FRONTAL',
      'vidro_traseiro': 'GRAVAÇÃO Nº VIDRO TRASEIRO',
      'vidro_traseiro_direito': 'GRAVAÇÃO Nº VIDRO TRASEIRO DIREITO',
      'vidro_traseiro_esquerdo': 'GRAVAÇÃO Nº VIDRO TRASEIRO ESQUERDO',
      'painel_hodometro': 'PAINEL E HODÔMETRO',
      'placa_dianteira': 'PLACA',
      'traseira_direita': 'TRASEIRA DIREITA',
      'traseira_esquerda': 'TRASEIRA ESQUERDA'
    };

    final half = (itens.length / 2).ceil();
    final colItems = colIndex == 1 ? itens.sublist(0, half) : itens.sublist(half);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(colItems.length, (i) {
        final id = colItems[i];
        final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
        final isConforme = status.toUpperCase().contains('CONFORME') || status.toUpperCase().contains('ORIGINAL') || status.toUpperCase().contains('PADRÕES');
        final color = isConforme ? _kGreen : (status == 'NÃO ANALISADO' ? _kGreyDark : _kRed);

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _kGreyLight, width: 1))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(child: pw.Text(labels[id]!, style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kBlack))),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor(color.red, color.green, color.blue, 0.1),
                  borderRadius: pw.BorderRadius.circular(2),
                  border: pw.Border.all(color: color, width: 0.5),
                ),
                child: pw.Text(status.toUpperCase(), style: pw.TextStyle(font: styles.bold, fontSize: 5, color: color)),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Páginas de Fotos ─────────────────────────────────────────────────────

  pw.Page _buildPageFotosGrid({
    required String titulo,
    required List<Map<String, dynamic>> fotos,
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo),
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            
            pw.SizedBox(height: 8),
            if (fotos.isEmpty)
              pw.Center(child: pw.Text('Nenhuma foto capturada.', style: pw.TextStyle(color: _kGreyDark, fontSize: 10)))
            else
              pw.Expanded(
                child: pw.GridView(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: fotos.map((f) {
                    try {
                      final bytes = File(f['path']).readAsBytesSync();
                      final img = pw.MemoryImage(bytes);
                      return pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                          color: _kWhite,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Expanded(
                              child: pw.ClipRRect(
                                horizontalRadius: 4, verticalRadius: 4,
                                child: pw.Image(img, fit: pw.BoxFit.cover),
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4),
                              child: pw.Text(
                                f['label'],
                                style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kBlack),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    } catch (_) {
                      return pw.Container();
                    }
                  }).toList(),
                ),
              ),
            
            _buildFooter(vistoria, styles, ctx, assinatura),
          ],
        );
      },
    );
  }

  // ── Página de Análise (Estrutura / Pintura - Fallback) ───────────────────

  pw.Page _buildPageAnalise({
    required String titulo,
    required List<String> itens,
    required Map<String, String> labels,
    required VistoriaWizardState? state,
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? backgroundImage,
    pw.ImageProvider? assinatura,
    bool isPintura = false,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo),
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar(titulo, styles),
            
            pw.SizedBox(height: 8),
            
            // Se for Análise Estrutural e tivermos a imagem, usar o diagrama visual
            if (!isPintura && backgroundImage != null)
              pw.Expanded(
                child: _buildDiagramaEstrutural(backgroundImage, state, styles),
              )
            else
              // Tabela provisória
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _kGreyLight),
                      children: [
                        _th('ITEM', styles), _th('STATUS', styles), _th('OBSERVAÇÃO', styles),
                      ],
                    ),
                    ...itens.map((id) {
                      final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                      final obs = state?.getObs(id) ?? '';
                      return pw.TableRow(
                        children: [
                          _td(labels[id] ?? id, styles),
                          _td(status.toUpperCase(), styles),
                          _td(obs, styles),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            
            _buildFooter(vistoria, styles, ctx, assinatura),
          ],
        );
      },
    );
  }

  pw.Widget _buildDiagramaEstrutural(pw.ImageProvider backgroundImage, VistoriaWizardState? state, _PdfStyles styles) {
    return pw.Center(
      child: pw.Stack(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 15, bottom: 35),
            child: pw.Image(backgroundImage, fit: pw.BoxFit.contain),
          ),
          pw.Positioned(
            top: 35, left: 5,
            child: _buildCaixaStatus('LONGARINA DIANTEIRA DIREITA', state?.getStatus('longarina_dianteira_direita') ?? 'NÃO ANALISADO', styles),
          ),
          pw.Positioned(
            top: 15, left: 200,
            child: _buildCaixaStatus('LONGARINA CENTRO DIREITA', state?.getStatus('longarina_centro_direita') ?? 'NÃO ANALISADO', styles),
          ),
          pw.Positioned(
            top: 25, right: 40,
            child: _buildCaixaStatus('LONGARINA TRASEIRA DIREITA', state?.getStatus('longarina_traseira_direita') ?? 'NÃO ANALISADO', styles),
          ),
          pw.Positioned(
            bottom: 55, left: 20,
            child: _buildCaixaStatus('LONGARINA DIANTEIRA ESQUERDA', state?.getStatus('longarina_dianteira_esquerda') ?? 'NÃO ANALISADO', styles),
          ),
          pw.Positioned(
            bottom: 50, left: 205,
            child: _buildCaixaStatus('LONGARINA CENTRO ESQUERDA', state?.getStatus('longarina_centro_esquerda') ?? 'NÃO ANALISADO', styles),
          ),
          pw.Positioned(
            bottom: 45, right: 30,
            child: _buildCaixaStatus('LONGARINA TRASEIRA ESQUERDA', state?.getStatus('longarina_traseira_esquerda') ?? 'NÃO ANALISADO', styles),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCaixaStatus(String titulo, String status, _PdfStyles styles) {
    status = status.toUpperCase();
    PdfColor color = _kGreyDark;
    
    // Simplificando verificação de status
    if (status.contains('CONFORME') || status.contains('SEM REPARO')) {
      color = _kGreen;
    } else if (status.contains('OBSERVAÇÕES') || status.contains('COM REPARO')) {
      color = _kOrange;
    } else if (status.contains('NÃO CONFORME') || status.contains('REPROVADO')) {
      color = _kRed;
    }

    return pw.Container(
      width: 120,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(4),
        color: _kWhite,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(2.5), topRight: pw.Radius.circular(2.5)),
            ),
            child: pw.Text(titulo, style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kWhite), textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 8, height: 8,
                  decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color),
                  child: pw.Center(
                    child: pw.Text(
                      color == _kGreen ? '✓' : (color == _kRed ? '✗' : '!'),
                      style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kWhite),
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(status, style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kBlack)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _maskCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return 'Não informado';
    final raw = cpf.replaceAll(RegExp(r'\D'), '');
    if (raw.length != 11) return cpf;
    return '***.${raw.substring(3, 6)}.${raw.substring(6, 9)}-**';
  }
}

class _PdfStyles {
  final pw.Font regular;
  final pw.Font bold;
  const _PdfStyles({required this.regular, required this.bold});
}
