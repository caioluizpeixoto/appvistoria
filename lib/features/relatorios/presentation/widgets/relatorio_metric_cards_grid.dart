import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/relatorio_dashboard_model.dart';
import 'relatorio_metric_card.dart';

class RelatorioMetricCardsGrid extends StatelessWidget {
  final RelatorioDashboardModel dashboard;

  const RelatorioMetricCardsGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double childAspectRatio = 1.38;

        if (constraints.maxWidth >= 1050) {
          crossAxisCount = 6;
          childAspectRatio = 1.35;
        } else if (constraints.maxWidth >= 720) {
          crossAxisCount = 3;
          childAspectRatio = 1.45;
        } else if (constraints.maxWidth < 360) {
          crossAxisCount = 1;
          childAspectRatio = 2.4;
        }

        final cards = [
          RelatorioMetricCard(
            title: 'Total de Vistorias',
            value: dashboard.totalVistorias.toString(),
            icon: Icons.assignment_turned_in_rounded,
            iconColor: AppTheme.primary,
            iconBgColor: const Color(0xFFE8F5E9),
            variacao: dashboard.totalVistoriasAnterior > 0
                ? dashboard.variacaoVistoriasFormatada
                : null,
            subtitulo: 'vs. período anterior',
          ),
          RelatorioMetricCard(
            title: 'Faturamento Total',
            value: dashboard.faturamentoTotal > 0
                ? dashboard.faturamentoTotalFormatado
                : 'R\$ 0,00',
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF15803D),
            iconBgColor: const Color(0xFFDCFCE7),
            variacao: dashboard.faturamentoTotal > 0 &&
                    dashboard.faturamentoTotalAnterior > 0
                ? dashboard.variacaoFaturamentoFormatada
                : null,
            subtitulo: dashboard.faturamentoTotal > 0
                ? 'vs. período anterior'
                : 'sem valores informados',
          ),
          RelatorioMetricCard(
            title: 'Ticket Médio',
            value: dashboard.ticketMedio > 0
                ? dashboard.ticketMedioFormatado
                : 'R\$ 0,00',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBgColor: const Color(0xFFE0F2FE),
            subtitulo: dashboard.ticketMedio > 0
                ? 'por vistoria emitida'
                : 'sem valores informados',
          ),
          RelatorioMetricCard(
            title: 'Clientes Atendidos',
            value: dashboard.quantidadeClientes.toString(),
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBgColor: const Color(0xFFEDE9FE),
            subtitulo: 'clientes distintos',
          ),
          RelatorioMetricCard(
            title: 'Laudos Concluídos',
            value: dashboard.quantidadeConcluidos.toString(),
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppTheme.conforme,
            iconBgColor: AppTheme.conformeLight,
            subtitulo: 'finalizados e aprovados',
          ),
          RelatorioMetricCard(
            title: 'Laudos Pendentes',
            value: dashboard.quantidadePendentes.toString(),
            icon: Icons.pending_actions_rounded,
            iconColor: dashboard.quantidadePendentes > 0
                ? AppTheme.comRestricao
                : AppTheme.textSecondary,
            iconBgColor: dashboard.quantidadePendentes > 0
                ? AppTheme.comRestricaoLight
                : AppTheme.surfaceVariant,
            subtitulo: 'em andamento/rascunho',
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}
