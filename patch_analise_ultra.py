import re
import sys

def patch():
    file_path = r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update Title Banner text
    content = content.replace("'FICHA TÉCNICA INTELIGENTE DO VEÍCULO (IA)'", "'ANÁLISE ULTRA DO VEÍCULO'")
    
    # 2. Find and replace buildSpecsAndMaintenanceSideBySide and buildPecasDesgaste
    start_specs = content.find("pw.Widget buildSpecsAndMaintenanceSideBySide() {")
    end_pecas = content.find("pw.Widget buildApontamentosWidget() {")
    
    if start_specs == -1 or end_pecas == -1:
        print("Could not find the bounds for replacing.")
        sys.exit(1)
        
    replacement = """pw.Widget buildAnaliseModeloWidget() {
      final analise = data['analise_modelo'] as Map<String, dynamic>?;
      if (analise == null || analise.isEmpty) return pw.SizedBox.shrink();

      final pontosAtencao = (analise['pontos_atencao'] as List<dynamic>?)?.cast<String>() ?? [];
      final problemasConhecidos = (analise['problemas_conhecidos'] as List<dynamic>?)?.cast<String>() ?? [];
      final manutencao = (analise['manutencao'] as List<dynamic>?)?.cast<String>() ?? [];
      final outrosFluidos = (analise['outros_fluidos'] as List<dynamic>?)?.cast<String>() ?? [];
      final checklist = (analise['checklist'] as List<dynamic>?)?.cast<String>() ?? [];
      final oleoMotor = analise['oleo_motor'] as Map<String, dynamic>?;

      pw.Widget buildListSection(String title, List<String> items, {PdfColor bgColor = lightRed, PdfColor borderColor = borderRed, PdfColor iconColor = themeRed}) {
        if (items.isEmpty) return pw.SizedBox.shrink();
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildRedBar(title, bgColor: bgColor),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFAFAFA),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                border: pw.Border.all(color: borderColor, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 3, right: 4),
                          width: 3,
                          height: 3,
                          decoration: pw.BoxDecoration(
                            color: iconColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            item,
                            style: pw.TextStyle(
                              font: styles.regular,
                              fontSize: 7,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 6),
          ],
        );
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    buildListSection('PONTOS DE ATENÇÃO DO MODELO', pontosAtencao, bgColor: const PdfColor.fromInt(0xFFFFF3E0), borderColor: const PdfColor.fromInt(0xFFFFB74D), iconColor: const PdfColor.fromInt(0xFFF57C00)),
                    buildListSection('PROBLEMAS CRÔNICOS CONHECIDOS', problemasConhecidos, bgColor: const PdfColor.fromInt(0xFFFFEBEE), borderColor: borderRed, iconColor: themeRed),
                    if (oleoMotor != null && oleoMotor.isNotEmpty)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          buildRedBar('ESPECIFICAÇÕES DE ÓLEO DO MOTOR', bgColor: mainGreen),
                          pw.Container(
                            width: double.infinity,
                            decoration: pw.BoxDecoration(
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFF81C784), width: 0.5),
                            ),
                            child: pw.Table(
                              columnWidths: const {
                                0: pw.FlexColumnWidth(1.0),
                                1: pw.FlexColumnWidth(1.2),
                              },
                              border: pw.TableBorder.symmetric(
                                inside: const pw.BorderSide(color: PdfColor.fromInt(0xFF81C784), width: 0.5),
                              ),
                              children: oleoMotor.entries.map((e) {
                                return pw.TableRow(children: [
                                  buildSoftTh(e.key.replaceAll('_', ' ').toUpperCase()),
                                  buildSoftTd(e.value.toString()),
                                ]);
                              }).toList(),
                            ),
                          ),
                          pw.SizedBox(height: 6),
                        ],
                      ),
                  ]
                )
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    buildListSection('MANUTENÇÃO RECOMENDADA', manutencao, bgColor: const PdfColor.fromInt(0xFFE8F5E9), borderColor: const PdfColor.fromInt(0xFF81C784), iconColor: const PdfColor.fromInt(0xFF388E3C)),
                    buildListSection('OUTROS FLUIDOS', outrosFluidos, bgColor: const PdfColor.fromInt(0xFFE3F2FD), borderColor: const PdfColor.fromInt(0xFF64B5F6), iconColor: const PdfColor.fromInt(0xFF1976D2)),
                    buildListSection('CHECKLIST ESPECÍFICO DO MODELO', checklist, bgColor: const PdfColor.fromInt(0xFFF3E5F5), borderColor: const PdfColor.fromInt(0xFFBA68C8), iconColor: const PdfColor.fromInt(0xFF7B1FA2)),
                  ]
                )
              ),
            ],
          ),
        ],
      );
    }

    """
    
    new_content = content[:start_specs] + replacement + content[end_pecas:]
    
    # 3. Update the place where it calls the old widgets
    call_old = """                  buildSpecsAndMaintenanceSideBySide(),
                  pw.SizedBox(height: 6),
                  buildPecasDesgaste(),
                  if (data['pecas_desgaste'] != null && (data['pecas_desgaste'] as List).isNotEmpty)
                    pw.SizedBox(height: 6),"""
                    
    call_new = """                  buildAnaliseModeloWidget(),"""
    new_content = new_content.replace(call_old, call_new)
    
    # 4. Update resumo pointer in buildAnaliseFinalWidget
    # "final resumo = data['resumo_inteligente']?.toString() ?? '';" -> "final resumo = (data['analise_modelo'] as Map?)?['resumo']?.toString() ?? '';"
    new_content = new_content.replace(
        "final resumo = data['resumo_inteligente']?.toString() ?? '';", 
        "final resumo = (data['analise_modelo'] as Map?)?['resumo']?.toString() ?? '';"
    )
    
    # 5. Fix "Se o conteúdo couber em 1 página (menos de 4 apontamentos e poucas observações)" logic
    # It still uses validApontamentos.length, but it doesn't know about pecas_desgaste anymore, which is fine since it's gone.
    # The page logic is mostly safe. Let's make sure there are no other references to `especificacoes_tecnicas`.
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    print("Patched successfully!")

if __name__ == '__main__':
    patch()
