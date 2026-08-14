import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import '../theme/app_theme.dart';

class PdfRadarGenerator {
  static const _kPrimaryHeader = PdfColor.fromInt(0xFF133B66);
  static const _kYellowHeader = PdfColor.fromInt(0xFFFDF7CC);
  static const _kYellowHeaderDarkText = PdfColor.fromInt(0xFF8B7500);
  static const _kBlueLight = PdfColor.fromInt(0xFFF2F2F2);
  static const _kTextDark = PdfColor.fromInt(0xFF333333);
  static const _kValueBlue = PdfColor.fromInt(0xFF0066CC);
  static const _kTeal = PdfColor.fromInt(0xFF008298);
  static const _kOrange = PdfColor.fromInt(0xFFEF7F1A);
  static const _kGreen = PdfColor.fromInt(0xFF4DB848);
  static const _kBorder = PdfColor.fromInt(0xFFDDDDDD);

  // SVGs Constants
  static const _svgMapPin =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M12,2C15.86,2 19,5.13 19,9C19,14.25 12,22 12,22C12,22 5,14.25 5,9C5,5.13 8.13,2 12,2M12,11.5A2.5,2.5 0 0,0 14.5,9A2.5,2.5 0 0,0 12,6.5A2.5,2.5 0 0,0 9.5,9A2.5,2.5 0 0,0 12,11.5Z" /></svg>';
  static const _svgEye =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9M12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17M12,4.5C7,4.5 2.73,7.61 1,12C2.73,16.39 7,19.5 12,19.5C17,19.5 21.27,16.39 23,12C21.27,7.61 17,4.5 12,4.5Z" /></svg>';
  static const _svgFlag =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M14.4,6L14,4H5V21H7V14H12.6L13,16H20V6H14.4Z" /></svg>';
  static const _svgPerson =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z" /></svg>';
  static const _svgWrench =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M22.7,19L13.6,9.9C14.14,8.81 14,7.4 13.06,6.46C11.96,5.36 10.37,5.06 9,5.56L11.54,8.1L9.42,10.22L6.88,7.68C6.38,9.05 6.68,10.64 7.78,11.74C8.72,12.68 10.13,12.82 11.22,12.28L20.3,21.36L22.7,19Z" /></svg>';
  static const _svgChart =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M16,11.78L20.24,4.45L21.97,5.45L16.74,14.5L10.23,10.75L5.46,19H22V21H2V3H4V17.54L9.5,8L16,11.78Z" /></svg>';
  static const _svgDocument =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" /></svg>';
  static const _svgCar =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/></svg>';
  static const _svgCheck =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M21,7L9,19L3.5,13.5L4.91,12.09L9,16.17L19.59,5.59L21,7Z" /></svg>';
  static const _svgWarning =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M13,14H11V10H13M13,18H11V16H13M1,21H23L12,2L1,21Z" /></svg>';
  static const _svgInfo =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M11,9H13V7H11M12,20C7.59,20 4,16.41 4,12C4,7.59 7.59,4 12,4C16.41,4 20,7.59 20,12C20,16.41 16.41,20 12,20M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M11,17H13V11H11V17Z" /></svg>';
  static const _svgBuilding =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M12,2L2,7H4V19H2V21H22V19H20V7H22L12,2M12,5.33L16.25,7H7.75L12,5.33M8,19V10H10.5V19H8M13.5,19V10H16V19H13.5Z" /></svg>';
  static const _svgMoney =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M5,6H23V18H5V6M14,9A3,3 0 0,1 17,12A3,3 0 0,1 14,15A3,3 0 0,1 11,12A3,3 0 0,1 14,9M7,8A2,2 0 0,1 9,10V14A2,2 0 0,1 7,16H5V8H7M21,16A2,2 0 0,1 19,14V10A2,2 0 0,1 21,8H23V16H21M1,10H3V20H19V22H1V10Z" /></svg>';
  static const _svgThermometer =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M15,13V5A3,3 0 0,0 9,5V13A5,5 0 1,0 15,13M12,4A1,1 0 0,1 13,5V8H11V5A1,1 0 0,1 12,4Z"/></svg>';
  static const _svgHammer =
      '<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="{color}" d="M12.92,10L14.34,11.41L11.5,14.24C11.5,14.24 11.23,14.5 11.23,14.79C11.23,15.08 11.5,15.35 11.5,15.35L12.92,16.77L9.38,20.31L7.96,18.9L10.8,16.06C10.8,16.06 11.07,15.8 11.07,15.5C11.07,15.21 10.8,14.94 10.8,14.94L9.38,13.53L12.92,10M17.16,4.6L19.28,6.72L16.45,9.55L14.33,7.43L17.16,4.6M15.75,8.84L17.87,10.96L17.16,11.67L15.04,9.55L15.75,8.84Z"/></svg>';

  static String _v(Map<String, dynamic> data, List<String> keys,
      {String fallback = 'Não informado'}) {
    String? searchRecursive(dynamic node, String targetKey) {
      if (node is Map) {
        final lowerTarget = targetKey.toLowerCase();
        for (var entry in node.entries) {
          if (entry.key.toString().toLowerCase() == lowerTarget) {
            final val = entry.value;
            if (val != null) {
              String valStr = '';
              if (val is Map) {
                if (val.containsKey('descricao') && val['descricao'] != null) {
                  valStr = val['descricao'].toString();
                } else if (val.containsKey('nome') && val['nome'] != null) {
                  valStr = val['nome'].toString();
                } else {
                  valStr = val.toString();
                }
              } else {
                valStr = val.toString().trim();
              }
              
              final lowerVal = valStr.toLowerCase();
              if (valStr.isNotEmpty &&
                  lowerVal != 'não informado' &&
                  lowerVal != 'nao informado' &&
                  lowerVal != 'null' &&
                  lowerVal != 'n/a' &&
                  lowerVal != '-') {
                return valStr;
              }
            }
          }
        }
        for (var entry in node.entries) {
          final result = searchRecursive(entry.value, targetKey);
          if (result != null) return result;
        }
      } else if (node is Iterable) {
        for (var item in node) {
          final result = searchRecursive(item, targetKey);
          if (result != null) return result;
        }
      }
      return null;
    }

    for (var k in keys) {
      final result = searchRecursive(data, k);
      if (result != null) return result;
    }
    return fallback;
  }

  static List<List<String>> _getVistoriasRows(Map<String, dynamic> data) {
    List<dynamic>? vistoriasList;

    void searchList(dynamic node, String targetKey) {
      if (node is Map) {
        final lowerTarget = targetKey.toLowerCase();
        for (var entry in node.entries) {
          if (entry.key.toString().toLowerCase() == lowerTarget) {
            if (entry.value is List) {
              vistoriasList = entry.value as List<dynamic>;
              return;
            } else if (entry.value is String) {
              // Might be a pre-formatted string or JSON string
              try {
                final parsed = jsonDecode(entry.value);
                if (parsed is List) vistoriasList = parsed;
              } catch (_) {}
            }
          }
        }
        if (vistoriasList == null) {
          for (var entry in node.entries) {
            searchList(entry.value, targetKey);
            if (vistoriasList != null) return;
          }
        }
      } else if (node is Iterable) {
        for (var item in node) {
          searchList(item, targetKey);
          if (vistoriasList != null) return;
        }
      }
    }

    searchList(data, 'vistorias_ssp');
    if (vistoriasList == null) searchList(data, 'vistoriasssp');
    if (vistoriasList == null) searchList(data, 'vistorias');

    if (vistoriasList == null || vistoriasList!.isEmpty) {
      final vistoriasText = _v(
          data, ['vistorias_ssp', 'vistoriasssp', 'vistorias'],
          fallback: 'Nenhum registro encontrado.');
      return [
        [vistoriasText]
      ];
    }

    List<List<String>> rows = [];
    for (var v in vistoriasList!) {
      if (v is Map) {
        final dt = v['data'] ??
            v['data_realizacao'] ??
            v['datarealizacao'] ??
            v['Data de realização'] ??
            '-';
        final km = v['km'] ??
            v['quilometragem'] ??
            v['quilometragem_informada'] ??
            v['Quilometragem informada'] ??
            '-';
        rows.add([
          'Data de realização',
          dt.toString(),
          'Quilometragem informada',
          km.toString()
        ]);
      } else {
        rows.add([v.toString()]);
      }
    }
    return rows;
  }

  static String _formatTons(String val) {
    if (val == 'Não informado' || val.isEmpty) return val;
    String s = val.trim();
    if (s.endsWith(',00')) s = s.substring(0, s.length - 3);
    if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
    if (s.length == 3 && s.endsWith('00')) return s.substring(0, 1);
    return s;
  }

  static final Map<String, pw.ImageProvider?> _brandLogoCache = {};

  static String _extractBrandSlug(String input) {
    if (input.isEmpty) return '';
    final upper = input.toUpperCase().trim();

    final knownBrands = {
      'VOLKSWAGEN': 'volkswagen',
      'VW': 'vw',
      'FIAT': 'fiat',
      'CHEVROLET': 'chevrolet',
      'GM': 'chevrolet',
      'FORD': 'ford',
      'HONDA': 'honda',
      'TOYOTA': 'toyota',
      'HYUNDAI': 'hyundai',
      'RENAULT': 'renault',
      'BMW': 'bmw',
      'MERCEDES': 'mercedes',
      'BENZ': 'mercedes',
      'AUDI': 'audi',
      'NISSAN': 'nissan',
      'JEEP': 'jeep',
      'PEUGEOT': 'peugeot',
      'CITROEN': 'citroen',
      'CHERY': 'chery',
      'KIA': 'kia',
      'VOLVO': 'volvo',
      'MITSUBISHI': 'mitsubishi',
      'SUZUKI': 'suzuki',
      'DODGE': 'dodge',
      'JAGUAR': 'jaguar',
      'PORSCHE': 'porsche',
      'SUBARU': 'subaru',
      'LIFAN': 'lifan',
      'JAC': 'jac',
      'RAM': 'ram',
      'YAMAHA': 'yamaha',
      'KAWASAKI': 'kawasaki',
      'HARLEY': 'harley-davidson',
      'TRIUMPH': 'triumph',
      'DUCATI': 'ducati',
      'AGRALE': 'agrale',
      'IVECO': 'iveco',
      'SCANIA': 'scania',
      'MAN': 'man',
    };

    for (final entry in knownBrands.entries) {
      if (upper.contains(entry.key)) {
        return entry.value;
      }
    }

    String clean = upper
        .replaceAll(RegExp(r'^(I|IMP|MMC|I\/|IMP\/)\s*'), '')
        .replaceAll(RegExp(r'[^A-Z0-9\s-]'), ' ')
        .trim();

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      final firstWord = parts.first.toLowerCase();
      if (firstWord.length >= 2) return firstWord;
    }

