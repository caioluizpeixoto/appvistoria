import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildPage1Modern and helper methods with perfect logic & styling
new_page1_code = '''
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

    // Funcao perfeita para classificar o status
    int getStatusCategory(String rawStatus) {
      final s = rawStatus.toLowerCase().trim();
      if (s.isEmpty) return 0;
      
      // Vermelho: Nao Conforme / Avariado / Divergente
      if (s.contains('divergente') || s.contains('adulteração') || s.contains('reprovado') ||
          s.contains('não original') || s.contains('substituído') || s.contains('ausente') ||
          s.contains('danificad') || s.contains('colisão') || s.contains('ilegível') ||
          s.contains('não localizad') || s.contains('não conforme')) {
        return 2; // Red
      }
      
      // Amarelo: Com Observacao / Repintura / Avaria leve
      if (s.contains('reparo') || s.contains('repintura') || s.contains('observação') || 
          s.contains('envelopado') || s.contains('amassado') || s.contains('riscado') ||
          s.contains('soldado') || s.contains('avaria') || s.contains('massa') ||
          s.contains('obstruído') || s.contains('alongado') || s.contains('consideração') ||
          s.contains('sem acesso') || s.contains('inexistente') || s.contains('remarcad')) {
        return 1; // Yellow
      }
      
      // Verde: Conforme / Original / Padrao / OK (Default)
      return 0; // Green
    }

    PdfColor getStatusColor(int statusVal) {
      if (statusVal == 0) return limeGreen;
      if (statusVal == 1) return warningYellow;
      return dangerRed;
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

        // Categorizacao precisa
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
                _buildHeader(vistoria, styles, logo, state: state),
                pw.SizedBox(height: 10),
                
                // DADOS DO VEÍCULO E PARECER FINAL
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DADOS DO VEÍCULO', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey800)),
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
                          pw.Text('PARECER FINAL', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey800)),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: warningYellow,
                                  shape: pw.BoxShape.circle
                                ),
                                child: pw.Center(
                                  child: pw.Text('!', style: pw.TextStyle(font: styles.bold, fontSize: 20, color: PdfColors.white))
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Expanded(
                                child: pw.Text(
                                  computedStatus.toUpperCase(), 
                                  style: pw.TextStyle(font: styles.bold, fontSize: 11, color: PdfColors.black)
                                ),
                              )
                            ]
                          )
                        ]
                      )
                    )
                  ]
                ),
                pw.SizedBox(height: 12),
                
                // SITUAÇÃO GERAL
                pw.Text('SITUAÇÃO GERAL', style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 100,
                      child: pw.Column(
                        children: [
                          pw.Text('$totalItens', style: pw.TextStyle(font: styles.bold, fontSize: 26, color: PdfColors.black)),
                          pw.Text('ITENS VERIFICADOS', style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.grey600)),
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
                pw.SizedBox(height: 10),
                
                // 3 COLUNAS DE CATEGORIAS COM SEPARADOR VERTICAL
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

                // ASSINATURAS DO RODAPE DA PAG 1
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 3),
                          pw.Text('CPF: Não informado', style: pw.TextStyle(font: styles.bold, fontSize: 7.5)),
                          pw.Text('Vistoriador', style: pw.TextStyle(font: styles.regular, fontSize: 6.5, color: PdfColors.grey700)),
                        ]
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 160, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 3),
                          pw.Text('CLIENTE', style: pw.TextStyle(font: styles.bold, fontSize: 7.5)),
                          pw.Text('Cliente', style: pw.TextStyle(font: styles.regular, fontSize: 6.5, color: PdfColors.grey700)),
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
          pw.SizedBox(width: 65, child: pw.Text(k, style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.black))),
          pw.Expanded(child: pw.Text(v ?? '-', style: pw.TextStyle(font: styles.regular, fontSize: 6.5, color: PdfColors.grey700))),
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
              width: 14, height: 14,
              decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
              child: pw.Center(
                child: pw.Text(
                  isCheck ? '✓' : (isWarning ? '!' : '✕'),
                  style: pw.TextStyle(font: styles.bold, fontSize: 8, color: PdfColors.white)
                )
              )
            ),
            pw.SizedBox(width: 8),
            pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColors.black)),
          ]
        ),
        pw.Text('$count ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColors.grey700)),
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
            pw.Text(title, style: pw.TextStyle(font: styles.bold, fontSize: 7.5, color: PdfColors.grey800)),
            pw.SizedBox(height: 6),
            _buildDonutChart(total, greens, yellows, reds, styles, limeGreen, warningYellow, dangerRed),
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: itens.map((e) {
                final statusVal = e['status'] as int;
                PdfColor dotColor = limeGreen;
                if (statusVal == 1) dotColor = warningYellow;
                if (statusVal == 2) dotColor = dangerRed;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 4, height: 4,
                        decoration: pw.BoxDecoration(color: dotColor, shape: pw.BoxShape.circle)
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Text(
                          e['nome'] as String, 
                          style: pw.TextStyle(
                            font: (statusVal != 0) ? styles.bold : styles.regular, 
                            fontSize: 4.8, 
                            color: (statusVal != 0) ? PdfColors.black : PdfColors.grey700
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
    if (total == 0) return pw.SizedBox(height: 55);
    return pw.SizedBox(
      width: 55, height: 55,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(55, 55),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final center = PdfPoint(size.x / 2, size.y / 2);
              final radius = 22.0;
              final stroke = 8.0;
              
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
              
              // Desenhar na ordem: Verde, depois Amarelo, depois Vermelho
              drawArcSegment(green, limeGreen);
              drawArcSegment(yellow, warningYellow);
              drawArcSegment(red, dangerRed);
            }
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$total', style: pw.TextStyle(font: styles.bold, fontSize: 11, color: PdfColors.black)),
              pw.Text('ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 4.5, color: PdfColors.grey600)),
            ]
          )
        ]
      )
    );
  }
'''

# Read content
with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace existing _buildPage1Modern up to _buildPage1Old
pattern = re.compile(r'Future<pw\.Page> _buildPage1Modern\(.*?Future<pw\.Page> _buildPage1Old\(', re.DOTALL)
content = pattern.sub(new_page1_code + '\n\n  Future<pw.Page> _buildPage1Old(', content)

with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated _buildPage1Modern perfectly!')
