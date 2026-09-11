import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../database/app_database.dart';
import '../../../../../database/daos/vistoria_dao.dart';
import '../../../../../core/services/sync_service.dart';
import '../../../../../injection_container.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../../domain/vistoria_type.dart';
import '../clientes_screen.dart';

/// Step 1 — Dados Gerais da Vistoria
class StepDadosGerais extends StatefulWidget {
  const StepDadosGerais({super.key});

  @override
  State<StepDadosGerais> createState() => _StepDadosGeraisState();
}

class _StepDadosGeraisState extends State<StepDadosGerais> {
  final _dao = sl<VistoriaDao>();
  final _clienteCtrl = TextEditingController();
  final _clienteEmailCtrl = TextEditingController();
  final _clienteCpfCtrl = TextEditingController();
  final _clienteTelefoneCtrl = TextEditingController();
  final _vistoriadorNomeCtrl = TextEditingController();
  final _vistoriadorCpfCtrl = TextEditingController();

  List<Vistoriadore> _vistoriadoresCadastrados = [];
  String? _vistoriadorSelecionadoId;

  List<Cliente> _clientesCadastrados = [];
  String? _clienteSelecionadoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<VistoriaWizardState>();
      _clienteCtrl.text = state.clienteNome;
      _clienteEmailCtrl.text = state.clienteEmail;
      _clienteCpfCtrl.text = state.clienteCpf;
      _clienteTelefoneCtrl.text = state.clienteTelefone;
      _vistoriadorNomeCtrl.text = state.vistoriadorNome;
      _vistoriadorCpfCtrl.text = state.vistoriadorCpf;

