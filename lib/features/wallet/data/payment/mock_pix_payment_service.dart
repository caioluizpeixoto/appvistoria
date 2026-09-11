import 'package:app_vistoria/features/wallet/data/payment/payment_provider.dart';

/// Provedor temporário de pagamento Pix enquanto a integração bancária real (Sicredi)
/// não estiver homologada e ativa.
///
/// NUNCA gera QR Code falso, TXID falso ou Pix Copia e Cola fictício.
class MockPixPaymentService implements PaymentProvider {
  @override
  String get providerName => 'sicredi_future';

  @override
  Future<PixChargeResult> createPixCharge({
    required String rechargeId,
    required double amount,
    required String companyId,
  }) async {
    // Simula resposta assíncrona sem dados fictícios de pagamento
    await Future.delayed(const Duration(milliseconds: 300));

    return const PixChargeResult(
      isAvailable: false,
      status: 'integration_pending',
      txid: null,
      pixCopyPaste: null,
      qrCodeData: null,
      userMessage:
          'Pagamento Pix ainda não disponível. A integração bancária está sendo preparada.',
    );
  }

  @override
  Future<PixChargeResult> getPixCharge({
    required String rechargeId,
    String? txid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return const PixChargeResult(
      isAvailable: false,
      status: 'integration_pending',
      txid: null,
      pixCopyPaste: null,
      qrCodeData: null,
      userMessage: 'Aguardando liberação da integração bancária.',
    );
  }

  @override
  Future<bool> cancelPixCharge({
    required String rechargeId,
    String? txid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  @override
  Future<bool> processPixWebhook(Map<String, dynamic> payload) async {
    // Webhook conceitual: no futuro será processado via Edge Function no Supabase
    return false;
  }
}
