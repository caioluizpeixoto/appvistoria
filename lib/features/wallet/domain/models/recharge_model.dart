enum RechargeStatus {
  pending,
  paid,
  expired,
  cancelled,
  failed;

  static RechargeStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return RechargeStatus.paid;
      case 'expired':
        return RechargeStatus.expired;
      case 'cancelled':
        return RechargeStatus.cancelled;
      case 'failed':
        return RechargeStatus.failed;
      case 'pending':
      default:
        return RechargeStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case RechargeStatus.pending:
        return 'Aguardando';
      case RechargeStatus.paid:
        return 'Pago';
      case RechargeStatus.expired:
        return 'Expirado';
      case RechargeStatus.cancelled:
        return 'Cancelado';
      case RechargeStatus.failed:
        return 'Falhou';
    }
  }
}

class RechargeModel {
  final String id;
  final String companyId;
  final String? userId;
  final String walletId;
  final double amount;
  final RechargeStatus status;
  final String paymentMethod;
  final String provider;
  final String? externalId;
  final String? txid;
  final String? pixCopyPaste;
  final String? qrCodeData;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  const RechargeModel({
    required this.id,
    required this.companyId,
    this.userId,
    required this.walletId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.provider,
    this.externalId,
    this.txid,
    this.pixCopyPaste,
    this.qrCodeData,
    required this.createdAt,
    this.paidAt,
    this.expiresAt,
  });

  factory RechargeModel.fromJson(Map<String, dynamic> json) {
    return RechargeModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      userId: json['user_id'] as String?,
      walletId: json['wallet_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: RechargeStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentMethod: json['payment_method'] as String? ?? 'pix',
      provider: json['provider'] as String? ?? 'sicredi_future',
      externalId: json['external_id'] as String?,
      txid: json['txid'] as String?,
      pixCopyPaste: json['pix_copy_paste'] as String?,
      qrCodeData: json['qr_code_data'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'user_id': userId,
      'wallet_id': walletId,
      'amount': amount,
      'status': status.name,
      'payment_method': paymentMethod,
      'provider': provider,
      'external_id': externalId,
      'txid': txid,
      'pix_copy_paste': pixCopyPaste,
      'qr_code_data': qrCodeData,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