    return '';
  }

  static Future<pw.ImageProvider?> _fetchBrandLogo(String slug) async {
    if (slug.isEmpty) return null;
    if (_brandLogoCache.containsKey(slug)) {
      return _brandLogoCache[slug];
    }

    try {
      final url =
          'https://www.radarconsultas.com.br/rdrv2/webfiles/img/marcas/$slug.png';
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data!.length > 100) {
        final bytes = Uint8List.fromList(response.data!);
        final image = pw.MemoryImage(bytes);
        _brandLogoCache[slug] = image;
        return image;
      }
    } catch (e) {
      print('Erro ao carregar logo da marca ($slug): $e');
    }

    _brandLogoCache[slug] = null;
    return null;
  }

  static Future<pw.ImageProvider?> _loadAssetImage(List<String> paths) async {
    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        return pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {}
    }
    return null;
  }

  static Future<List<pw.Page>> buildRadarPages(
      Map<String, dynamic> dadosPesquisa,
      {pw.Widget? footerWidget,
      bool incluirCabecalhoEmpresa = false,
      pw.ImageProvider? customLogo}) async {
    final List<pw.Page> pages = [];

    final placa = _v(dadosPesquisa, ['placa'], fallback: '');
    final chassi = _v(dadosPesquisa, ['chassi'], fallback: '');
    final renavam = _v(dadosPesquisa, ['renavam'], fallback: '');
    final anomodelo =
        _v(dadosPesquisa, ['anomodelo', 'anoModelo'], fallback: '');
    final estado = _v(dadosPesquisa, ['uf', 'estado'], fallback: '');
    final procedencia =
        _v(dadosPesquisa, ['procedencia'], fallback: 'NACIONAL');
    final marcaStr = _v(
        dadosPesquisa, ['marcamodelo', 'marcaModelo', 'marca'],
        fallback: '');

    final brandSlug = _extractBrandSlug(marcaStr);
    final brandLogo = await _fetchBrandLogo(brandSlug);

    pw.Widget? headerEmpresaWidget;
    if (incluirCabecalhoEmpresa) {
      final logo = customLogo ??
          await _loadAssetImage([
            'assets/images/logo.pdf.PNG',
            'assets/images/logo.pdf.png',
            'assets/images/logo.png',
            'assets/images/logo.PNG',
          ]);
      if (logo != null) {
        headerEmpresaWidget = pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 14),
          alignment: pw.Alignment.center,
          child: pw.Image(logo, height: 52, fit: pw.BoxFit.contain),
        );
      }
    }

    final List<pw.Widget> contentWidgets = [
      if (headerEmpresaWidget != null) headerEmpresaWidget,
      _buildSectionHeader('Bin **',
          svgIcon: null, bgColor: _kPrimaryHeader, textColor: PdfColors.white),
      pw.SizedBox(height: 10),
      _buildTopHeader(placa, chassi, renavam, anomodelo, estado, procedencia,
          brandLogoImage: brandLogo),
      pw.SizedBox(height: 10),
      ..._buildSectionBin(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildInformacoesRelevantesBin(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildBaseEstadual(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildInformacoesRelevantesEstadual(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildProprietario(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildChassi(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildPrecificador(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildHistoricoLaudos(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildSenatranInfo(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildSenatranRestricoes(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildDetalhesComplementares(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildSecoesFinais(dadosPesquisa),
      ..._buildSecoesDinamicas(dadosPesquisa),
    ];

    pages.add(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) {
          if (context.pageNumber == context.pagesCount &&
              footerWidget != null) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),
              child: footerWidget,
            );
          }
          return pw.SizedBox.shrink();
        },
        build: (context) => contentWidgets,
      ),
    );

    return pages;
  }

  static Future<Uint8List> generatePesquisaPdfBytes(
      Map<String, dynamic> dadosPesquisa,
      {pw.ImageProvider? customLogo}) async {
    final pdf = pw.Document(
      title: 'Relatório de Pesquisa Veicular',
      author: 'App Vistoria',
    );

    final pages = await buildRadarPages(
      dadosPesquisa,
      incluirCabecalhoEmpresa: true,
      customLogo: customLogo,
    );

    for (final page in pages) {
      pdf.addPage(page);
    }

    return await pdf.save();
  }

  static Future<Uint8List> converterHtmlParaPdfComLogo(String htmlContent) async {
    // Carrega a logo do app em base64
    String base64Logo = '';
    try {
      final bytes = await rootBundle.load('assets/images/logo.pdf.PNG');
      base64Logo = base64Encode(bytes.buffer.asUint8List());
    } catch (_) {}

    final logoHtml = base64Logo.isNotEmpty
        ? '''
<div style="width: 100%; text-align: center; padding-top: 15px; padding-bottom: 12px; margin-bottom: 10px;">
  <img src="data:image/png;base64,$base64Logo" style="max-height: 55px; max-width: 250px; object-fit: contain;" />
</div>
'''
        : '';

    const cssPrintFix = '''
<style>
  @page {
    size: A4 portrait;
    margin: 0 !important;
  }
  html, body {
    margin: 0 !important;
    padding: 0 !important;
    zoom: 1.0 !important;
    max-width: 100% !important;
    width: 100% !important;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    box-sizing: border-box !important;
  }
  table, .table, div, .container, .row, p, span {
    max-width: 100% !important;
    box-sizing: border-box !important;
  }
</style>
''';

    String adjustedHtml = htmlContent;
    if (adjustedHtml.contains('</head>')) {
      adjustedHtml = adjustedHtml.replaceFirst('</head>', '$cssPrintFix</head>');
    } else if (adjustedHtml.contains('<body')) {
      adjustedHtml = adjustedHtml.replaceFirst('<body', '$cssPrintFix<body');
    } else {
      adjustedHtml = '$cssPrintFix$adjustedHtml';
    }

    if (adjustedHtml.contains('<body')) {
      final bodyIndex = adjustedHtml.indexOf(RegExp(r'<body[^>]*>'));
      if (bodyIndex != -1) {
        final match = RegExp(r'<body[^>]*>').firstMatch(adjustedHtml)!;
        final endTag = match.end;
        adjustedHtml = adjustedHtml.substring(0, endTag) +
            logoHtml +
            adjustedHtml.substring(endTag);
      } else {
        adjustedHtml = '$logoHtml$adjustedHtml';
      }
    } else {
      adjustedHtml = '$logoHtml$adjustedHtml';
    }

    final tempDir = await getTemporaryDirectory();
    final convertedFile = await FlutterHtmlToPdf.convertFromHtmlContent(
      adjustedHtml,
      tempDir.path,
      'pesquisa_temp_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (await convertedFile.exists()) {
      final bytes = await convertedFile.readAsBytes();
      try {
        await convertedFile.delete();
      } catch (_) {}
      return bytes;
    }
    throw Exception('Falha ao converter HTML para PDF');
  }

  static Future<void> visualizarPesquisaPdf({
    required BuildContext context,
    required Map<String, dynamic> dadosPesquisa,
    String? urlPesquisa,
    String? placa,
  }) async {
    bool dialogAberta = false;
    if (context.mounted) {
      dialogAberta = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Preparando relatório em PDF...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      Uint8List? bytes;

      final url = (urlPesquisa != null && urlPesquisa.trim().isNotEmpty)
          ? urlPesquisa.trim()
          : _v(dadosPesquisa, ['arquivoPesquisaUrl', 'arquivo_pesquisa_url', 'view_full', 'url'], fallback: '');

      if (url.isNotEmpty && url.startsWith('http')) {
        try {
          final dio = Dio();
          final response = await dio.get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              sendTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(seconds: 25),
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            final rawBytes = Uint8List.fromList(response.data!);
            final isPdf = rawBytes.length > 4 &&
                rawBytes[0] == 0x25 &&
                rawBytes[1] == 0x50 &&
                rawBytes[2] == 0x44 &&
                rawBytes[3] == 0x46;

            if (isPdf) {
              bytes = rawBytes;
            } else {
              final htmlContent = utf8.decode(rawBytes, allowMalformed: true);
              bytes = await converterHtmlParaPdfComLogo(htmlContent);
            }
          }
        } catch (e) {
          print('Aviso ao baixar/converter HTML da pesquisa: $e');
        }
      }

      bytes ??= await generatePesquisaPdfBytes(dadosPesquisa);

      final placaStr = (placa != null && placa.isNotEmpty)
          ? placa
          : _v(dadosPesquisa, ['placa'], fallback: 'VEICULO');

      if (context.mounted && dialogAberta) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAberta = false;
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes!,
        name: 'Pesquisa_Veicular_$placaStr.pdf',
      );
    } catch (e) {
      if (context.mounted && dialogAberta) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogAberta = false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF da pesquisa: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  static pw.Widget _buildTopHeader(
      String placa,
      String chassi,
      String renavam,
      String anomodelo,
      String estado,
      String procedencia,
      {pw.ImageProvider? brandLogoImage}) {
    return pw.Row(children: [
      pw.Expanded(
          flex: 1,
          child: pw.Container(
            height: 60,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _kBorder, width: 0.5),
                color: PdfColors.white),
            child: brandLogoImage != null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Image(brandLogoImage,
                        height: 48, fit: pw.BoxFit.contain),
                  )
                : pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.SvgImage(
                          svg: _svgCar.replaceAll(
                              '{color}', _kPrimaryHeader.toHex()),
                          height: 24),
                      pw.SizedBox(width: 4),
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('AUTO PERÍCIA',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: _kPrimaryHeader,
                                  fontSize: 8)),
                          pw.Text('HRF',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: _kOrange,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
          )),
      pw.SizedBox(width: 8),
      pw.Expanded(
          flex: 1,
          child: pw.Container(
              height: 60,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _kBorder, width: 0.5),
                  color: PdfColors.white),
              child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.SvgImage(
                        svg: _svgMapPin.replaceAll(
                            '{color}', _kTextDark.toHex()),
                        height: 20),
                    pw.SizedBox(height: 2),
                    pw.Text(
                        procedencia.isNotEmpty
                            ? procedencia.toUpperCase()
                            : 'NACIONAL',
                        style: const pw.TextStyle(fontSize: 8)),
                  ]))),
      pw.SizedBox(width: 8),
      pw.Expanded(
          flex: 2,
          child: pw.Container(
              height: 60,
              child: pw.Column(children: [
                pw.Expanded(
                    child: pw.Row(children: [
                  _buildTopGridCell('PLACA', placa),
                  pw.SizedBox(width: 8),
                  _buildTopGridCell('RENAVAM', renavam),
                ])),
                pw.SizedBox(height: 8),
                pw.Expanded(
                    child: pw.Row(children: [
                  _buildTopGridCell('CHASSI', chassi),
                  pw.SizedBox(width: 8),
                  _buildTopGridCell(
                      estado.isNotEmpty ? 'ESTADO' : 'ANO MOD.',
                      estado.isNotEmpty ? estado : anomodelo),
                ]))
              ])))
    ]);
  }

  static pw.Widget _buildTopGridCell(String title, String value) {
    return pw.Expanded(
        child: pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _kBorder, width: 0.5),
                color: PdfColors.white),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(title,
                      style: const pw.TextStyle(
                          fontSize: 6, color: PdfColors.grey)),
                  pw.Text(value,
                      style: pw.TextStyle(fontSize: 9, color: _kTextDark)),
                ])));
  }

  static pw.Widget _buildSectionHeader(String title,
      {String? svgIcon,
      PdfColor bgColor = _kPrimaryHeader,
      PdfColor textColor = PdfColors.white}) {
    return pw.Container(
        width: double.infinity,
        color: bgColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: pw.Row(children: [
          if (svgIcon != null) ...[
            pw.SvgImage(
                svg: svgIcon.replaceAll(
                    '{color}',
                    textColor.toHex().length == 9
                        ? textColor.toHex().substring(0, 7)
                        : textColor.toHex()),
                height: 10),
            pw.SizedBox(width: 4),
          ],
          pw.Text(
            title,
            style: pw.TextStyle(
                color: textColor, fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ]));
  }

  static List<pw.Widget> _buildDataGrid(List<List<String>> rows) {
    return List.generate(rows.length, (index) {
      final isEven = index % 2 == 0;
      final rowData = rows[index];

      if (rowData.length == 1) {
        return pw.Container(
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kBorder, width: 0.5),
              color: isEven ? PdfColors.white : _kBlueLight),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          width: double.infinity,
          child: _buildValueBlock(rowData[0], isTitle: true),
        );
      }

      return pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.5),
            color: isEven ? PdfColors.white : _kBlueLight),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Row(
          children: [
            if (rowData.isNotEmpty)
              pw.Expanded(
                  child: _buildLabelValue(
                      rowData[0], rowData.length > 1 ? rowData[1] : '')),
            if (rowData.length >= 4)
              pw.Expanded(child: _buildLabelValue(rowData[2], rowData[3])),
          ],
        ),
      );
    });
  }

  static pw.Widget _buildValueBlock(String value, {bool isTitle = false}) {
    final vUpper = value.toUpperCase();
    PdfColor color = _kValueBlue;
    String? icon;

    if (vUpper.contains('VEICULO NÃO POSSUI RESTRIÇÃO') ||
        vUpper.contains('CHASSI NÃO POSSUÍ IRREGULARIDADES') ||
        vUpper.contains('O VEÍCULO PESQUISADO NÃO POSSUI RECALL') ||
        vUpper.contains('NÃO POSSUI INFORMAÇÕES NO DNIT') ||
        vUpper.contains('NÃO FOI ENCONTRADO NENHUMA OCORRÊNCIA') ||
        vUpper == 'VEÍCULO NÃO POSSUÍ INDÍCIO DE SINISTRO' ||
        vUpper.contains('NÃO POSSUÍ LAUDO EM NOSSA PLATAFORMA')) {
      color = _kGreen;
      icon = _svgCheck;
    } else if (vUpper == 'FORNECEDOR INDISPONÍVEL') {
      color = PdfColor.fromInt(0xFFD67362); // Reddish color from image
    } else if (vUpper.contains('NÃO FOI ENCONTRADO NENHUMA') ||
        vUpper.contains('NÃO POSSUI INDÍCIO')) {
      color = _kOrange;
      icon = _svgWarning;
    } else if (vUpper.contains('NÃO FORAM ENCONTRADOS REGISTROS DE ROUBO') ||
        vUpper.contains('QUANTIDADE DE PESQUISAS')) {
      color = PdfColor.fromInt(0xFF5BC0DE);
      icon = _svgInfo;
    }

    String hexColor = color.toHex();
    if (hexColor.length == 9)
      hexColor = hexColor.substring(0, 7); // Convert #RRGGBBAA to #RRGGBB

    return pw.Row(children: [
      if (icon != null) ...[
        pw.SvgImage(svg: icon.replaceAll('{color}', hexColor), height: 8),
        pw.SizedBox(width: 4),
      ],
      pw.Expanded(
        child: pw.Text(value,
            style: pw.TextStyle(
                fontSize: 8,
                color: color,
                fontWeight:
                    isTitle ? pw.FontWeight.bold : pw.FontWeight.normal)),
      )
    ]);
  }

  static pw.Widget _buildLabelValue(String label, String value) {
    PdfColor color = _kValueBlue;
    pw.FontWeight weight = pw.FontWeight.bold;
    String? icon;
    PdfColor iconColor = _kValueBlue;

    final vUpper = value.toUpperCase();
    final lUpper = label.toUpperCase();

    final bool isNegativeValue = vUpper == 'NAO' ||
        vUpper == 'NÃO' ||
        vUpper == 'NADA CONSTA' ||
        vUpper == 'NÃO POSSUI' ||
        vUpper == 'NAO POSSUI' ||
        vUpper == 'SEM RESTRICAO' ||
        vUpper == 'SEM RESTRIÇÃO' ||
        vUpper == 'SEM RESTRICAO DE ROUBO/FURTO' ||
        vUpper == 'FORNECEDOR INDISPONÍVEL' ||
        vUpper == 'FORNECEDOR INDISPONIVEL' ||
        vUpper.contains('NÃO FOI ENCONTRADO') ||
        vUpper.contains('NAO FOI ENCONTRADO') ||
        vUpper.contains('NÃO POSSUI RESTRIÇÃO') ||
        vUpper.contains('VEÍCULO NÃO POSSUÍ INDÍCIO DE SINISTRO') ||
        vUpper == '-';

    if ((lUpper.contains('RENAJUD') || vUpper.contains('RENAJUD')) &&
        !isNegativeValue) {
      color = PdfColor.fromInt(0xFFD67362);
      weight = pw.FontWeight.bold;
      icon = _svgWarning;
      iconColor = PdfColor.fromInt(0xFFD67362);
    } else if ((lUpper.contains('LEILÃO') ||
            lUpper.contains('LEILAO') ||
            lUpper.contains('SINISTRO')) &&
        !isNegativeValue &&
        !vUpper.contains('QUANTIDADE DE PESQUISAS')) {
      color = PdfColor.fromInt(0xFFD67362);
      weight = pw.FontWeight.bold;
      icon = _svgWarning;
      iconColor = PdfColor.fromInt(0xFFD67362);
    } else if ((lUpper.contains('FINANCI') ||
            lUpper.contains('ALIENAÇ') ||
            lUpper.contains('GRAVAME') ||
            lUpper.contains('ARRENDAT')) &&
        !isNegativeValue) {
      color = _kOrange;
      weight = pw.FontWeight.bold;
      iconColor = _kOrange;
    } else if (lUpper == 'CHASSI' ||
        lUpper == 'MOTOR' ||
        lUpper == 'NUMERO DO MOTOR' ||
        lUpper == 'Nº SERIE CHASSI' ||
        lUpper == 'ANO FAB/MOD') {
      color = _kOrange;
      weight = pw.FontWeight.bold;
      if (lUpper != 'ANO FAB/MOD') {
        icon = _svgWrench;
      }
      iconColor = _kOrange;
    } else if ((lUpper.startsWith('RESTRIÇÃO') ||
            lUpper.startsWith('RESTRICAO') ||
            lUpper.startsWith('RESTRIÇÕES') ||
            lUpper.startsWith('RESTRICOES') ||
            lUpper.startsWith('IND. RESTRI') ||
            lUpper == 'RESTRIÇÕES ADMINISTRATIVAS') &&
        !isNegativeValue) {
      color = _kOrange;
      weight = pw.FontWeight.bold;
      iconColor = _kOrange;
    } else if (lUpper == 'ROUBO/FURTO' && vUpper == 'NÃO POSSUI') {
      color = PdfColor.fromInt(0xFFD67362);
      weight = pw.FontWeight.bold;
      icon = _svgWarning;
      iconColor = PdfColor.fromInt(0xFFD67362);
    } else if (vUpper == 'CIRCULACAO' ||
        vUpper == 'EM CIRCULACAO' ||
        vUpper == 'CIRCULAÇÃO' ||
        vUpper == 'VEICULO EM CIRCULACAO' ||
        vUpper == 'NORMAL') {
      color = _kGreen;
      weight = pw.FontWeight.bold;
      icon = _svgCheck;
      iconColor = _kGreen;
    } else if (vUpper.contains('VEICULO NÃO POSSUI RESTRIÇÃO') ||
        vUpper.contains('CHASSI NÃO POSSUÍ IRREGULARIDADES') ||
        vUpper.contains('VEICULO SEM OCORRENCIA DE ROUBO FURTO')) {
      color = _kGreen;
      weight = pw.FontWeight.bold;
      icon = _svgCheck;
      iconColor = _kGreen;
    } else if (vUpper == 'NÃO INFORMADO' &&
        (lUpper == 'SITUAÇÃO CHASSI' ||
            lUpper == 'REMARCAÇÃO CHASSI' ||
            lUpper == 'REMARCACAO CHASSI')) {
      color = _kValueBlue;
      weight = pw.FontWeight.bold;
      iconColor = _kValueBlue;
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label  ',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _kTextDark)),
        pw.Expanded(
            child: pw.Row(children: [
          if (icon != null) ...[
            pw.SvgImage(
                svg: icon.replaceAll('{color}', iconColor.toHex()), height: 7),
            pw.SizedBox(width: 2),
          ],
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 8, color: color, fontWeight: weight)),
          ),
        ])),
      ],
    );
  }

  static List<pw.Widget> _buildSectionBin(Map<String, dynamic> data) {
    return _buildDataGrid([
          [
            'Placa',
            _v(data, ['placa']),
            'Procedência',
            _v(data, ['procedencia'])
          ],
          [
            'Chassi',
            _v(data, ['chassi']),
            'Numero do Motor',
            _v(data, ['numerodomotor', 'motor'])
          ],
          [
            'Renavam',
            _v(data, ['renavam']),
            'Montagem',
            _v(data, ['montagem'])
          ],
          [
            'Cor',
            _v(data, ['cor']),
            'Ano Modelo',
            _v(data, ['anomodelo', 'anoModelo'])
          ],
          [
            'Ano Fabricação',
            _v(data, ['anofabricacao', 'anoFabricacao']),
            'Marca/Modelo',
            _v(data, ['marcamodelo', 'marcaModelo'])
          ],
          [
            'Municipio',
            _v(data, ['municipio', 'cidade']),
            'UF',
            _v(data, ['uf', 'estado'])
          ],
          [
            'Capacidade de passageiros',
            _v(data, [
              'capacidade_passageiros',
              'capacidadepassageiros',
              'lotacao',
              'quantidade_passageiros',
              'quantidadepassageiros',
              'passageiros'
            ]),
            'Combustível',
            _v(data, ['combustivel', 'tipocombustivel'])
          ],
          [
            'Potência',
            _v(data, ['potencia']),
            'Especie',
            _v(data, ['especie'])
          ],
          [
            'Carroceria',
            _v(data, ['carroceria']),
            'Nº Câmbio',
            _v(data, ['cambio', 'ncambio'], fallback: '-')
          ],
          [
            'Capacidade de Carga',
            _v(data, ['capacidade_carga', 'capacidadecarga']),
            'Cilindradas',
            _v(data, ['cilindradas'])
          ],
          [
            'Remarcação do Chassi',
            _v(data, ['remarcacao_chassi', 'remarcacaochassi']),
            'Tipo',
            _v(data, ['tipo', 'tipoveiculo'])
          ],
          [
            'Situação',
            _v(data, ['situacao']),
            'Data última Atualização',
            _v(data, ['data_atualizacao', 'dataatualizacao'])
          ],
          [
            'Emplacamento Eletrônico',
            _v(data, ['emplacamento_eletronico', 'emplacamentoeletronico']),
            'Histórico Roubo e Furto *',
            _findList(data, ['rf']).isNotEmpty 
                ? 'POSSUI OCORRÊNCIA'
                : _v(data, [
                    'historico_roubo_furto',
                    'roubo_furto',
                    'roubofurto',
                    'queixaderoubo'
                  ], fallback: 'Nada Consta')
          ],
        ]);
  }

  static List<pw.Widget> _buildInformacoesRelevantesBin(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Informações Relevantes',
            svgIcon: _svgEye,
            bgColor: _kYellowHeader,
            textColor: _kYellowHeaderDarkText),
        ..._buildDataGrid([
          [
            'Queixa de Roubo e/ou Furto',
            _v(data, ['queixaderoubo', 'roubofurto', 'queixa_roubo'],
                fallback: 'VEICULO NÃO POSSUI RESTRIÇÃO DE ROUBO/FURTO')
          ],
          [
            'Situação',
            _v(data, ['situacao']),
            'Recall',
            _v(data, ['recall'])
          ],
          [
            'Ind. Restrições',
            _v(data, ['ind_restricoes', 'indrestricoes']),
            'Restrição Renajud',
            _v(data, ['restricaorenajud', 'renajud'], fallback: 'NAO')
          ],
          [
            'Restrição RFB',
            _v(data, ['restricaorfb', 'rfb']),
            'Restrição01',
            _v(data, ['restricao1', 'restricoes1', 'restricao01'],
                fallback: 'NADA CONSTA')
          ],
          [
            'Restrição02',
            _v(data, ['restricao2', 'restricoes2', 'restricao02'],
                fallback: 'NADA CONSTA'),
            'Restrição03',
            _v(data, ['restricao3', 'restricoes3', 'restricao03'],
                fallback: 'NADA CONSTA')
          ],
          [
            'Restrição04',
            _v(data, ['restricao4', 'restricoes4', 'restricao04'],
                fallback: 'NADA CONSTA'),
            'Data Limite Restrição Tributária',
            _v(data, ['datalimiterestricaotributaria', 'datalimite'])
          ],
          [
            'Placa Mercosul',
            _v(data, ['placamercosul', 'mercosul'])
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildBaseEstadual(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Base Estadual **', svgIcon: _svgFlag),
        ..._buildDataGrid([
          [
            'Placa',
            _v(data, ['placa']),
            'Procedencia',
            _v(data, ['procedencia'])
          ],
          [
            'Chassi',
            _v(data, ['chassi']),
            'Motor',
            _v(data, ['motor', 'numerodomotor'])
          ],
          [
            'Renavam',
            _v(data, ['renavam']),
            'Data de emissão do CRV',
            _v(data, [
              'dataemissaocrv',
              'emissaocrv',
              'data_emissao_crv',
              'emissao_crv',
              'data_emissao_do_crv',
              'crv_data',
              'data_crv',
              'dataemissao',
              'data_emissao'
            ])
          ],
          [
            'Indica débitos IPVA licenciamento',
            _v(data, [
              'debitosipva',
              'indica_debitos_ipva',
              'indicadebitosipva',
              'ipva_licenciamento',
              'debito_ipva',
              'debitos_ipva',
              'indicadebitos',
              'debitos',
              'debito',
              'debitoipva'
            ]),
            'Indica débitos em multas',
            _v(data, [
              'debitosmultas',
              'indica_debitos_multas',
              'indicadebitosmultas',
              'debito_multas',
              'debitos_multas',
              'debitomultas',
              'multas',
              'multa'
            ])
          ],
          [
            'Cor',
            _v(data, ['cor']),
            'ANO FAB/MOD',
            '${_v(data, ['anofabricacao', 'anoFabricacao'])}/${_v(data, [
                  'anomodelo',
                  'anoModelo'
                ])}'
          ],
          [
            'Município/UF',
            '${_v(data, ['municipio', 'cidade'])}/${_v(data, [
                  'uf',
                  'estado'
                ])}',
            'Marca',
            _v(data, ['marcamodelo', 'marca'])
          ],
          [
            'Combustível',
            _v(data, ['combustivel', 'tipocombustivel']),
            'Potência',
            _v(data, ['potencia'])
          ],
          [
            'Capacidade de carga',
            _v(data, ['capacidadecarga', 'capacidade_carga']),
            'Espécie',
            _v(data, ['especie'])
          ],
          [
            'Carroceria',
            _v(data, ['carroceria']),
            'Tipo de carroceria',
            _v(data, [
              'tipocarroceria',
              'tipo_carroceria',
              'carroceriatipo',
              'carroceria_tipo',
              'descricaocarroceria',
              'descricao_carroceria'
            ])
          ],
          [
            'Câmbio',
            _v(data, ['cambio']),
            'Eixos',
            _v(data, ['eixos', 'quantidadeeixos', 'qtdeixos', 'numeixos'])
          ],
          [
            'Cilindradas',
            _v(data, ['cilindradas']),
            'Situação chassi',
            _v(data, ['situacaochassi', 'situacao_chassi'])
          ],
          [
            'PBT',
            _formatTons(_v(data, ['pbt'])),
            'Categoria',
            _v(data, ['categoria'])
          ],
          [
            'Tipo do veículo',
            _v(data, ['tipoveiculo', 'tipo_veiculo']),
            'CMT',
            _formatTons(_v(data, ['cmt']))
          ],
          [
            'Situação',
            _v(data, ['situacao']),
            'Roubo/furto',
            _v(data, ['roubofurto', 'roubo_furto'], fallback: 'Não Possui')
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildInformacoesRelevantesEstadual(
      Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Informações Relevantes',
            svgIcon: _svgEye,
            bgColor: _kYellowHeader,
            textColor: _kYellowHeaderDarkText),
        ..._buildDataGrid([
          [
            'Comunicação de Venda',
            _v(data, ['comunicacaovenda', 'comunicadovenda'], fallback: 'Não'),
            'DPVAT',
            _v(data, ['dpvat'])
          ],
          [
            'IPVA',
            _v(data, ['ipva']),
            'DERSA',
            _v(data, ['dersa'])
          ],
          [
            'DER',
            _v(data, ['der']),
            'DETRAN',
            _v(data, ['detran'])
          ],
          [
            'CETESB',
            _v(data, ['cetesb']),
            'Municipais',
            _v(data, ['municipais'])
          ],
          [
            'Polícia Rodoviária Federal',
            _v(data, ['prf', 'policiarodoviariafederal']),
            'Débito Licenciamento',
            _v(data, ['debitolicenciamento', 'licenciamento'])
          ],
          [
            'Data Licenciamento',
            _v(data, ['datalicenciamento']),
            'Exercício Licenciamento',
            _v(data, ['exerciciolicenciamento'])
          ],
          [
            'Débito Multas',
            _v(data, ['debitomultas', 'multas']),
            'Restrições Administrativas',
            _v(data, ['restricoesadministrativas', 'restricaoadministrativa'])
          ],
          [
            'Restrições BloqueioGuincho',
            _v(data, ['restricoesbloqueioguincho', 'bloqueioguincho']),
            'Restrições Furto',
            _v(data, ['restricoesfurto'], fallback: 'Não Possui')
          ],
          [
            'Restrições InspAmbiental',
            _v(data, ['restricoesinspambiental', 'inspambiental']),
            'Restrições Judicial',
            _v(data, ['restricoesjudicial', 'restricaojudicial'])
          ],
          [
            'Restrições Renajud',
            _v(data, ['restricoesrenajud', 'restricaorenajud'],
                fallback: 'Não Possui'),
            'Restrições Tributária',
            _v(data, ['restricoestributaria', 'restricaotributaria'])
          ],
          [
            'Restrições Financeiras',
            _v(data, ['restricoesfinanceiras', 'restricaofinanceira']),
            'Restrição 1',
            _v(data, ['restricao1_br', 'restricaobaseagregadores1'],
                fallback: 'SEM RESTRICAO'),
            'Restrição 2',
            _v(data, ['restricao2_br', 'restricaobaseagregadores2'],
                fallback: 'SEM RESTRICAO')
          ],
          [
            'Restrição 3',
            _v(data, ['restricao3_br', 'restricaobaseagregadores3'],
                fallback: 'SEM RESTRICAO'),
            'Restrição 4',
            _v(data, ['restricao4_br', 'restricaobaseagregadores4'],
                fallback: 'SEM RESTRICAO')
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildProprietario(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Informações de Proprietário', svgIcon: _svgPerson),
        ..._buildDataGrid([
          [
            'Anterior',
            _v(data, ['proprietarioanterior', 'nomeproprietarioanterior']),
            'Atual',
            _v(data, [
              'proprietario',
              'nomeproprietario',
              'proprietario_atual',
              'nome_proprietario_atual',
              'possuidor'
            ])
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildChassi(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Decodificador de Chassi', svgIcon: _svgWrench),
        ..._buildDataGrid([
          ['CHASSI NÃO POSSUÍ IRREGULARIDADES'],
          [
            'Chassi',
            _v(data, ['chassi']),
            'ANO MOD',
            _v(data, ['anomodelo', 'anoModelo'])
          ],
          [
            'Combustível',
            _v(data, ['combustivel']),
            'Marca',
            _v(data, ['marca'])
          ],
          [
            'Modelo',
            _v(data, ['modelo']),
            'Veículo',
            _v(data, ['veiculo'])
          ],
          [
            'Versão',
            _v(data, ['versao']),
            'Motor',
            _v(data, ['chassi_motor', 'motor', 'numerodomotor'])
          ],
          [
            'COD. Categoria',
            _v(data, ['codigocategoria', 'codcategoria']),
            'Categoria',
            _v(data, [
              'categoria_chassi',
              'chassi_categoria',
              'chassicategoria',
              'categoria'
            ])
          ],
          [
            'Local fabricação',
            _v(data, ['chassi_local', 'localfabricacao']),
            'Origem',
            _v(data, ['origem'])
          ],
          [
            'País',
            _v(data, ['chassi_pais', 'pais']),
            'Região',
            _v(data, ['chassi_regiao', 'regiao'])
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildPrecificador(Map<String, dynamic> data) {
    List<dynamic> fipes = [];
    if (data['fipe'] is List) {
      fipes = data['fipe'] as List<dynamic>;
    } else if (data['fipes'] is List) {
      fipes = data['fipes'] as List<dynamic>;
    } else if (data['precificador'] is List) {
      fipes = data['precificador'] as List<dynamic>;
    } else if (data['fipe'] is Map) {
      fipes = [data['fipe']];
    } else {
      fipes = [data]; // Fallback to root data
    }

    List<pw.Widget> fipeRows = [];
    for (var i = 0; i < fipes.length; i++) {
      var f = fipes[i] is Map ? (fipes[i] as Map<String, dynamic>) : data;
      fipeRows.add(
        pw.Container(
          color: i % 2 == 0 ? PdfColors.white : _kBlueLight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            children: [
              pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                      _v(f, ['codigo_fipe', 'codigofipe', 'fipe_codigo'],
                          fallback: '-'),
                      style:
                          const pw.TextStyle(fontSize: 8, color: _kTextDark))),
              pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                      _v(
                          f,
                          [
                            'combustivel_fipe',
                            'fipe_combustivel',
                            'combustivel'
                          ],
                          fallback: '-'),
                      style:
                          const pw.TextStyle(fontSize: 8, color: _kTextDark))),
              pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                      _v(f, ['marca_fipe', 'fipe_marca', 'marca'],
                          fallback: '-'),
                      style:
                          const pw.TextStyle(fontSize: 8, color: _kTextDark))),
              pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                      _v(f, ['modelo_fipe', 'fipe_modelo', 'modelo'],
                          fallback: '-'),
                      style:
                          const pw.TextStyle(fontSize: 8, color: _kTextDark))),
              pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                      _v(f, ['valor_fipe', 'fipe_valor', 'valorfipe', 'valor'],
                          fallback: '-'),
                      style:
                          const pw.TextStyle(fontSize: 8, color: _kTextDark))),
            ],
          ),
        ),
      );
    }

    return [
      _buildSectionHeader('Precificador I - FIPE', svgIcon: _svgChart),
      pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.5)),
        child: pw.Column(
          children: [
            pw.Container(
              color: _kBlueLight,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Código',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _kTextDark))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Combustível',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _kTextDark))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Marca',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _kTextDark))),
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text('Modelo',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _kTextDark))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Valor R\$',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: _kTextDark))),
                ],
              ),
            ),
            ...fipeRows,
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildHistoricoLaudos(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('Histórico de Laudos', svgIcon: _svgDocument),
        ..._buildDataGrid([
          [
            _v(data, ['historicolaudos', 'laudos'],
                fallback: 'VEÍCULO NÃO POSSUÍ LAUDO EM NOSSA PLATAFORMA')
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildSenatranInfo(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('SENATRAN Detalhado Informações - Online',
            svgIcon: _svgCar),
        ..._buildDataGrid([
          [
            'Placa',
            _v(data, ['placa']),
            'Renavam',
            _v(data, ['renavam'])
          ],
          [
            'Tipo do proprietario',
            _v(data, ['tipoproprietario']),
            'Documento Proprietario',
            _v(data, ['documentoproprietario', 'documento_proprietario'])
          ],
          [
            'Proprietario',
            _v(data, ['proprietario', 'nomeproprietario']),
            'Chassi',
            _v(data, ['chassi'])
          ],
          [
            'Tipo',
            _v(data, ['tipo', 'tipoveiculo']),
            'Espécie',
            _v(data, ['especie'])
          ],
          [
            'Numero Carroceria',
            _v(data, ['numerocarroceria']),
            'Tipo da Carroceria',
            _v(data, [
              'tipocarroceria',
              'tipo_carroceria',
              'carroceriatipo',
              'carroceria_tipo',
              'descricaocarroceria',
              'descricao_carroceria'
            ])
          ],
          [
            'Categoria',
            _v(data, ['categoria']),
            'Combustível',
            _v(data, ['combustivel'])
          ],
          [
            'Marca / Modelo',
            _v(data, ['marcamodelo']),
            'Cambio',
            _v(data, ['cambio'])
          ],
          [
            'Motor',
            _v(data, ['motor', 'numerodomotor']),
            'Ano de Fabricacao',
            _v(data, ['anofabricacao'])
          ],
          [
            'Ano de Modelo',
            _v(data, ['anomodelo']),
            'Cor',
            _v(data, ['cor'])
          ],
          [
            'Lotação',
            _v(data, [
              'lotacao',
              'capacidade_passageiros',
              'capacidadepassageiros',
              'quantidade_passageiros',
              'quantidadepassageiros',
              'passageiros'
            ]),
            'Potencia',
            _v(data, ['potencia'])
          ],
          [
            'Cilindradas',
            _v(data, ['cilindradas']),
            'Tipo de arrendatário',
            _v(data, ['tipoarrendatario'])
          ],
          [
            'Nome do Arrendatario',
            _v(data, ['nomearrendatario']),
            'Documento do arrendatario',
            _v(data, ['documentoarrendatario'])
          ],
          [
            'Procedência',
            _v(data, ['procedencia']),
            'Nº Serie Chassi',
            _v(data, ['serieschassi', 'seriechassi'])
          ],
          [
            'CMC',
            _v(data, ['cmc']),
            'CMT',
            _v(data, ['cmt'])
          ],
          [
            'PBT',
            _v(data, ['pbt']),
            'Placa novo modelo',
            _v(data, ['placanovomodelo', 'mercosul'])
          ],
          [
            'Situação',
            _v(data, ['situacao']),
            'Remarcação Chassi',
            _v(data, ['remarcacaochassi'])
          ],
          [
            'Eixo Auxiliar',
            _v(data, ['eixoauxiliar', 'eixo_auxiliar']),
            'Eixo Traseiro',
            _v(data, ['eixotraseiro', 'eixo_traseiro'])
          ],
          [
            'Município de Emplacamento',
            _v(data, ['municipioemplacamento', 'municipio_emplacamento']),
            'Quantidade de eixos',
            _v(data, ['quantidadeeixos', 'quantidade_eixos', 'eixos', 'qtdeixos', 'numeixos'])
          ],
          [
            'UF de jurisdição',
            _v(data, ['ufjurisdicao', 'uf_jurisdicao']),
            'Data de emissão CRV',
            _v(data, ['dataemissaocrv', 'data_emissao_crv'])
          ],
          [
            'Data Ultima Atualizacao',
            _v(data, [
              'dataultimaatualizacao',
              'data_ultima_atualizacao',
              'data_atualizacao'
            ]),
            'Natureza Faturado',
            _v(data, ['naturezafaturado', 'natureza_faturado'])
          ],
          [
            'UF Faturado',
            _v(data, ['uffaturado', 'uf_faturado']),
            'Natureza do importador',
            _v(data, ['naturezaimportador', 'natureza_importador'])
          ],
          [
            'Documento do importandor',
            _v(data, ['documentoimportador', 'documento_importador']),
            'País tranferência',
            _v(data, ['paistransferencia', 'pais_transferencia'])
          ],
          [
            'Documento do proprietário indicado',
            _v(data, [
              'documentoproprietarioindicado',
              'documento_proprietario_indicado'
            ]),
            'Declaração de importação',
            _v(data, ['declaracaoimportacao', 'declaracao_importacao'])
          ],
          [
            'Identificação do faturamento',
            _v(data, ['identificacaofaturamento', 'identificacao_faturamento']),
            'Identificação do importador',
            _v(data, ['identificacaoimportador', 'identificacao_importador'])
          ],
          [
            'Possuidor',
            'Nome: ' +
                _v(data, ['nomepossuidor', 'nome_possuidor'], fallback: '-') +
                '\nDocumento: ' +
                _v(data, ['documentoposuidort', 'documento_possuidor'],
                    fallback: '-'),
            'Registro Aduaneiro',
            _v(data, ['registroaduaneiro', 'registro_aduaneiro'])
          ],
          [
            'Permite Baixar CRV Digital?',
            _v(data, ['permitebaixarcrvdigital', 'crv_digital'],
                fallback: 'Não'),
            '',
            ''
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildSenatranRestricoes(Map<String, dynamic> data) {
    return [
        _buildSectionHeader('SENATRAN Detalhado Restrições - Online',
            svgIcon: _svgCar),
        ..._buildDataGrid([
          [
            'Possui Leilão',
            _v(data, ['possuileilao', 'leilao'], fallback: 'Não'),
            'Possui Multa Renainf',
            _v(data, ['possuimultarenainf', 'multarenainf'])
          ],
          [
            'Possui Pendência de emissão',
            _v(data, ['pendenciaemissao'], fallback: 'Não'),
            'Possui restrição RENAJUD',
            _v(data, ['possuirestricaorenajud', 'renajud'], fallback: 'Não')
          ],
          [
            'Possui Restrição RFB',
            _v(data, ['possuirestricaorfb', 'rfb']),
            'Órgão RFB',
            _v(data, ['orgaorfb'])
          ],
          [
            'Restricao 1',
            _v(data, ['restricaosenatran1'], fallback: '- SEM RESTRICAO'),
            'Restricao 2',
            _v(data, ['restricaosenatran2'], fallback: '- SEM RESTRICAO')
          ],
          [
            'Restricao 3',
            _v(data, ['restricaosenatran3'], fallback: '- SEM RESTRICAO'),
            'Restricao 4',
            _v(data, ['restricaosenatran4'], fallback: '- SEM RESTRICAO')
          ],
          [
            'Alarme',
            _v(data, ['alarme'], fallback: 'Não'),
            '',
            ''
          ],
        ]),
    ];
  }

  static List<pw.Widget> _buildDetalhesComplementares(
      Map<String, dynamic> data) {
    return [
      _buildSectionHeader('Certificados de seguro de veículo emitidos'),
      ..._buildDataGrid([
        [
          'Número CSV',
          _v(
              data,
              [
                'numerocsv',
                'numero_csv',
                'csv',
                'certificadosseguro',
                'seguros'
              ],
              fallback: 'Nenhum registro encontrado.')
        ]
      ]),

      ..._buildHistoricoRouboFurto(data),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Detalhes de Multa Renainf'),
      ..._buildDataGrid([
        [
          _v(data, ['multasrenainfdetalhes', 'multas_renainf'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Comunicado de Venda - Online', svgIcon: _svgMoney),
      ..._buildDataGrid([
        [
          'Existe comunicação de venda ativa?',
          _v(data, ['comunicadovenda', 'comunicacaovenda'], fallback: 'Sim'),
          'Existe multa Renainf?',
          _v(data, ['existemultarenainf'], fallback: 'Sim')
        ],
        [
          'Placa',
          _v(data, ['placa']),
          'Código RENAVAM',
          _v(data, ['renavam'])
        ],
        [
          'CPF/CNPJ do Proprietário',
          _v(data, ['cpfcnpjproprietario', 'documentoproprietario']),
          'Data da Venda',
          _v(data, ['datavenda'])
        ],
        [
          'Data do Registro da Comunicação de Venda',
          _v(data, ['dataregistrocomunicacao']),
          'CPF/CNPJ do Comprador',
          _v(data, ['documentocomprador'])
        ],
        [
          'Nome do Comprador',
          _v(data, ['nomecomprador']),
          '',
          ''
        ],
      ]),
      pw.SizedBox(height: 10),
      ..._buildRecallTable(data),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Multas de Transito - DNIT', svgIcon: _svgFlag),
      ..._buildDataGrid([
        [
          _v(data, ['multasdnit', 'dnit'],
              fallback: 'VEICULO NÃO POSSUI INFORMAÇÕES NO DNIT')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('SSP - Cortesia', svgIcon: _svgBuilding),
      ..._buildDataGrid([
        ['Dados Veículo'],
        [
          'Placa',
          _v(data, ['placa']),
          'Marca / Modelo',
          _v(data, ['marcamodelo'])
        ],
        [
          'Cor',
          _v(data, ['cor']),
          'Renavam',
          _v(data, ['renavam'])
        ],
        [
          'Ano fabricação',
          _v(data, ['anofabricacao']),
          'Chassi',
          _v(data, ['chassi'])
        ],
        [
          'Ano modelo',
          _v(data, ['anomodelo']),
          'Tipo',
          _v(data, ['tipoveiculo'])
        ],
        [
          'Combustível',
          _v(data, ['combustivel']),
          '',
          ''
        ],
        ['Multas'],
        [
          _v(data, ['multasssp', 'multas_ssp'],
              fallback: 'Nenhum registro encontrado.')
        ],
        ['IPVA'],
        [
          _v(data, ['ipvasssp', 'ipva_ssp'],
              fallback: 'Nenhum registro encontrado.')
        ],
        ['Licenciamento'],
        [
          _v(data, ['licenciamentossp', 'licenciamento_ssp'],
              fallback: 'Nenhum registro encontrado.')
        ],
        ['Vistorias'],
        ..._getVistoriasRows(data),
        ['Restrições'],
        [
          'Bloqueio de furto/roubo',
          _v(data, ['ssp_bloqueio_furto', 'restricoesfurto_ssp'],
              fallback: 'Nada consta'),
          'Restrição tributária',
          _v(data, ['ssp_restricao_tributaria'], fallback: 'Nada consta')
        ],
        [
          'Restrição financeira',
          _v(data, ['ssp_restricao_financeira', 'restricaofinanceira'],
              fallback: 'Nada consta'),
          'Restrição administrativa',
          _v(data, ['ssp_restricao_administrativa'], fallback: 'Nada consta')
        ],
        [
          'Restrição judicial',
          _v(data, ['ssp_restricao_judicial'], fallback: 'Nada consta'),
          'Restrição por veículo guinchado',
          _v(data, ['ssp_restricao_guincho'], fallback: 'Nada consta')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('IPVA - Secretaria de Fazenda',
          svgIcon: _svgBuilding),
      ..._buildDataGrid([
        [
          'Placa',
          _v(data, ['placa']),
          'Renavam',
          _v(data, ['renavam'])
        ],
        [
          'Espécie',
          _v(data, ['especie']),
          'Categoria',
          _v(data, ['categoria'])
        ],
        [
          'Marca',
          _v(data, ['marcamodelo']),
          'Tipo',
          _v(data, ['tipoveiculo'])
        ],
        [
          'Faixa IPVA',
          _v(data, ['faixaipva']),
          'Passageiros',
          _v(data, [
            'lotacao',
            'capacidade_passageiros',
            'capacidadepassageiros',
            'quantidade_passageiros',
            'quantidadepassageiros',
            'passageiros'
          ])
        ],
        [
          'Ano de fabricação',
          _v(data, ['anofabricacao']),
          'Carroceria',
          _v(data, ['carroceria'])
        ],
        [
          'Município',
          _v(data, ['municipio']),
          'Último licenciamento',
          _v(data, ['ultimolicenciamento'])
        ],
        [
          'Combustível',
          _v(data, ['combustivel']),
          'Data da Venda',
          _v(data, ['datavenda_ipva'], fallback: '-')
        ],
        [
          'Data da Comunicação',
          _v(data, ['datacomunicacao_ipva'], fallback: '-'),
          '',
          ''
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('DPVATs'),
      ..._buildDataGrid([
        [
          _v(data, ['dpvat_detalhes'], fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      ..._buildIpvaSefazTable(data),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Pagamentos de Débitos'),
      ..._buildDataGrid([
        [
          _v(data, ['pagamentos_debitos'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('IPVA não inscritos'),
      ..._buildDataGrid([
        [
          _v(data, ['ipva_nao_inscritos'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Licenciamentos'),
      ..._buildDataGrid([
        [
          _v(data, ['licenciamentos_detalhes'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
    ];
  }

  static List<pw.Widget> _buildSecoesFinais(Map<String, dynamic> data) {
    return [
      pw.SizedBox(height: 10),
      _buildSectionHeader('Pagamentos Efetuados 2026'),
      ..._buildDataGrid([
        [
          _v(data, ['pagamentos_efetuados', 'pagamentos_efetuados_2026'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Débitos Inscritos na Dívida Ativa'),
      ..._buildDataGrid([
        [
          _v(data, ['divida_ativa', 'dividaativa'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      ..._buildMultasTable(data, 'Multas Detalhadas'),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Sinistro - Base On-line', svgIcon: _svgThermometer),
      ..._buildDataGrid([
        [
          _v(data, ['sinistro_base'], fallback: 'FORNECEDOR INDISPONÍVEL')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Ofertas de Leilão', svgIcon: _svgHammer),
      ..._buildDataGrid([
        [
          _v(data, ['ofertasleilao1', 'leilao1', 'leilao'],
              fallback:
                  'NÃO FOI ENCONTRADO NENHUMA OCORRÊNCIA DE LEILÃO NA BASE 1')
        ],
        [
          _v(data, ['pesquisasleilao'],
              fallback: 'QUANTIDADE DE PESQUISAS NOS ÚLTIMOS MESES: 0')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Ofertas de Leilão *', svgIcon: _svgHammer),
      ..._buildDataGrid([
        [
          _v(data, ['ofertasleilao2', 'leilao2'],
              fallback:
                  'NÃO FOI ENCONTRADO NENHUMA OCORRÊNCIA DE LEILÃO NA BASE 2')
        ],
      ]),
      pw.Container(
          width: double.infinity,
          color: _kBlueLight,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
              'As informações de leilões são captadas por empresas privadas e não de órgãos públicos como Detran e Denatran. Essas empresas não obtém 100% de informações de leilões. Sendo assim não há destas empresas garantia pelas informações de captação de leilão.',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.black),
              textAlign: pw.TextAlign.justify)),
      pw.SizedBox(height: 10),
      _buildSectionHeader(
          'Leilão Corporativo - Remarketing Automotivo / Venda Direta (Cortesia)',
          svgIcon: _svgHammer),
      ..._buildDataGrid([
        [
          _v(data, ['remarketing'],
              fallback:
                  'NÃO FOI ENCONTRADO NENHUMA OCORRÊNCIA DE REMARKETING AUTOMOTIVO')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('[OP] Análise Técnica de Informações',
          svgIcon: _svgThermometer),
      ..._buildDataGrid([
        [
          _v(data, ['analisetecnica', 'sinistro'],
              fallback: 'VEÍCULO NÃO POSSUÍ INDÍCIO DE SINISTRO')
        ],
      ]),
      ..._buildProcessos(data),
      ..._buildImpedimentos(data),
      pw.Container(
          width: double.infinity,
          color: _kBlueLight,
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
              'Estas informações são confidenciais e deverão ser utilizadas exclusivamente para a orientação das transações comerciais. A responsabilidade da contratada limita-se a transmitir fielmente as informações oriundas das bases de Negativação, Protesto Cartoriais e sobre veículos automotores registrados em base de Dados públicas e privadas detentoras das informações. O levantamento das informações veiculares via consulta eletrônica jamais pode substituir a consulta do órgão oficial. Devido as informações DPVAT (Histórico de Proprietários), que ficou indisponível desde 12/07/2018 no mercado de informações veiculares e o Sinistro de Indenização Integral fornecido pela FENASEG/CNSEG desde 18/07/2018, não há como a empresa vistoriadora e fornecedor da consulta, se responsabilizar por informações de Sinistro de Indenização Integral.',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.black),
              textAlign: pw.TextAlign.justify)),
    ];
  }

  static List<dynamic> _findList(Map<String, dynamic> data, List<String> keys) {
    List<dynamic>? foundList;
    void searchList(dynamic node, String targetKey) {
      if (node is Map) {
        final lowerTarget = targetKey.toLowerCase();
        for (var entry in node.entries) {
          if (entry.key.toString().toLowerCase() == lowerTarget) {
            if (entry.value is List) {
              foundList = entry.value as List<dynamic>;
              return;
            } else if (entry.value is String) {
              try {
                final parsed = jsonDecode(entry.value);
                if (parsed is List) {
                  foundList = parsed;
                  return;
                }
              } catch (_) {}
            }
          }
        }
        if (foundList == null) {
          for (var entry in node.entries) {
            searchList(entry.value, targetKey);
            if (foundList != null) return;
          }
        }
      } else if (node is Iterable) {
        for (var item in node) {
          searchList(item, targetKey);
          if (foundList != null) return;
        }
      }
    }

    for (var k in keys) {
      searchList(data, k);
      if (foundList != null && foundList!.isNotEmpty) return foundList!;
    }
    return [];
  }

  static List<pw.Widget> _buildGenericGrid(List<List<String>> rows, List<int> flexes) {
    return List.generate(rows.length, (index) {
      final isHeader = index == 0;
      final isEven = index % 2 == 0;
      final rowData = rows[index];

      return pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.5),
            color: isHeader
                ? _kBlueLight
                : (isEven ? PdfColors.white : _kBlueLight)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: List.generate(rowData.length, (colIndex) {
            return pw.Expanded(
                flex: flexes.length > colIndex ? flexes[colIndex] : 1,
                child: pw.Text(rowData[colIndex],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: isHeader
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _kTextDark)));
          }),
        ),
      );
    });
  }

  static List<pw.Widget> _buildRecallTable(Map<String, dynamic> data) {
    List<dynamic> recalls = _findList(data, ['recall', 'recalls', 'lista_recall']);
    
    if (recalls.isEmpty) {
      return [
        _buildSectionHeader('Recall', svgIcon: _svgWrench),
        ..._buildDataGrid([
          ['O VEÍCULO PESQUISADO NÃO POSSUI RECALL PENDENTE OU NÃO PERTENCE A NENHUM RECALL DIVULGADO PELAS MONTADORAS.']
        ]),
      ];
    }

    List<List<String>> rows = [
      ['Recall', 'Descrição', 'Data de registro']
    ];

    for (var item in recalls) {
      if (item is Map) {
        final codigo = item['codigo'] ?? item['numero_campanha'] ?? item['campanha'] ?? '-';
        final descricao = item['descricao'] ?? item['motivo'] ?? '-';
        final dataReg = item['data_registro'] ?? item['data'] ?? '-';
        rows.add([
          codigo.toString(),
          descricao.toString(),
          dataReg.toString()
        ]);
      }
    }

    return [
      _buildSectionHeader('Recall', svgIcon: _svgWrench),
      ..._buildGenericGrid(rows, [2, 4, 2]),
    ];
  }

  static List<pw.Widget> _buildMultasTable(Map<String, dynamic> data, String title) {
    List<dynamic> multas = [];
    if (data['multas'] is List && (data['multas'] as List).isNotEmpty) {
      multas = data['multas'] as List;
    } else {
      multas = _findList(data, ['multas', 'multa', 'infracoes']);
    }
    
    if (multas.isEmpty) {
      return [
        _buildSectionHeader(title),
        ..._buildDataGrid([
          ['Nenhum registro encontrado.']
        ]),
      ];
    }

    List<List<String>> rows = [
      ['Num.Auto/Situação', 'Descrição', 'Local/Complemento', 'Valor']
    ];

    for (var item in multas) {
      if (item is Map) {
        final auto = item['autoInfracao'] ?? item['auto_infracao'] ?? item['auto'] ?? '-';
        final renainf = item['autoRenainf'] ?? item['renainf'] ?? '-';
        final situacao = item['situacao'] ?? item['status'] ?? '-';
        
        final autoText = '$auto\n(Renainf: $renainf)\nSituação: $situacao';
        final descricao = item['descricao'] ?? item['motivo'] ?? '-';
        
        final dataInfracao = item['dataInfracao'] ?? item['data'] ?? '-';
        final local = item['local'] ?? '-';
        final localText = 'Em $dataInfracao\n$local';
        
        final valor = item['valor'] ?? '-';
        final valorText = valor.toString().startsWith('R\$') ? valor.toString() : 'R\$ $valor';

        rows.add([
          autoText,
          descricao.toString(),
          localText,
          valorText
        ]);
      }
    }

    return [
      _buildSectionHeader(title),
      ..._buildGenericGrid(rows, [3, 4, 3, 2]),
    ];
  }

  static List<pw.Widget> _buildProcessos(Map<String, dynamic> data) {
    final processos = _findList(data, ['ultimo_processo', 'processo', 'processos']);
    if (processos.isEmpty) return [];

    List<List<String>> rows = [
      ['Processo', 'Interessado', 'Serviço', 'Operação']
    ];

    for (var item in processos) {
      if (item is Map) {
        rows.add([
          (item['processo'] ?? '-').toString(),
          (item['interessado'] ?? '-').toString(),
          (item['servico'] ?? '-').toString(),
          (item['operacao'] ?? '-').toString(),
        ]);
      }
    }

    return [
      _buildSectionHeader('Último Processo', svgIcon: _svgDocument),
      ..._buildGenericGrid(rows, [2, 3, 3, 3]),
      pw.SizedBox(height: 10),
    ];
  }

  static List<pw.Widget> _buildImpedimentos(Map<String, dynamic> data) {
    final impedimentos = _findList(data, ['historico_impedimentos', 'impedimentos']);
    if (impedimentos.isEmpty) return [];

    List<pw.Widget> widgets = [];
    int idx = 1;
    for (var item in impedimentos) {
      if (item is Map) {
        widgets.add(_buildSectionHeader('Histórico Impedimentos Veículo #$idx'));
        
        List<List<String>> grid = [];
        for (var key in item.keys) {
           grid.add([key, item[key].toString()]);
        }
        
        widgets.addAll(_buildDataGrid(grid));
        widgets.add(pw.SizedBox(height: 10));
        idx++;
      }
    }
    return widgets;
  }

  static List<pw.Widget> _buildIpvaSefazTable(Map<String, dynamic> data) {
    List<dynamic>? ipvaList;

    void searchIpvaList(dynamic node) {
      if (node is Map) {
        if (node['ipva'] is List) {
          ipvaList = node['ipva'] as List<dynamic>;
          return;
        }
        for (var v in node.values) {
          searchIpvaList(v);
          if (ipvaList != null) return;
        }
      } else if (node is List) {
        for (var item in node) {
          searchIpvaList(item);
          if (ipvaList != null) return;
        }
      }
    }

    searchIpvaList(data);

    final temValor = _v(data, ['ipva_valor', 'valor'], fallback: 'NÃO_TEM') != 'NÃO_TEM';
    final temBase = _v(data, ['ipva_basecalculo', 'basecalculo'], fallback: 'NÃO_TEM') != 'NÃO_TEM';
    final temApurado = _v(data, ['ipva_apurado', 'apurado'], fallback: 'NÃO_TEM') != 'NÃO_TEM';

    if (ipvaList == null || ipvaList!.isEmpty) {
      if (!temValor && !temBase && !temApurado) {
        return [];
      }

      return [
        pw.SizedBox(height: 10),
        _buildSectionHeader('IPVA (SEFAZ)'),
        ..._buildDataGrid([
          [
          'Base calculo',
          _v(data, ['ipva_basecalculo', 'basecalculo'], fallback: 'R\$ 0,00'),
          'Aliquota',
          _v(data, ['ipva_aliquota', 'aliquota'], fallback: 'R\$ 0,00')
        ],
        [
          'Apurado',
          _v(data, ['ipva_apurado', 'apurado'], fallback: 'R\$ 0,00'),
          'Credito Nota Fiscal Paulista',
          _v(data, ['ipva_nfp', 'credito_nfp', 'nfp'], fallback: 'R\$ 0,00')
        ],
        [
          'Devido',
          _v(data, ['ipva_devido', 'devido'], fallback: 'R\$ 0,00'),
          'Pagamento efetuado',
          _v(data, ['ipva_pagamento', 'pagamento_efetuado', 'pagamento'],
              fallback: 'R\$ 0,00')
        ],
        [
          'Descontos',
          _v(data, ['ipva_desconto', 'descontos', 'desconto'],
              fallback: 'R\$ 0,00'),
          'Saldo devido',
          _v(data, ['ipva_saldo', 'saldo_devido', 'saldo'],
              fallback: 'R\$ 0,00')
        ],
        [
          'Acrescimos',
          _v(data, ['ipva_acrescimo', 'acrescimos', 'acrescimo'],
              fallback: 'R\$ 0,00'),
          'Competência',
          _v(data, ['ipva_competencia', 'competencia'], fallback: '-')
        ],
        [
          'Valor',
          _v(data, ['ipva_valor', 'valor'], fallback: 'R\$ 0,00'),
          '',
          ''
        ],
      ])];
    }

    List<List<String>> rows = [
      [
        'Parcela / Tributo',
        'Situação',
        'Vencimento',
        'Valor Total',
        'Data Pagamento'
      ]
    ];

    for (var item in ipvaList!) {
      if (item is Map) {
        final tributo = item['tributo-parcela'] ??
            item['tributo'] ??
            item['descricao'] ??
            '-';
        final situacao = item['situacao'] ?? item['status'] ?? '-';
        final vencimento = item['vencimento'] ?? '-';
        final valor = item['valor-total'] ?? item['valor'] ?? '-';
        final dataPagto =
            item['data-pagamento'] ?? item['datapagamento'] ?? '-';
        rows.add([
          tributo.toString(),
          situacao.toString(),
          vencimento.toString(),
          valor.toString().startsWith('R\$')
              ? valor.toString()
              : 'R\$ ${valor.toString()}',
          (dataPagto != null && dataPagto.toString() != 'null')
              ? dataPagto.toString()
              : '-'
        ]);
      }
    }

    return [
      pw.SizedBox(height: 10),
      _buildSectionHeader('IPVA (SEFAZ)'),
      ..._buildIpvaCustomGrid(rows)
    ];
  }

  static List<pw.Widget> _buildIpvaCustomGrid(List<List<String>> rows) {
    return List.generate(rows.length, (index) {
      final isHeader = index == 0;
      final isEven = index % 2 == 0;
      final rowData = rows[index];

      return pw.Container(
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder, width: 0.5),
            color: isHeader
                ? _kBlueLight
                : (isEven ? PdfColors.white : _kBlueLight)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Row(
          children: [
            pw.Expanded(
                flex: 3,
                child: pw.Text(rowData[0],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: isHeader
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _kTextDark))),
            pw.Expanded(
                flex: 2,
                child: pw.Text(rowData[1],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: isHeader
                            ? _kTextDark
                            : (rowData[1].toUpperCase() == 'PAGO'
                                ? _kGreen
                                : (rowData[1].toUpperCase() == 'PENDENTE'
                                    ? _kOrange
                                    : _kTextDark))))),
            pw.Expanded(
                flex: 2,
                child: pw.Text(rowData[2],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: isHeader
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _kTextDark))),
            pw.Expanded(
                flex: 2,
                child: pw.Text(rowData[3],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: isHeader
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _kTextDark))),
            pw.Expanded(
                flex: 2,
                child: pw.Text(rowData[4],
                    style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: isHeader
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                        color: _kTextDark))),
          ],
        ),
      );
    });
  }

  static List<pw.Widget> _buildHistoricoRouboFurto(Map<String, dynamic> data) {
    List<dynamic> rf = _findList(data, ['rf']);
    
    if (rf.isEmpty) {
      return [];
    }

    List<List<String>> rows = [
      ['Data', 'Categoria', 'Município/UF', 'B.O']
    ];

    for (var item in rf) {
      if (item is Map) {
        final dataOco = item['data_ocorrencia'] ?? item['data'] ?? '-';
        final categoria = item['categoria_ocorrencia'] ?? item['categoria'] ?? '-';
        final municipio = item['municipio_ocorrencia'] ?? item['municipio'] ?? '-';
        final uf = item['uf_ocorrencia'] ?? item['uf'] ?? '-';
        final bo = item['boletim'] ?? '-';
        
        rows.add([
          dataOco.toString(),
          categoria.toString(),
          '$municipio - $uf',
          bo.toString(),
        ]);
      }
    }

    return [
      _buildSectionHeader('Histórico Roubo e Furto', svgIcon: _svgWarning, bgColor: _kOrange, textColor: PdfColors.white),
      ..._buildGenericGrid(rows, [2, 3, 3, 2]),
    ];
  }

  static List<pw.Widget> _buildSecoesDinamicas(Map<String, dynamic> data) {
    if (data['resultados_completos'] == null || data['resultados_completos'] is! List) {
      return [];
    }

    final List<dynamic> resultados = data['resultados_completos'];
    
    final knownTitles = [
      'BIN **',
      'BASE ESTADUAL **',
      'SENATRAN DETALHADO INFORMAÇÕES - ONLINE',
      'SENATRAN DETALHADO RESTRIÇÕES - ONLINE',
      'COMUNICADO DE VENDA - ONLINE',
      'DECODIFICADOR DE CHASSI',
      'PRECIFICADOR I - FIPE',
      'HISTÓRICO DE LAUDOS',
      'CERTIFICADOS DE SEGURO DE VEÍCULO EMITIDOS',
      'DETALHES DE MULTA RENAINF',
      'HISTÓRICO ROUBO E FURTO *',
      'HISTÓRICO DE ROUBO E FURTO',
      'RECALL',
      'MULTAS DE TRANSITO - DNIT',
      'SSP - CORTESIA',
      'IPVA - SECRETARIA DE FAZENDA',
      'DPVATS',
      'IPVA (SEFAZ)',
      'PAGAMENTOS DE DÉBITOS',
      'IPVA NÃO INSCRITOS',
      'LICENCIAMENTOS',
      'PAGAMENTOS EFETUADOS 2026',
      'DÉBITOS INSCRITOS NA DÍVIDA ATIVA',
      'MULTAS DETALHADAS',
      'SINISTRO - BASE ON-LINE',
      'OFERTAS DE LEILÃO',
      'OFERTAS DE LEILÃO *',
      'LEILÃO CORPORATIVO - REMARKETING AUTOMOTIVO / VENDA DIRETA (CORTESIA)',
      '[OP] ANÁLISE TÉCNICA DE INFORMAÇÕES'
    ];

    List<pw.Widget> dynamicWidgets = [];

    for (var sec in resultados) {
      if (sec is! Map) continue;
      
      final title = sec['title']?.toString().toUpperCase() ?? '';
      if (title.isEmpty || knownTitles.contains(title)) {
        continue;
      }
      
      var retorno = sec['retorno'];
      if (retorno == null) continue;
      
      if (retorno is Map && retorno.containsKey('data')) {
        retorno = retorno['data'];
      }
      
      if (retorno is! Map || retorno.isEmpty) continue;
      
      dynamicWidgets.add(pw.SizedBox(height: 10));
      dynamicWidgets.add(_buildSectionHeader(sec['title'].toString()));
      
      List<List<String>> gridRows = [];
      List<String> currentRow = [];
      
      for (var entry in (retorno as Map).entries) {
        String keyStr = entry.key.toString();
        String valStr = '';
        
        final val = entry.value;
        if (val == null) continue;
        
        if (val is Map) {
          if (val.containsKey('descricao') && val['descricao'] != null) {
            valStr = val['descricao'].toString();
          } else if (val.containsKey('nome') && val['nome'] != null) {
            valStr = val['nome'].toString();
          } else {
            valStr = val.toString();
          }
        } else if (val is List) {
           valStr = 'Lista de registros (\${val.length})';
        } else {
          valStr = val.toString();
        }
        
        final lowerVal = valStr.toLowerCase();
        if (valStr.isEmpty || lowerVal == 'não informado' || lowerVal == 'nao informado' || lowerVal == 'null') {
          continue;
        }
        
        currentRow.add(keyStr);
        currentRow.add(valStr);
        
        if (currentRow.length == 4) {
          gridRows.add(List.from(currentRow));
          currentRow.clear();
        }
      }
      
      if (currentRow.isNotEmpty) {
        if (currentRow.length == 2) {
           gridRows.add([currentRow[0], currentRow[1], '', '']);
        }
      }
      
      if (gridRows.isNotEmpty) {
        dynamicWidgets.addAll(_buildDataGrid(gridRows));
      } else {
        dynamicWidgets.addAll(_buildDataGrid([['Nenhum dado retornado para esta sessão.']]));
      }
    }
    
    return dynamicWidgets;
  }
}
