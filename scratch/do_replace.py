import os

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

with open(r'scratch\original_block.txt', 'r', encoding='utf-8') as f:
    old_block = f.read()

new_block = """    // Ficha Técnica Inteligente unificada (MultiPage)
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      header: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vistoria, styles, logo, state: state),
            pw.SizedBox(height: 8),
          ]
        );
      },
      footer: (ctx) {
        return pw.Column(
          children: [
            _buildFooter(vistoria, styles, ctx, assinatura, showSignatures: false),
            _buildPdfFooter(ctx, styles),
          ]
        );
      },
      build: (ctx) {
        final apontamentosOriginais = data['apontamentos_veiculo'] is List
            ? (data['apontamentos_veiculo'] as List)
            : [];
        bool isZeroCurrency(dynamic val) {
          if (val == null) return true;
          final str = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
          return str.isEmpty || int.tryParse(str) == 0;
        }

        final validApontamentos = apontamentosOriginais.where((item) {
          final pecaUpper = (item['peca_ou_problema']?.toString() ?? '').toUpperCase();
          final obsUpper = (item['observacao_indicada']?.toString() ?? '').toUpperCase();
          final isNoAvaria = pecaUpper.contains('SEM ACESSO') ||
              pecaUpper.contains('SEMA ACESSO') ||
              obsUpper.contains('SEM ACESSO') ||
              obsUpper.contains('SEMA ACESSO') ||
              pecaUpper.contains('PLAQUETA AUSENTE') ||
              obsUpper.contains('PLAQUETA AUSENTE') ||
              ((pecaUpper.contains('CAMBIO') || pecaUpper.contains('CÂMBIO')) &&
                  (pecaUpper.contains('AUSENTE') || obsUpper.contains('AUSENTE'))) ||
              obsUpper.contains('NÃO É AVARIA') ||
              obsUpper.contains('NAO E AVARIA') ||
              obsUpper.contains('NÃO REPRESENTA AVARIA') ||
              pecaUpper.contains('REPINT') ||
              pecaUpper.contains('RETOQUE') ||
              obsUpper.contains('SERVIÇO DE REPINTURA') ||
              obsUpper.contains('REPINTURA JÁ REALIZADA') ||
              obsUpper.contains('REPINTURA JÁ REALIZADO') ||
              obsUpper.contains('REPINT') ||
              obsUpper.contains('RETOQUE') ||
              obsUpper.contains('OBSTRUÍDO') ||
              obsUpper.contains('OBSTRUIDO') ||
              obsUpper.contains('DENTRO DOS PADRÕES') ||
              obsUpper.contains('DENTRO DOS PADROES') ||
              obsUpper.contains('PADRÃO DE FÁBRICA') ||
              obsUpper.contains('PADRAO DE FABRICA') ||
              obsUpper.contains('PADRÃO DO FABRICANTE') ||
              obsUpper.contains('SEM AVARIA');

          if (isNoAvaria) return false;

          final valPecaZero = isZeroCurrency(item['valor_peca_estimado']);
          final valMaoObraZero = isZeroCurrency(item['valor_mao_de_obra_estimado']);

          if (valPecaZero && valMaoObraZero) {
            return false;
          }

          return true;
        }).toList();

        return <pw.Widget>[
            pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: lightRed,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: themeRed, width: 1)),
                child: pw.Center(
                  child: pw.Text('FICHA TÉCNICA INTELIGENTE DO VEÍCULO',
                      style: pw.TextStyle(font: styles.bold, fontSize: 12, color: themeRed)),
                )),
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
                    return pw.TableRow(children: [
                      buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                      buildSoftTd(e.value.toString()),
                    ]);
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
                    return pw.TableRow(children: [
                      buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                      buildSoftTd(e.value.toString()),
                    ]);
                  }).toList(),
                ),
              ),
            
            pw.SizedBox(height: 16),
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
                          buildSoftTh('PEÇA'),
                          buildSoftTh('VIDA ÚTIL'),
                          buildSoftTh('VALOR PEÇA'),
                          buildSoftTh('MÃO DE OBRA')
                        ]),
                    ...((data['pecas_desgaste'] as List).map((item) {
                      return pw.TableRow(children: [
                        buildSoftTd(item['peca']?.toString() ?? ''),
                        buildSoftTd(item['vida_util_media']?.toString() ?? ''),
                        buildSoftTd(formatCurrency(item['valor_peca_estimado'])),
                        buildSoftTd('${formatCurrency(item['valor_mao_de_obra_estimado'])} (${item['tempo_mao_de_obra_estimado']})'),
                      ]);
                    }).toList()),
                  ],
                ),
              ),
            if (validApontamentos.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF57F17),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text('APONTAMENTOS DA VISTORIA (VALORES ESTIMADOS)',
                    style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)),
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
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('PEÇA / PROBLEMA',
                                  style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('OBSERVAÇÃO',
                                  style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('VALOR PEÇA',
                                  style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                          pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('MÃO DE OBRA',
                                  style: pw.TextStyle(font: styles.bold, fontSize: 8, color: const PdfColor.fromInt(0xFFF57F17)))),
                        ]),
                    ...(validApontamentos.map((item) {
                      final peca = item['peca_ou_problema']?.toString() ?? '';
                      final obs = item['observacao_indicada']?.toString() ?? '';
                      final valPeca = formatCurrency(item['valor_peca_estimado']);
                      final valMaoObra = formatCurrency(item['valor_mao_de_obra_estimado']);

                      return pw.TableRow(children: [
                        buildSoftTd(peca),
                        buildSoftTd(obs),
                        buildSoftTd(valPeca),
                        buildSoftTd(valMaoObra),
                      ]);
                    }).toList()),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'OBSERVAÇÃO: Os valores de peças e mão de obra apresentados neste relatório são estimativas geradas de forma automatizada por Inteligência Artificial. Eles não representam um orçamento exato ou valor de mercado definitivo, podendo sofrer variações conforme a região, oficina ou fornecedor.',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.justify,
              ),
            ],
            
            if (data['observacoes'] != null && data['observacoes'] is List && (data['observacoes'] as List).isNotEmpty) ...[
                pw.SizedBox(height: 16),
                buildRedBar('OBSERVAÇÕES ADICIONAIS'),
                pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                        color: lightRed,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: borderRed, width: 1)),
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
                                    width: 3,
                                    height: 3,
                                    decoration: pw.BoxDecoration(color: themeRed, shape: pw.BoxShape.circle),
                                  ),
                                  pw.Expanded(
                                      child: pw.Text('$obs', style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark))),
                                ]));
                      }).toList()),
                    ))
            ],
            
            if (data['analise_final'] != null) ...[
              pw.SizedBox(height: 16),
              (() {
                final analise = data['analise_final'];
                final resumo = analise['resumo_estado_veiculo']?.toString() ?? '';
                
                final String valorMercado = _formatCurrencyBrl(analise['valor_venda_mercado_local']);
                final String desconto = apontamentosList.isEmpty 
                    ? 'R\$ 0,00' 
                    : _formatCurrencyBrl(analise['desconto_total_avarias']);
                final String valorSugerido = apontamentosList.isEmpty
                    ? valorMercado
                    : _formatCurrencyBrl(analise['valor_venda_sugerido_final']);
                    
                final justificativa = analise['justificativa']?.toString() ?? '';

                final mainGreen = PdfColor.fromHex('8CC63F');
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
                        child: pw.Text('ANÁLISE FINAL E AVALIAÇÃO DE MERCADO (IA)',
                            style: pw.TextStyle(font: styles.bold, fontSize: 9, color: PdfColors.white)),
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
                                pw.SizedBox(height: 6),
                                pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              pw.Text('Valor Médio Local:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
                                              pw.Text(valorMercado, style: pw.TextStyle(font: styles.bold, fontSize: 11, color: textDark)),
                                            ]),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                                            children: [
                                              pw.Text('Desconto (Avarias/Reparos):', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: blueColor)),
                                              pw.Text(desconto, style: pw.TextStyle(font: styles.bold, fontSize: 11, color: blueColor)),
                                            ]),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                                            children: [
                                              pw.Text('Valor Sugerido Final:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: mainGreen)),
                                              pw.Text(valorSugerido, style: pw.TextStyle(font: styles.bold, fontSize: 12, color: mainGreen)),
                                            ]),
                                      ),
                                    ]),
                                pw.SizedBox(height: 6),
                                pw.Text('Justificativa:', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
                                pw.SizedBox(height: 2),
                                pw.Text(justificativa, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark)),
                                pw.SizedBox(height: 10),
                                pw.Text(
                                    '* OBS: As estimativas de valores (mercado, peças, mão de obra e descontos) e o relatório técnico complementar desta ficha são gerados por Inteligência Artificial com base em médias de mercado. Estes valores servem apenas como referência comercial e não constituem promessa, garantia de preço de compra/venda ou orçamento exato.',
                                    style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.grey700)),
                              ]))
                    ]);
              })()
            ],
        ];
      }
    ));
"""

if old_block in content:
    new_content = content.replace(old_block, new_block)
    with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully replaced!")
else:
    print("Could not find the exact old_block in the file.")
