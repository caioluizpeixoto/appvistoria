import '../../database/app_database.dart';
import '../../features/vistoria/domain/vistoria_wizard_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';

class HtmlGeneratorService {
  static String generateHtml({
    required Vistoria vistoria,
    required Veiculo veiculo,
    required List<Map<String, dynamic>> allSections,
    VistoriaWizardState? state,
  }) {
    // Generate HTML string
    final sb = StringBuffer();
    sb.writeln('<!DOCTYPE html>');
    sb.writeln('<html lang="pt-BR">');
    sb.writeln('<head>');
    sb.writeln('<meta charset="UTF-8">');
    sb.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    sb.writeln('<title>Laudo Cautelar - ${vistoria.numeroLaudo}</title>');
    
    // Injetando Lightbox (GLightbox) para as imagens
    sb.writeln('<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/glightbox/dist/css/glightbox.min.css" />');
    sb.writeln('<script src="https://cdn.jsdelivr.net/gh/mcstudios/glightbox/dist/js/glightbox.min.js"></script>');

    sb.writeln('''
      <style>
        body { font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 0; background: #f4f4f9; color: #333; }
        .header { background: #222; color: #fff; padding: 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 24px; color: #8CC63F; }
        .header p { margin: 5px 0 0; font-size: 14px; color: #ccc; }
        .container { max-width: 800px; margin: 20px auto; padding: 0 15px; }
        .card { background: #fff; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); margin-bottom: 20px; padding: 20px; }
        .card h2 { margin-top: 0; font-size: 18px; border-bottom: 2px solid #8CC63F; padding-bottom: 10px; color: #222; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .info-item { font-size: 14px; }
        .info-item strong { color: #555; }
        .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 15px; margin-top: 15px; }
        .gallery-item { text-align: center; }
        .gallery-item img { width: 100%; height: 120px; object-fit: cover; border-radius: 6px; cursor: pointer; transition: transform 0.2s; border: 1px solid #ddd; }
        .gallery-item img:hover { transform: scale(1.05); }
        .gallery-item p { font-size: 12px; margin: 5px 0 0; font-weight: bold; color: #444; }
        .status { padding: 10px; border-radius: 4px; font-weight: bold; text-align: center; font-size: 18px; color: #fff; }
        .status.aprovado { background: #8CC63F; }
        .status.reprovado { background: #e74c3c; }
        .status.aprovado_restricao { background: #f39c12; }
        
        @media (max-width: 600px) {
          .info-grid { grid-template-columns: 1fr; }
          .gallery { grid-template-columns: repeat(2, 1fr); }
        }
      </style>
    ''');
    sb.writeln('</head>');
    sb.writeln('<body>');

    sb.writeln('''
      <div class="header">
        <h1>LAUDO CAUTELAR</h1>
        <p>Número do Laudo: ${vistoria.numeroLaudo}</p>
        <p>Data: ${vistoria.createdAt.day.toString().padLeft(2, '0')}/${vistoria.createdAt.month.toString().padLeft(2, '0')}/${vistoria.createdAt.year}</p>
      </div>
    ''');

    sb.writeln('<div class="container">');

    // Parecer Técnico (Status)
    String statusFinal = (vistoria.statusFinal ?? '').toUpperCase();
    String statusClass = 'status';
    if (statusFinal.contains('REPROVADO')) statusClass += ' reprovado';
    else if (statusFinal.contains('RESTRIÇÃO') || statusFinal.contains('RESTRICAO')) statusClass += ' aprovado_restricao';
    else if (statusFinal.contains('APROVADO')) statusClass += ' aprovado';
    else statusClass += ' aprovado';

    sb.writeln('''
      <div class="card">
        <h2>Parecer Técnico</h2>
        <div class="$statusClass">$statusFinal</div>
        <p style="margin-top: 15px; font-size: 14px; line-height: 1.5;">${vistoria.parecerTecnico?.replaceAll('\n', '<br>') ?? 'Nenhum parecer técnico informado.'}</p>
      </div>
    ''');

    // Dados do Veículo
    sb.writeln('''
      <div class="card">
        <h2>Dados do Veículo</h2>
        <div class="info-grid">
          <div class="info-item"><strong>Placa:</strong> ${veiculo.placa}</div>
          <div class="info-item"><strong>Marca/Modelo:</strong> ${veiculo.marca} / ${veiculo.modelo}</div>
          <div class="info-item"><strong>Ano:</strong> ${veiculo.anoFabricacao}/${veiculo.anoModelo}</div>
          <div class="info-item"><strong>Cor:</strong> ${veiculo.cor}</div>
          <div class="info-item"><strong>Chassi:</strong> ${veiculo.chassiVeiculo}</div>
          <div class="info-item"><strong>Motor:</strong> ${veiculo.motorVeiculo}</div>
        </div>
      </div>
    ''');

    // Galeria de Fotos
    for (var section in allSections) {
      if (section['fotos'] != null && (section['fotos'] as List).isNotEmpty) {
        sb.writeln('<div class="card">');
        sb.writeln('<h2>${section['titulo']}</h2>');
        sb.writeln('<div class="gallery">');

        for (var foto in (section['fotos'] as List<Map<String, dynamic>>)) {
          String url = (foto['url'] as String?) ?? '';
          
          if (url.isEmpty && foto['base64'] != null && (foto['base64'] as String).isNotEmpty) {
            url = 'data:image/jpeg;base64,${foto['base64']}';
          } else if (url.isEmpty && foto['path'] != null) {
            try {
              final file = File(foto['path']);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
                url = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              }
            } catch (_) {}
          }

          if (url.isNotEmpty) {
            sb.writeln('''
              <div class="gallery-item">
                <a href="$url" class="glightbox" data-title="${foto['label']}">
                  <img src="$url" alt="${foto['label']}" loading="lazy">
                </a>
                <p>${foto['label']}</p>
              </div>
            ''');
          }
        }

        sb.writeln('</div></div>');
      }
    }

    sb.writeln('</div>');

    // Inicialização do Lightbox
    sb.writeln('''
      <script>
        const lightbox = GLightbox({
          touchNavigation: true,
          loop: true,
          zoomable: true
        });
      </script>
    ''');

    sb.writeln('</body>');
    sb.writeln('</html>');

    return sb.toString();
  }
}