      // Carregar lista de vistoriadores e clientes cadastrados
      try {
        final listaVist = await _dao.listarVistoriadores();
        final listaCli = await _dao.listarClientes();
        if (mounted) {
          setState(() {
            _vistoriadoresCadastrados = listaVist;
            _clientesCadastrados = listaCli;
          });

          // Não selecionar automaticamente o vistoriador; o usuário escolherá manualmente da lista
          if (state.vistoriadorNome.isNotEmpty && listaVist.isNotEmpty) {
            final correspondente = listaVist.firstWhere(
              (v) => v.nome.toLowerCase() == state.vistoriadorNome.toLowerCase(),
              orElse: () => listaVist.first,
            );
            if (correspondente.nome.toLowerCase() == state.vistoriadorNome.toLowerCase()) {
              setState(() => _vistoriadorSelecionadoId = correspondente.id);
            }
          }

          // Se já tem cliente preenchido, tenta vincular
          if (state.clienteNome.isNotEmpty && listaCli.isNotEmpty) {
            final corrCli = listaCli.firstWhere(
              (c) => c.nome.toLowerCase() == state.clienteNome.toLowerCase(),
              orElse: () => listaCli.first,
            );
            if (corrCli.nome.toLowerCase() == state.clienteNome.toLowerCase()) {
              setState(() => _clienteSelecionadoId = corrCli.id);
            }
          }
        }
      } catch (_) {}
    });
  }

  void _selecionarCliente(Cliente c, VistoriaWizardState state) {
    setState(() {
      _clienteSelecionadoId = c.id;
      _clienteCtrl.text = c.nome;
      _clienteCpfCtrl.text = c.cpfCnpj ?? '';
      _clienteEmailCtrl.text = c.email ?? '';
      _clienteTelefoneCtrl.text = c.telefone ?? '';

      state.clienteNome = c.nome;
      state.clienteCpf = c.cpfCnpj ?? '';
      state.clienteEmail = c.email ?? '';
      state.clienteTelefone = c.telefone ?? '';
    });
  }

  Future<void> _salvarClienteNoBanco(VistoriaWizardState state) async {
    final nome = _clienteCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do cliente antes de salvar.'),
          backgroundColor: AppTheme.comObs,
        ),
      );
      return;
    }

    final id = const Uuid().v4();
    final companion = ClientesCompanion(
      id: drift.Value(id),
      nome: drift.Value(nome.toUpperCase()),
      cpfCnpj: drift.Value(_clienteCpfCtrl.text.trim()),
      email: drift.Value(_clienteEmailCtrl.text.trim().toLowerCase()),
      telefone: drift.Value(_clienteTelefoneCtrl.text.trim()),
      createdAt: drift.Value(DateTime.now()),
    );

    await _dao.inserirOuAtualizarCliente(companion);
    try {
      sl<SyncService>().syncClientes();
    } catch (_) {}
    final listaCli = await _dao.listarClientes();
    if (mounted) {
      setState(() {
        _clientesCadastrados = listaCli;
        _clienteSelecionadoId = id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente "$nome" salvo no cadastro!'),
          backgroundColor: AppTheme.conforme,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selecionarVistoriador(Vistoriadore v, VistoriaWizardState state) {
    setState(() {
      _vistoriadorSelecionadoId = v.id;
      _vistoriadorNomeCtrl.text = v.nome;
      _vistoriadorCpfCtrl.text = v.cpf;
      state.vistoriadorNome = v.nome;
      state.vistoriadorCpf = v.cpf;
    });
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _clienteEmailCtrl.dispose();
    _clienteCpfCtrl.dispose();
    _clienteTelefoneCtrl.dispose();
    _vistoriadorNomeCtrl.dispose();
    _vistoriadorCpfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.assignment_rounded,
            title: 'Dados Gerais',
            subtitle: 'Informações básicas da vistoria',
          ),
          const SizedBox(height: 20),

          // ── Número do laudo (somente leitura) ────────────────────────────
          _InfoCard(
            children: [
              _InfoRow(
                  icon: Icons.tag_rounded,
                  label: (state.tipoVistoria
                              .toLowerCase()
                              .contains('cautelar') ||
                          state.tipoVistoria.toLowerCase().contains('croqui'))
                      ? 'Número do Laudo'
                      : 'Número do Registro',
                  value: state.numeroLaudo.isNotEmpty
                      ? state.numeroLaudo
                      : 'Carregando...'),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Data e Hora',
                value: _formatDateTime(DateTime.now()),
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.fiber_manual_record_rounded,
                label: 'Status',
                value: state.status,
                valueColor: AppTheme.emAndamento,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.category_rounded,
                label: 'Tipo de Vistoria',
                value: state.tipoVistoria,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Cliente ──────────────────────────────────────────────────────
          if (!state.isChecklist &&
              state.tipoEnum != TipoVistoria.vistoriaEntrada) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dados do Cliente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.people_alt_rounded, size: 16),
                  label: const Text('Selecionar do Cadastro'),
                  onPressed: () async {
                    final selecionado = await Navigator.push<Cliente>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientesScreen(isSelectionMode: true),
                      ),
                    );
                    if (selecionado != null) {
                      _selecionarCliente(selecionado, state);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dropdown rápido caso existam clientes cadastrados
            if (_clientesCadastrados.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Row(
                      children: [
                        Icon(Icons.person_search_rounded, size: 18, color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text('Escolha um cliente cadastrado...',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                    value: _clientesCadastrados.any((c) => c.id == _clienteSelecionadoId)
                        ? _clienteSelecionadoId
                        : null,
                    items: _clientesCadastrados.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.cpfCnpj != null && c.cpfCnpj!.isNotEmpty)
                              Text(
                                ' (${c.cpfCnpj})',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (novoId) {
                      if (novoId == null) return;
                      final c = _clientesCadastrados.firstWhere((item) => item.id == novoId);
                      _selecionarCliente(c, state);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _clienteCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Cliente / Proprietário (opcional)',
                prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
                suffixIcon: _clienteCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _clienteSelecionadoId = null;
                            _clienteCtrl.clear();
                            _clienteCpfCtrl.clear();
                            _clienteEmailCtrl.clear();
                            _clienteTelefoneCtrl.clear();
                            state.clienteNome = '';
                            state.clienteCpf = '';
                            state.clienteEmail = '';
                            state.clienteTelefone = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                state.clienteNome = v;
                setState(() => _clienteSelecionadoId = null);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _clienteCpfCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF / CNPJ do Cliente (opcional)',
                hintText: '000.000.000-00',
                prefixIcon: Icon(Icons.credit_card_rounded, color: AppTheme.primary),
              ),
              onChanged: (v) {
                state.clienteCpf = v;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _clienteEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail do Cliente (opcional)',
                hintText: 'cliente@email.com',
                prefixIcon: Icon(Icons.email_rounded, color: AppTheme.primary),
              ),
              onChanged: (v) {
                state.clienteEmail = v;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _clienteTelefoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp do Cliente (opcional)',
                hintText: '(00) 90000-0000',
                prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.primary),
              ),
              onChanged: (v) {
                state.clienteTelefone = v;
              },
            ),
            if (_clienteCtrl.text.trim().isNotEmpty && _clienteSelecionadoId == null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.save_as_rounded, size: 16),
                  label: const Text('Salvar no Cadastro de Clientes', style: TextStyle(fontSize: 12)),
                  onPressed: () => _salvarClienteNoBanco(state),
                ),
              ),
            ],
            const SizedBox(height: 14),

            const SizedBox(height: 10),
          ],
          _SectionHeader(
            icon: Icons.badge_rounded,
            title: 'Dados do Vistoriador',
            subtitle: 'Escolha manualmente o vistoriador responsável pela inspeção',
          ),
          const SizedBox(height: 14),

          // ── Seletor Manual de Vistoriador da Empresa ────────────────────
          if (_vistoriadoresCadastrados.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _vistoriadorSelecionadoId == null
                    ? AppTheme.comObsLight
                    : AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _vistoriadorSelecionadoId == null
                      ? AppTheme.comObs
                      : AppTheme.primary.withValues(alpha: 0.3),
                  width: _vistoriadorSelecionadoId == null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_pin_rounded,
                    color: _vistoriadorSelecionadoId == null
                        ? AppTheme.comObs
                        : AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _vistoriadoresCadastrados
                                .any((v) => v.id == _vistoriadorSelecionadoId)
                            ? _vistoriadorSelecionadoId
                            : null,
                        hint: const Text(
                          'Toque para escolher o Vistoriador...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        isExpanded: true,
                        items: _vistoriadoresCadastrados.map((v) {
                          return DropdownMenuItem<String>(
                            value: v.id,
                            child: Text(
                              '${v.nome} (CPF: ${v.cpf})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final v = _vistoriadoresCadastrados
                                .firstWhere((item) => item.id == id);
                            _selecionarVistoriador(v, state);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Vistoriador ──────────────────────────────────────────────────
          TextFormField(
            controller: _vistoriadorNomeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do Vistoriador',
              prefixIcon:
                  Icon(Icons.person_search_rounded, color: AppTheme.primary),
            ),
            onChanged: (v) {
              state.vistoriadorNome = v;
            },
          ),
          if (!state.isChecklist &&
              state.tipoEnum != TipoVistoria.vistoriaEntrada) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _vistoriadorCpfCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'CPF do Vistoriador',
                hintText: '000.000.000-00',
                prefixIcon:
                    Icon(Icons.credit_card_rounded, color: AppTheme.primary),
              ),
              onChanged: (v) {
                state.vistoriadorCpf = v;
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y às $h:$min';
  }
}

// ── Helpers internos ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
