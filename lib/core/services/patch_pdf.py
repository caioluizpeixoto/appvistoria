import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _buildModernPage1 and helpers before _buildPage1
modern_page_code = '''
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

    // Calcular Totais
    int countConforme = 0;
    int countObs = 0;
    int countNaoConforme = 0;
    
    final Map<String, List<Map<String, String>>> grupos = {
      'IDENTIFICAÇÃO': [],
      'ESTRUTURA': [],
      'PINTURA E LATARIA': []
    };

    if (state != null) {
      for (final entry in state.checklistStatus.entries) {
        final id = entry.key;
        final status = entry.value;
        final nome = id.replaceAll('_', ' ').toUpperCase();
        
        // Ignorar opcionais do wizard base
        if (nome.contains('OPCIONAL')) continue;
        if (status == 'NÃO ANALISADO') continue;

        int statusVal = 0; // 0=green, 1=yellow, 2=red
        if (status == 'CONFORME' || status.contains('ORIGINAL')) {
          countConforme++;
          statusVal = 0;
        } else if (status.contains('NÃO CONFORME') || status.contains('AVARIADO')) {
          countNaoConforme++;
          statusVal = 2;
        } else {
          countObs++;
          statusVal = 1;
        }
        
        // Agrupar
        if (id.startsWith('chassi') || id.startsWith('motor') || id.startsWith('vidro') || id.startsWith('etiqueta') || id.startsWith('painel_hodometro') || id.startsWith('foto_placa')) {
          grupos['IDENTIFICAÇÃO']!.add({'nome': nome, 'status': statusVal.toString()});
        } else if (id.startsWith('longarina') || id.startsWith('caixa') || id.startsWith('coluna') || id.startsWith('painel') || id.startsWith('torre') || id.startsWith('assoalho')) {
          grupos['ESTRUTURA']!.add({'nome': nome, 'status': statusVal.toString()});
        } else {
          grupos['PINTURA E LATARIA']!.add({'nome': nome, 'status': statusVal.toString()});
        }
      }
    }
    
    final int totalItens = countConforme + countObs + countNaoConforme;
    
    PdfColor getStatusColor(String val) {
      if (val == '0') return PdfColors.green500;
      if (val == '1') return PdfColors.yellow700;
      return PdfColors.red600;
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
                    opacity: 0.1,
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
                pw.SizedBox(height: 12),
                
                // DADOS DO VEÍCULO E PARECER FINAL
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DADOS DO VEÍCULO', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey700)),
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
                                  _buildKv('Nº CHASSI:', veiculo.chassi, styles),
                                  _buildKv('Nº MOTOR:', veiculo.motor, styles),
                                  _buildKv('COMBUSTÍVEL:', veiculo.combustivel, styles),
                                  _buildKv('QUILOMETRAGEM:', veiculo.quilometragem, styles),
                                  _buildKv('MUNICÍPIO:', veiculo.municipio, styles),
                                ]
                              )),
                            ]
                          ),
                        ]
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PARECER FINAL', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 30, height: 30,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.yellow600,
                                  shape: pw.BoxShape.circle
                                ),
                                child: pw.Center(child: pw.Text('!', style: pw.TextStyle(font: styles.bold, fontSize: 18, color: PdfColors.white))),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Text(computedStatus, style: pw.TextStyle(font: styles.bold, fontSize: 12, color: PdfColors.black)),
                              )
                            ]
                          )
                        ]
                      )
                    )
                  ]
                ),
                pw.SizedBox(height: 16),
                
                // SITUAÇÃO GERAL
                pw.Text('SITUAÇÃO GERAL', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
                
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        children: [
                          pw.Text('$totalItens', style: pw.TextStyle(font: styles.bold, fontSize: 24, color: PdfColors.black)),
                          pw.Text('ITENS ANALISADOS', style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey600)),
                        ]
                      )
                    ),
                    pw.Expanded(
                      flex: 7,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('CONFORME', countConforme, PdfColors.green500, styles),
                          pw.SizedBox(height: 4),
                          _buildLegendItem('CONFORME (COM OBSERVAÇÃO)', countObs, PdfColors.yellow700, styles),
                          pw.SizedBox(height: 4),
                          _buildLegendItem('NÃO CONFORME', countNaoConforme, PdfColors.red600, styles),
                        ]
                      )
                    )
                  ]
                ),
                
                pw.SizedBox(height: 20),
                
                // GRAFICOS E LISTAS
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildColumnGraphList('IDENTIFICAÇÃO', grupos['IDENTIFICAÇÃO']!, styles, getStatusColor),
                    _buildColumnGraphList('ESTRUTURA', grupos['ESTRUTURA']!, styles, getStatusColor),
                    _buildColumnGraphList('PINTURA E LATARIA', grupos['PINTURA E LATARIA']!, styles, getStatusColor),
                  ]
                ),

                pw.Spacer(),
                
                // ASSINATURAS DO RODAPE DA PAG 1
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('CPF: Não informado', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                          pw.Text('Vistoriador', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
                        ]
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('CLIENTE', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                          pw.Text('Cliente', style: pw.TextStyle(font: styles.regular, fontSize: 7)),
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
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 60, child: pw.Text(k, style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.black))),
          pw.Expanded(child: pw.Text(v ?? '-', style: pw.TextStyle(font: styles.regular, fontSize: 7, color: PdfColors.grey700))),
        ]
      )
    );
  }

  pw.Widget _buildLegendItem(String title, int count, PdfColor color, _PdfStyles styles) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 12, height: 12,
              decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              child: pw.Center(child: pw.Icon(pw.IconData(color == PdfColors.green500 ? 0xe5ca : (color == PdfColors.yellow700 ? 0xe002 : 0xe5cd)), color: PdfColors.white, size: 8))
            ),
            pw.SizedBox(width: 8),
            pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.black)),
          ]
        ),
        pw.Text('$count ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey700)),
      ]
    );
  }

  pw.Widget _buildColumnGraphList(String title, List<Map<String, String>> itens, _PdfStyles styles, PdfColor Function(String) colorFn) {
    int greens = itens.where((e) => e['status'] == '0').length;
    int yellows = itens.where((e) => e['status'] == '1').length;
    int reds = itens.where((e) => e['status'] == '2').length;
    int total = itens.length;
    
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          _buildDonut(total, greens, yellows, reds, styles),
          pw.SizedBox(height: 15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: itens.map((e) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 2, right: 4),
                      width: 4, height: 4,
                      decoration: pw.BoxDecoration(color: colorFn(e['status']!), shape: pw.BoxShape.circle)
                    ),
                    pw.Expanded(child: pw.Text(e['nome']!, style: pw.TextStyle(font: styles.regular, fontSize: 5, color: PdfColors.grey600))),
                  ]
                )
              );
            }).toList()
          )
        ]
      )
    );
  }

  pw.Widget _buildDonut(int total, int green, int yellow, int red, _PdfStyles styles) {
    if (total == 0) return pw.SizedBox(height: 60);
    return pw.SizedBox(
      width: 60, height: 60,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(60, 60),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final center = PdfPoint(size.x / 2, size.y / 2);
              final radius = 25.0;
              final stroke = 10.0;
              
              double currentAngle = -1.5708; // -Pi/2 (Start at top)
              
              void drawSlice(int count, PdfColor color) {
                if (count == 0) return;
                final sweepAngle = (count / total) * 6.28319; // 2*Pi
                
                canvas.saveContext();
                final int steps = 30;
                canvas.moveTo(center.x + radius * math.cos(currentAngle), center.y + radius * math.sin(currentAngle));
                for (int i = 1; i <= steps; i++) {
                  final a = currentAngle + (sweepAngle * i / steps);
                  canvas.lineTo(center.x + radius * math.cos(a), center.y + radius * math.sin(a));
                }
                canvas.setStrokeColor(color);
                canvas.setLineWidth(stroke);
                canvas.strokePath();
                canvas.restoreContext();
                
                currentAngle += sweepAngle;
              }
              
              drawSlice(green, PdfColors.green500);
              drawSlice(yellow, PdfColors.yellow700);
              drawSlice(red, PdfColors.red600);
            }
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$total', style: pw.TextStyle(font: styles.bold, fontSize: 12)),
              pw.Text('ITENS', style: pw.TextStyle(font: styles.regular, fontSize: 5)),
            ]
          )
        ]
      )
    );
  }
'''

