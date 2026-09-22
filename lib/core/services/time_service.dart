import 'package:ntp/ntp.dart';

class TimeService {
  Duration _offset = Duration.zero;

  /// Obtém o offset em relação ao relógio verdadeiro usando NTP.
  /// Se falhar, usa a hora local sem alterar.
  Future<void> init() async {
    try {
      final ntpTime = await NTP.now(timeout: const Duration(seconds: 5));
      _offset = ntpTime.difference(DateTime.now());
      print('[TimeService] NTP Sync Sucesso. Offset: ${_offset.inMilliseconds}ms');
    } catch (e) {
      print('[TimeService] Erro ao obter NTP: $e. Usando hora local.');
    }
  }

  /// Retorna o horário real atual focado no fuso horário de Brasília (UTC-3).
  DateTime nowBrasilia() {
    // Hora real (corrigida pelo offset NTP)
    final trueNow = DateTime.now().add(_offset);
    
    // Converte para UTC verdadeiro e ajusta para -3 horas (Brasília)
    return trueNow.toUtc().subtract(const Duration(hours: 3));
  }
}
