import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrCrlvResult {
  final String placa;
  final String renavam;
  final String chassi;
  final String anoFabricacao;
  final String anoModelo;
  final String cor;
  final String marcaModelo;
  final String combustivel;

  OcrCrlvResult({
    this.placa = '',
    this.renavam = '',
    this.chassi = '',
    this.anoFabricacao = '',
    this.anoModelo = '',
    this.cor = '',
    this.marcaModelo = '',
    this.combustivel = '',
  });

  bool get isEmpty =>
      placa.isEmpty &&
      renavam.isEmpty &&
      chassi.isEmpty &&
      anoFabricacao.isEmpty &&
      anoModelo.isEmpty &&
      cor.isEmpty &&
      marcaModelo.isEmpty &&
      combustivel.isEmpty;

  @override
  String toString() {
    return 'Placa: $placa, Renavam: $renavam, Chassi: $chassi, Ano: $anoFabricacao/$anoModelo, Cor: $cor, Modelo: $marcaModelo, Comb: $combustivel';
  }
}

class OcrCrlvService {
  static Future<OcrCrlvResult> scanImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final String text = recognizedText.text.toUpperCase();

      // Cleaned blocks for easier parsing
      final List<String> blocks =
          recognizedText.blocks.map((b) => b.text.toUpperCase()).toList();

      String placa = '';
      String renavam = '';
      String chassi = '';
      String anoFab = '';
      String anoMod = '';
      String cor = '';
      String marca = '';
      String combustivel = '';

      // Regex patterns
      final placaRegExp = RegExp(r'\b[A-Z]{3}[-]?[0-9][A-Z0-9][0-9]{2}\b');
      final renavamRegExp = RegExp(r'\b\d{11}\b');
      final chassiRegExp =
          RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b'); // Chassi valid chars
      final anoRegExp = RegExp(r'\b(19[8-9]\d|20[0-3]\d)\b'); // 1980 a 2039

      // Heuristics across all text blocks
      for (int i = 0; i < blocks.length; i++) {
        final blockText = blocks[i].replaceAll('\n', ' ');

        // PLACA
        if (placa.isEmpty) {
          final match = placaRegExp.firstMatch(blockText);
          if (match != null) {
            placa = match.group(0)!.replaceAll('-', '');
          }
        }

        // RENAVAM
        if (renavam.isEmpty) {
          final match = renavamRegExp.firstMatch(blockText);
          if (match != null) {
            renavam = match.group(0)!;
          }
        }

        // CHASSI
        if (chassi.isEmpty) {
          final match = chassiRegExp.firstMatch(blockText);
          if (match != null) {
            chassi = match.group(0)!;
          }
        }

        // ANO (ex: 2020/2021)
        if (anoFab.isEmpty && blockText.contains('/')) {
          final parts = blockText.split('/');
          for (var p in parts) {
            final m = anoRegExp.allMatches(p).toList();
            if (m.isNotEmpty && anoFab.isEmpty) {
              anoFab = m.first.group(0)!;
            } else if (m.isNotEmpty && anoMod.isEmpty) {
              anoMod = m.first.group(0)!;
            }
          }
        }

        // COR
        final coresConhecidas = [
          'BRANCA',
          'PRETA',
          'PRATA',
          'CINZA',
          'VERMELHA',
          'AZUL',
          'VERDE',
          'AMARELA',
          'MARROM',
          'BEGE',
          'FANTASIA'
        ];
        for (var c in coresConhecidas) {
          if (blockText.contains(c) && cor.isEmpty) {
            cor = c;
          }
        }

        // COMBUSTIVEL
        final combConhecidos = [
          'ALCOOL/GASOLINA',
          'ALCOOL/GASOL',
          'ALCOOL',
          'GASOLINA',
          'DIESEL',
          'FLEX',
          'ELETRICO',
          'HIBRIDO'
        ];
        for (var c in combConhecidos) {
          if (blockText.contains(c) && combustivel.isEmpty) {
            combustivel = c.replaceAll('ALCOOL', 'ÁLCOOL');
          }
        }

        // MARCA/MODELO
        // Heuristics: usually starts with I/ or VW/, FIAT/, GM/, CHEVROLET/, FORD/ etc.
        // Or if block contains "MARCA/MODELO", we check the next block
        if (blockText.contains('MARCA/MODELO') ||
            blockText.contains('MARCA / MODELO')) {
          if (i + 1 < blocks.length) {
            marca = blocks[i + 1].replaceAll('\n', ' ').trim();
            // Clean some possible garbage
            if (marca.contains('ESPECIE'))
              marca = marca.split('ESPECIE').first.trim();
          }
        } else if (marca.isEmpty) {
          final m = RegExp(
                  r'\b(VW/|FIAT/|GM/|CHEV/|FORD/|HONDA/|TOYOTA/|HYUNDAI/|RENAULT/|NISSAN/|JEEP/|I/)\S+')
              .firstMatch(blockText);
          if (m != null) {
            marca = blockText; // Take the whole block since models have spaces
          }
        }
      }

      // Fallback global search for Ano if not found
      if (anoFab.isEmpty) {
        final matches = anoRegExp.allMatches(text).toList();
        if (matches.isNotEmpty) anoFab = matches[0].group(0)!;
        if (matches.length > 1) anoMod = matches[1].group(0)!;
      }

      textRecognizer.close();

      return OcrCrlvResult(
        placa: placa,
        renavam: renavam,
        chassi: chassi,
        anoFabricacao: anoFab,
        anoModelo: anoMod,
        cor: cor,
        marcaModelo: marca,
        combustivel: combustivel,
      );
    } catch (e) {
      textRecognizer.close();
      print('OCR Error: $e');
      return OcrCrlvResult(); // empty
    }
  }
}
