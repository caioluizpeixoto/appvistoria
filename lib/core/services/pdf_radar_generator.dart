import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dio/dio.dart';
import 'dart:convert';

class PdfRadarGenerator {
  static const _kPrimaryHeader = PdfColor.fromInt(0xFF1F5E3D);
  static const _kYellowHeader = PdfColor.fromInt(0xFFFDF7CC);
  static const _kYellowHeaderDarkText = PdfColor.fromInt(0xFF8B7500);
  static const _kBlueLight = PdfColor.fromInt(0xFFF2F2F2);
  static const _kTextDark = PdfColor.fromInt(0xFF333333);
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
            if (entry.value != null &&
                entry.value.toString().trim().isNotEmpty) {
              return entry.value.toString().trim();
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

  static Future<List<pw.Page>> buildRadarPages(
      Map<String, dynamic> dadosPesquisa,
      {pw.Widget? footerWidget}) async {
    final List<pw.Page> pages = [];

    final String marca =
        _v(dadosPesquisa, ['marca', 'marcamodelo', 'marcaModelo'], fallback: '')
            .toUpperCase();
    pw.MemoryImage? marcaLogo;
    final marcaBusca = marca.split(' ').first.toLowerCase();

    try {
      final ByteData data =
          await rootBundle.load('assets/logos/$marcaBusca.png');
      marcaLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      try {
        final response = await Dio().get(
          'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/thumb/$marcaBusca.png',
          options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 3)),
        );
        if (response.statusCode == 200 && response.data != null) {
          marcaLogo = pw.MemoryImage(response.data);
        }
      } catch (_) {}
    }

    final placa = _v(dadosPesquisa, ['placa'], fallback: '');
    final chassi = _v(dadosPesquisa, ['chassi'], fallback: '');
    final renavam = _v(dadosPesquisa, ['renavam'], fallback: '');
    final anomodelo =
        _v(dadosPesquisa, ['anomodelo', 'anoModelo'], fallback: '');

