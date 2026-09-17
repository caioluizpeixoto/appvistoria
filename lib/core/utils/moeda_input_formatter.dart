import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formata valores monetários em tempo real no padrão Real Brasileiro (R$ 0,00).
/// Conforme o usuário digita números, os centavos são deslocados automaticamente:
/// 1 -> 0,01
/// 15 -> 0,15
/// 150 -> 1,50
/// 1500 -> 15,00
/// 15000 -> 150,00
/// 150000 -> 1.500,00
class MoedaPtBrInputFormatter extends TextInputFormatter {
  final int maxDigits;

  MoedaPtBrInputFormatter({this.maxDigits = 11});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Extrai apenas os números
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty || int.tryParse(digitsOnly) == 0) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Limita o tamanho de dígitos
    String limitedDigits = digitsOnly;
    if (limitedDigits.length > maxDigits) {
      limitedDigits = limitedDigits.substring(0, maxDigits);
    }

    // Converte centavos para decimal
    final double value = double.parse(limitedDigits) / 100.0;

    // Formata usando a pontuação oficial pt_BR (#.##0,00)
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    final formattedText = formatter.format(value).trim();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  /// Converte texto formatado (ex: "1.500,00") para double (1500.0)
  static double? parse(String text) {
    final clean = text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return null;
    final val = double.tryParse(clean);
    if (val == null || val == 0) return null;
    return val / 100.0;
  }

  /// Formata um double para o texto monetário pt_BR (ex: 150.0 -> "150,00")
  static String format(double? value) {
    if (value == null || value <= 0) return '';
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }
}
