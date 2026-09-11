import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/models/recharge_model.dart';

class MinhasRecargasScreen extends StatefulWidget {
  const MinhasRecargasScreen({super.key});

  @override
  State<MinhasRecargasScreen> createState() => _MinhasRecargasScreenState();
}

class _MinhasRecargasScreenState extends State<MinhasRecargasScreen> {
  final WalletRepository _walletRepository = sl<WalletRepository>();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<RechargeModel> _recharges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecharges();
  }

  Future<void> _loadRecharges() async {
    setState(() => _isLoading = true);
    try {
      final list = await _walletRepository.getRecharges();
      if (mounted) {
        setState(() {
          _recharges = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar recargas: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  void _showRechargeDetails(RechargeModel recharge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalhes da Recarga',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  _buildStatusBadge(recharge.status),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                'Valor solicitado',
                _currencyFormat.format(recharge.amount),
                isBold: true,
              ),
              const Divider(height: 20),
              _buildDetailRow(
                'Forma de pagamento',
                recharge.paymentMethod.toUpperCase(),
              ),
              const Divider(height: 20),
              _buildDetailRow(
                'Data da solicitação',
                _dateFormat.format(recharge.createdAt),
              ),
              if (recharge.paidAt != null) ...[
                const Divider(height: 20),
                _buildDetailRow(
                  'Data do pagamento',
                  _dateFormat.format(recharge.paidAt!),
                ),
              ],
              const SizedBox(height: 20),
              if (recharge.status == RechargeStatus.pending)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.hourglass_top_rounded,
                          color: AppTheme.comObs, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aguardando liberação da integração bancária Sicredi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(RechargeStatus status) {
    Color textColor;
    Color bgColor;

    switch (status) {
      case RechargeStatus.paid:
        textColor = AppTheme.conforme;
        bgColor = AppTheme.conformeLight;
        break;
      case RechargeStatus.pending:
        textColor = AppTheme.comObs;
        bgColor = AppTheme.comObsLight;
        break;
      case RechargeStatus.expired:
      case RechargeStatus.cancelled:
      case RechargeStatus.failed:
        textColor = AppTheme.naoConforme;
        bgColor = AppTheme.naoConformeLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Minhas Recargas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: _loadRecharges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _recharges.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma recarga solicitada',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ao solicitar adição de saldo via Pix, suas recargas aparecerão listadas nesta área.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/carteira/adicionar-saldo'),
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text(
                            'Nova Recarga',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadRecharges,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recharges.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final recharge = _recharges[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.surfaceVariant,
                            radius: 22,
                            child: const Icon(
                              Icons.pix_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currencyFormat.format(recharge.amount),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              _buildStatusBadge(recharge.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Forma: ${recharge.paymentMethod.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  _dateFormat.format(recharge.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => _showRechargeDetails(recharge),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/carteira/adicionar-saldo');
          _loadRecharges();
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Recarregar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
