import re

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We need to find the start and end of _buildFichaTecnicaPages
# Start: "  void _buildFichaTecnicaPages("
# End: "  static pw.Widget _buildSituacaoGeralRow("
start_idx = content.find('  void _buildFichaTecnicaPages(')
end_idx = content.find('  static pw.Widget _buildSituacaoGeralRow(')

if start_idx != -1 and end_idx != -1:
    new_method = """  void _buildFichaTecnicaPages(
    pw.Document pdf,
    Map<String, dynamic> data,
    Vistoria vistoria,
    _PdfStyles styles,
    pw.ImageProvider? logo,
    pw.ImageProvider? assinatura,
    VistoriaWizardState? state,
  ) {
    final themeGreen = PdfColor.fromHex('#1F5E3D');
    final textDark = PdfColor.fromHex('#222222');
    final warningColor = PdfColor.fromHex('#F57F17');

    final rawApontamentos = data['apontamentos'] as List<dynamic>? ?? [];
    final valorFipeDouble = _parseFipeValue(data['fipe_valor_oficial']);
    
    final validApontamentos = VehicleDepreciationService.parseRespostaIa(rawApontamentos);
    final resultadoDepreciacao = VehicleDepreciationService.processar(
      valorFipe: valorFipeDouble,
      itens: validApontamentos,
    );

    pw.Widget buildSectionTitle(String title, {PdfColor? bgColor}) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
        decoration: pw.BoxDecoration(
          color: bgColor ?? themeGreen,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: styles.bold,
            fontSize: 9,
            color: PdfColors.white,
          ),
        ),
      );
    }

    pw.Widget buildItemText(String label, String value) {
      if (value.isEmpty) return pw.SizedBox.shrink();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$label: ', style: pw.TextStyle(font: styles.bold, fontSize: 8, color: textDark)),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: styles.regular, fontSize: 8, color: textDark))),
          ],
        ),
      );
    }

    final s1 = data['secao1_visao_geral'] as Map<String, dynamic>?;
    final s2 = data['secao2_pontos_positivos'] as List<dynamic>?;
    final s3 = data['secao3_pontos_atencao'] as List<dynamic>?;
    final s4 = data['secao4_destaques'] as List<dynamic>?;
    final s5 = data['secao5_ficha_tecnica'] as Map<String, dynamic>?;
    final s6 = data['secao6_desempenho_consumo'] as Map<String, dynamic>?;
    final s7 = data['secao7_manutencao_custos'] as Map<String, dynamic>?;
    final s8 = data['secao8_seguranca'] as Map<String, dynamic>?;
    final s9 = data['secao9_mercado'] as Map<String, dynamic>?;
    final s10 = data['secao10_analise_comprador'] as Map<String, dynamic>?;
    final s11 = data['secao11_resumo_executivo'] as Map<String, dynamic>?;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        header: (ctx) => _buildHeader(vistoria, styles, logo, state: state),
        footer: (ctx) => _buildPdfFooter(ctx, styles),
        build: (ctx) {
          final List<pw.Widget> widgets = [];

          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: themeGreen,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Center(
                child: pw.Text(
                  'ANÁLISE ULTRA DO VEÍCULO',
                  style: pw.TextStyle(
                    font: styles.bold,
                    fontSize: 14,
                    color: PdfColors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          );

          if (s1 != null) {
            widgets.add(buildSectionTitle('1. VISÃO GERAL DO VEÍCULO'));
            widgets.add(pw.Text(s1['resumo_apresentacao']?.toString() ?? '', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Perfil de Utilização: ${s1['perfil_utilizacao']?.toString() ?? ''}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Diferenciais: ${s1['principais_diferenciais']?.toString() ?? ''}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
          }

          if (s2 != null && s2.isNotEmpty) {
            widgets.add(buildSectionTitle('2. O QUE É BOM NESTE VEÍCULO'));
            for (var item in s2) {
              widgets.add(buildItemText(item['titulo']?.toString() ?? '', item['descricao']?.toString() ?? ''));
            }
          }

          if (s3 != null && s3.isNotEmpty) {
            widgets.add(buildSectionTitle('3. PONTOS QUE MERECEM ATENÇÃO', bgColor: warningColor));
            for (var item in s3) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF3E0'),
                    border: pw.Border.all(color: warningColor, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item['componente']?.toString() ?? '', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: warningColor)),
                      pw.SizedBox(height: 2),
                      buildItemText('Motivo', item['motivo']?.toString() ?? ''),
                      buildItemText('Sinais', item['sinais']?.toString() ?? ''),
                      buildItemText('Verificação', item['verificacao']?.toString() ?? ''),
                      buildItemText('Impacto/Custo', '${item['nivel_impacto']} - ${item['consequencia_financeira']}'),
                    ]
                  )
                )
              );
            }
          }

          if (s5 != null) {
            widgets.add(buildSectionTitle('FICHA TÉCNICA RESUMIDA'));
            final ident = s5['identificacao'] as Map?;
            final motor = s5['motorizacao'] as Map?;
            final trans = s5['transmissao_tracao'] as Map?;
            
            if (ident != null) {
              widgets.add(pw.Text('Veículo: ${ident['marca']} ${ident['modelo']} ${ident['versao']} (${ident['ano']})', style: pw.TextStyle(font: styles.bold, fontSize: 8)));
            }
            if (motor != null) {
              widgets.add(pw.Text('Motor: ${motor['tipo_motor']} ${motor['cilindrada']} - ${motor['potencia']} / ${motor['torque']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
            }
            if (trans != null) {
              widgets.add(pw.Text('Câmbio/Tração: ${trans['cambio']} ${trans['marchas']} - ${trans['tracao']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
            }
          }

          if (s6 != null) {
            final inds = s6['indicadores'] as List?;
            if (inds != null && inds.isNotEmpty) {
              widgets.add(buildSectionTitle('DESEMPENHO E CONSUMO'));
              for (var ind in inds) {
                widgets.add(buildItemText(ind['indicador']?.toString() ?? '', '${ind['valor']} - ${ind['explicacao']}'));
              }
            }
          }

          if (s7 != null) {
            widgets.add(buildSectionTitle('MANUTENÇÃO E CUSTOS'));
            final fluidos = s7['fluidos'] as List?;
            if (fluidos != null && fluidos.isNotEmpty) {
              widgets.add(pw.Text('Fluidos e Lubrificantes:', style: pw.TextStyle(font: styles.bold, fontSize: 8)));
              for (var f in fluidos) {
                widgets.add(pw.Text('- ${f['item']}: ${f['especificacao']} (${f['capacidade']}) - Troca: ${f['intervalo_troca']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
              }
              widgets.add(pw.SizedBox(height: 4));
            }
            final custos = s7['custos_estimados'] as List?;
            if (custos != null && custos.isNotEmpty) {
              widgets.add(pw.Text('Custos Estimados:', style: pw.TextStyle(font: styles.bold, fontSize: 8)));
              for (var c in custos) {
                widgets.add(pw.Text('- ${c['item']}: ${c['faixa_custo']}', style: pw.TextStyle(font: styles.regular, fontSize: 8)));
              }
            }
          }

          if (s11 != null) {
            widgets.add(buildSectionTitle('RESUMO EXECUTIVO'));
            widgets.add(buildItemText('Destaque', s11['destaque_principal']?.toString() ?? ''));
            widgets.add(buildItemText('Vantagens', s11['vantagens']?.toString() ?? ''));
            widgets.add(buildItemText('Atenção', s11['atencao']?.toString() ?? ''));
            widgets.add(buildItemText('Perfil Ideal', s11['perfil_ideal']?.toString() ?? ''));
          }

          // DEPRECIAÇÃO
          if (resultadoDepreciacao.itens.isNotEmpty) {
            widgets.add(buildSectionTitle('DEPRECIAÇÃO ESTIMADA POR APONTAMENTOS (${resultadoDepreciacao.itens.length} ITENS)', bgColor: warningColor));
            
            widgets.add(
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: warningColor, width: 0.5),
                ),
                child: pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.4),
                    1: pw.FlexColumnWidth(1.6),
                    2: pw.FlexColumnWidth(1.0),
                  },
                  border: pw.TableBorder.symmetric(inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF3E0')),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PEÇA', style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PROBLEMA', style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('CUSTO EST.', style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                      ]
                    ),
                    ...resultadoDepreciacao.itens.map((item) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.nomePeca, style: pw.TextStyle(font: styles.regular, fontSize: 7))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.descricaoProblema, style: pw.TextStyle(font: styles.regular, fontSize: 7))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(VehicleDepreciationService.formatarMoeda(item.valorTotalEstimado), style: pw.TextStyle(font: styles.bold, fontSize: 7))),
                        ]
                      );
                    }).toList()
                  ]
                )
              )
            );

            widgets.add(pw.SizedBox(height: 10));
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FCE4EC'),
                  border: pw.Border.all(color: PdfColor.fromHex('#F06292'), width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FIPE: ${resultadoDepreciacao.fipeDisponivel ? VehicleDepreciationService.formatarMoeda(resultadoDepreciacao.valorFipe) : "Indisponível"}', style: pw.TextStyle(font: styles.bold, fontSize: 9)),
                        pw.Text('Depreciação Total: ${VehicleDepreciationService.formatarMoeda(resultadoDepreciacao.depreciacaoTotal)}', style: pw.TextStyle(font: styles.bold, fontSize: 9, color: warningColor)),
                      ]
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('VALOR FINAL SUGERIDO', style: pw.TextStyle(font: styles.bold, fontSize: 8)),
                        pw.Text(resultadoDepreciacao.fipeDisponivel ? VehicleDepreciationService.formatarMoeda(resultadoDepreciacao.valorFinal) : "Indisponível", style: pw.TextStyle(font: styles.bold, fontSize: 12, color: themeGreen)),
                      ]
                    ),
                  ]
                )
              )
            );
          }

          return widgets;
        }
      )
    );
  }
"""

    new_content = content[:start_idx] + new_method + "\n" + content[end_idx:]
    with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Sucesso!")
else:
    print("Não encontrou os índices!")
