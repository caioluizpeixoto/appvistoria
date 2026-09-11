class WalletModel {
  final String id;
  final String companyId;
  final double balance;
  final int graceOperationsUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.companyId,
    required this.balance,
    required this.graceOperationsUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      graceOperationsUsed: (json['grace_operations_used'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'balance': balance,
      'grace_operations_used': graceOperationsUsed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WalletModel copyWith({
    String? id,
    String? companyId,
    double? balance,
    int? graceOperationsUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      balance: balance ?? this.balance,
      graceOperationsUsed: graceOperationsUsed ?? this.graceOperationsUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
