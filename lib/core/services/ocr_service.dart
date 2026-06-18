import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Erro ao processar OCR: $e');
      return null;
    }
  }

  /// Tenta encontrar um padrão de chassi (17 caracteres alfanuméricos)
  String? extractChassi(String rawText) {
    final cleanText = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final match = RegExp(r'[A-HJ-NPR-Z0-9]{17}').firstMatch(cleanText);
    return match?.group(0);
  }

  /// Tenta encontrar uma placa padrão Mercosul (ABC1D23) ou antiga (ABC1234)
  String? extractPlaca(String rawText) {
    final cleanText = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final match = RegExp(r'[A-Z]{3}[0-9][A-Z0-9][0-9]{2}').firstMatch(cleanText);
    if (match != null) {
      final p = match.group(0)!;
      return '${p.substring(0, 3)}-${p.substring(3)}';
    }
    return null;
  }

  /// Limpa e retorna texto genérico para motor (não tem padrão rígido global)
  String extractMotor(String rawText) {
    // Retorna o maior bloco contínuo de caracteres alfanuméricos
    final blocks = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s]'), '').split(RegExp(r'\s+'));
    blocks.sort((a, b) => b.length.compareTo(a.length));
    return blocks.isNotEmpty ? blocks.first : '';
  }

  void dispose() {
    _textRecognizer.close();
  }
}
