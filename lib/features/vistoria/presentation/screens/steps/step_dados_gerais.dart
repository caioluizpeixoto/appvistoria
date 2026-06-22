import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

/// Step 1 — Dados Gerais da Vistoria
class StepDadosGerais extends StatefulWidget {
  const StepDadosGerais({super.key});

  @override
  State<StepDadosGerais> createState() => _StepDadosGeraisState();
}

class _StepDadosGeraisState extends State<StepDadosGerais> {
  final _clienteCtrl = TextEditingController();
  final _unidadeCtrl = TextEditingController();
  final _vistoriadorNomeCtrl = TextEditingController();
  final _vistoriadorCpfCtrl = TextEditingController();



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<VistoriaWizardState>();
      _clienteCtrl.text = state.clienteNome;
      _unidadeCtrl.text = state.unidade;
      _vistoriadorNomeCtrl.text = state.vistoriadorNome;
      _vistoriadorCpfCtrl.text = state.vistoriadorCpf;
    });
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _unidadeCtrl.dispose();
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
                  label: 'Número do Laudo',
                  value: state.numeroLaudo.isNotEmpty ? state.numeroLaudo : 'Carregando...'),
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
          TextFormField(
            controller: _clienteCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cliente / Proprietário',
              prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            ),
            onChanged: (v) {
              state.clienteNome = v;
            },
          ),
          const SizedBox(height: 14),

          // ── Unidade ──────────────────────────────────────────────────────
          TextFormField(
            controller: _unidadeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Unidade / Empresa',
              prefixIcon: Icon(Icons.business_rounded, color: AppTheme.primary),
            ),
            onChanged: (v) {
              state.unidade = v;
            },
          ),

          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.badge_rounded,
            title: 'Dados do Vistoriador',
            subtitle: 'Responsável técnico pela inspeção',
          ),
          const SizedBox(height: 14),

          // ── Vistoriador ──────────────────────────────────────────────────
          TextFormField(
            controller: _vistoriadorNomeCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do Vistoriador',
              prefixIcon: Icon(Icons.engineering_rounded, color: AppTheme.primary),
            ),
            onChanged: (v) {
              state.vistoriadorNome = v;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _vistoriadorCpfCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'CPF do Vistoriador',
              hintText: '000.000.000-00',
              prefixIcon: Icon(Icons.credit_card_rounded, color: AppTheme.primary),
            ),
            onChanged: (v) {
              state.vistoriadorCpf = v;
            },
          ),
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
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
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
