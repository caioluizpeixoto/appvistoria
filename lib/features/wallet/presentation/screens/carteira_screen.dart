import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../domain/models/wallet_model.dart';
import '../../domain/models/wallet_transaction_model.dart';
import '../../data/repositories/wallet_repository.dart';

class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> {
  final WalletRepository _walletRepository = sl<WalletRepository>();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingTransactions = false;
  bool _isEnforcementActive = false;
  WalletTransactionType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _walletRepository.getOrCreateWallet();
      final enforcement = await _walletRepository.isEnforcementEnabled();
      final transactions = await _walletRepository.getTransactions(
        filterType: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isEnforcementActive = enforcement;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar carteira: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  Future<void> _filterTransactions(WalletTransactionType? filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoadingTransactions = true;
    });

    try {
      final transactions = await _walletRepository.getTransactions(
        filterType: filter,
      );
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoadingTransactions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Minha Carteira',
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
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            tooltip: 'Minhas Recargas',
            onPressed: () => context.push('/carteira/recargas'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: ValueListenableBuilder<WalletModel?>(
        valueListenable: _walletRepository.getWalletNotifier(),
        builder: (context, currentWallet, child) {
          if (_isLoading && currentWallet == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final balance = currentWallet?.balance ?? 0.0;
          final graceUsed = currentWallet?.graceOperationsUsed ?? 0;

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: _loadInitialData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card de Saldo
                        _buildBalanceCard(balance, graceUsed),
                        const SizedBox(height: 16),

                        // Atalhos de ação
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await context.push('/carteira/adicionar-saldo');
                                  _loadInitialData();
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.white),
                                label: const Text(
                                  'Adicionar saldo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/carteira/recargas'),
                              icon: const Icon(Icons.history_rounded,
                                  color: AppTheme.primary),
                              label: const Text(
                                'Recargas',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                side: const BorderSide(
                                    color: AppTheme.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Aviso de Tolerância (Somente exibido quando a cobrança estiver ativada)
                        if (_isEnforcementActive && graceUsed > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.comObsLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.comObs.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppTheme.comObs, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Você está utilizando operação de tolerância ($graceUsed de 2 utilizadas). Recarregue para renovar.',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Cabeçalho da seção Extrato
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Extrato de Operações',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${_transactions.length} registros',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filtros do Extrato
                        _buildFilterChips(),
                      ],
                    ),
                  ),
                ),

                // Lista do Extrato
                if (_isLoadingTransactions)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (_transactions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 56,
                            color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhuma movimentação encontrada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'As recargas e consumos aparecerão listados aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = _transactions[index];
                          return _buildTransactionTile(tx);
                        },
                        childCount: _transactions.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 32),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance, int graceUsed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Saldo disponível',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pré-pago',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilize seu saldo para pesquisas e consultas com liberação imediata.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos', null),
          const SizedBox(width: 8),
          _buildFilterChip('Entradas', WalletTransactionType.credit),
          const SizedBox(width: 8),
          _buildFilterChip('Saídas', WalletTransactionType.debit),
          const SizedBox(width: 8),
          _buildFilterChip('Utilizações', WalletTransactionType.usage),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, WalletTransactionType? type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
      ),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.border,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => _filterTransactions(type),
    );
  }

  Widget _buildTransactionTile(WalletTransactionModel tx) {
    IconData icon;
    Color iconColor;
    Color bgColor;
    String prefix;

    switch (tx.type) {
      case WalletTransactionType.credit:
        icon = Icons.arrow_downward_rounded;
        iconColor = AppTheme.conforme;
        bgColor = AppTheme.conformeLight;
        prefix = '+ ';
        break;
      case WalletTransactionType.debit:
        icon = Icons.arrow_upward_rounded;
        iconColor = AppTheme.naoConforme;
        bgColor = AppTheme.naoConformeLight;
        prefix = '- ';
        break;
      case WalletTransactionType.usage:
        icon = Icons.bolt_rounded;
        iconColor = AppTheme.accent;
        bgColor = AppTheme.surfaceVariant;
        prefix = '';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          radius: 20,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              _dateFormat.format(tx.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (tx.type == WalletTransactionType.usage && !_isEnforcementActive)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Consumo registrado',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.conforme,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (tx.usedGraceOperation)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Operação em tolerância',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.comObs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          '$prefix${_currencyFormat.format(tx.amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: tx.type == WalletTransactionType.credit
                ? AppTheme.conforme
                : tx.type == WalletTransactionType.debit
                    ? AppTheme.naoConforme
                    : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
