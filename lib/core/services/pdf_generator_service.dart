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

    // Página 1 — Dados Gerais
    pdf.addPage(await _buildPage1(vistoria: vistoria, veiculo: veiculo, state: wizardState, styles: styles, logo: logoImage, assinatura: assinaturaImage));

    final tipoEnum = TipoVistoria.fromString(vistoria.tipoVistoria ?? '');
    final isCaminhao = tipoEnum == TipoVistoria.cautelarCaminhao;
    final temCroqui = tipoEnum != TipoVistoria.cautelarCaminhao;
    final temAvarias = tipoEnum == TipoVistoria.carroComCroqui;
    final bgImage = isCaminhao ? caminhaoEstruturaImage : carroEstruturaImage;

    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    // ── Geração de Fotos Padronizada (Item 15) ──────────────────────────────
    final Map<String, List<String>> secoesFotos = {
      'FOTOS PRINCIPAIS - IDENTIFICAÇÃO': [
        'foto_placa',
        'frente_esquerda',
        'frente_direita',
        'traseira_esquerda',
        'traseira_direita',
      ],
      'FOTOS PRINCIPAIS - VIDROS': [
        'vidro_frontal',
        'vidro_traseiro',
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
        'motor_gravacao',
        'cambio_gravacao',
        if (!isCaminhao) 'etiqueta_vis_motor',
        if (!isCaminhao) 'etiqueta_vis_porta',
        'chassi_gravacao',
      ],
      if (temCroqui && !isCaminhao) 'FOTOS - ESTRUTURAL': [
        'longarina_dianteira_esquerda',
        'longarina_dianteira_direita',
        'longarina_centro_esquerda',
        'longarina_centro_direita',
        'longarina_traseira_esquerda',
        'longarina_traseira_direita',
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
    final chunkSize = 15;

    if (wizardState != null) {
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
          hasAnyPhoto = true;
          for (var i = 0; i < fotosSecao.length; i += chunkSize) {
            final end = (i + chunkSize < fotosSecao.length) ? i + chunkSize : fotosSecao.length;
            final chunk = fotosSecao.sublist(i, end);
            pdf.addPage(_buildPageFotosGrid(
              titulo: i == 0 ? tituloSecao : '$tituloSecao (CONT.)',
              fotos: chunk,
              vistoria: vistoria,
              styles: styles,
              logo: logoImage,
              assinatura: assinaturaImage,
              state: wizardState,
            ));
          }
        }
        // Croquis foram movidos para fora deste loop para garantir geração.
      }

      // Adicionar Fotos Extras (T2)
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
        hasAnyPhoto = true;
        for (var i = 0; i < fotosExtrasList.length; i += chunkSize) {
          final end = (i + chunkSize < fotosExtrasList.length) ? i + chunkSize : fotosExtrasList.length;
          final chunk = fotosExtrasList.sublist(i, end);
          pdf.addPage(_buildPageFotosGrid(
            titulo: i == 0 ? 'FOTOS EXTRAS' : 'FOTOS EXTRAS (CONT.)',
            fotos: chunk,
            vistoria: vistoria,
            styles: styles,
            logo: logoImage,
            assinatura: assinaturaImage,
            state: wizardState,
          ));
        }
      }
    }

    // ── Páginas de Croqui (Sempre geradas se aplicável) ──────────────────────
    if (temCroqui && !isCaminhao) {
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
    }

    if (temAvarias && !isCaminhao) {
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
        isPintura: true, state: wizardState, vistoria: vistoria, styles: styles, logo: logoImage, backgroundImage: carroPinturaImage ?? bgImage, assinatura: assinaturaImage,
      ));
    }

    if (!hasAnyPhoto) {
      pdf.addPage(_buildPageFotosGrid(
        titulo: 'FOTOS DA VISTORIA',
        fotos: [],
        vistoria: vistoria,
        styles: styles,
        logo: logoImage,
        assinatura: assinaturaImage,
        state: wizardState,
      ));
    }


    // ── Ficha Técnica Inteligente (Gemini) ──────────────────────────────────
    try {
      final resFicha = await Supabase.instance.client.functions.invoke(
        'gerar-ficha-veiculo',
        body: {
          'brand': veiculo.marca ?? '',
          'model': veiculo.modelo ?? '',
          'year': veiculo.anoFabricacao ?? veiculo.anoModelo ?? DateTime.now().year,
          'version': veiculo.modelo ?? '',
          'fuel': veiculo.combustivel ?? '',
          'engine': veiculo.motorVeiculo ?? '',
        },
      ).timeout(const Duration(seconds: 20));

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

    final autocredDao = sl<AutocredDao>();
    final consulta = await autocredDao.buscarConsultaPorVistoria(vistoria.id);

    if (consulta != null && consulta.dadosTratadosJson != null && consulta.dadosTratadosJson!.isNotEmpty) {
      Map<String, dynamic> radarData = {};
      Map<String, dynamic> rawFull = {};
      String? radarUrl;
      try {
        radarData = jsonDecode(consulta.dadosTratadosJson!);
        if (radarData['resultadoCompleto'] != null) {
          rawFull = radarData['resultadoCompleto'];
        } else {
          rawFull = radarData;
        }
        
        if (radarData['view'] != null && radarData['view']['full'] != null) {
          radarUrl = radarData['view']['full']?.toString();
        } else if (rawFull['view'] != null && rawFull['view']['full'] != null) {
          radarUrl = rawFull['view']['full']?.toString();
        } else if (radarData['resultados'] != null && radarData['resultados'].isNotEmpty) {
          if (radarData['resultados'][0]['view'] != null) {
            radarUrl = radarData['resultados'][0]['view']['full']?.toString();
          }
        }
      } catch (_) {}

            // ── Buscar logo da marca ──
            pw.MemoryImage? marcaLogoImage;
            String marcaStr = '';
            if (radarData['marcaModelo'] != null) {
              String mm = radarData['marcaModelo'].toString().toLowerCase();
              if (mm.startsWith('i/')) mm = mm.substring(2);
              marcaStr = mm.split('/').first.split(' ').first.trim();
              
              final domainMap = {
                'vw': 'vw.com', 'volkswagen': 'vw.com', 'chevrolet': 'chevrolet.com',
                'fiat': 'fiat.com', 'ford': 'ford.com', 'honda': 'honda.com',
                'toyota': 'toyota.com', 'hyundai': 'hyundai.com', 'jeep': 'jeep.com',
                'nissan': 'nissan.com', 'peugeot': 'peugeot.com', 'citroen': 'citroen.com',
                'renault': 'renault.com', 'mitsubishi': 'mitsubishi-motors.com',
                'bmw': 'bmw.com', 'audi': 'audi.com', 'kia': 'kia.com', 'mercedes': 'mercedes-benz.com'
              };
              
              String domain = domainMap[marcaStr] ?? '$marcaStr.com';
              try {
                final res = await Dio().get<List<int>>(
                  'https://logo.clearbit.com/$domain',
                  options: Options(responseType: ResponseType.bytes, validateStatus: (status) => true),
                ).timeout(const Duration(seconds: 4));
                if (res.statusCode == 200 && res.data != null) {
                  marcaLogoImage = pw.MemoryImage(Uint8List.fromList(res.data!));
                }
              } catch (_) {}
            }

            pdf.addPage(
              pw.MultiPage(
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.all(16),
                header: (ctx) => _buildHeader(vistoria, styles, logoImage, state: wizardState),
                footer: (ctx) => _buildFooter(vistoria, styles, ctx, assinaturaImage),
                build: (ctx) {

            final cDarkBlue = PdfColor.fromHex('#215b8b');
            final cGreyBg = PdfColor.fromHex('#f5f5f5');
            final cBorder = PdfColors.grey300;
            
            String safeStr(dynamic val) {
              if (val == null || val.toString().trim().isEmpty || val.toString() == 'null / null' || val.toString() == 'null') return 'Não Informado';
              return val.toString();
            }

            pw.Widget buildTopCard(String label, String? val) {
              return pw.Container(
                width: 110,
                margin: const pw.EdgeInsets.only(bottom: 4, left: 4),
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(label, style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    pw.Text(safeStr(val), style: pw.TextStyle(font: styles.regular, fontSize: 9, color: PdfColors.black)),
                  ]
                )
              );
            }

            int rowIndex = 0;
            pw.Widget buildGridRow(String label1, String? val1, String label2, String? val2, {bool isAlert1 = false, bool isAlert2 = false}) {
              rowIndex++;
              bool isEven = rowIndex % 2 == 0;
              
              pw.Widget renderVal(String? val, bool alert) {
                final text = safeStr(val);
                PdfColor color = PdfColors.grey900;
                if (alert) {
                  if (text.toUpperCase() == 'EM CIRCULAÇÃO' || text.toUpperCase() == 'NORMAL') color = PdfColors.teal700; 
                  else if (text.toUpperCase() == 'NÃO' || text.toUpperCase() == 'NADA CONSTA') color = PdfColors.orange700; 
                  else if (text == 'Não Informado') color = PdfColors.grey800;
                  else color = PdfColors.red700;
                }
                return pw.Text(text, style: pw.TextStyle(font: alert && text != 'Não Informado' ? styles.bold : styles.regular, fontSize: 8, color: color));
              }

              return pw.Container(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColor.fromHex('#f7fbff'),
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColor.fromHex('#e1e8ed'), width: 0.5),
                    left: pw.BorderSide(color: PdfColor.fromHex('#e1e8ed'), width: 0.5),
                    right: pw.BorderSide(color: PdfColor.fromHex('#e1e8ed'), width: 0.5),
                  )
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(label1, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: cDarkBlue))),
                    pw.Expanded(flex: 3, child: renderVal(val1, isAlert1)),
                    pw.Expanded(flex: 2, child: pw.Text(label2, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: cDarkBlue))),
                    pw.Expanded(flex: 3, child: renderVal(val2, isAlert2)),
                  ]
                )
              );
            }

            final queixaRoubo = safeStr(rawFull['rouboefurto'] ?? rawFull['roubofurto']);

            return [
              // Header top
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: cDarkBlue,
                  borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(4))
                ),
                child: pw.Text('Bin **', style: pw.TextStyle(color: PdfColors.white, font: styles.bold, fontSize: 10)),
              ),
              
              // Gray area
              pw.Container(
                color: cGreyBg,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo box
                    pw.Container(
                      width: 80, height: 80,
                      color: PdfColors.white,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          if (marcaLogoImage != null)
                            pw.Image(marcaLogoImage, width: 45, height: 45, fit: pw.BoxFit.contain),
                          if (marcaLogoImage != null) pw.SizedBox(height: 4),
                          pw.Text(
                            marcaStr.toUpperCase().isNotEmpty ? marcaStr.toUpperCase() : safeStr(radarData['marcaModelo']).split(' ').first, 
                            style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.black)
                          ),
                        ]
                      )
                    ),
                    pw.SizedBox(width: 8),
                    // Globe box
                    pw.Expanded(
                      child: pw.Container(
                        height: 80,
                        color: PdfColors.white,
                        child: pw.Center(child: pw.Text('NAO INFORMADO', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: PdfColors.grey)))
                      )
                    ),
                    pw.SizedBox(width: 8),
                    // Right cards
                    pw.Column(
                      children: [
                        pw.Row(children: [ buildTopCard('PLACA', radarData['placa']), buildTopCard('RENAVAM', radarData['renavam']) ]),
                        pw.Row(children: [ buildTopCard('CHASSI', radarData['chassi']), buildTopCard('ESTADO', radarData['estado']) ]),
                      ]
                    )
                  ]
                )
              ),
              
              // Tabela Principal
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: cBorder), right: pw.BorderSide(color: cBorder))
                ),
                child: pw.Column(
                  children: [
                    buildGridRow('Placa', radarData['placa'], 'Procedência', rawFull['procedencia']),
                    buildGridRow('Chassi', radarData['chassi'], 'Numero do Motor', radarData['motor'], isAlert1: true),
                    buildGridRow('Renavam', radarData['renavam'], 'Montagem', rawFull['montagem']),
                    buildGridRow('Cor', radarData['cor'], 'Ano Modelo', radarData['anoModelo']?.toString()),
                    buildGridRow('Ano Fabricação', radarData['anoFabricacao']?.toString(), 'Marca/Modelo', radarData['marcaModelo']),
                    buildGridRow('Municipio', radarData['municipio'], 'UF', radarData['estado']),
                    buildGridRow('Capacidade de passageiros', rawFull['capacidadepassageiro']?.toString(), 'Combustível', radarData['combustivel']),
                    buildGridRow('Potência', rawFull['potencia']?.toString(), 'Especie', rawFull['especie']),
                    buildGridRow('Carroceria', rawFull['carroceria'], 'Nº Câmbio', rawFull['cambio']),
                    buildGridRow('Capacidade de Carga', rawFull['capacidadecarga']?.toString(), 'Cilindradas', rawFull['cilindradas']?.toString()),
                    buildGridRow('Remarcação do Chassi', rawFull['remarcacaochassi'] ?? rawFull['remarcacaobase'], 'Tipo', rawFull['tipo']),
                    buildGridRow('Situação', radarData['situacao'], 'Data última Atualização', rawFull['dataatualizacao'], isAlert1: true),
                    
                    // Tratamento flexível para capturar a FIPE independente do formato da Radar
                    (){
                      String fipeCod = '';
                      String fipeVal = '';
                      if (rawFull['fipe'] != null) {
                        if (rawFull['fipe'] is List && rawFull['fipe'].isNotEmpty) {
                          fipeCod = (rawFull['fipe'][0]['codigo'] ?? rawFull['fipe'][0]['codigoFipe'] ?? rawFull['fipe'][0]['fipe_codigo'] ?? '').toString();
                          fipeVal = (rawFull['fipe'][0]['valor'] ?? rawFull['fipe'][0]['valorFipe'] ?? rawFull['fipe'][0]['fipe_valor'] ?? '').toString();
                        } else if (rawFull['fipe'] is Map) {
                          fipeCod = (rawFull['fipe']['codigo'] ?? rawFull['fipe']['codigoFipe'] ?? rawFull['fipe']['fipe_codigo'] ?? '').toString();
                          fipeVal = (rawFull['fipe']['valor'] ?? rawFull['fipe']['valorFipe'] ?? rawFull['fipe']['fipe_valor'] ?? '').toString();
                        } else {
                          fipeCod = rawFull['fipe'].toString();
                        }
                      }
                      if (fipeCod.isEmpty || fipeCod == 'null') fipeCod = safeStr(rawFull['codigofipe'] ?? rawFull['codigo_fipe'] ?? rawFull['fipe_codigo']);
                      if (fipeVal.isEmpty || fipeVal == 'null') fipeVal = safeStr(rawFull['valorfipe'] ?? rawFull['valor_fipe'] ?? rawFull['fipe_valor'] ?? rawFull['valor']);

                      return pw.Column(
                        children: [
                          buildGridRow('Emplacamento Eletrônico', rawFull['emplacamentoeletronico'], 'Código FIPE', fipeCod.isNotEmpty ? fipeCod : null),
                          buildGridRow('Valor FIPE', fipeVal.isNotEmpty ? fipeVal : null, '', ''),
                        ]
                      );
                    }()
                  ]
                )
              ),

              // Tratamento inteligente para Informações Relevantes
              (){
                var info = radarData['informacoesRelevantes'];
                pw.Widget? contentWidget;
                
                if (info is Map) {
                  List<pw.Widget> bullets = [];
                  info.forEach((key, value) {
                    final valStr = value.toString().trim();
                    final valLower = valStr.toLowerCase();
                    if (valStr.isEmpty || valLower == 'não informado' || valLower == 'nada consta' || valLower == 'null' || valStr == '[]' || valStr.contains('NADA CONSTA, NADA CONSTA')) return;
                    
                    bullets.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: cDarkBlue)),
                            pw.Expanded(
                              child: pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    pw.TextSpan(text: '$key: ', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey900)),
                                    pw.TextSpan(text: valStr, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: PdfColors.grey800)),
                                  ]
                                )
                              )
                            )
                          ]
                        )
                      )
                    );
                  });
                  if (bullets.isNotEmpty) {
                    contentWidget = pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: bullets);
                  }
                } else if (info is List && info.isNotEmpty) {
                  List<pw.Widget> bullets = [];
                  for (var item in info) {
                    final valStr = item.toString().trim();
                    if (valStr.isEmpty || valStr.toLowerCase() == 'nada consta' || valStr.toLowerCase() == 'não informado') continue;
                    bullets.add(pw.Text('• $valStr', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: PdfColors.grey800)));
                  }
                  if (bullets.isNotEmpty) {
                    contentWidget = pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: bullets);
                  }
                } else if (info != null && info.toString().trim().isNotEmpty && info.toString().toLowerCase() != 'não informado') {
                  contentWidget = pw.Text(info.toString(), style: pw.TextStyle(font: styles.regular, fontSize: 8, color: PdfColors.grey800));
                }

                if (contentWidget == null) return pw.SizedBox();

                return pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: PdfColor.fromHex('#fff3cd'),
                      child: pw.Text('Informações Relevantes', style: pw.TextStyle(color: PdfColor.fromHex('#856404'), font: styles.bold, fontSize: 9)),
                    ),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: cBorder)
                      ),
                      child: contentWidget,
                    )
                  ]
                );
              }(),

              // Roubo / Furto
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: cBorder)),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text('Queixa de Roubo e/ou Furto', style: pw.TextStyle(font: styles.bold, fontSize: 8))),
                    pw.Expanded(flex: 8, child: pw.Text(
                      queixaRoubo == 'Não Informado' ? 'VEICULO NÃO POSSUI RESTRIÇÃO DE ROUBO/FURTO' : queixaRoubo, 
                      style: pw.TextStyle(font: styles.bold, fontSize: 9, color: queixaRoubo == 'Não Informado' ? PdfColors.green : PdfColors.red)
                    )),
                  ]
                )
              ),
              
              pw.SizedBox(height: 8),

              // Tabela Restrições
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(color: cBorder)),
                child: pw.Column(
                  children: [
                    buildGridRow('Situação', radarData['situacao'], 'Recall', rawFull['recall'], isAlert1: true),
                    buildGridRow('Ind. Restrições', rawFull['indicadorrestricoes'], 'Restrição Renajud', rawFull['restricaorenajud'] ?? 'NÃO', isAlert2: true),
                    buildGridRow('Restrição RFB', rawFull['restricaorfb'] ?? 'NÃO', 'Restrição01', radarData['restricoes1'] ?? 'NADA CONSTA', isAlert1: true, isAlert2: true),
                    buildGridRow('Restrição02', radarData['restricoes2'] ?? 'NADA CONSTA', 'Restrição03', radarData['restricoes3'] ?? 'NADA CONSTA', isAlert1: true, isAlert2: true),
                    buildGridRow('Restrição04', radarData['restricoes4'] ?? 'NADA CONSTA', 'Data Limite Restrição Tributária', rawFull['datalimiterestricaotributaria'], isAlert1: true),
                    buildGridRow('Placa Mercosul', rawFull['placamercosul'], '', ''),
                  ]
                )
              ),
              
              pw.SizedBox(height: 16),

              if (radarUrl != null && radarUrl.isNotEmpty)
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.UrlLink(
                    destination: radarUrl,
                    child: pw.Text(
                      '🔗 Clique aqui para visualizar o Laudo Original no portal da Radar Consultas', 
                      style: pw.TextStyle(
                        color: PdfColors.blue900,
                        decoration: pw.TextDecoration.underline,
                        font: styles.bold,
                        fontSize: 9,
                      )
                    )
                  )
                ),
              
              // Disclaimer final
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                color: cGreyBg,
                child: pw.Text(
                  'Estas informações são confidencias e deverão ser utilizadas exclusivamente para a orientação das transações comerciais do CNPJ/CPF: 24.868.718/0001-62, responsabilizando-se civil e criminalmente por danos que ocasionar a terceiros, quando utilizadas em desacordo com a legislação em vigor. A responsabilidade da contratada limita-se a transmitir fielmente as informações oriundas das bases de Negativação, Protesto Cartoriais e sobre veículos automotores registrados em base de Dados públicas e privadas detentoras das informações. As informações exibidas nesta consulta são as que se encontram disponíveis na data e hora da consulta nas Bases de Dados públicas ou privadas, cabendo ao CNPJ/CPF: 24.868.718/0001-62. Em caso de dúvida ou divergência, consulta diretamente o órgão competente. O CNPJ/CPF: 24.868.718/0001-62, declara ter ciência que todas as informações prestadas no corpo desta consulta visam exclusivamente colaborar com o processo de averiguação de procedência do veículo, servindo apenas como uma ferramenta de análise prévia e não como elemento de decisão única para vistoria ou comercialização do veículo. O levantamento das informações veiculares via consulta eletrônica jamais pode substituir a consulta do órgão oficial especialmente pelo fato de que as informações podem ser acrescidas, modificadas ou retiradas de forma "on-line" pelos órgãos públicos, instituições financeiras e seguradoras. Devido as informações DPVAT (Histórico de Proprietários), que ficou indisponível desde 12/07/2018 no mercado de informações veiculares e o Sinistro de Indenização Integral fornecido pela FENASEG/CNSEG desde 18/07/2018, não há como a empresa vistoriadora e fornecedor da consulta, se responsabilizar por informações de Sinistro de Indenização Integral.',
                  style: pw.TextStyle(font: styles.regular, fontSize: 6, color: PdfColors.grey700),
                  textAlign: pw.TextAlign.justify,
                )
              )
            ];
          },
        ),
      );
    }

    // Inserir a página de Disclaimer no final do nosso PDF local
    pdf.addPage(_buildPageDisclaimer(
      vistoria: vistoria,
      styles: styles,
      logo: logoImage,
      assinatura: assinaturaImage,
      state: wizardState,
    ));

    final Uint8List finalBytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Laudo_${vistoria.numeroLaudo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(finalBytes);

    return file.path;
  }

  // ── Página de Disclaimer ─────────────────────────────────────────────────

  pw.Page _buildPageDisclaimer({
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
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
                ],
              ),
            ),
            _buildFooter(vistoria, styles, ctx, assinatura),
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
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _kGreyLight,
            ),
            child: logo != null 
                ? pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover))
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
          // pw.Text(
          //   'Isenção informada: declaro ter recebido a segunda via e EXAME VISTORIA VEICULAR... [Texto de isenção placeholder]... Qualquer dúvida estamos à disposição.',
          //   style: pw.TextStyle(font: styles.regular, fontSize: 5, color: _kGreyDark),
          //   textAlign: pw.TextAlign.justify,
          // ),
          // pw.Container(
          //   margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
          //   height: 1, color: _kBlack,
          // ),
          // pw.Text('NULL', style: pw.TextStyle(font: styles.regular, fontSize: 6, color: _kGreyDark)),
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
        return pw.Column(
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
      'foto_placa', 'traseira_direita',
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
      'foto_placa': 'PLACA',
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

  // ── Páginas de Fotos ─────────────────────────────────────────────────────

  pw.Page _buildPageFotosGrid({
    required String titulo,
    required List<Map<String, dynamic>> fotos,
    required Vistoria vistoria,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
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
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar(titulo, styles),
            
            pw.SizedBox(height: 8),
            if (fotos.isEmpty)
              pw.Center(child: pw.Text('Nenhuma foto capturada.', style: pw.TextStyle(color: _kGreyDark, fontSize: 10)))
            else
              pw.Expanded(
                child: pw.Align(
                  alignment: pw.Alignment.topCenter,
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
            _buildHeader(vistoria, styles, logo, state: state),
            _buildBlackBar('VISTORIA CAUTELAR: ${vistoria.numeroLaudo}', styles),
            _buildBlackBar(titulo, styles),
            
            pw.SizedBox(height: 8),
            
            // Se for Análise Estrutural e tivermos a imagem, usar o diagrama visual
            if (!isPintura && backgroundImage != null)
              pw.Expanded(
                child: _buildDiagramaEstrutural(backgroundImage, state, styles),
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
                      child: pw.Table(
                        border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(color: _kGreyLight),
                            children: [
                              _th('PEÇA', styles), _th('STATUS', styles), _th('OBSERVAÇÃO', styles),
                            ],
                          ),
                          ...itens.where((id) {
                            final obs = state?.getObs(id) ?? '';
                            final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                            return obs.isNotEmpty || (status != 'NÃO ANALISADO' && status != 'Pintura original' && status != 'CONFORME');
                          }).map((id) {
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
            
            _buildFooter(vistoria, styles, ctx, assinatura),
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
            left: 25, bottom: 50, // Subiu 40px, 30px pra esquerda
            child: _buildPinturaStatus('PARA-LAMA DIAN. ESQ.', state?.getStatus('peca_paralama_dianteiro_esquerdo') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            left: 175, bottom: 60, // Subiu 10px, 30px pra direita
            child: _buildPinturaStatus('PORTA DIAN. ESQ.', state?.getStatus('peca_porta_dianteira_esquerda') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            right: 165, bottom: 60, // Desceu 20px
            child: _buildPinturaStatus('PORTA TRAS. ESQ.', state?.getStatus('peca_porta_traseira_esquerda') ?? 'NÃO ANALISADO', styles, width: 85, tagOnTop: true),
          ),
          pw.Positioned(
            right: 55, bottom: 70, // Subiu 30px, 20px pra esquerda
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
    if (status.contains('CONFORME') || status.contains('SEM REPARO') || status.contains('ORIGINAL')) {
      color = _kGreen;
    } else if (status.contains('SUBSTITUÍDO') || status.contains('SOLDADO') || status.contains('NÃO CONFORME') || status.contains('REPROVADO') || status.contains('TRINCADO') || status.contains('CORTADO') || status.contains('DANIFICADO')) {
      color = _kRed;
    } else if (status.contains('REPARO') || status.contains('OBSERVAÇÕES') || status.contains('AMASSADO')) {
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
              _buildBlackBar('FICHA TÉCNICA DO VEÍCULO', styles),
              
              pw.SizedBox(height: 8),
              _buildBlackBar('ESPECIFICAÇÕES TÉCNICAS', styles),
              if (data['especificacoes_tecnicas'] != null)
                pw.Table(
                  border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                  children: (data['especificacoes_tecnicas'] as Map<String, dynamic>).entries.map((e) {
                    return pw.TableRow(
                      children: [
                        _th(e.key.replaceAll('_', ' ').toUpperCase(), styles),
                        _td(e.value.toString(), styles),
                      ]
                    );
                  }).toList(),
                ),

              pw.SizedBox(height: 8),
              _buildBlackBar('MANUTENÇÃO RECOMENDADA', styles),
              if (data['manutencao'] != null)
                pw.Table(
                  border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                  children: (data['manutencao'] as Map<String, dynamic>).entries.map((e) {
                    return pw.TableRow(
                      children: [
                        _th(e.key.replaceAll('_', ' ').toUpperCase(), styles),
                        _td(e.value.toString(), styles),
                      ]
                    );
                  }).toList(),
                ),

              pw.Spacer(),
              _buildFooter(vistoria, styles, ctx, assinatura),
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
              _buildBlackBar('PONTOS DE ATENÇÃO (HISTÓRICO DO MODELO)', styles),
              if (data['problemas_comuns'] != null && data['problemas_comuns'] is List)
                ...((data['problemas_comuns'] as List).map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: _kBlack, width: 0.5)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${item['item']}', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                        pw.Text('${item['sintomas']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)),
                        pw.Text('Ponto de Atenção: ${item['observacao_vistoria']}', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kGreyDark)),
                      ],
                    ),
                  );
                }).toList()),

              pw.SizedBox(height: 8),
              _buildBlackBar('PEÇAS DE DESGASTE', styles),
              if (data['pecas_desgaste'] != null && data['pecas_desgaste'] is List)
                pw.Table(
                  border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _kGreyLight),
                      children: [
                        _th('PEÇA', styles), _th('VIDA ÚTIL', styles), _th('VALOR PEÇA', styles), _th('MÃO DE OBRA', styles)
                      ]
                    ),
                    ...((data['pecas_desgaste'] as List).map((item) {
                      return pw.TableRow(
                        children: [
                          _td(item['peca']?.toString() ?? '', styles),
                          _td(item['vida_util_media']?.toString() ?? '', styles),
                          _td(item['valor_peca_estimado']?.toString() ?? '', styles),
                          _td('${item['valor_mao_de_obra_estimado']} (${item['tempo_mao_de_obra_estimado']})', styles),
                        ]
                      );
                    }).toList()),
                  ],
                ),

              pw.Spacer(),
              _buildFooter(vistoria, styles, ctx, assinatura),
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
                _buildBlackBar('RECOMENDAÇÕES DE REVISÃO (HISTÓRICO DO MODELO)', styles),
                ...((data['dicas_vistoria'] as List).map((item) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: _kBlack, width: 0.5)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Área: ${item['area']}', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                        pw.Text('Verificar: ${item['o_que_verificar']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)),
                        pw.Text('Recomendação: ${item['sinal_de_alerta']}', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: _kGreyDark)),
                      ],
                    ),
                  );
                }).toList()),

                pw.SizedBox(height: 8),
                _buildBlackBar('OBSERVAÇÕES', styles),
                if (data['observacoes'] != null && data['observacoes'] is List)
                  ...((data['observacoes'] as List).map((obs) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('- $obs', style: pw.TextStyle(font: styles.regular, fontSize: 8))
                    );
                  }).toList()),

                pw.Spacer(),
                _buildFooter(vistoria, styles, ctx, assinatura),
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
