class PixChargeResult {
  final bool isAvailable;
  final String status;
  final String? txid;
  final String? pixCopyPaste;
  final String? qrCodeData;
  final String userMessage;

  const PixChargeResult({
    required this.isAvailable,
    required this.status,
    this.txid,
    this.pixCopyPaste,
    this.qrCodeData,
    required this.userMessage,
  });
}

abstract class PaymentProvider {
  String get providerName;

  /// Cria uma cobrança Pix (ou registra solicitação de recarga)
  Future<PixChargeResult> createPixCharge({
    required String rechargeId,
    required double amount,
    required String companyId,
  });

  /// Consulta o status atual de uma cobrança Pix
  Future<PixChargeResult> getPixCharge({
    required String rechargeId,
    String? txid,
  });

  /// Cancela uma cobrança Pix pendente
  Future<bool> cancelPixCharge({
    required String rechargeId,
    String? txid,
  });

  /// Processamento conceitual de webhook (a ser executado no backend / Edge Function)
  Future<bool> processPixWebhook(Map<String, dynamic> payload);
}