content = content.replace('  Future<pw.Page> _buildPage1({', modern_page_code + '\n\n  Future<pw.Page> _buildPage1Old({')

# 2. Modify the caller to use _buildPage1Modern instead of _buildPage1
content = content.replace('pdf.addPage(await _buildPage1(', 'pdf.addPage(await _buildPage1Modern(')

# 3. Modify Pintura table to look like Screenshot 3
old_pintura_table = '''                      _buildBlackBar('OBSERVAÇÕES DA PINTURA', styles),
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
                                  _td(id.replaceAll('_', ' ').toUpperCase(), styles),
                                  _td(status, styles),
                                  _td(obs, styles),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),'''

new_pintura_table = '''                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        color: _kBlack,
                        child: pw.Text('TABELA DE REFERÊNCIA DE APONTAMENTOS DA PINTURA', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.white)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Table(
                          border: pw.TableBorder.all(color: _kBlack, width: 0.5),
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('PEÇA / ITEM', style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                                pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('DIAGNÓSTICO / OBSERVAÇÃO', style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                              ],
                            ),
                            ...itens.where((id) {
                              final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                              return status != 'NÃO ANALISADO';
                            }).map((id) {
                              final status = state?.getStatus(id) ?? 'NÃO ANALISADO';
                              final obs = state?.getObs(id) ?? '';
                              final diag = status.toUpperCase();
                              
                              PdfColor bgColor = PdfColors.white;
                              if (diag == 'REPINTURA' || diag == 'MASSA' || diag == 'AMASSADO') {
                                bgColor = PdfColors.amber300;
                              } else if (diag == 'PINTURA ORIGINAL' || diag == 'CONFORME') {
                                bgColor = PdfColors.lightGreen400;
                              } else {
                                bgColor = PdfColors.red300;
                              }
                              
                              return pw.TableRow(
                                decoration: pw.BoxDecoration(color: bgColor),
                                children: [
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(id.replaceAll('_', ' ').toUpperCase(), style: pw.TextStyle(font: styles.regular, fontSize: 6, color: PdfColors.black))),
                                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(diag + (obs.isNotEmpty ? ' - ' + obs : ''), style: pw.TextStyle(font: styles.bold, fontSize: 6, color: PdfColors.black))),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),'''

content = content.replace(old_pintura_table, new_pintura_table)

with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Patch script finished!')
