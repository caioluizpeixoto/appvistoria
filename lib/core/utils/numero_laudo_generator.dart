import 'dart:math';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class NumeroLaudoGenerator {
  static final _uuid = Uuid();

  /// Gera número de laudo no formato:
  /// XXXXXXXX-YYYYMMDD-HHmmss-SSSS-RRRRRR
  static String gerar() {
    final now = DateTime.now();
    final parte1 = _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    final parte2 = DateFormat('yyyyMMdd').format(now);
    final parte3 = DateFormat('HHmmss').format(now);
    final parte4 = Random().nextInt(9999).toString().padLeft(4, '0');
    final parte5 =
        Random().nextInt(999999).toString().padLeft(6, '0');
    return '$parte1-$parte2-$parte3-$parte4-$parte5';
  }
}
