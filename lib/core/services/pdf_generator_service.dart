import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/app_database.dart';
import '../../features/vistoria/domain/vistoria_type.dart';
import '../../features/vistoria/domain/vistoria_wizard_state.dart';
import '../../injection_container.dart';
import '../../database/daos/autocred_dao.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pdf_radar_generator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  Future<String?> _obterUfPorGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      Position? position = await Geolocator.getLastKnownPosition();
      
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }
      
      final geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea;
      }
    } catch (e) {
      print('Erro ao obter GPS para UF: $e');
    }
    return null;
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
      final logoBytes = await rootBundle.load('assets/images/logo.pdf.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pw.ImageProvider? marcaImage;
    try {
      final marcaBytes = await rootBundle.load('assets/images/marca.png');
      marcaImage = pw.MemoryImage(marcaBytes.buffer.asUint8List());
    } catch (_) {}

    pw.ImageProvider? carroEstruturaImage;
    pw.ImageProvider? caminhaoEstruturaImage;
    pw.ImageProvider? carroPinturaImage;
    try {
      final bytes = await rootBundle.load('assets/images/carro_estrutura.png');
      carroEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final bytes = await rootBundle.load('assets/images/caminhao_estrutura.png');
      caminhaoEstruturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    try {
      final bytes = await rootBundle.load('assets/images/carro_pintura.png');
      carroPinturaImage = pw.MemoryImage(bytes.buffer.asUint8List());
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

    // Página 1 — Dados Gerais
    pdf.addPage(await _buildPage1Modern(vistoria: vistoria, veiculo: veiculo, state: wizardState, styles: styles, logo: logoImage, assinatura: assinaturaImage, assinaturaCliente: assinaturaClienteImage, marcaAgua: marcaImage));

    final tipoEnum = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
    final isCaminhao = tipoEnum == TipoVistoria.cautelarCaminhao;
    final temCroqui = tipoEnum != TipoVistoria.cautelarCaminhao;
    final temAvarias = tipoEnum == TipoVistoria.carroComCroqui;
    final bgImage = isCaminhao ? caminhaoEstruturaImage : carroEstruturaImage;

    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    final Map<String, List<String>> secoesFotos = {
      'FOTOS PRINCIPAIS - IDENTIFICAÇÃO': [
        'chassi_gravacao',
        'motor_gravacao',
        'frente_esquerda',
        'frente_direita',
        'traseira_esquerda',
        'traseira_direita',
      ],
      'FOTOS PRINCIPAIS - VIDROS': [
        'vidro_frontal',
        if (wizardState?.getStatus('vidro_traseiro').toUpperCase() != 'INEXISTENTE') 'vidro_traseiro',
        'vidro_dianteiro_direito',
        'vidro_dianteiro_esquerdo',
        if (!isCaminhao) 'vidro_traseiro_direito',
        if (!isCaminhao) 'vidro_traseiro_esquerdo',
        if (isCaminhao) 'plaqueta_da_cabine',
        if (isCaminhao) 'Plaqueta da cabine',
        if (wizardState != null) ...wizardState.vidrosExtrasIds,
      ],
      'FOTOS PRINCIPAIS - MOTOR / CHASSI': [
        if (!isCaminhao) 'painel_hodometro',
        if (!isCaminhao) 'compartimento_motor',
        'cambio_gravacao',
        if (!isCaminhao) 'etiqueta_vis_motor',
        if (!isCaminhao) 'etiqueta_vis_porta',
      ],
      if (temCroqui && !isCaminhao) 'FOTOS - ESTRUTURAL': [
        'painel_frontal',
        'painel_corta_fogo',
        'torre_amortecedor_esquerda',
        'longarina_dianteira_esquerda',
        'caixa_roda_dianteira_esquerda',
        'coluna_dianteira_esquerda',
        'caixa_ar_esquerda',
        'assoalho_esquerdo',
        'coluna_central_esquerda',
        'longarina_centro_esquerda',
        'coluna_traseira_esquerda',
        'caixa_roda_traseira_esquerda',
        'longarina_traseira_esquerda',
        'painel_traseiro',
        'caixa_estepe',
        'longarina_traseira_direita',
        'caixa_roda_traseira_direita',
        'coluna_traseira_direita',
        'longarina_centro_direita',
        'coluna_central_direita',
        'assoalho_direito',
        'caixa_ar_direita',
        'coluna_dianteira_direita',
        'caixa_roda_dianteira_direita',
        'longarina_dianteira_direita',
        'torre_amortecedor_direita',
      ],
      if (temAvarias && !isCaminhao) 'FOTOS - PINTURA': [
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
      ],
    };

    bool hasAnyPhoto = false;

    if (wizardState != null) {
      final allSections = <Map<String, dynamic>>[];
      
      for (final entry in secoesFotos.entries) {
        final tituloSecao = entry.key;
        final orderedFotoIds = entry.value;

        final fotosSecao = <Map<String, dynamic>>[];
        for (final id in orderedFotoIds) {
          final locals = wizardState.getFotosLocais(id);
          for (final localPath in locals) {
            final f = File(localPath);
            if (f.existsSync()) {
              var label = id.toUpperCase();
              if (label.startsWith('PECA_') || label.startsWith('PEÇA_')) {
                label = label.replaceFirst(RegExp(r'^PE[CÇ]A_'), '');
              }
              label = label.replaceAll('_', ' ');

              fotosSecao.add({
                'path': localPath,
                'label': label,
              });
            }
          }
        }
        if (fotosSecao.isNotEmpty) {
           allSections.add({
             'titulo': tituloSecao,
             'fotos': fotosSecao,
           });
           hasAnyPhoto = true;
        }
      }

      // Adicionar Fotos Extras
      final fotosExtrasList = <Map<String, dynamic>>[];
      for (final extra in wizardState.fotosExtras) {
        final path = extra['pathLocal'] as String?;
        final titulo = extra['titulo'] as String? ?? 'FOTO EXTRA';
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (f.existsSync()) {
            fotosExtrasList.add({
              'path': path,
              'label': titulo.toUpperCase(),
            });
          }
        }
      }
      if (fotosExtrasList.isNotEmpty) {
         allSections.add({
           'titulo': 'FOTOS EXTRAS',
           'fotos': fotosExtrasList,
         });
         hasAnyPhoto = true;
      }
      
      if (hasAnyPhoto) {
        final limeGreen = PdfColor.fromHex('8CC63F');
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            header: (ctx) => pw.Column(
              children: [
                _buildHeader(vistoria, styles, logoImage, state: wizardState),
                pw.SizedBox(height: 8),
              ]
            ),
            build: (ctx) {
              final widgets = <pw.Widget>[];

              // CLIENT INFO HEADER on first page
              widgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('DADOS DO CLIENTE', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: limeGreen)),
                            pw.SizedBox(height: 4),
                            _buildKvSmall('CLIENTE:', vistoria.clienteNome ?? '-', styles),
                            _buildKvSmall('E-MAIL:', '-', styles),
                            _buildKvSmall('CPF:', '-', styles),
                            _buildKvSmall('TELEFONE:', '-', styles),
                          ]
                        )
                      )
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('DADOS DO VEICULO (DENATRAN)', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: limeGreen)),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      _buildKvSmall('Nº CHASSI:', veiculo.chassiVeiculo ?? '-', styles),
                                      _buildKvSmall('Nº MOTOR:', veiculo.motorVeiculo ?? '-', styles),
                                      _buildKvSmall('PLACA:', veiculo.placa ?? '-', styles),
                                      _buildKvSmall('MARCA:', veiculo.marca ?? '-', styles),
                                      _buildKvSmall('MODELO:', veiculo.modelo ?? '-', styles),
                                    ]
                                  )
                                ),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      _buildKvSmall('COR:', veiculo.cor ?? '-', styles),
                                      _buildKvSmall('COMBUSTÍVEL:', veiculo.combustivel ?? '-', styles),
                                      _buildKvSmall('ANO FABRICAÇÃO:', veiculo.anoFabricacao?.toString() ?? '-', styles),
                                      _buildKvSmall('ANO MODELO:', veiculo.anoModelo?.toString() ?? '-', styles),
                                      _buildKvSmall('SITUAÇÃO CHASSI:', 'CIRCULAÇÃO', styles),
                                    ]
                                  )
                                ),
                              ]
                            )
                          ]
                        )
                      )
                    ),
                  ],
                )
              );
              widgets.add(pw.SizedBox(height: 10));

              pw.Widget buildPhotoItem(Map<String, dynamic> f) {
                final label = (f['label'] as String? ?? '').toUpperCase();
                pw.Widget imageWidget;
                
                try {
                  final pathStr = f['path'] as String? ?? '';
                  if (f['base64'] != null && (f['base64'] as String).isNotEmpty) {
                    final bytes = base64Decode(f['base64'] as String);
                    imageWidget = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                  } else if (pathStr.isNotEmpty && File(pathStr).existsSync()) {
                    final bytes = File(pathStr).readAsBytesSync();
                    imageWidget = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                  } else if (logoImage != null) {
                    imageWidget = pw.Center(
                      child: pw.Opacity(
                        opacity: 0.2,
                        child: pw.Container(width: 120, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
                      ),
                    );
                  } else {
                    imageWidget = pw.Center(
                      child: pw.Text('Sem foto', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    );
                  }
                } catch (e) {
                  imageWidget = pw.Center(
                    child: pw.Text('Sem foto', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  );
                }

                return pw.Container(
                  width: 270.0,
                  height: 180.0,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    color: PdfColors.white,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: imageWidget,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          label, 
                          style: pw.TextStyle(font: styles.bold, fontSize: 6, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }

              for (final section in allSections) {
                final titulo = section['titulo'] as String;
                final fotos = section['fotos'] as List<Map<String, dynamic>>;

                final firstRow = fotos.take(2).toList();
                final rest = fotos.skip(2).toList();

                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: double.infinity,
                              color: PdfColor.fromHex('2D3035'),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: pw.Text(titulo.toUpperCase(), style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.white)),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: firstRow.map(buildPhotoItem).toList(),
                            ),
                          ]
                        )
                      )
                    ]
                  )
                );

                if (rest.isNotEmpty) {
                  widgets.add(pw.SizedBox(height: 8));
                  widgets.add(
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rest.map(buildPhotoItem).toList(),
                    )
                  );
                }

                widgets.add(pw.SizedBox(height: 16));
              }

              return widgets;
            }
          )
        );
      }
    }

    // ── Páginas de Croqui (Sempre geradas se aplicável) ──────────────────────
    if (temCroqui && !isCaminhao) {
      pdf.addPage(_buildPageAnalise(
        titulo: 'ANÁLISE ESTRUTURAL',
        itens: const [
          'painel_frontal', 'painel_corta_fogo',
          'torre_amortecedor_esquerda', 'longarina_dianteira_esquerda', 'caixa_roda_dianteira_esquerda',
          'coluna_dianteira_esquerda', 'caixa_ar_esquerda', 'assoalho_esquerdo', 'coluna_central_esquerda',
          'longarina_centro_esquerda', 'coluna_traseira_esquerda',
          'caixa_roda_traseira_esquerda', 'longarina_traseira_esquerda',
          'painel_traseiro', 'caixa_estepe',
          'longarina_traseira_direita', 'caixa_roda_traseira_direita',
          'coluna_traseira_direita', 'longarina_centro_direita', 'coluna_central_direita',
          'assoalho_direito', 'caixa_ar_direita', 'coluna_dianteira_direita',
          'caixa_roda_dianteira_direita', 'longarina_dianteira_direita', 'torre_amortecedor_direita',
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
          'assoalho_esquerdo': 'Assoalho Esquerdo',
          'assoalho_direito': 'Assoalho Direito',
          'caixa_ar_esquerda': 'Caixa de Ar Esquerda',
          'caixa_ar_direita': 'Caixa de Ar Direita',
          'caixa_estepe': 'Caixa do Estepe',
          'caixa_roda_dianteira_esquerda': 'Caixa de Roda Dianteira Esquerda',
          'caixa_roda_dianteira_direita': 'Caixa de Roda Dianteira Direita',
          'caixa_roda_traseira_esquerda': 'Caixa de Roda Traseira Esquerda',
          'caixa_roda_traseira_direita': 'Caixa de Roda Traseira Direita',
          'coluna_dianteira_esquerda': 'Coluna Dianteira Esquerda',
          'coluna_dianteira_direita': 'Coluna Dianteira Direita',
          'coluna_central_esquerda': 'Coluna Central Esquerda',
          'coluna_central_direita': 'Coluna Central Direita',
          'coluna_traseira_esquerda': 'Coluna Traseira Esquerda',
          'coluna_traseira_direita': 'Coluna Traseira Direita',
          'torre_amortecedor_esquerda': 'Torre de Amortecedor Esquerda',
          'torre_amortecedor_direita': 'Torre de Amortecedor Direita',
          'painel_corta_fogo': 'Painel Corta Fogo',
        },
        state: wizardState, vistoria: vistoria, styles: styles, logo: logoImage, backgroundImage: bgImage, assinatura: assinaturaImage, assinaturaCliente: assinaturaClienteImage, showSignatures: true,
      ));
    }

    if (temAvarias && !isCaminhao) {
      pw.ImageProvider? ai3dImage;
      if (veiculo.aiImage3dBase64 != null && veiculo.aiImage3dBase64!.isNotEmpty) {
        try {
          final bytes = base64Decode(veiculo.aiImage3dBase64!);
          ai3dImage = pw.MemoryImage(bytes);
        } catch (_) {}
      }

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
        isPintura: true, 
        is3d: ai3dImage != null,
        state: wizardState, vistoria: vistoria, styles: styles, logo: logoImage, 
        backgroundImage: ai3dImage ?? carroPinturaImage ?? bgImage, 
        assinatura: assinaturaImage, assinaturaCliente: assinaturaClienteImage, showSignatures: false,
      ));
    }

    if (!hasAnyPhoto) {
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logoImage, state: wizardState),
            pw.SizedBox(height: 10),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text('Nenhuma foto capturada.', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
              )
            )
          ]
        )
      ));
    }


    // ── Ficha Técnica Inteligente (Gemini) ──────────────────────────────────
    try {
      List<String> apontamentosList = [];
      if (wizardState != null) {
        apontamentosList = wizardState.checklistStatus.entries
            .where((e) => e.value != 'CONFORME' && e.value != 'NÃO ANALISADO' && !e.value.toUpperCase().contains('ORIGINAL'))
            .map((e) {
              final nomeLimpo = e.key.replaceAll('_', ' ').toUpperCase();
              final obs = wizardState.checklistObs[e.key] ?? '';
              return '$nomeLimpo: ${e.value}${obs.isNotEmpty ? " (Obs: $obs)" : ""}';
            }).toList();
      }

      final resFicha = await Supabase.instance.client.functions.invoke(
        'gerar-ficha-veiculo',
        body: {
          'brand': veiculo.marca ?? '',
          'model': veiculo.modelo ?? '',
          'year': veiculo.anoFabricacao ?? veiculo.anoModelo ?? DateTime.now().year,
          'version': veiculo.modelo ?? '',
          'fuel': veiculo.combustivel ?? '',
          'engine': veiculo.motorVeiculo ?? '',
          if (apontamentosList.isNotEmpty) 'apontamentos': apontamentosList,
          'uf': await _obterUfPorGps() ?? veiculo.uf ?? '',
        },
      ).timeout(const Duration(seconds: 60));

      if (resFicha.status == 200 && resFicha.data != null) {
        final data = resFicha.data is String ? jsonDecode(resFicha.data) : resFicha.data;
        if (data != null && data['data'] != null) {
          _buildFichaTecnicaPages(pdf, data['data'], vistoria, styles, logoImage, assinaturaImage, wizardState);
        }
      }
    } catch (e) {
      print('Erro ao gerar ficha técnica inteligente: $e');
      // Continua gerando o PDF normalmente
    }



    // Inserir a página de Disclaimer no final do nosso PDF local
    pdf.addPage(_buildPageDisclaimer(
      vistoria: vistoria,
      styles: styles,
      logo: logoImage,
      assinatura: assinaturaImage,
      assinaturaCliente: assinaturaClienteImage,
      state: wizardState,
    ));

    // ── Anexar Pesquisa (Radar) se existir ──────────────────────────────────
    try {
      final autocredDao = sl<AutocredDao>();
      final consulta = await autocredDao.buscarConsultaPorVistoria(vistoria.id);
      if (consulta != null && consulta.dadosTratadosJson != null && consulta.dadosTratadosJson!.isNotEmpty) {
        final Map<String, dynamic> dadosPesquisa = jsonDecode(consulta.dadosTratadosJson!);
        final radarPages = await PdfRadarGenerator.buildRadarPages(dadosPesquisa);
        for (var page in radarPages) {
          pdf.addPage(page);
        }
      }
    } catch (e, stackTrace) {
      print('Erro ao anexar pesquisa Radar ao PDF: $e');
      print('Stack trace: $stackTrace');
    }

    final Uint8List finalBytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laudo_${vistoria.numeroLaudo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(finalBytes);

    try {
      final storagePath = '${vistoria.id}/${vistoria.numeroLaudo}.pdf';
      await Supabase.instance.client.storage.from('laudos-pdf').uploadBinary(
        storagePath,
        finalBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
      );
    } catch (e) {
      print('Erro ao fazer upload do PDF para o Supabase: $e');
    }

    return file.path;
  }

  // ── Página de Disclaimer ─────────────────────────────────────────────────

  pw.Page _buildPageDisclaimer({
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    VistoriaWizardState? state,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            _buildBlackBar('DISCLAIMER DE SERVIÇO', styles),
            pw.SizedBox(height: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _disclaimerText('Este laudo trata-se da vistoria cautelar do veículo, possuindo caráter informativo da análise de itens, conforme padrões estabelecidos pelos fabricantes.', styles),
                  _disclaimerText('NÃO substituindo em nenhuma hipótese a Perícia Oficial do Instituto de Criminalística.', styles, bold: true),
                  _disclaimerText('Cabe destacar que a unidade não se responsabiliza por quaisquer modificações nos itens do veículo contemplados nesta vistoria, posteriores à realização deste laudo, cuja validade tem sua garantia certificada no momento da realização da vistoria.', styles),
                  _disclaimerText('O resultado do laudo técnico segue critérios de avaliação estabelecidos, podendo sofrer alterações necessárias em determinado momento, sem prévia comunicação.', styles),
                  _disclaimerText('As informações dos veículos, obtidas através de pesquisa via base de dados dos órgãos públicos e empresas privadas, são de responsabilidade da empresa fornecedora da pesquisa, cabendo apenas reiterar os dados cadastrados nas referidas bases de consulta.', styles),
                  _disclaimerText('Ao receber este laudo, o cliente fica ciente que as companhias de seguro possuem métodos e critérios próprios de avaliação do risco para aceitação ou não de veículos.', styles),
                  _disclaimerText('Não obstante, o critério de avaliação bem como o resultado final da vistoria, independe da aceitação ou não da seguradora.', styles),
                  _disclaimerText('Importante notar que NÃO são examinados itens de mecânica, elétrica, transmissão, suspensão e freios.', styles, bold: true),
                  _disclaimerText('A análise de pintura é realizada através de medidores digitais que informam a espessura da camada de tinta, apenas em caráter informativo de retoques ou reparos expressivos em sua lataria, que não afetam a estrutura do veículo, NÃO apontamos pequenos riscos nem desgastes na pintura.', styles),
                  _disclaimerText('NÃO nos responsabilizamos por defeitos ou fraudes em equipamentos de Air-Bag.', styles, bold: true),
                  _disclaimerText('A verificação da numeração da caixa de câmbio somente é realizada se tal item está aparente, sem a necessidade de desmontar partes do veículo que tornem a gravação obstruída.', styles),
                  _disclaimerText('A vistoria cautelar não afere a idoneidade da quilometragem constante no hodômetro do veículo, sendo apenas registrado em caráter informativo a quilometragem aparente em seu painel de instrumentos.', styles),
                  _disclaimerText('Alguns itens obrigatórios e acessórios como pneus, setas, cintos e outros acessórios, são apenas informados quanto à sua existência e funcionamento mínimo, não sendo atestada calibração ou cumprimento de normas técnicas específicas.', styles),
                  _disclaimerText('A análise proposta é particular, restrita exclusivamente aos itens analisados e não à vistoria regulamentada pelo CONTRAN ou à perícia realizada pelo Instituto de Criminalística.', styles),
                  if (vistoria.tipoVistoria.toLowerCase().contains('caminh'))
                    _disclaimerText('ATENÇÃO (VEÍCULO DE CARGA): As modificações nas dimensões do chassi (alongamento ou encurtamento) estão sujeitas à regulamentação específica (Resolução CONTRAN nº 292/2008 e atualizações como a Res. 916/2022). Este laudo aponta apenas as condições aparentes da estrutura para fins de vistoria cautelar, não suprindo a exigência legal do Certificado de Segurança Veicular (CSV) nem garantindo a regularização das modificações perante o DETRAN.', styles, bold: true),
                ],
              ),
            ),
            _buildFooter(vistoria, styles, ctx, assinatura, assinaturaCliente: assinaturaCliente, showSignatures: true),
          ],
        );
      },
    );
  }

  pw.Widget _disclaimerText(String text, _PdfStyles styles, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? styles.bold : styles.regular,
          fontSize: 9,
          color: _kBlack,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  // ── Seções Compartilhadas ────────────────────────────────────────────────

  pw.Widget _buildHeader(Vistoria vistoria, _PdfStyles styles, pw.ImageProvider? logo, {VistoriaWizardState? state}) {
    String statusFinal = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        statusFinal = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        statusFinal = state.statusSugerido;
      }
    }
    
    PdfColor bgColor;
    String svgIcon;
    final lowerStatus = statusFinal.toLowerCase();
    
    if (lowerStatus == 'conforme') {
      bgColor = _kGreen;
      svgIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    } else if (lowerStatus.contains('observaç')) {
      bgColor = _kOrange;
      svgIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    } else if (lowerStatus.contains('reprovado') || lowerStatus.contains('não conforme')) {
      bgColor = _kRed;
      svgIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else {
      bgColor = PdfColor.fromInt(0xFF2196F3); // Azul
      svgIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M11 18h2v-2h-2v2zm1-16C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-14c-2.21 0-4 1.79-4 4h2c0-1.1.9-2 2-2s2 .9 2 2c0 2-3 1.75-3 5h2c0-2.25 3-2.5 3-5 0-2.21-1.79-4-4-4z"/></svg>';
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          pw.Container(
            width: 70, height: 70,
            child: logo != null 
                ? pw.Image(logo, fit: pw.BoxFit.contain)
                : pw.Center(child: pw.Text('Logo', style: pw.TextStyle(color: _kGreyDark, fontSize: 10))),
          ),
          pw.SizedBox(width: 16),
          // Numero do Laudo
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('LAUDO CAUTELAR', style: pw.TextStyle(font: styles.bold, fontSize: 14, color: _kBlack)),
                pw.SizedBox(height: 4),
                pw.Text('Número do Laudo: ${vistoria.numeroLaudo}', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: _kGreyDark)),
              ],
            ),
          ),
          // Status Pill
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Container(
                  width: 14, height: 14,
                  child: pw.SvgImage(svg: svgIcon),
                ),
                pw.SizedBox(width: 8),
                pw.Text(statusFinal.toUpperCase(), style: pw.TextStyle(font: styles.bold, fontSize: 11, color: _kWhite)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // QR Code
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: Supabase.instance.client.storage.from('laudos-pdf').getPublicUrl('${vistoria.id}/${vistoria.numeroLaudo}.pdf'),
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

  pw.Widget _buildFooter(Vistoria vistoria, _PdfStyles styles, pw.Context ctx, pw.ImageProvider? assinatura, {pw.ImageProvider? assinaturaCliente, bool showSignatures = false}) {
    if (!showSignatures) return pw.SizedBox.shrink();
    
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
                  pw.Text(vistoria.vistoriadorNome?.toUpperCase() ?? 'VISTORIADOR', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('CPF: ${_maskCpf(vistoria.vistoriadorCpf)}', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('Vistoriador', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                ],
              ),
              pw.Column(
                children: [
                  if (assinaturaCliente != null)
                    pw.Container(
                      height: 30,
                      child: pw.Image(assinaturaCliente, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.SizedBox(height: 30),
                  pw.Container(width: 150, height: 1, color: _kBlack),
                  pw.SizedBox(height: 4),
                  pw.Text((vistoria.clienteNome != null && vistoria.clienteNome!.trim().isNotEmpty) ? vistoria.clienteNome!.toUpperCase() : 'CLIENTE', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                  pw.Text('Cliente', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Página 1 ─────────────────────────────────────────────────────────────

  Future<pw.Page> _buildPage1Modern({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    pw.ImageProvider? marcaAgua,
  }) async {
    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }


    final limeGreen = PdfColor.fromHex('8CC63F');
    final warningYellow = PdfColor.fromHex('FBB03B');
    final dangerRed = PdfColor.fromHex('EE4036');

    PdfColor statusColor = warningYellow;
    String statusIcon = '!';
    String upStatus = computedStatus.toUpperCase();
    if (upStatus.contains('NÃO CONFORME') || upStatus.contains('REPROVADO')) {
      statusColor = dangerRed;
      statusIcon = '✗';
    } else if (upStatus.contains('CONFORME') || upStatus == 'APROVADO') {
      statusColor = limeGreen;
      statusIcon = '✓';
    } else if (upStatus.contains('APONTAMENTOS') || upStatus.contains('OBSERVAÇÕES')) {
      statusColor = warningYellow;
      statusIcon = '!';
    } else {
      statusColor = limeGreen;
      statusIcon = '✓';
    }

    int getStatusCategory(String rawStatus) {
      final s = rawStatus.toLowerCase().trim();
      if (s.isEmpty) return 0;
      
      if (s.contains('divergente') || s.contains('adulteração') || s.contains('reprovado') ||
          s.contains('não original') || s.contains('substituído') || s.contains('ausente') ||
          s.contains('danificad') || s.contains('colisão') || s.contains('ilegível') ||
          s.contains('não localizad') || s.contains('não conforme')) {
        return 2;
      }
      
      if (s.contains('reparo') || s.contains('repintura') || s.contains('observação') || 
          s.contains('envelopado') || s.contains('amassado') || s.contains('riscado') ||
          s.contains('soldado') || s.contains('avaria') || s.contains('massa') ||
          s.contains('obstruído') || s.contains('alongado') || s.contains('consideração') ||
          s.contains('sem acesso') || s.contains('inexistente') || s.contains('remarcad')) {
        return 1;
      }
      
      return 0;
    }

    int countConforme = 0;
    int countObs = 0;
    int countNaoConforme = 0;
    
    final Map<String, List<Map<String, dynamic>>> grupos = {
      'IDENTIFICAÇÃO': [],
      'ESTRUTURA': [],
      'PINTURA E LATARIA': []
    };

    if (state != null) {
      for (final entry in state.checklistStatus.entries) {
        final id = entry.key;
        final rawStatus = entry.value;
        final nome = id.replaceAll('_', ' ').toUpperCase();
        
        if (nome.contains('OPCIONAL')) continue;
        if (rawStatus.toUpperCase() == 'NÃO ANALISADO') continue;

        final cat = getStatusCategory(rawStatus);
        if (cat == 0) countConforme++;
        else if (cat == 1) countObs++;
        else countNaoConforme++;
        
        final itemMap = {'nome': nome, 'status': cat, 'id': id};

        if (id.startsWith('chassi') || id.startsWith('motor') || id.startsWith('cambio') || 
            id.startsWith('vidro') || id.startsWith('etiqueta') || id.startsWith('painel_hodometro') || 
            id.startsWith('foto_placa') || id.startsWith('compartimento_motor')) {
          grupos['IDENTIFICAÇÃO']!.add(itemMap);
        } else if (id.startsWith('longarina') || id.startsWith('caixa') || id.startsWith('coluna') || 
                   id.startsWith('painel') || id.startsWith('torre') || id.startsWith('assoalho')) {
          grupos['ESTRUTURA']!.add(itemMap);
        } else {
          grupos['PINTURA E LATARIA']!.add(itemMap);
        }
      }
    }
    
    final int totalItens = countConforme + countObs + countNaoConforme;
    final nowStr = '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Stack(
          children: [
            if (marcaAgua != null || logo != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.12,
                    child: pw.Container(
                      width: 380,
                      child: pw.Image(marcaAgua ?? logo!, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null)
                      pw.Container(width: 85, height: 45, child: pw.Image(logo, fit: pw.BoxFit.contain))
                    else
                      pw.SizedBox(width: 85),
                    pw.Column(
                      children: [
                        pw.Text('LAUDO CAUTELAR', style: pw.TextStyle(font: styles.bold, fontSize: 16, color: PdfColors.black)),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey700,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Text('LAUDO DE VISTORIA VEICULAR', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.white)),
                        ),
                      ]
                    ),
                    pw.Container(
                      width: 50, height: 50,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'http://autocred.vistoria/${vistoria.numeroLaudo}',
                      ),
                    ),
                  ]
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DATA REALIZAÇÃO: $nowStr    DATA IMPRESSÃO: $nowStr', style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.grey600)),
                    pw.Text('Nº LAUDO: ${vistoria.numeroLaudo}', style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.grey600)),
                  ]
                ),
                pw.SizedBox(height: 4),
                pw.Container(height: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DADOS DO VEÍCULO', style: pw.TextStyle(font: styles.bold, fontSize: 11, color: PdfColors.grey800)),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildKv('PLACA:', veiculo.placa, styles),
                                  _buildKv('MARCA:', veiculo.marca, styles),
                                  _buildKv('MODELO:', veiculo.modelo, styles),
                                  _buildKv('ANO FAB/MOD:', '${veiculo.anoFabricacao}/${veiculo.anoModelo}', styles),
                                  _buildKv('COR:', veiculo.cor, styles),
                                ]
                              )),
                              pw.Expanded(child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildKv('Nº CHASSI:', veiculo.chassiVeiculo, styles),
                                  _buildKv('Nº MOTOR:', veiculo.motorVeiculo, styles),
                                  _buildKv('COMBUSTÍVEL:', veiculo.combustivel, styles),
                                  _buildKv('QUILOMETRAGEM:', veiculo.km?.toString(), styles),
                                  _buildKv('MUNICÍPIO:', veiculo.municipio, styles),
                                ]
                              )),
                            ]
                          ),
                        ]
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PARECER FINAL', style: pw.TextStyle(font: styles.bold, fontSize: 11, color: PdfColors.grey800)),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 36, height: 36,
                                decoration: pw.BoxDecoration(
                                  color: statusColor,
                                  shape: pw.BoxShape.circle
                                ),
                                child: pw.Center(
                                  child: pw.Text(statusIcon, style: pw.TextStyle(font: styles.bold, fontSize: 22, color: PdfColors.white))
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Expanded(
                                child: pw.Text(
                                  computedStatus.toUpperCase(), 
                                  style: pw.TextStyle(font: styles.bold, fontSize: 12, color: PdfColors.black)
                                ),
                              )
                            ]
                          )
                        ]
                      )
                    )
                  ]
                ),
                pw.SizedBox(height: 14),
                
                pw.Text('SITUAÇÃO GERAL', style: pw.TextStyle(font: styles.bold, fontSize: 11, color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 110,
                      child: pw.Column(
                        children: [
                          pw.Text('$totalItens', style: pw.TextStyle(font: styles.bold, fontSize: 28, color: PdfColors.black)),
                          pw.Text('ITENS VERIFICADOS', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.grey600)),
                        ]
                      )
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow('CONFORME', countConforme, limeGreen, styles, isCheck: true),
                          pw.SizedBox(height: 4),
                          _buildLegendRow('CONFORME (COM OBSERVAÇÃO)', countObs, warningYellow, styles, isWarning: true),
                          pw.SizedBox(height: 4),
                          _buildLegendRow('NÃO CONFORME', countNaoConforme, dangerRed, styles, isCross: true),
                        ]
                      )
                    )
                  ]
                ),
                
                pw.SizedBox(height: 10),
                pw.Container(height: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCategoryColumn('IDENTIFICAÇÃO', grupos['IDENTIFICAÇÃO']!, styles, limeGreen, warningYellow, dangerRed),
                      pw.Container(width: 0.5, height: double.infinity, color: PdfColors.grey200),
                      _buildCategoryColumn('ESTRUTURA', grupos['ESTRUTURA']!, styles, limeGreen, warningYellow, dangerRed),
                      pw.Container(width: 0.5, height: double.infinity, color: PdfColors.grey200),
                      _buildCategoryColumn('PINTURA E LATARIA', grupos['PINTURA E LATARIA']!, styles, limeGreen, warningYellow, dangerRed),
                    ]
                  )
                ),

                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 3),
                          pw.Text('CPF: Não informado', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                          pw.Text('Vistoriador', style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey700)),
                        ]
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 3),
                          pw.Text('CLIENTE', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                          pw.Text('Cliente', style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey700)),
                        ]
                      )
                    ]
                  )
                )

              ],
            )
          ]
        );
      }
    );
  }

  pw.Widget _buildKv(String k, String? v, _PdfStyles styles) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 70, child: pw.Text(k, style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColors.black))),
          pw.Expanded(child: pw.Text(v ?? '-', style: pw.TextStyle(font: styles.regular, fontSize: 7.5, color: PdfColors.grey800))),
        ]
      )
    );
  }

  pw.Widget _buildLegendRow(String title, int count, PdfColor color, _PdfStyles styles, {bool isCheck = false, bool isWarning = false, bool isCross = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 16, height: 16,
              decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              child: pw.Center(
                child: pw.Text(
                  isCheck ? '✓' : (isWarning ? '!' : '✕'),
                  style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)
                )
              )
            ),
            pw.SizedBox(width: 8),
            pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 8.5, color: PdfColors.black)),
          ]
        ),
        pw.Text('$count ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 8.5, color: PdfColors.grey700)),
      ]
    );
  }

  pw.Widget _buildCategoryColumn(
    String title, 
    List<Map<String, dynamic>> itens, 
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
    int greens = itens.where((e) => e['status'] == 0).length;
    int yellows = itens.where((e) => e['status'] == 1).length;
    int reds = itens.where((e) => e['status'] == 2).length;
    int total = itens.length;

    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6),
        child: pw.Column(
          children: [
            pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey900)),
            pw.SizedBox(height: 8),
            _buildDonutChart(total, greens, yellows, reds, styles, limeGreen, warningYellow, dangerRed),
            pw.SizedBox(height: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: itens.map((e) {
                final statusVal = e['status'] as int;
                PdfColor dotColor = limeGreen;
                if (statusVal == 1) dotColor = warningYellow;
                if (statusVal == 2) dotColor = dangerRed;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 5, height: 5,
                        decoration: pw.BoxDecoration(color: dotColor, shape: pw.BoxShape.circle)
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Text(
                          e['nome'] as String, 
                          style: pw.TextStyle(
                            font: (statusVal != 0) ? styles.bold : styles.regular, 
                            fontSize: 6.5, 
                            color: (statusVal != 0) ? PdfColors.black : PdfColors.grey800
                          )
                        )
                      ),
                    ]
                  )
                );
              }).toList()
            )
          ]
        )
      )
    );
  }

  pw.Widget _buildDonutChart(
    int total, 
    int green, 
    int yellow, 
    int red, 
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
    if (total == 0) return pw.SizedBox(height: 80);
    return pw.SizedBox(
      width: 80, height: 80,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(80, 80),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final center = PdfPoint(size.x / 2, size.y / 2);
              final radius = 32.0;
              final stroke = 11.0;
              
              double currentAngle = -1.5708; // Top
              
              void drawArcSegment(int count, PdfColor color) {
                if (count == 0) return;
                final sweepAngle = (count / total) * 6.283185307179586;
                
                canvas.saveContext();
                final int steps = 30;
                canvas.moveTo(
                  center.x + radius * math.cos(currentAngle), 
                  center.y + radius * math.sin(currentAngle)
                );
                for (int i = 1; i <= steps; i++) {
                  final a = currentAngle + (sweepAngle * i / steps);
                  canvas.lineTo(
                    center.x + radius * math.cos(a), 
                    center.y + radius * math.sin(a)
                  );
                }
                canvas.setStrokeColor(color);
                canvas.setLineWidth(stroke);
                canvas.strokePath();
                canvas.restoreContext();
                
                currentAngle += sweepAngle;
              }
              
              drawArcSegment(green, limeGreen);
              drawArcSegment(yellow, warningYellow);
              drawArcSegment(red, dangerRed);
            }
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$total', style: pw.TextStyle(font: styles.bold, fontSize: 16, color: PdfColors.black)),
              pw.Text('ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.grey600)),
            ]
          )
        ]
      )
    );
  }


  Future<pw.Page> _buildPage1({
    required Vistoria vistoria,
    required Veiculo veiculo,
    VistoriaWizardState? state,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    pw.ImageProvider? assinaturaCliente,
    pw.ImageProvider? marcaAgua,
  }) async {
    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Stack(
          children: [
            if (marcaAgua != null || logo != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.15,
                    child: pw.Container(
                      width: 350,
                      child: pw.Image(marcaAgua ?? logo!, fit: pw.BoxFit.contain),
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            _buildHeader(vistoria, styles, logo, state: state),
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
                    _th('STATUS:', styles), _td(computedStatus.toUpperCase(), styles),
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

            _buildFooter(vistoria, styles, ctx, assinatura, assinaturaCliente: assinaturaCliente, showSignatures: true),
              ],
            ),
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
    var itens = [
      'compartimento_motor', 'etiqueta_vis_motor',
      'etiqueta_vis_porta', 'frente_direita',
      'frente_esquerda', 'chassi_gravacao',
      'motor_gravacao', 'vidro_dianteiro_direito',
      'vidro_dianteiro_esquerdo', 'vidro_frontal',
      'vidro_traseiro', 'vidro_traseiro_direito',
      'vidro_traseiro_esquerdo', 'painel_hodometro',
      'foto_placa', 'traseira_direita',
      'traseira_esquerda'
    ];
    
    final isCaminhao = state?.tipoVistoria.toLowerCase().contains('caminh') ?? false;
    
    if (isCaminhao) {
      itens.remove('compartimento_motor');
      itens.remove('etiqueta_vis_motor');
      itens.remove('etiqueta_vis_porta');
      itens.remove('vidro_traseiro_direito');
      itens.remove('vidro_traseiro_esquerdo');
    }
    
    itens = itens.where((id) {
      final status = state?.getStatus(id).toUpperCase() ?? '';
      return status != 'INEXISTENTE';
    }).toList();

    
    final labels = {
      'compartimento_motor': 'COMPARTIMENTO DO MOTOR',
      'etiqueta_vis_motor': 'ETIQUETA VIS COMPARTIMENTO MOTOR',
      'etiqueta_vis_porta': 'ETIQUETA VIS PORTA',
      'foto_chassi': 'GRAVAÇÃO DO CHASSI',
      'foto_motor': 'GRAVAÇÃO DO MOTOR',
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
              pw.Text(status.toUpperCase(), style: pw.TextStyle(font: styles.bold, fontSize: 6, color: _kBlack)),
            ],
          ),
        );
      }),
    );
  }
  pw.Widget _buildKvSmall(String k, String v, _PdfStyles styles) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        children: [
          pw.Text(k, style: pw.TextStyle(font: styles.bold, fontSize: 5.5, color: PdfColors.black)),
          pw.SizedBox(width: 3),
          pw.Expanded(
            child: pw.Text(v, style: pw.TextStyle(font: styles.regular, fontSize: 5.5, color: PdfColors.grey700), maxLines: 1, overflow: pw.TextOverflow.clip)
          ),
        ]
      )
    );
  }

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
    pw.ImageProvider? assinaturaCliente,
    bool isPintura = false,
    bool showSignatures = false,
    bool is3d = false,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar(titulo, styles),
            
            pw.SizedBox(height: 8),
            
            if (!isPintura && backgroundImage != null)
              pw.Expanded(
                child: _buildDiagramaEstrutural(backgroundImage, state, styles),
              )
            else if (isPintura && is3d && backgroundImage != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 20),
                        child: pw.Center(
                          child: pw.Image(backgroundImage, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildBlackBar('OBSERVAÇÕES DA PINTURA', styles),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: itens.map((id) {
                          final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                          final obs = state?.getObs(id) ?? '';
                          final color = _getPinturaColor(status);
                          return pw.Container(
                            width: 170,
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('F9F9F9'),
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 10, height: 10,
                                  margin: const pw.EdgeInsets.only(top: 1, right: 6),
                                  decoration: pw.BoxDecoration(
                                    color: color, 
                                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))
                                  )
                                ),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(labels[id] ?? id, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey900)),
                                      pw.SizedBox(height: 2),
                                      pw.Text(status.toUpperCase(), style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey700)),
                                      if (obs.isNotEmpty) ...[
                                        pw.SizedBox(height: 2),
                                        pw.Text('Obs: $obs', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.red700)),
                                      ]
                                    ]
                                  )
                                )
                              ]
                            )
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else if (isPintura && backgroundImage != null)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: _buildDiagramaPintura(backgroundImage, state, styles),
                    ),
                    pw.SizedBox(height: 8),
                    _buildBlackBar('OBSERVAÇÕES DA PINTURA', styles),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: itens.map((id) {
                          final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                          final obs = state?.getObs(id) ?? '';
                          final color = _getPinturaColor(status);
                          return pw.Container(
                            width: 170,
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('F9F9F9'),
                              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 10, height: 10,
                                  margin: const pw.EdgeInsets.only(top: 1, right: 6),
                                  decoration: pw.BoxDecoration(
                                    color: color, 
                                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))
                                  )
                                ),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(labels[id] ?? id, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey900)),
                                      pw.SizedBox(height: 2),
                                      pw.Text(status.toUpperCase(), style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey700)),
                                      if (obs.isNotEmpty) ...[
                                        pw.SizedBox(height: 2),
                                        pw.Text('Obs: $obs', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.red700)),
                                      ]
                                    ]
                                  )
                                )
                              ]
                            )
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
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
            
            _buildFooter(vistoria, styles, ctx, assinatura, assinaturaCliente: assinaturaCliente, showSignatures: showSignatures),
          ],
        );
      },
    );
  }

  pw.Widget _buildDiagramaPintura(pw.ImageProvider backgroundImage, VistoriaWizardState? state, _PdfStyles styles) {
    const double boxWidth = 95;
    
    return pw.Center(
      child: pw.Stack(
        children: [
          // Base invisível para forçar a largura total e evitar que os itens se espremam
          pw.Container(width: 520),
          
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: pw.Image(backgroundImage, fit: pw.BoxFit.contain),
          ),
          
          // MEIO (Extremidades, não cortadas)
          pw.Positioned(
            left: 5, top: 110,
            child: _buildPinturaStatus('CAPÔ DIANTEIRO', state?.getStatus('peca_capo_dianteiro') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            right: 5, top: 160, // Desceu 50px
            child: _buildPinturaStatus('TAMPA TRASEIRA', state?.getStatus('peca_tampa_traseira') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),

          // TOPO (5 caixas)
          pw.Positioned(
            left: 35, top: 30, // Desceu 30px, 30px direita
            child: _buildPinturaStatus('PARA-LAMA DIAN. DIR.', state?.getStatus('peca_paralama_dianteiro_direito') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: false),
          ),
          pw.Positioned(
            left: 135, top: 20, // 30px pra direita e desceu 20px
            child: _buildPinturaStatus('PORTA DIAN. DIR.', state?.getStatus('peca_porta_dianteira_direita') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: false),
          ),
          pw.Positioned(
            left: 247.5, top: 0, // 30px pra direita
            child: _buildPinturaStatus('TETO', state?.getStatus('peca_teto') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: false),
          ),
          pw.Positioned(
            right: 135, top: 20, // 30px pra esquerda, desceu 20px
            child: _buildPinturaStatus('PORTA TRAS. DIR.', state?.getStatus('peca_porta_traseira_direita') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: false),
          ),
          pw.Positioned(
            right: 45, top: 20, // 40px pra esquerda, desceu 20px
            child: _buildPinturaStatus('LATERAL TRAS. DIR.', state?.getStatus('peca_lateral_traseira_direita') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: false),
          ),

          // BASE (4 caixas)
          pw.Positioned(
            left: 25, bottom: 100, // Subiu 50px
            child: _buildPinturaStatus('PARA-LAMA DIAN. ESQ.', state?.getStatus('peca_paralama_dianteiro_esquerdo') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            left: 165, bottom: 110, // Subiu 50px, 10px pra esquerda
            child: _buildPinturaStatus('PORTA DIAN. ESQ.', state?.getStatus('peca_porta_dianteira_esquerda') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            right: 145, bottom: 110, // Subiu 50px, 20px pra direita
            child: _buildPinturaStatus('PORTA TRAS. ESQ.', state?.getStatus('peca_porta_traseira_esquerda') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            right: 45, bottom: 120, // Subiu 50px, 10px pra direita
            child: _buildPinturaStatus('LATERAL TRAS. ESQ.', state?.getStatus('peca_lateral_traseira_esquerda') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
        ],
      ),
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
            top: 0, left: 10,
            child: _buildCaixaStatus('LONGARINA DIANTEIRA DIREITA', state?.getStatus('longarina_dianteira_direita') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: true),
          ),
          pw.Positioned(
            top: 0, left: 215,
            child: _buildCaixaStatus('LONGARINA CENTRO DIREITA', state?.getStatus('longarina_centro_direita') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: true),
          ),
          pw.Positioned(
            top: 0, right: 15,
            child: _buildCaixaStatus('LONGARINA TRASEIRA DIREITA', state?.getStatus('longarina_traseira_direita') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: true),
          ),
          pw.Positioned(
            bottom: 20, left: 5,
            child: _buildCaixaStatus('LONGARINA DIANTEIRA ESQUERDA', state?.getStatus('longarina_dianteira_esquerda') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: false),
          ),
          pw.Positioned(
            bottom: 20, left: 225,
            child: _buildCaixaStatus('LONGARINA CENTRO ESQUERDA', state?.getStatus('longarina_centro_esquerda') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: false),
          ),
          pw.Positioned(
            bottom: 20, right: 15,
            child: _buildCaixaStatus('LONGARINA TRASEIRA ESQUERDA', state?.getStatus('longarina_traseira_esquerda') ?? 'NÃO ANALISADO', styles, width: 95, tagOnTop: false),
          ),
        ],
      ),
    );
  }

  PdfColor _getPinturaColor(String status) {
    status = status.toUpperCase();
    if (status.contains('ORIGINAL') || status.contains('CONFORME')) {
      return _kGreen;
    } else if (status.contains('REPINTURA E/OU MASSA') || status.contains('SUBSTITUÍDO') || status.contains('DANIFICADO') || status.contains('REPROVADO') || status.contains('NÃO CONFORME')) {
      return _kRed;
    } else if (status.contains('REPINTURA') || status.contains('ENVELOPADO') || status.contains('RISCADO') || status.contains('REPARO')) {
      return _kOrange;
    }
    return _kGreyDark;
  }

  pw.Widget _buildPinturaStatus(String titulo, String status, _PdfStyles styles, {double width = 90, bool tagOnTop = true}) {
    status = status.toUpperCase();
    PdfColor color = _getPinturaColor(status);

    final titleWidget = pw.Text(
      titulo,
      style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kBlack),
      textAlign: pw.TextAlign.center,
    );
    
    String icon = color == _kGreen ? '✓' : (color == _kRed ? '✗' : '!');

    final tagWidget = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            icon,
            style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            status,
            style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: tagOnTop 
            ? [tagWidget, pw.SizedBox(height: 2), titleWidget]
            : [titleWidget, pw.SizedBox(height: 2), tagWidget],
      ),
    );
  }

  pw.Widget _buildCaixaStatus(String titulo, String status, _PdfStyles styles, {double width = 95, bool tagOnTop = true}) {
    status = status.toUpperCase();
    PdfColor color = _kGreyDark;
    
    // Verificação de status estrutural
    if (status.contains('NÃO CONFORME') || status.contains('SUBSTITUÍDO') || status.contains('SOLDADO') || status.contains('REPROVADO') || status.contains('TRINCADO') || status.contains('CORTADO') || status.contains('DANIFICADO')) {
      color = _kRed;
    } else if (status.contains('CONFORME') || status.contains('SEM REPARO') || status.contains('ORIGINAL') || status == 'APROVADO') {
      color = _kGreen;
    } else if (status.contains('REPARO') || status.contains('OBSERVAÇÕES') || status.contains('AMASSADO') || status.contains('APONTAMENTOS')) {
      color = _kOrange;
    }

    final titleWidget = pw.Text(
      titulo,
      style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kBlack),
      textAlign: pw.TextAlign.center,
    );
    
    String icon = color == _kGreen ? '✓' : (color == _kRed ? '✗' : '!');

    final tagWidget = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            icon,
            style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            status,
            style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: _kWhite),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: tagOnTop 
            ? [tagWidget, pw.SizedBox(height: 2), titleWidget]
            : [titleWidget, pw.SizedBox(height: 2), tagWidget],
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

  void _buildFichaTecnicaPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    Vistoria vistoria,
    _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    VistoriaWizardState? state,
  ) {
    final themeRed = PdfColor.fromHex('#0288d1'); // Azul claro principal (mantendo o nome da variavel para nao quebrar)
    final lightRed = PdfColor.fromHex('#e1f5fe'); // Fundo azul clarinho
    final borderRed = PdfColor.fromHex('#b3e5fc'); // Borda azul suave
    final textDark = PdfColor.fromHex('#333333');
    final textMuted = PdfColor.fromHex('#666666');

    pw.Widget buildRedBar(String text) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
        decoration: pw.BoxDecoration(
          color: themeRed,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(text, style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)),
      );
    }

    pw.Widget buildSoftTh(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        color: lightRed,
        child: pw.Text(text, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: themeRed)),
      );
    }

    pw.Widget buildSoftTd(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
      );
    }

    String formatCurrency(dynamic val) {
      if (val == null) return '-';
      final str = val.toString();
      if (str.toUpperCase().startsWith('R\$')) return str;
      
      final clean = str.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (clean.isEmpty) return str;
      
      try {
        final parsed = double.parse(clean.replaceAll(',', '.'));
        return 'R\$ ' + parsed.toStringAsFixed(2).replaceAll('.', ',');
      } catch (_) {
        return str;
      }
    }

    // Especificações e Manutenção
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(vistoria, styles, logo, state: state),
              
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightRed,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: themeRed, width: 1)
                ),
                child: pw.Center(
                  child: pw.Text('FICHA TÉCNICA INTELIGENTE DO VEÍCULO', style: pw.TextStyle(font: styles.bold, fontSize: 12, color: themeRed)),
                )
              ),
              
              pw.SizedBox(height: 8),
              buildRedBar('ESPECIFICAÇÕES TÉCNICAS'),
              if (data['especificacoes_tecnicas'] != null)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: borderRed, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: borderRed, width: 0.5)),
                    children: (data['especificacoes_tecnicas'] as Map<String, dynamic>).entries.map((e) {
                      return pw.TableRow(
                        children: [
                          buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                          buildSoftTd(e.value.toString()),
                        ]
                      );
                    }).toList(),
                  ),
                ),

              pw.SizedBox(height: 8),
              buildRedBar('MANUTENÇÃO RECOMENDADA'),
              if (data['manutencao'] != null)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: borderRed, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: borderRed, width: 0.5)),
                    children: (data['manutencao'] as Map<String, dynamic>).entries.map((e) {
                      return pw.TableRow(
                        children: [
                          buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                          buildSoftTd(e.value.toString()),
                        ]
                      );
                    }).toList(),
                  ),
                ),

              pw.Spacer(),
              _buildFooter(vistoria, styles, ctx, assinatura, showSignatures: false),
            ],
          );
        },
      )
    );

    // Problemas e Peças
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(vistoria, styles, logo, state: state),
              buildRedBar('PONTOS DE ATENÇÃO (HISTÓRICO DO MODELO)'),
              if (data['problemas_comuns'] != null && data['problemas_comuns'] is List)
                ...((data['problemas_comuns'] as List).map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: borderRed, width: 1)
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Icon(const pw.IconData(0xe002), color: themeRed, size: 10), // Warning icon if supported, else just colored text
                            pw.SizedBox(width: 4),
                            pw.Text('${item['item']}', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: themeRed)),
                          ]
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('${item['sintomas']}', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
                        pw.SizedBox(height: 2),
                        pw.Text('Ponto de Atenção: ${item['observacao_vistoria']}', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textMuted)),
                      ],
                    ),
                  );
                }).toList()),

              pw.SizedBox(height: 8),
              buildRedBar('PEÇAS DE DESGASTE'),
              if (data['pecas_desgaste'] != null && data['pecas_desgaste'] is List)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: borderRed, width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: borderRed, width: 0.5)),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: lightRed),
                        children: [
                          buildSoftTh('PEÇA'), buildSoftTh('VIDA ÚTIL'), buildSoftTh('VALOR PEÇA'), buildSoftTh('MÃO DE OBRA')
                        ]
                      ),
                      ...((data['pecas_desgaste'] as List).map((item) {
                        return pw.TableRow(
                          children: [
                            buildSoftTd(item['peca']?.toString() ?? ''),
                            buildSoftTd(item['vida_util_media']?.toString() ?? ''),
                            buildSoftTd(formatCurrency(item['valor_peca_estimado'])),
                            buildSoftTd('${formatCurrency(item['valor_mao_de_obra_estimado'])} (${item['tempo_mao_de_obra_estimado']})'),
                          ]
                        );
                      }).toList()),
                    ],
                  ),
                ),

              if (data['apontamentos_veiculo'] != null && data['apontamentos_veiculo'] is List) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF57F17),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text('APONTAMENTOS DA VISTORIA (VALORES ESTIMADOS)', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)),
                ),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFE082), width: 1),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColor.fromInt(0xFFFFE082), width: 0.5)),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFF9C4)),
                        children: [
                          pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text('PEÇA / PROBLEMA', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text('OBSERVAÇÃO', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text('VALOR PEÇA', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(padding: const pw.EdgeInsets.all(6), child: pw.Text('MÃO DE OBRA', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                        ]
                      ),
                      ...((data['apontamentos_veiculo'] as List).map((item) {
                        return pw.TableRow(
                          children: [
                            buildSoftTd(item['peca_ou_problema']?.toString() ?? ''),
                            buildSoftTd(item['observacao_indicada']?.toString() ?? ''),
                            buildSoftTd(formatCurrency(item['valor_peca_estimado'])),
                            buildSoftTd(formatCurrency(item['valor_mao_de_obra_estimado'])),
                          ]
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),
              _buildFooter(vistoria, styles, ctx, assinatura, showSignatures: false),
            ],
          );
        },
      )
    );

    // Dicas
    if (data['dicas_vistoria'] != null && (data['dicas_vistoria'] as List).isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(vistoria, styles, logo, state: state),
                buildRedBar('RECOMENDAÇÕES DE REVISÃO (HISTÓRICO DO MODELO)'),
                ...((data['dicas_vistoria'] as List).map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: borderRed, width: 1)
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Área: ${item['area']}', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: themeRed)),
                        pw.SizedBox(height: 2),
                        pw.Text('Verificar: ${item['o_que_verificar']}', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
                        pw.SizedBox(height: 2),
                        pw.Text('Recomendação: ${item['sinal_de_alerta']}', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textMuted)),
                      ],
                    ),
                  );
                }).toList()),

                pw.SizedBox(height: 8),
                if (data['observacoes'] != null && data['observacoes'] is List && (data['observacoes'] as List).isNotEmpty) ...[
                  buildRedBar('OBSERVAÇÕES ADICIONAIS'),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: lightRed,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: borderRed, width: 1)
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: ((data['observacoes'] as List).map((obs) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                margin: const pw.EdgeInsets.only(top: 3, right: 6),
                                width: 3, height: 3,
                                decoration: pw.BoxDecoration(color: themeRed, shape: pw.BoxShape.circle),
                              ),
                              pw.Expanded(child: pw.Text('$obs', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark))),
                            ]
                          )
                        );
                      }).toList()),
                    )
                  )
                ],

                pw.SizedBox(height: 8),
                (() {
                  if (data['analise_final'] == null) {
                    return pw.SizedBox.shrink();
                  }
                  
                  final analise = data['analise_final'];
                  final resumo = analise['resumo_estado_veiculo']?.toString() ?? '';
                  String valorMercado = analise['valor_venda_mercado_local']?.toString() ?? 'R\$ 0,00';
                  String desconto = analise['desconto_total_avarias']?.toString() ?? 'R\$ 0,00';
                  String valorSugerido = analise['valor_venda_sugerido_final']?.toString() ?? 'R\$ 0,00';
                  final justificativa = analise['justificativa']?.toString() ?? '';

                  String guaranteeBrl(String val) {
                    if (!val.toUpperCase().contains('R\$') && !val.contains(r'\$')) {
                      return 'R\$ ' + val;
                    }
                    if (val.contains(r'\$') && !val.toUpperCase().contains('R')) {
                      return val.replaceFirst(r'\$', 'R\$ ');
                    }
                    return val;
                  }
                  
                  valorMercado = guaranteeBrl(valorMercado);
                  desconto = guaranteeBrl(desconto);
                  valorSugerido = guaranteeBrl(valorSugerido);

                  final mainGreen = const PdfColor.fromInt(0xFF2E7D32);
                  final blueColor = const PdfColor.fromInt(0xFF1976D2);
                  
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: pw.BoxDecoration(
                          color: mainGreen,
                          borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(4), topRight: pw.Radius.circular(4)),
                        ),
                        child: pw.Text('ANÁLISE FINAL E AVALIAÇÃO DE MERCADO (IA)', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)),
                      ),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.only(bottomLeft: pw.Radius.circular(4), bottomRight: pw.Radius.circular(4)),
                          border: pw.Border.all(color: mainGreen, width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Resumo do Estado:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
                            pw.SizedBox(height: 2),
                            pw.Text(resumo, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
                            pw.SizedBox(height: 10),
                            
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('Valor Médio Local:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
                                      pw.Text(valorMercado, style: pw.TextStyle(font: styles.bold, fontSize: 11, color: textDark)),
                                    ]
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text('Desconto (Avarias/Reparos):', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: blueColor)),
                                      pw.Text(desconto, style: pw.TextStyle(font: styles.bold, fontSize: 11, color: blueColor)),
                                    ]
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                                    children: [
                                      pw.Text('Valor Sugerido Final:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: mainGreen)),
                                      pw.Text(valorSugerido, style: pw.TextStyle(font: styles.bold, fontSize: 12, color: mainGreen)),
                                    ]
                                  ),
                                ),
                              ]
                            ),
                            
                            pw.SizedBox(height: 10),
                            pw.Text('Justificativa:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
                            pw.SizedBox(height: 2),
                            pw.Text(justificativa, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
                          ]
                        )
                      )
                    ]
                  );
                })(),

                pw.Spacer(),
                _buildFooter(vistoria, styles, ctx, assinatura, showSignatures: false),
              ],
            );
          },
        )
      );
    }
  }
}

class _PdfStyles {
  final pw.Font regular;
  final pw.Font bold;
  const _PdfStyles({required this.regular, required this.bold});
}
