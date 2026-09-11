import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../data/repositories/wallet_repository.dart';

class AdicionarSaldoScreen extends StatefulWidget {
  const AdicionarSaldoScreen({super.key});

  @override
  State<AdicionarSaldoScreen> createState() => _AdicionarSaldoScreenState();
}

class _AdicionarSaldoScreenState extends State<AdicionarSaldoScreen> {
  final WalletRepository _walletRepository = sl<WalletRepository>();
  final TextEditingController _customValueController = TextEditingController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final List<double> _quickAmounts = [50.0, 100.0, 200.0, 500.0, 1000.0];
  double? _selectedAmount = 100.0;
  bool _isCustomSelected = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _customValueController.dispose();
    super.dispose();
  }

  void _onQuickSelect(double amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomSelected = false;
      _customValueController.clear();
    });
  }

  void _onSelectCustom() {
    setState(() {
      _isCustomSelected = true;
      _selectedAmount = null;
    });
  }

  double? _getFinalAmount() {
    if (!_isCustomSelected) {
      return _selectedAmount;
    }

    final raw = _customValueController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    return parsed;
  }

  Future<void> _handleContinuarPix() async {
    final amount = _getFinalAmount();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe um valor válido para a recarga.'),
          backgroundColor: AppTheme.naoConforme,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _walletRepository.requestRecharge(amount);

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Exibe diálogo informando com clareza a situação do Pix e que a solicitação foi registrada
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Solicitação de Recarga',
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
              Text(
                'Valor selecionado: ${_currencyFormat.format(amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Forma de pagamento: Pix',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Status: Aguardando integração bancária',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.comObs,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Pagamento Pix ainda não disponível. A integração bancária está sendo preparada.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sua solicitação de recarga foi registrada e ficará listada em "Minhas Recargas".',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop(); // Volta para a tela da carteira
              },
              child: const Text(
                'OK',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pushReplacement('/carteira/recargas');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Ver Minhas Recargas',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar recarga: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Adicionar Saldo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escolha quanto deseja adicionar à sua carteira.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'O saldo estará disponível para utilização de pesquisas, consultas e emissão de laudos.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Grade de Opções Rápidas
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._quickAmounts.map((amt) {
                    final isSelected = !_isCustomSelected && _selectedAmount == amt;
                    return _buildAmountOptionCard(
                      label: _currencyFormat.format(amt),
                      isSelected: isSelected,
                      onTap: () => _onQuickSelect(amt),
                    );
                  }),
                  _buildAmountOptionCard(
                    label: 'Outro valor',
                    isSelected: _isCustomSelected,
                    icon: Icons.edit_note_rounded,
                    onTap: _onSelectCustom,
                  ),
                ],
              ),

              if (_isCustomSelected) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Digite o valor desejado (R\$):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customValueController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+[\.,]?\d{0,2}')),
                        ],
                        autofocus: true,
                        decoration: InputDecoration(
                          prefixText: 'R\$ ',
                          prefixStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                          hintText: '0,00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Botão Continuar com Pix
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinuarPix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.pix_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'CONTINUAR COM PIX',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // Informação de Segurança e Transparência
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.verified_user_outlined,
                      size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operações financeiras corporativas criptografadas. Suas solicitações de recarga são processadas com segurança.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountOptionCard({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 40 - 12) / 2,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.conformeLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
