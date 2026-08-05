import re

with open('lib/core/services/pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

logic_block = '''    final limeGreen = PdfColor.fromHex('8CC63F');
    final warningYellow = PdfColor.fromHex('FBB03B');
    final dangerRed = PdfColor.fromHex('EE4036');

    String computedStatus = vistoria.statusFinal ?? 'CONFORME';
    if (state != null) {
      if (state.resultadoFinal.isNotEmpty) {
        computedStatus = state.resultadoFinal;
      } else if (state.statusSugerido.isNotEmpty) {
        computedStatus = state.statusSugerido;
      }
    }
    PdfColor statusColor = warningYellow;
    String statusIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    String upStatus = computedStatus.toUpperCase();
    if (upStatus.contains('NÃO CONFORME') || upStatus.contains('REPROVADO')) {
      statusColor = dangerRed;
      statusIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>';
    } else if (upStatus.contains('CONFORME') || upStatus == 'APROVADO') {
      statusColor = limeGreen;
      statusIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    } else if (upStatus.contains('APONTAMENTOS') || upStatus.contains('OBSERVAÇÕES')) {
      statusColor = warningYellow;
      statusIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg>';
    } else {
      statusColor = limeGreen;
      statusIcon = '<svg viewBox="0 0 24 24"><path fill="white" d="M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z"/></svg>';
    }

    int getStatusCategory(String rawStatus) {
      final s = rawStatus.toLowerCase().trim();
      if (s.isEmpty) return 0;
      if (s.contains('divergente') || s.contains('adulteração') || s.contains('reprovado') || s.contains('não original') || s.contains('substituído') || s.contains('ausente') || s.contains('danificad') || s.contains('colisão') || s.contains('ilegível') || s.contains('não localizad') || s.contains('não conforme')) return 2;
      if (s.contains('reparo') || s.contains('repintura') || s.contains('observação') || s.contains('envelopado') || s.contains('amassado') || s.contains('riscado') || s.contains('soldado') || s.contains('avaria') || s.contains('massa') || s.contains('obstruído') || s.contains('alongado') || s.contains('consideração') || s.contains('sem acesso') || s.contains('inexistente') || s.contains('remarcad')) return 1;
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
        if (id.startsWith('chassi') || id.startsWith('motor') || id.startsWith('cambio') || id.startsWith('vidro') || id.startsWith('etiqueta') || id.startsWith('painel_hodometro') || id.startsWith('foto_placa') || id.startsWith('compartimento_motor')) {
          grupos['IDENTIFICAÇÃO']!.add(itemMap);
        } else if (id.startsWith('longarina') || id.startsWith('caixa') || id.startsWith('coluna') || id.startsWith('painel') || id.startsWith('torre') || id.startsWith('assoalho')) {
          grupos['ESTRUTURA']!.add(itemMap);
        } else {
          grupos['PINTURA E LATARIA']!.add(itemMap);
        }
      }
    }
    final int totalItens = countConforme + countObs + countNaoConforme;
'''

content = content.replace("final dangerRed = PdfColor.fromHex('EE4036');", logic_block, 1)

parecer_block = '''                            pw.Container(
                              padding: const pw.EdgeInsets.all(16),
                              margin: const pw.EdgeInsets.only(bottom: 12),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('F9F9F9'),
                                borderRadius: pw.BorderRadius.circular(8),
                                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 52,
                                    height: 52,
                                    decoration: pw.BoxDecoration(
                                        color: statusColor, shape: pw.BoxShape.circle),
                                    child: pw.Center(
                                        child: pw.SvgImage(
                                            svg: statusIcon, width: 30, height: 30)),
                                  ),
                                  pw.SizedBox(width: 16),
                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Text('PARECER FINAL DA VISTORIA',
                                            style: pw.TextStyle(
                                                font: styles.bold,
                                                fontSize: 12,
                                                color: PdfColors.grey600)),
                                        pw.SizedBox(height: 2),
                                        pw.Text(computedStatus.toUpperCase(),
                                            style: pw.TextStyle(
                                                font: styles.bold,
                                                fontSize: 18,
                                                color: PdfColors.black)),
                                        pw.SizedBox(height: 2),
                                        pw.Text(
                                            'Conclusão baseada na análise dos itens verificados',
                                            style: pw.TextStyle(
                                                font: styles.regular,
                                                fontSize: 9,
                                                color: PdfColors.grey500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
'''
content = content.replace("buildBanner(\n                                'INFORMAÇÕES BASEADAS NA CONSULTA AO VEÍCULO'),", parecer_block + "                            buildBanner(\n                                'INFORMAÇÕES BASEADAS NA CONSULTA AO VEÍCULO'),", 1)


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
                            pw.SizedBox(height: 4),
'''

pattern = r"(pw\.SizedBox\(height: 6\);\s*pw\.Text\('DADOS DO VEÍCULO'.*?textAlign: pw\.TextAlign\.center\),)"
content = re.sub(pattern, pie_chart_block.strip().replace('\\\\n', '\\n'), content, flags=re.DOTALL)

with open('lib/core/services/pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done replacing blocks')
