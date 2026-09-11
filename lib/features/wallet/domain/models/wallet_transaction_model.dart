enum WalletTransactionType {
  credit,
  debit,
  usage;

  static WalletTransactionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'credit':
        return WalletTransactionType.credit;
      case 'debit':
        return WalletTransactionType.debit;
      case 'usage':
      default:
        return WalletTransactionType.usage;
    }
  }

  String get label {
    switch (this) {
      case WalletTransactionType.credit:
        return 'Entrada';
      case WalletTransactionType.debit:
        return 'Saída';
      case WalletTransactionType.usage:
        return 'Consumo';
    }
  }
}

class WalletTransactionModel {
  final String id;
  final String companyId;
  final String walletId;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final String? referenceType;
  final String? referenceId;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final bool usedGraceOperation;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.companyId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceType,
    this.referenceId,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.usedGraceOperation,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      walletId: json['wallet_id'] as String,
      type: WalletTransactionType.fromString(json['type'] as String? ?? 'usage'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'completed',
      usedGraceOperation: json['used_grace_operation'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'wallet_id': walletId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'status': status,
      'used_grace_operation': usedGraceOperation,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
