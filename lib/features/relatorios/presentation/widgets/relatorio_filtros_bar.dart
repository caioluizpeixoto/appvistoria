import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/relatorio_filtros_model.dart';
import '../cubit/relatorios_cubit.dart';
import 'relatorio_filtros_modal.dart';

class RelatorioFiltrosBar extends StatelessWidget {
  final RelatoriosCubit cubit;
  final RelatorioFiltrosModel filtros;
  final List<Map<String, dynamic>> empresasMaster;
  final bool isMaster;
  final VoidCallback onGerarRelatorio;

  const RelatorioFiltrosBar({
    super.key,
    required this.cubit,
    required this.filtros,
    required this.empresasMaster,
    required this.isMaster,
    required this.onGerarRelatorio,
  });

  int get _contagemFiltrosAtivos {
    int count = 0;
    if (filtros.cliente != null && filtros.cliente != 'todos') count++;
    if (filtros.tipoServico != null && filtros.tipoServico != 'todos') count++;
    if (filtros.perito != null && filtros.perito != 'todos') count++;
    if (filtros.digitador != null && filtros.digitador != 'todos') count++;
    if (filtros.status != null && filtros.status != 'todos') count++;
    return count;
  }

  Future<void> _selecionarPeriodoCustom(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: filtros.dataInicio,
        end: filtros.dataFim,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      cubit.alterarPeriodo(
        TipoPeriodoFiltro.personalizado,
        customRange: range,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Seletor de Empresa para Master (se houver)
          if (isMaster && empresasMaster.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.business_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Empresa:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: (filtros.empresaId != null &&
                              (filtros.empresaId == 'todas' ||
                               empresasMaster.any((e) => e['id'] == filtros.empresaId)))
                          ? filtros.empresaId
                          : 'todas',
                      items: [
                        const DropdownMenuItem(
                          value: 'todas',
                          child: Text(
                            'Todas as Empresas (Consolidado)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...empresasMaster.map((emp) {
                          return DropdownMenuItem(
                            value: emp['id'] as String,
                            child: Text(
                              (emp['razao_social'] as String? ?? 'Sem Nome')
                                  .toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        cubit.selecionarEmpresaMaster(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],

          // Linha 2: Chips de Período e Botões de Ação
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return Row(
                children: [
                  // Chips de Período
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TipoPeriodoFiltro.values.map((p) {
                          final isSelected = filtros.tipoPeriodo == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(p.label),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (p == TipoPeriodoFiltro.personalizado) {
                                  _selecionarPeriodoCustom(context);
                                } else {
                                  cubit.alterarPeriodo(p);
                                }
                              },
                              backgroundColor: AppTheme.surfaceVariant,
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botão Filtros Detalhados
                  OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => RelatorioFiltrosModal(
                          cubit: cubit,
                          filtros: filtros,
                        ),
                      );
                    },
                    icon: Badge(
                      isLabelVisible: _contagemFiltrosAtivos > 0,
                      label: Text('$_contagemFiltrosAtivos'),
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.tune_rounded, size: 18),
                    ),
                    label: isWide
                        ? const Text('Filtros')
                        : const SizedBox.shrink(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 14 : 10,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: _contagemFiltrosAtivos > 0
                            ? AppTheme.primary
                            : AppTheme.border,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botão Gerar Relatório
                  ElevatedButton.icon(
                    onPressed: onGerarRelatorio,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: isWide
                        ? const Text('Gerar Relatório')
                        : const Text('Exportar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 16 : 12,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
