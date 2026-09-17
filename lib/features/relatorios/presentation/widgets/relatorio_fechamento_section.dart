import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/fechamento_cliente_model.dart';
import '../cubit/relatorios_cubit.dart';

class RelatorioFechamentoSection extends StatelessWidget {
  final List<FechamentoClienteModel> clientes;
  final double faturamentoTotal;
  final RelatoriosCubit cubit;

  const RelatorioFechamentoSection({
    super.key,
    required this.clientes,
    required this.faturamentoTotal,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Seção Responsivo
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              final titleWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.account_balance_rounded,
                      color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Fechamento por Cliente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              );

              final badgeWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.conformeLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.conforme.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${clientes.length} clientes com produção',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.conforme,
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    badgeWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleWidget,
                  badgeWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'Consolidação de volume e faturamento por cliente durante o período selecionado.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 16),

          // Tabela ou Lista Responsiva
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 650) {
                return _buildDesktopTable(context);
              } else {
                return _buildMobileList(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 620),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceVariant),
          headingRowHeight: 38,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 48,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('CLIENTE', style: _headerStyle)),
            DataColumn(label: Text('SERVIÇOS', style: _headerStyle)),
            DataColumn(label: Text('TOTAL FATURADO', style: _headerStyle)),
            DataColumn(label: Text('TICKET MÉDIO', style: _headerStyle)),
            DataColumn(label: Text('% FATURAMENTO', style: _headerStyle)),
            DataColumn(label: Text('FILTRAR', style: _headerStyle)),
          ],
          rows: clientes.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      c.clienteNome,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${c.quantidadeServicos}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    c.faturamentoFormatado,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.conforme,
                    ),
                  ),
                ),
                DataCell(Text(c.ticketMedioFormatado, style: _cellStyle)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c.percentualFormatado,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    tooltip: 'Filtrar painel por ${c.clienteNome}',
                    onPressed: () {
                      cubit.aplicarFiltrosSecundarios(cliente: c.clienteNome);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filtrado por: ${c.clienteNome}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clientes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = clientes[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.clienteNome,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    c.faturamentoFormatado,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.conforme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${c.quantidadeServicos} laudos realizados',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Ticket: ${c.ticketMedioFormatado} (${c.percentualFormatado})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  InkWell(
                    onTap: () {
                      cubit.aplicarFiltrosSecundarios(cliente: c.clienteNome);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Filtrado por: ${c.clienteNome}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.filter_alt_outlined, size: 18, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  static const TextStyle _cellStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textPrimary,
  );
}
