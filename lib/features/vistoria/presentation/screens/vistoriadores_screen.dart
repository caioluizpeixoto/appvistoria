import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../injection_container.dart';

/// Tela de gerenciamento e cadastro de vistoriadores da empresa.
class VistoriadoresScreen extends StatefulWidget {
  const VistoriadoresScreen({super.key});

  @override
  State<VistoriadoresScreen> createState() => _VistoriadoresScreenState();
}

class _VistoriadoresScreenState extends State<VistoriadoresScreen> {
  final _dao = sl<VistoriaDao>();

  @override
  void initState() {
    super.initState();
    try {
      sl<SyncService>().syncVistoriadores();
    } catch (_) {}
  }

  // ── Formatação de CPF ───────────────────────────────────────────────────────

  String _formatarCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
    }
    return cpf;
  }

  // ── Diálogo de Cadastro / Edição ────────────────────────────────────────────

  Future<void> _abrirDialogVistoriador({Vistoriadore? vistoriador}) async {
    final isEditing = vistoriador != null;
    final nomeCtrl = TextEditingController(text: vistoriador?.nome ?? '');
    final cpfCtrl = TextEditingController(text: vistoriador?.cpf ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              isEditing ? 'Editar Vistoriador' : 'Novo Vistoriador',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cadastre o vistoriador para seleção manual nos laudos.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Nome Completo
                TextFormField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo *',
                    hintText: 'Ex: João da Silva',
                    prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o nome do vistoriador';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // CPF
                TextFormField(
                  controller: cpfCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CPF do Vistoriador *',
                    hintText: '000.000.000-00',
                    prefixIcon:
                        Icon(Icons.credit_card_rounded, color: AppTheme.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o CPF do vistoriador';
                    }
                    final limpo = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (limpo.length != 11) {
                      return 'CPF deve conter 11 dígitos';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final id = vistoriador?.id ?? const Uuid().v4();
              final nome = nomeCtrl.text.trim();
              final cpf = _formatarCpf(cpfCtrl.text.trim());

              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);

              await _dao.inserirOuAtualizarVistoriador(
                VistoriadoresCompanion(
                  id: drift.Value(id),
                  nome: drift.Value(nome),
                  cpf: drift.Value(cpf),
                  unidadeNome: const drift.Value('Matriz'),
                  cargo: const drift.Value('Vistoriador'),
                  ativo: const drift.Value(true),
                ),
              );

              try {
                sl<SyncService>().syncVistoriadores();
              } catch (_) {}

              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? '✅ Vistoriador atualizado com sucesso!'
                      : '✅ Vistoriador cadastrado com sucesso!'),
                  backgroundColor: AppTheme.conforme,
                ),
              );
            },
            child: Text(
              isEditing ? 'Salvar Alterações' : 'Cadastrar',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmação de Exclusão ────────────────────────────────────────────────

  Future<void> _confirmarExclusao(Vistoriadore item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.naoConforme),
            SizedBox(width: 10),
            Text('Excluir Vistoriador'),
          ],
        ),
        content: Text(
            'Deseja realmente remover o vistoriador "${item.nome}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.naoConforme,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dao.deletarVistoriador(item.id);
      try {
        sl<SyncService>().deletarVistoriadorCloud(item.id);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vistoriador removido.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Build Principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vistoriadores'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Vistoriador',
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _abrirDialogVistoriador(),
      ),
      body: StreamBuilder<List<Vistoriadore>>(
        stream: _dao.watchVistoriadores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nenhum vistoriador cadastrado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre os vistoriadores da sua empresa para que o nome e CPF sejam preenchidos automaticamente nos laudos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Cadastrar Primeiro Vistoriador',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _abrirDialogVistoriador(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: list.length,
            itemBuilder: (ctx, idx) {
              final item = list[idx];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar com Inicial
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          item.nome.isNotEmpty
                              ? item.nome.substring(0, 1).toUpperCase()
                              : 'V',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Informações
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CPF: ${item.cpf}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ações
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            color: AppTheme.textSecondary),
                        onSelected: (action) async {
                          if (action == 'editar') {
                            _abrirDialogVistoriador(vistoriador: item);
                          } else if (action == 'excluir') {
                            _confirmarExclusao(item);
                          }
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: AppTheme.primary, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: AppTheme.naoConforme, size: 20),
                                SizedBox(width: 8),
                                Text('Excluir',
                                    style: TextStyle(
                                        color: AppTheme.naoConforme)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