    final List<pw.Widget> contentWidgets = [
      _buildSectionHeader('Bin **',
          svgIcon: null, bgColor: _kPrimaryHeader, textColor: PdfColors.white),
      pw.SizedBox(height: 10),
      _buildTopHeader(marca, marcaLogo, placa, chassi, renavam, anomodelo),
      pw.SizedBox(height: 10),
      _buildSectionBin(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildInformacoesRelevantesBin(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildBaseEstadual(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildInformacoesRelevantesEstadual(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildProprietario(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildChassi(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildPrecificador(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildHistoricoLaudos(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildSenatranInfo(dadosPesquisa),
      pw.SizedBox(height: 10),
      _buildSenatranRestricoes(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildDetalhesComplementares(dadosPesquisa),
      pw.SizedBox(height: 10),
      ..._buildSecoesFinais(dadosPesquisa),
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

  static pw.Widget _buildTopHeader(String marcaNome, pw.MemoryImage? logo,
      String placa, String chassi, String renavam, String anomodelo) {
    return pw.Row(children: [
      pw.Expanded(
          flex: 1,
          child: pw.Container(
            height: 60,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _kBorder, width: 0.5),
                color: PdfColors.white),
            child: logo != null
                ? pw.Image(logo, height: 35)
                : pw.Text(marcaNome,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: _kTextDark)),
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
                    pw.Text('NACIONAL', style: const pw.TextStyle(fontSize: 8)),
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
                  _buildTopGridCell('ANO MOD.', anomodelo),
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

  static pw.Widget _buildDataGrid(List<List<String>> rows) {
    return pw.Container(
      decoration:
          pw.BoxDecoration(border: pw.Border.all(color: _kBorder, width: 0.5)),
      child: pw.Column(
        children: List.generate(rows.length, (index) {
          final isEven = index % 2 == 0;
          final rowData = rows[index];

          if (rowData.length == 1) {
            return pw.Container(
              color: isEven ? PdfColors.white : _kBlueLight,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: double.infinity,
              child: _buildValueBlock(rowData[0], isTitle: true),
            );
          }

          return pw.Container(
            color: isEven ? PdfColors.white : _kBlueLight,
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
        }),
      ),
    );
  }

  static pw.Widget _buildValueBlock(String value, {bool isTitle = false}) {
    final vUpper = value.toUpperCase();
    PdfColor color = _kTextDark;
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
    PdfColor color = _kTextDark;
    pw.FontWeight weight = pw.FontWeight.normal;
    String? icon;
    PdfColor iconColor = PdfColors.black;

    final vUpper = value.toUpperCase();
    final lUpper = label.toUpperCase();

    if (lUpper == 'CHASSI' ||
        lUpper == 'MOTOR' ||
        lUpper == 'NUMERO DO MOTOR') {
      color = _kTeal;
      weight = pw.FontWeight.bold;
      icon = _svgWrench;
      iconColor = _kTeal;
    } else if (lUpper == 'DATA DE EMISSÃO DO CRV') {
      color = _kTeal;
    } else if (lUpper.startsWith('RESTRIÇÃO') ||
        lUpper.startsWith('RESTRICAO') ||
        lUpper.startsWith('RESTRIÇÕES') ||
        lUpper.startsWith('RESTRICOES') ||
        lUpper.startsWith('IND. RESTRI') ||
        lUpper == 'RESTRIÇÕES ADMINISTRATIVAS') {
      color = _kOrange;
      weight = pw.FontWeight.bold;
    } else if (lUpper == 'ROUBO/FURTO' && vUpper == 'NÃO POSSUI') {
      color = PdfColor.fromInt(0xFFD67362);
      weight = pw.FontWeight.bold;
      icon = _svgWarning;
      iconColor = PdfColor.fromInt(0xFFD67362);
    } else if (vUpper == 'CIRCULACAO' ||
        vUpper == 'EM CIRCULACAO' ||
        vUpper == 'CIRCULAÇÃO') {
      color = _kTeal;
      weight = pw.FontWeight.bold;
      icon = _svgCheck;
      iconColor = _kTeal;
    } else if (vUpper.contains('VEICULO NÃO POSSUI RESTRIÇÃO') ||
        vUpper.contains('CHASSI NÃO POSSUÍ IRREGULARIDADES')) {
      color = _kGreen;
      weight = pw.FontWeight.bold;
      icon = _svgCheck;
      iconColor = _kGreen;
    } else if (vUpper == 'NÃO INFORMADO' &&
        (lUpper == 'SITUAÇÃO CHASSI' ||
            lUpper == 'REMARCAÇÃO CHASSI' ||
            lUpper == 'REMARCACAO CHASSI')) {
      color = _kTeal;
      weight = pw.FontWeight.bold;
      icon = _svgCheck;
      iconColor = _kTeal;
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

  static pw.Widget _buildSectionBin(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildDataGrid([
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
            _v(data, ['emplacamento_eletronico', 'emplacamentoeletronico'])
          ],
        ]),
      ],
    );
  }

  static pw.Widget _buildInformacoesRelevantesBin(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Informações Relevantes',
            svgIcon: _svgEye,
            bgColor: _kYellowHeader,
            textColor: _kYellowHeaderDarkText),
        _buildDataGrid([
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
      ],
    );
  }

  static pw.Widget _buildBaseEstadual(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Base Estadual **', svgIcon: _svgFlag),
        _buildDataGrid([
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
            _v(data, ['eixos', 'quantidadeeixos'])
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
      ],
    );
  }

  static pw.Widget _buildInformacoesRelevantesEstadual(
      Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Informações Relevantes',
            svgIcon: _svgEye,
            bgColor: _kYellowHeader,
            textColor: _kYellowHeaderDarkText),
        _buildDataGrid([
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
            _v(data, ['restricao1_est', 'restricaobaseestadual1'],
                fallback: 'SEM RESTRICAO')
          ],
          [
            'Restrição 2',
            _v(data, ['restricao2_est', 'restricaobaseestadual2'],
                fallback: 'SEM RESTRICAO'),
            'Restrição 3',
            _v(data, ['restricao3_est', 'restricaobaseestadual3'],
                fallback: 'SEM RESTRICAO')
          ],
          [
            'Restrição 4',
            _v(data, ['restricao4_est', 'restricaobaseestadual4'],
                fallback: 'SEM RESTRICAO'),
            '',
            ''
          ],
        ]),
      ],
    );
  }

  static pw.Widget _buildProprietario(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Informações de Proprietário', svgIcon: _svgPerson),
        _buildDataGrid([
          [
            'Anterior',
            _v(data, ['proprietarioanterior', 'nomeproprietarioanterior']),
            'Atual',
            _v(data, ['proprietario', 'nomeproprietario'])
          ],
        ]),
      ],
    );
  }

  static pw.Widget _buildChassi(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Decodificador de Chassi', svgIcon: _svgWrench),
        _buildDataGrid([
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
            _v(data, ['codcategoria']),
            'Categoria',
            _v(data, ['categoria'])
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
      ],
    );
  }

  static pw.Widget _buildPrecificador(Map<String, dynamic> data) {
    return pw.Column(
      children: [
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
              pw.Container(
                color: PdfColors.white,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(_v(data, ['codigofipe', 'fipe_codigo']),
                            style: const pw.TextStyle(
                                fontSize: 8, color: _kTextDark))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(_v(data, ['combustivel']),
                            style: const pw.TextStyle(
                                fontSize: 8, color: _kTextDark))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(_v(data, ['marca']),
                            style: const pw.TextStyle(
                                fontSize: 8, color: _kTextDark))),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(_v(data, ['modelo', 'fipe_modelo']),
                            style: const pw.TextStyle(
                                fontSize: 8, color: _kTextDark))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(_v(data, ['valorfipe', 'fipe_valor']),
                            style: const pw.TextStyle(
                                fontSize: 8, color: _kTextDark))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHistoricoLaudos(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('Histórico de Laudos', svgIcon: _svgDocument),
        _buildDataGrid([
          [
            _v(data, ['historicolaudos', 'laudos'],
                fallback: 'VEÍCULO NÃO POSSUÍ LAUDO EM NOSSA PLATAFORMA')
          ],
        ]),
      ],
    );
  }

  static pw.Widget _buildSenatranInfo(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('SENATRAN Detalhado Informações - Online',
            svgIcon: _svgCar),
        _buildDataGrid([
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
        ]),
      ],
    );
  }

  static pw.Widget _buildSenatranRestricoes(Map<String, dynamic> data) {
    return pw.Column(
      children: [
        _buildSectionHeader('SENATRAN Detalhado Restrições - Online',
            svgIcon: _svgCar),
        _buildDataGrid([
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
      ],
    );
  }

  static List<pw.Widget> _buildDetalhesComplementares(
      Map<String, dynamic> data) {
    return [
      _buildSectionHeader('Certificados de seguro de veículo emitidos'),
      _buildDataGrid([
        [
          _v(data, ['certificadosseguro', 'seguros'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Detalhes de Roubo/Furto'),
      _buildDataGrid([
        [
          _v(data, ['detalhesroubofurto', 'roubo_furto_detalhes'],
              fallback: 'NÃO FORAM ENCONTRADOS REGISTROS DE ROUBO / FURTO')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Detalhes de Multa Renainf'),
      _buildDataGrid([
        [
          _v(data, ['multasrenainfdetalhes', 'multas_renainf'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Comunicado de Venda', svgIcon: _svgMoney),
      _buildDataGrid([
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
      _buildSectionHeader('Recall', svgIcon: _svgWrench),
      _buildDataGrid([
        [
          _v(data, ['recall_texto', 'recalltexto'],
              fallback:
                  'O VEÍCULO PESQUISADO NÃO POSSUI RECALL PENDENTE OU NÃO PERTENCE A NENHUM RECALL DIVULGADO PELAS MONTADORAS A PARTIR DE 17/03/2011. PARA PERÍODOS ANTERIORES, ENTRE EM CONTATO DIRETAMENTE COM O FABRICANTE DO VEÍCULO.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Multas de Transito - DNIT', svgIcon: _svgFlag),
      _buildDataGrid([
        [
          _v(data, ['multasdnit', 'dnit'],
              fallback: 'VEICULO NÃO POSSUI INFORMAÇÕES NO DNIT')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('SSP - Cortesia', svgIcon: _svgBuilding),
      _buildDataGrid([
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
      _buildDataGrid([
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
      _buildDataGrid([
        [
          _v(data, ['dpvat_detalhes'], fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('IPVA'),
      _buildDataGrid([
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
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Pagamentos de Débitos'),
      _buildDataGrid([
        [
          _v(data, ['pagamentos_debitos'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('IPVA não inscritos'),
      _buildDataGrid([
        [
          _v(data, ['ipva_nao_inscritos'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Licenciamentos'),
      _buildDataGrid([
        [
          _v(data, ['licenciamentos_detalhes'],
              fallback: 'Nenhum registro encontrado.')
        ],
      ]),
    ];
  }

  static List<pw.Widget> _buildSecoesFinais(Map<String, dynamic> data) {
    return [
      _buildSectionHeader('Sinistro - Base On-line', svgIcon: _svgThermometer),
      _buildDataGrid([
        [
          _v(data, ['sinistro_base'], fallback: 'FORNECEDOR INDISPONÍVEL')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('Ofertas de Leilão', svgIcon: _svgHammer),
      _buildDataGrid([
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
      _buildDataGrid([
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
      _buildDataGrid([
        [
          _v(data, ['remarketing'],
              fallback:
                  'NÃO FOI ENCONTRADO NENHUMA OCORRÊNCIA DE REMARKETING AUTOMOTIVO')
        ],
      ]),
      pw.SizedBox(height: 10),
      _buildSectionHeader('[OP] Análise Técnica de Informações',
          svgIcon: _svgThermometer),
      _buildDataGrid([
        [
          _v(data, ['analisetecnica', 'sinistro'],
              fallback: 'VEÍCULO NÃO POSSUÍ INDÍCIO DE SINISTRO')
        ],
      ]),
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
}
