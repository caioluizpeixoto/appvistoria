import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class AbaCreditosMasterWidget extends StatefulWidget {
  const AbaCreditosMasterWidget({super.key});

  @override
  State<AbaCreditosMasterWidget> createState() => _AbaCreditosMasterWidgetState();
}

class _AbaCreditosMasterWidgetState extends State<AbaCreditosMasterWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _empresas = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.rpc('get_wallets_master');
      if (res != null) {
        setState(() {
          _empresas = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar carteiras: $e'), backgroundColor: AppTheme.naoConforme),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirDialogCredito(Map<String, dynamic> empresa, bool isCredito) async {
    final amountCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isCredito ? 'Adicionar Crédito Manual' : 'Remover Saldo Manual'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Empresa: ${empresa['empresa_nome']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Email: ${empresa['email']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor (Ex: 15.00)',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: motivoCtrl..text = isCredito ? 'Recarga' : 'Ajuste de Saldo', // Pré-preenchido
                      decoration: const InputDecoration(
                        labelText: 'Motivo / Descrição',
                        hintText: 'Descrição do ajuste',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: isCredito ? AppTheme.conforme : AppTheme.naoConforme),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amountText = amountCtrl.text.replaceAll(',', '.');
                          final amount = double.tryParse(amountText);
                          final motivo = motivoCtrl.text.trim();

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Informe um valor válido.')));
                            return;
                          }
                          if (motivo.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Informe o motivo do ajuste.')));
                            return;
                          }

                          setStateDialog(() => isSaving = true);
                          try {
                            final rpcName = isCredito ? 'master_add_credits' : 'master_remove_credits';
                            await _supabase.rpc(rpcName, params: {
                              'target_company_id': empresa['company_id'],
                              'amount': amount,
                              'description': motivo,
                            });
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCredito ? 'Crédito adicionado com sucesso!' : 'Saldo removido com sucesso!'), backgroundColor: isCredito ? AppTheme.conforme : AppTheme.naoConforme));
                              _carregarEmpresas();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro: $e')));
                            setStateDialog(() => isSaving = false);
                          }
                        },
                  icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, color: Colors.white),
                  label: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_empresas.isEmpty) {
      return const Center(child: Text('Nenhuma empresa encontrada.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _carregarEmpresas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _empresas.length,
        itemBuilder: (context, index) {
          final e = _empresas[index];
          final saldo = (e['balance'] as num?)?.toDouble() ?? 0.0;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.business, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['empresa_nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(e['email'] ?? 'Sem Email', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Saldo Atual: ', style: TextStyle(fontSize: 13)),
                                Text(_currencyFormat.format(saldo), style: TextStyle(fontWeight: FontWeight.bold, color: saldo < 0 ? AppTheme.naoConforme : AppTheme.conforme)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.naoConforme.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.naoConforme,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => _abrirDialogCredito(e, false),
                        child: const Icon(Icons.remove, size: 18),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.conforme),
                        onPressed: () => _abrirDialogCredito(e, true),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text('Crédito', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
