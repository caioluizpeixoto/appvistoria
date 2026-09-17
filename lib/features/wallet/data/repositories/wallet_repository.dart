import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_vistoria/features/wallet/domain/models/wallet_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/recharge_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/service_price_model.dart';
import 'package:app_vistoria/features/wallet/data/payment/payment_provider.dart';

class OperationAuthorizationResult {
  final bool allowed;
  final bool enforcementEnabled;
  final double balance;
  final int graceOperationsUsed;
  final bool usedGraceOperation;
  final int? graceOperationsRemaining;
  final double consumedAmount;
  final String? reason;

  const OperationAuthorizationResult({
    required this.allowed,
    required this.enforcementEnabled,
    required this.balance,
    required this.graceOperationsUsed,
    this.usedGraceOperation = false,
    this.graceOperationsRemaining,
    this.consumedAmount = 0.0,
    this.reason,
  });

  factory OperationAuthorizationResult.fromJson(Map<String, dynamic> json) {
    return OperationAuthorizationResult(
      allowed: json['allowed'] as bool? ?? false,
      enforcementEnabled: json['enforcement_enabled'] as bool? ?? false,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      graceOperationsUsed: (json['grace_operations_used'] as num?)?.toInt() ?? 0,
      usedGraceOperation: json['used_grace_operation'] as bool? ?? false,
      graceOperationsRemaining: (json['grace_operations_remaining'] as num?)?.toInt(),
      consumedAmount: (json['consumed_amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
    );
  }
}

class WalletRepository {
  final SupabaseClient supabase;
  final PaymentProvider paymentProvider;

  WalletRepository({
    required this.supabase,
    required this.paymentProvider,
  });

  String? get currentUserId => supabase.auth.currentUser?.id;

  /// Obtém a carteira da empresa autenticada ou inicializa uma com saldo R$ 0,00
  Future<WalletModel> getOrCreateWallet() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      final res = await supabase.rpc('get_or_create_wallet');
      if (res != null && res is Map<String, dynamic>) {
        return WalletModel.fromJson(res);
      }
    } catch (_) {
      // Fallback para consulta direta caso o RPC retorne formato alternativo
    }

    final query = await supabase
        .from('wallets')
        .select()
        .eq('company_id', userId)
        .maybeSingle();

    if (query != null) {
      return WalletModel.fromJson(query);
    }

    // Se ainda não existir registro, insere
    final inserted = await supabase
        .from('wallets')
        .insert({
          'company_id': userId,
          'balance': 0.00,
          'grace_operations_used': 0,
        })
        .select()
        .single();

    return WalletModel.fromJson(inserted);
  }

  /// Escuta atualizações da carteira em tempo real via Supabase Realtime
  Stream<WalletModel?> streamWallet() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('company_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return WalletModel.fromJson(rows.first);
        });
  }

  /// Lista o extrato de movimentações da carteira com filtro opcional
  Future<List<WalletTransactionModel>> getTransactions({
    WalletTransactionType? filterType,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = supabase
        .from('wallet_transactions')
        .select()
        .eq('company_id', userId);

    if (filterType != null) {
      query = query.eq('type', filterType.name);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lista o histórico de solicitações de recarga
  Future<List<RechargeModel>> getRecharges() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final data = await supabase
        .from('recharges')
        .select()
        .eq('company_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => RechargeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Solicita uma recarga via Pix
  /// Solicita uma recarga via Pix através do Backend
  Future<Map<String, dynamic>> requestRecharge(double amount) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuário não autenticado.');
    }

    // Chama a Edge Function que centraliza as regras de segurança e criação
    final response = await supabase.functions.invoke(
      'create-pix-charge',
      body: {'amount': amount},
    );

    if (response.status != 200) {
      final data = response.data;
      throw Exception(data != null && data is Map && data['error'] != null
          ? data['error']
          : 'Falha ao processar pagamento Pix.');
    }

    final data = response.data as Map<String, dynamic>;

    return {
      'recharge': RechargeModel.fromJson({
        'id': data['recharge_id'],
        'amount': data['amount'],
        'status': 'pending',
        'company_id': userId,
      }),
      'charge_result': {
        'txid': data['txid'],
        'pixCopyPaste': data['pixCopyPaste'],
        'qrCodeData': data['qrCodeData'],
      },
    };
  }

  /// Autoriza uma operação paga de forma segura e atômica no backend Supabase
  Future<OperationAuthorizationResult> authorizePaidOperation({
    required String serviceCode,
    required String referenceType,
    required String referenceId,
    String? description,
  }) async {
    final res = await supabase.rpc(
      'authorize_paid_operation',
      params: {
        'p_service_code': serviceCode,
        'p_reference_type': referenceType,
        'p_reference_id': referenceId,
        'p_description': description,
      },
    );

    if (res is Map<String, dynamic>) {
      return OperationAuthorizationResult.fromJson(res);
    }

    return const OperationAuthorizationResult(
      allowed: false,
      enforcementEnabled: false,
      balance: 0.0,
      graceOperationsUsed: 0,
      reason: 'UNKNOWN_RESPONSE',
    );
  }

  /// Busca os preços de serviços configurados
  Future<List<ServicePriceModel>> getServicePrices() async {
    final data = await supabase
        .from('service_prices')
        .select()
        .eq('active', true)
        .order('price', ascending: true);

    return (data as List)
        .map((item) => ServicePriceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Verifica se a cobrança financeira está ativada no Supabase
  Future<bool> isEnforcementEnabled() async {
    try {
      final res = await supabase.rpc('is_financial_enforcement_enabled');
      return res as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
