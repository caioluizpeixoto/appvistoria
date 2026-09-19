import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_vistoria/features/wallet/domain/models/wallet_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/wallet_transaction_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/recharge_model.dart';
import 'package:app_vistoria/features/wallet/domain/models/service_price_model.dart';
import 'package:app_vistoria/features/wallet/data/payment/payment_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      graceOperationsUsed:
          (json['grace_operations_used'] as num?)?.toInt() ?? 0,
      usedGraceOperation: json['used_grace_operation'] as bool? ?? false,
      graceOperationsRemaining:
          (json['grace_operations_remaining'] as num?)?.toInt(),
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
        final wallet = WalletModel.fromJson(res);
        walletNotifier.value = wallet;
        return wallet;
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
      final wallet = WalletModel.fromJson(query);
      walletNotifier.value = wallet;
      return wallet;
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

    final newWallet = WalletModel.fromJson(inserted);
    walletNotifier.value = newWallet;
    return newWallet;
  }

  final ValueNotifier<WalletModel?> walletNotifier = ValueNotifier(null);
  RealtimeChannel? _walletChannel;

  /// Retorna o ValueNotifier da carteira para a UI reagir instantaneamente
  ValueNotifier<WalletModel?> getWalletNotifier() {
    final userId = currentUserId;
    if (userId == null) return walletNotifier;

    // Se já estiver escutando, apenas retorna o notifier
    if (_walletChannel != null) return walletNotifier;

    // Busca o valor inicial e notifica
    getOrCreateWallet().then((wallet) {
      walletNotifier.value = wallet;
    });

    // Configura o listener do Supabase
    _walletChannel = supabase
        .channel('public:wallets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'company_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              walletNotifier.value = WalletModel.fromJson(payload.newRecord);
            }
          },
        )
        .subscribe();

    return walletNotifier;
  }

  /// Lista o extrato de movimentações da carteira com filtro opcional
  Future<List<WalletTransactionModel>> getTransactions({
    WalletTransactionType? filterType,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query =
        supabase.from('wallet_transactions').select().eq('company_id', userId);

    if (filterType != null) {
      query = query.eq('type', filterType.name);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((item) =>
            WalletTransactionModel.fromJson(item as Map<String, dynamic>))
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
  /// Solicita uma recarga via Pix através do Backend Node.js
  Future<Map<String, dynamic>> requestRecharge(double amount) async {
    final userId = currentUserId;
    final session = supabase.auth.currentSession;

    if (userId == null || session == null) {
      throw Exception('Usuário não autenticado.');
    }

    final dio = Dio();

    // URL base do backend Node.js
    // Usa localhost (ou 10.0.2.2 no android) dependendo da plataforma
    final isAndroidEmulator =
        defaultTargetPlatform == TargetPlatform.android && !kIsWeb;
    final baseUrl = const String.fromEnvironment('PIX_BACKEND_URL',
        defaultValue: 'http://localhost:3000');
    final endpointUrl =
        (baseUrl == 'http://localhost:3000' && isAndroidEmulator)
            ? 'http://10.0.2.2:3000/api/pix/create-charge'
            : '$baseUrl/api/pix/create-charge';

    try {
      final response = await dio.post(
        endpointUrl,
        data: {'amount': amount},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      final data = response.data ?? {};

      return {
        'recharge': RechargeModel.fromJson({
          'id': data['id']?.toString() ?? '',
          'amount': data['amount'] ?? amount,
          'status': data['status']?.toString() ?? 'pending',
          'company_id': userId,
          'wallet_id': data['wallet_id']?.toString() ?? '',
        }),
        'charge_result': {
          'txid': data['txid']?.toString() ?? '',
          'pixCopyPaste': (data['pixCopyPaste'] ?? data['pixCopiaECola'])?.toString(),
          'qrCodeData': (data['pixCopyPaste'] ?? data['pixCopiaECola'])?.toString(),
          'expiresAt': data['expiresAt']?.toString() ?? data['expiracao']?.toString(),
        },
      };
    } on DioException catch (e) {
      String errorMsg = 'Falha ao processar pagamento Pix.';
      if (e.response?.data is Map<String, dynamic>) {
        errorMsg = e.response?.data['error'] ?? errorMsg;
      } else if (e.response?.data is String) {
        errorMsg = 'Erro do servidor: ${e.response?.statusCode}';
      }
      throw Exception(errorMsg);
    }
  }

  /// Verifica ativamente o status de uma recarga no backend Node.js
  /// Isso força o backend a consultar o Sicredi e atualizar o banco (fallback para webhooks)
  Future<void> checkRechargeStatus(String txid) async {
    final session = supabase.auth.currentSession;
    if (session == null || txid.isEmpty) return;

    final dio = Dio();
    final isAndroidEmulator = defaultTargetPlatform == TargetPlatform.android && !kIsWeb;
    final baseUrl = const String.fromEnvironment('PIX_BACKEND_URL', defaultValue: 'http://localhost:3000');
    final endpointUrl = (baseUrl == 'http://localhost:3000' && isAndroidEmulator)
        ? 'http://10.0.2.2:3000/api/pix/charge/$txid'
        : '$baseUrl/api/pix/charge/$txid';

    try {
      await dio.get(
        endpointUrl,
        options: Options(
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        ),
      );
    } catch (_) {
      // Falhas silenciosas aqui pois é apenas um processo em background de sincronização
    }
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
      final authResult = OperationAuthorizationResult.fromJson(res);
      
      // Se a operação foi permitida (cobrada), atualiza a UI localmente e em background
      if (authResult.allowed) {
        final currentWallet = walletNotifier.value;
        if (currentWallet != null) {
          // Atualiza instantaneamente a UI para não ter delay nenhum
          walletNotifier.value = WalletModel(
            id: currentWallet.id,
            companyId: currentWallet.companyId,
            balance: authResult.balance,
            graceOperationsUsed: authResult.graceOperationsUsed,
            createdAt: currentWallet.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        // Dispara uma busca real no banco para garantir consistência em background
        getOrCreateWallet().catchError((_) => currentWallet); // Ignora erros do background
      }
      
      return authResult;
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
