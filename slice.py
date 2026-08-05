import re

with open('lib/core/services/pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

pie_chart_block = '''                            pw.SizedBox(height: 14),
                            pw.Text('SITUAÇÃO GERAL',
                                style: pw.TextStyle(
                                    font: styles.bold,
                                    fontSize: 11,
                                    color: PdfColors.grey800)),
                            pw.SizedBox(height: 8),
                            pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                      width: 110,
                                      child: pw.Column(children: [
                                        pw.Text('',
                                            style: pw.TextStyle(
                                                font: styles.bold,
                                                fontSize: 28,
                                                color: PdfColors.black)),
                                        pw.Text('ITENS VERIFICADOS',
                                            style: pw.TextStyle(
                                                font: styles.bold,
                                                fontSize: 7,
                                                color: PdfColors.grey600)),
                                      ])),
                                  pw.SizedBox(width: 20),
                                  pw.Expanded(
                                      child: pw.Column(
                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                          children: [
                                        _buildLegendRow(
                                            'CONFORME', countConforme, limeGreen, styles,
                                            isCheck: true),
                                        pw.SizedBox(height: 4),
                                        _buildLegendRow('CONFORME (COM OBSERVAÇÃO)',
                                            countObs, warningYellow, styles,
                                            isWarning: true),
                                        pw.SizedBox(height: 4),
                                        _buildLegendRow('NÃO CONFORME', countNaoConforme,
                                            dangerRed, styles,
                                            isCross: true),
                                      ]))
                                ]),
                            pw.SizedBox(height: 6),
                            pw.Container(height: 0.5, color: PdfColors.grey300),
                            pw.SizedBox(height: 12),
                            pw.Container(
                                height: 350,
                                child: pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      _buildCategoryColumn(
                                          'IDENTIFICAÇÃO',
                                          grupos['IDENTIFICAÇÃO']!,
                                          styles,
                                          limeGreen,
                                          warningYellow,
                                          dangerRed),
                                      pw.Container(
                                          width: 0.5,
                                          height: double.infinity,
                                          color: PdfColors.grey200),
                                      _buildCategoryColumn('ESTRUTURA', grupos['ESTRUTURA']!,
                                          styles, limeGreen, warningYellow, dangerRed),
                                      pw.Container(
                                          width: 0.5,
                                          height: double.infinity,
                                          color: PdfColors.grey200),
                                      _buildCategoryColumn(
                                          'PINTURA E LATARIA',
                                          grupos['PINTURA E LATARIA']!,
                                          styles,
                                          limeGreen,
                                          warningYellow,
                                          dangerRed),
                                    ])),
                            
                            pw.SizedBox(height: 16),
                            pw.Text(
                                '* ESTA CONSULTA NÃO SUBSTITUI A VISTORIA FÍSICA DO VEÍCULO.\\nAs informações apresentadas neste relatório são baseadas em dados disponibilizados por órgãos oficiais e fontes privadas na data da consulta.',
                                style: pw.TextStyle(
                                    font: styles.bold,
                                    fontSize: 8,
                                    color: PdfColors.grey600),
                                textAlign: pw.TextAlign.center),
                            pw.SizedBox(height: 4),\\n'''

# Convert the block to lines
block_lines = pie_chart_block.replace('\\\\n', '\\n').splitlines(True)

# lines are 0-indexed. 1735 is index 1734. 1912 is index 1911.
# We slice before 1734 and after 1911. (i.e. replacing index 1734 up to 1912)
new_lines = lines[:1734] + block_lines + lines[1912:]

with open('lib/core/services/pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Done replacing lines via slicing')
