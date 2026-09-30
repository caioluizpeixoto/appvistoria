import re

file_path = r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update themeGreen to _kOrange
content = content.replace("final themeGreen = PdfColor.fromHex('#1F5E3D');", "final themeGreen = _kOrange; // amarelo ouro")

# 2. Update buildSectionTitle text color
old_section = """        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: styles.bold,
            fontSize: 9,
            color: PdfColors.white,
            letterSpacing: 0.5,
          ),
        ),"""
new_section = """        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: styles.bold,
            fontSize: 9,
            color: textDark, // Preto para legibilidade sobre amarelo
            letterSpacing: 0.5,
          ),
        ),"""
content = content.replace(old_section, new_section)

# 3. Update top banner ANÁLISE ULTRA DO VEÍCULO text color
old_ultra = """                  'ANÁLISE ULTRA DO VEÍCULO',
                  style: pw.TextStyle(
                    font: styles.bold,
                    fontSize: 14,
                    color: PdfColors.white,
                    letterSpacing: 1.5,
                  ),"""
new_ultra = """                  'ANÁLISE ULTRA DO VEÍCULO',
                  style: pw.TextStyle(
                    font: styles.bold,
                    fontSize: 14,
                    color: textDark,
                    letterSpacing: 1.5,
                  ),"""
content = content.replace(old_ultra, new_ultra)

# 4. Update buildPremiumTable colors
old_table = """                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#263238')), // Blue Grey 900
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), 
                      child: pw.Text('INFORMAÇÃO', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.white))
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), 
                      child: pw.Text('DADOS', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: PdfColors.white))
                    ),
                  ]
                ),"""
new_table = """                pw.TableRow(
                  decoration: pw.BoxDecoration(color: themeGreen),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), 
                      child: pw.Text('INFORMAÇÃO', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: textDark))
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6), 
                      child: pw.Text('DADOS', style: pw.TextStyle(font: styles.bold, fontSize: 7, color: textDark))
                    ),
                  ]
                ),"""
content = content.replace(old_table, new_table)

# 5. Remove custom bgColors from buildSectionTitle
content = content.replace(", bgColor: PdfColor.fromHex('#2E7D32')", "")
content = content.replace(", bgColor: warningColor", "")
content = content.replace(", bgColor: PdfColor.fromHex('#1976D2')", "")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Patch concluído com sucesso!")