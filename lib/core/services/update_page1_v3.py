import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make donut chart larger and thicker, increase category header and text sizes
old_donut_func = '''  pw.Widget _buildDonutChart(
    int total, 
    int green, 
    int yellow, 
    int red, 
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
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
              final radius = 24.0;
              final stroke = 8.5;
              
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
              
              drawArcSegment(green, limeGreen);
              drawArcSegment(yellow, warningYellow);
              drawArcSegment(red, dangerRed);
            }
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$total', style: pw.TextStyle(font: styles.bold, fontSize: 12, color: PdfColors.black)),
              pw.Text('ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 5, color: PdfColors.grey600)),
            ]
          )
        ]
      )
    );
  }'''

new_donut_func = '''  pw.Widget _buildDonutChart(
    int total, 
    int green, 
    int yellow, 
    int red, 
    _PdfStyles styles,
    PdfColor limeGreen,
    PdfColor warningYellow,
    PdfColor dangerRed,
  ) {
    if (total == 0) return pw.SizedBox(height: 80);
    return pw.SizedBox(
      width: 80, height: 80,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(80, 80),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final center = PdfPoint(size.x / 2, size.y / 2);
              final radius = 32.0;
              final stroke = 11.0;
              
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
              
              drawArcSegment(green, limeGreen);
              drawArcSegment(yellow, warningYellow);
              drawArcSegment(red, dangerRed);
            }
          ),
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$total', style: pw.TextStyle(font: styles.bold, fontSize: 16, color: PdfColors.black)),
              pw.Text('ITENS', style: pw.TextStyle(font: styles.bold, fontSize: 6.5, color: PdfColors.grey600)),
            ]
          )
        ]
      )
    );
  }'''

content = content.replace(old_donut_func, new_donut_func)

# Also update column title font size and item text size in _buildCategoryColumn
content = content.replace("style: pw.TextStyle(font: styles.bold, fontSize: 8.5, color: PdfColors.grey800)", "style: pw.TextStyle(font: styles.bold, fontSize: 10, color: PdfColors.grey900)")
content = content.replace("fontSize: 6.2,", "fontSize: 6.5,")

with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated donut chart size to 80x80!')
