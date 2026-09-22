import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/wallet_repository.dart';

class InsufficientBalanceDialog extends StatelessWidget {
  final OperationAuthorizationResult authResult;
  final String? customServiceName;
  final double? customPrice;

  const InsufficientBalanceDialog({
    super.key,
    required this.authResult,
    this.customServiceName,
    this.customPrice,
  });

  static Future<bool?> show(
    BuildContext context, {
    required OperationAuthorizationResult authResult,
    String? customServiceName,
    double? customPrice,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InsufficientBalanceDialog(
        authResult: authResult,
        customServiceName: customServiceName,
        customPrice: customPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final serviceName = customServiceName ?? authResult.serviceName ?? 'Operação solicitada';
    final price = customPrice ?? (authResult.price > 0 ? authResult.price : 0.0);
    final currentBalance = authResult.balance;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.naoConformeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.naoConforme,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Saldo Insuficiente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Você não possui saldo suficiente para realizar esta operação.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Serviço:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Flexible(
                      child: Text(
                        serviceName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                if (price > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor do serviço:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      Text(
                        currencyFormat.format(price),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16, color: AppTheme.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Seu saldo atual:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text(
                      currencyFormat.format(currentBalance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: currentBalance < 0 ? AppTheme.naoConforme : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (authResult.graceOperationsUsed >= 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.comObsLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.comObs.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.comObs, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suas operações de tolerância já foram utilizadas. Recarregue para renovar seu limite.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Voltar', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    context.push('/carteira/adicionar-saldo');
                  },
                  icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Recarregar via PIX',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
