import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognizer {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _speechEnabled = false;
  static String _lastRecognizedWords = "";

  static Future<bool> init() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => print('SpeechToText onError: $val'),
      onStatus: (val) => print('SpeechToText onStatus: $val'),
    );
    return _speechEnabled;
  }

  static Future<void> startListening() async {
    _lastRecognizedWords = "";
    if (!_speechEnabled) {
      bool initialized = await init();
      if (!initialized) return;
    }
    
    await _speechToText.listen(
      onResult: (result) {
        _lastRecognizedWords = result.recognizedWords;
      },
      localeId: 'pt_BR',
    );
  }

  static Future<String?> stopListening(List<String> availableOptions) async {
    await _speechToText.stop();
    if (_lastRecognizedWords.isEmpty) return null;
    
    print('Texto reconhecido: $_lastRecognizedWords');
    return matchChecklistOption(_lastRecognizedWords, availableOptions);
  }

  static String normalize(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ã', 'a').replaceAll('â', 'a')
        .replaceAll('é', 'e').replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('õ', 'o').replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  static String? matchChecklistOption(String spokenText, List<String> availableOptions) {
    String normalizedSpoken = normalize(spokenText);
    
    // First, check for direct matches or contains
    for (String option in availableOptions) {
      String normalizedOption = normalize(option);
      if (normalizedSpoken.contains(normalizedOption)) {
        return option; // Match found!
      }
    }
    
    // Custom mappings for common synonyms
    if (normalizedSpoken.contains('amassado') || 
        normalizedSpoken.contains('riscado') || 
        normalizedSpoken.contains('trincado') || 
        normalizedSpoken.contains('quebrado') || 
        normalizedSpoken.contains('batido')) {
      return _findBest(availableOptions, ['Avariado']);
    }
    
    if (normalizedSpoken.contains('repintura')) {
      return _findBest(availableOptions, ['Repintado']);
    }
    
    return null; // Could not confidently match
  }
  
  static String? _findBest(List<String> options, List<String> targets) {
    for (var opt in options) {
      String normOpt = normalize(opt);
      for (var target in targets) {
        if (normOpt.contains(normalize(target))) {
          return opt;
        }
      }
    }
    return null;
  }
}
