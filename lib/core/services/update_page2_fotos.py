import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_page_fotos = '''
  pw.Page _buildPageFotosGrid({
    required String titulo,
    required List<Map<String, dynamic>> fotos,
    required Vistoria vistoria,
    required Veiculo veiculo,
    required _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    VistoriaWizardState? state,
  }) {
    final limeGreen = PdfColor.fromHex('8CC63F');

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            pw.SizedBox(height: 8),

            // CAIXAS DADOS DO CLIENTE E DADOS DO VEICULO (DENATRAN)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // DADOS DO CLIENTE
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
                        _buildKvSmall('E-MAIL:', vistoria.clienteEmail ?? '-', styles),
                        _buildKvSmall('CPF:', vistoria.clienteCpf ?? '-', styles),
                        _buildKvSmall('TELEFONE:', vistoria.clienteTelefone ?? '-', styles),
                      ]
                    )
                  )
                ),
                pw.SizedBox(width: 8),
                // DADOS DO VEICULO (DENATRAN)
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
              ]
            ),

            pw.SizedBox(height: 10),

            // GRADE DE 6 FOTOS (2 COLUNAS x 3 LINHAS)
            if (fotos.isEmpty)
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text('Nenhuma foto capturada.', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
                )
              )
            else
              pw.Expanded(
                child: pw.GridView(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: fotos.map((f) {
                    try {
                      Uint8List bytes;
                      if (f['base64'] != null && (f['base64'] as String).isNotEmpty) {
                        bytes = base64Decode(f['base64'] as String);
                      } else {
                        bytes = File(f['path'] as String).readAsBytesSync();
                      }
                      final img = pw.MemoryImage(bytes);
                      final label = (f['label'] as String? ?? '').toUpperCase();

                      return pw.Container(
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
                                child: pw.Image(img, fit: pw.BoxFit.cover),
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
                    } catch (e) {
                      return pw.Container(
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                        child: pw.Center(child: pw.Text('Erro Imagem', style: pw.TextStyle(fontSize: 8))),
                      );
                    }
                  }).toList(),
                ),
              ),
          ],
        );
      }
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
'''

# Update callers of _buildPageFotosGrid to pass `veiculo: veiculo`
content = content.replace('_buildPageFotosGrid(\n                titulo:', '_buildPageFotosGrid(\n                veiculo: veiculo,\n                titulo:')
content = content.replace('_buildPageFotosGrid(\n              titulo:', '_buildPageFotosGrid(\n              veiculo: veiculo,\n              titulo:')
content = content.replace('_buildPageFotosGrid(\n          titulo:', '_buildPageFotosGrid(\n          veiculo: veiculo,\n          titulo:')

# Replace the method _buildPageFotosGrid definition
pattern = re.compile(r'pw\.Page _buildPageFotosGrid\(.*?^\s*\}\n  \}', re.DOTALL | re.MULTILINE)
content = pattern.sub(new_page_fotos, content)

with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated _buildPageFotosGrid successfully!')
