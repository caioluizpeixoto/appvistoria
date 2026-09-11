import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../injection_container.dart';

/// Tela de gerenciamento e cadastro de clientes da empresa.
class ClientesScreen extends StatefulWidget {
  final bool isSelectionMode;
  final ValueChanged<Cliente>? onClientSelected;

  const ClientesScreen({
    super.key,
    this.isSelectionMode = false,
    this.onClientSelected,
  });

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _dao = sl<VistoriaDao>();
  String _filtroPesquisa = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    try {
      sl<SyncService>().syncClientes();
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Formatação de CPF / CNPJ ────────────────────────────────────────────────
  String _formatarDocumento(String? doc) {
    if (doc == null || doc.isEmpty) return 'Não informado';
    final clean = doc.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
    } else if (clean.length == 14) {
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12, 14)}';
    }
    return doc;
  }

  // ── Formatação de Telefone ─────────────────────────────────────────────────
  String _formatarTelefone(String? tel) {
    if (tel == null || tel.isEmpty) return 'Não informado';
    final clean = tel.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7, 11)}';
    } else if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6, 10)}';
    }
    return tel;
  }

  // ── Diálogo de Cadastro / Edição ────────────────────────────────────────────
  Future<void> _abrirDialogCliente({Cliente? cliente}) async {
    final isEditing = cliente != null;
    final nomeCtrl = TextEditingController(text: cliente?.nome ?? '');
    final docCtrl = TextEditingController(text: cliente?.cpfCnpj ?? '');
    final emailCtrl = TextEditingController(text: cliente?.email ?? '');
    final telCtrl = TextEditingController(text: cliente?.telefone ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Editar Cliente' : 'Novo Cliente',
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
                    'Cadastre as informações do cliente para auto-preenchimento no laudo.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Nome Completo / Razão Social
                  TextFormField(
                    controller: nomeCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo ou Razão Social *',
                      prefixIcon: const Icon(Icons.badge_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do cliente' : null,
                  ),
                  const SizedBox(height: 12),

                  // CPF / CNPJ
                  TextFormField(
                    controller: docCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'CPF ou CNPJ',
                      hintText: 'Apenas números',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Telefone / WhatsApp
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      hintText: '(19) 99999-9999',
                      prefixIcon: const Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // E-mail
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'cliente@exemplo.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Salvar Alterações' : 'Cadastrar'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final id = cliente?.id ?? const Uuid().v4();
                final novoCliente = ClientesCompanion(
                  id: drift.Value(id),
                  nome: drift.Value(nomeCtrl.text.trim().toUpperCase()),
                  cpfCnpj: drift.Value(docCtrl.text.trim().replaceAll(RegExp(r'\D'), '')),
                  telefone: drift.Value(telCtrl.text.trim()),
                  email: drift.Value(emailCtrl.text.trim().toLowerCase()),
                  createdAt: drift.Value(cliente?.createdAt ?? DateTime.now()),
                );

                await _dao.inserirOuAtualizarCliente(novoCliente);
                try {
                  sl<SyncService>().syncClientes();
                } catch (_) {}
                if (ctx.mounted) Navigator.of(ctx).pop();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Cliente atualizado com sucesso!'
                            : 'Cliente cadastrado com sucesso!',
                      ),
                      backgroundColor: AppTheme.conforme,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmação de Exclusão ─────────────────────────────────────────────────
  Future<void> _confirmarExclusao(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppTheme.naoConforme),
            SizedBox(width: 10),
            Text('Excluir Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Deseja realmente remover o cliente "${cliente.nome}" do cadastro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.naoConforme,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dao.deletarCliente(cliente.id);
      try {
        sl<SyncService>().deletarClienteCloud(cliente.id);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente "${cliente.nome}" removido.'),
            backgroundColor: AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Selecionar Cliente' : 'Clientes'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo Cliente'),
        onPressed: () => _abrirDialogCliente(),
      ),
      body: StreamBuilder<List<Cliente>>(
        stream: _dao.watchClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todosClientes = snapshot.data ?? [];
          final clientes = todosClientes.where((c) {
            if (_filtroPesquisa.isEmpty) return true;
            final termo = _filtroPesquisa.toLowerCase();
            return c.nome.toLowerCase().contains(termo) ||
                (c.cpfCnpj != null && c.cpfCnpj!.contains(termo)) ||
                (c.telefone != null && c.telefone!.contains(termo)) ||
                (c.email != null && c.email!.toLowerCase().contains(termo));
          }).toList();

          if (todosClientes.isEmpty) {
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
                        Icons.people_outline_rounded,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nenhum cliente cadastrado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre os clientes para que os dados sejam preenchidos automaticamente nos laudos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Cadastrar Primeiro Cliente'),
                      onPressed: () => _abrirDialogCliente(),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Barra de Pesquisa
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome, CPF/CNPJ, telefone ou e-mail...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _filtroPesquisa.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filtroPesquisa = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (val) {
                    setState(() => _filtroPesquisa = val.trim());
                  },
                ),
              ),

              if (clientes.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Nenhum cliente encontrado para "$_filtroPesquisa"',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: clientes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      final docFmt = _formatarDocumento(cliente.cpfCnpj);
                      final telFmt = _formatarTelefone(cliente.telefone);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: widget.isSelectionMode
                              ? () {
                                  widget.onClientSelected?.call(cliente);
                                  Navigator.of(context).pop(cliente);
                                }
                              : () => _abrirDialogCliente(cliente: cliente),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar com iniciais
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    cliente.nome.isNotEmpty
                                        ? cliente.nome.substring(0, 1).toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Detalhes do Cliente
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // CPF / CNPJ
                                      if (cliente.cpfCnpj != null && cliente.cpfCnpj!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Row(
                                            children: [
                                              Icon(Icons.credit_card_rounded,
                                                  size: 13, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Doc: $docFmt',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Telefone / WhatsApp
                                      if (cliente.telefone != null && cliente.telefone!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Row(
                                            children: [
                                              Icon(Icons.phone_rounded,
                                                  size: 13, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                telFmt,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () async {
                                                  final clean = cliente.telefone!
                                                      .replaceAll(RegExp(r'\D'), '');
                                                  final url = Uri.parse(
                                                      'https://wa.me/55$clean');
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url,
                                                        mode: LaunchMode.externalApplication);
                                                  }
                                                },
                                                child: const Icon(
                                                  Icons.chat_bubble_outline_rounded,
                                                  size: 14,
                                                  color: AppTheme.conforme,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // E-mail
                                      if (cliente.email != null && cliente.email!.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(Icons.alternate_email_rounded,
                                                size: 13, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                cliente.email!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                // Botão de Ações ou Seleção
                                if (widget.isSelectionMode)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      widget.onClientSelected?.call(cliente);
                                      Navigator.of(context).pop(cliente);
                                    },
                                    child: const Text('Selecionar', style: TextStyle(fontSize: 12)),
                                  )
                                else
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _abrirDialogCliente(cliente: cliente);
                                      } else if (val == 'delete') {
                                        _confirmarExclusao(cliente);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, size: 18),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_forever_rounded,
                                                size: 18, color: AppTheme.naoConforme),
                                            SizedBox(width: 8),
                                            Text('Excluir',
                                                style: TextStyle(color: AppTheme.naoConforme)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
