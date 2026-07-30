import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _buildPageFotosGrid to gracefully render placeholder when file path is missing or empty
old_card_render = '''                    try {
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
                    }'''

new_card_render = '''                    final label = (f['label'] as String? ?? '').toUpperCase();
                    pw.Widget imageWidget;
                    
                    try {
                      final pathStr = f['path'] as String? ?? '';
                      if (f['base64'] != null && (f['base64'] as String).isNotEmpty) {
                        final bytes = base64Decode(f['base64'] as String);
                        imageWidget = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                      } else if (pathStr.isNotEmpty && File(pathStr).existsSync()) {
                        final bytes = File(pathStr).readAsBytesSync();
                        imageWidget = pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover);
                      } else if (logo != null) {
                        imageWidget = pw.Center(
                          child: pw.Opacity(
                            opacity: 0.2,
                            child: pw.Container(width: 120, child: pw.Image(logo, fit: pw.BoxFit.contain)),
                          ),
                        );
                      } else {
                        imageWidget = pw.Center(
                          child: pw.Text('Sem foto', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                        );
                      }
                    } catch (e) {
                      imageWidget = pw.Center(
                        child: pw.Text('Sem foto', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                      );
                    }

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
                              child: imageWidget,
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
                    );'''

content = content.replace(old_card_render, new_card_render)

# 2. Update page generation block in buildPdf to build EXACTLY the 6 main photos for Page 2
old_photos_generation = '''      bool hasAnyPhoto = false;
      final chunkSize = 6;

      if (wizardState != null) {
        for (final entry in secoesFotos.entries) {
          final tituloSecao = entry.key;
          final orderedFotoIds = entry.value;

          final fotosSecao = <Map<String, dynamic>>[];
          for (final id in orderedFotoIds) {
            final locals = wizardState.getFotosLocais(id);
            for (final localPath in locals) {
              final f = File(localPath);
              if (f.existsSync()) {
                var label = id.toUpperCase();
                if (label.startsWith('PECA_') || label.startsWith('PEÇA_')) {
                  label = label.replaceFirst(RegExp(r'^PE[CÇ]A_'), '');
                }
                label = label.replaceAll('_', ' ');

                fotosSecao.add({
                  'path': localPath,
                  'label': label,
                });
              }
            }
          }

          if (fotosSecao.isNotEmpty) {
            hasAnyPhoto = true;
            for (var i = 0; i < fotosSecao.length; i += chunkSize) {
              final end = (i + chunkSize < fotosSecao.length) ? i + chunkSize : fotosSecao.length;
              final chunk = fotosSecao.sublist(i, end);
              pdf.addPage(_buildPageFotosGrid(
                veiculo: veiculo,
                titulo: i == 0 ? tituloSecao : '$tituloSecao (CONT.)',
                fotos: chunk,
                vistoria: vistoria,
                styles: styles,
                logo: logoImage,
                assinatura: assinaturaImage,
                state: wizardState,
              ));
            }
          }
        }
      }'''

new_photos_generation = '''      // Configuração Exata das 6 Fotos Principais da Página 2
      final main6Config = [
        {'id': 'chassi_gravacao', 'altId': 'chassi', 'label': 'CHASSI'},
        {'id': 'motor_gravacao', 'altId': 'motor', 'label': 'MOTOR'},
        {'id': 'frente_direita', 'altId': 'dianteira_direita', 'label': 'DIANTEIRA C/ LATERAL DIREITA'},
        {'id': 'frente_esquerda', 'altId': 'dianteira_esquerda', 'label': 'DIANTEIRA C/ LATERAL ESQUERDA'},
        {'id': 'traseira_direita', 'altId': 'traseira_direita', 'label': 'TRASEIRA C/ LATERAL DIREITA'},
        {'id': 'traseira_esquerda', 'altId': 'traseira_esquerda', 'label': 'TRASEIRA C/ LATERAL ESQUERDA'},
      ];

      final fotosPagina2 = <Map<String, dynamic>>[];
      for (final cfg in main6Config) {
        String? path;
        if (wizardState != null) {
          var locals = wizardState.getFotosLocais(cfg['id']!);
          if (locals.isEmpty && cfg['altId'] != null) {
            locals = wizardState.getFotosLocais(cfg['altId']!);
          }
          if (locals.isNotEmpty) {
            path = locals.first;
          }
        }
        fotosPagina2.add({
          'path': path ?? '',
          'label': cfg['label']!,
        });
      }

      // Adiciona a Página 2 com exatamente as 6 fotos principais
      pdf.addPage(_buildPageFotosGrid(
        veiculo: veiculo,
        titulo: 'FOTOS PRINCIPAIS DA VISTORIA',
        fotos: fotosPagina2,
        vistoria: vistoria,
        styles: styles,
        logo: logoImage,
        assinatura: assinaturaImage,
        state: wizardState,
      ));'''

content = content.replace(old_photos_generation, new_photos_generation)

with open(r'lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated exact 6 main photos for Page 2!')
