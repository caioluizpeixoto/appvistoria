import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../data/models/vistoria_relatorio_item_model.dart';
import '../cubit/relatorios_cubit.dart';
import '../cubit/relatorios_state.dart';
import 'detalhes_vistoria_dialog.dart';

class RelatorioTabelaSection extends StatefulWidget {
  final RelatoriosLoaded state;
  final RelatoriosCubit cubit;

  const RelatorioTabelaSection({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  State<RelatorioTabelaSection> createState() => _RelatorioTabelaSectionState();
}

class _RelatorioTabelaSectionState extends State<RelatorioTabelaSection> {
  late final TextEditingController _buscaController;

  @override
  void initState() {
    super.initState();
    _buscaController =
        TextEditingController(text: widget.state.filtros.queryBusca);
  }

  @override
  void didUpdateWidget(covariant RelatorioTabelaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.filtros.queryBusca != _buscaController.text) {
      _buscaController.text = widget.state.filtros.queryBusca;
    }
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _abrirDetalhes(VistoriaRelatorioItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => DetalhesVistoriaDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = widget.state.itensPaginados;
    final total = widget.state.dashboard.itensVistoria.length;
    final pagina = widget.state.paginaAtual;
    final totalPaginas = widget.state.totalPaginas;
    final itensPorPagina = widget.state.itensPorPagina;

    final inicio = total == 0 ? 0 : ((pagina - 1) * itensPorPagina) + 1;
    final fim = (pagina * itensPorPagina).clamp(0, total);

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
          // ── Barra Superior: Título, Busca e Paginação por página ───────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Vistorias Realizadas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Dropdown de Itens por Página
                  Row(
                    children: [
                      const Text(
                        'Exibir: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: itensPorPagina,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 25, child: Text('25')),
                            DropdownMenuItem(value: 50, child: Text('50')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              widget.cubit.alterarItensPorPagina(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Campo de Pesquisa em Tempo Real
              TextField(
                controller: _buscaController,
                onChanged: (val) => widget.cubit.buscar(val),
                decoration: InputDecoration(
                  hintText:
                      'Pesquise por placa, chassi, cliente ou nº do laudo...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _buscaController.clear();
                            widget.cubit.buscar('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Tabela Responsiva ou Cards Móveis ──────────────────────────────
          if (total == 0)
            _buildVazio()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 780) {
                  return _buildDataTable(itens);
                } else {
                  return _buildMobileList(itens);
                }
              },
            ),

          const SizedBox(height: 16),

          // ── Rodapé de Paginação Responsivo ─────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.first_page_rounded),
                    onPressed: pagina > 1
                        ? () => widget.cubit.mudarPagina(1)
                        : null,
                    tooltip: 'Primeira página',
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: pagina > 1
                        ? () => widget.cubit.mudarPagina(pagina - 1)
                        : null,
                    tooltip: 'Página anterior',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$pagina / $totalPaginas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: pagina < totalPaginas
                        ? () => widget.cubit.mudarPagina(pagina + 1)
                        : null,
                    tooltip: 'Próxima página',
                  ),
                  IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.last_page_rounded),
                    onPressed: pagina < totalPaginas
                        ? () => widget.cubit.mudarPagina(totalPaginas)
                        : null,
                    tooltip: 'Última página',
                  ),
                ],
              );

              final infoText = Text(
                'Exibindo $inicio a $fim de $total registros',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    infoText,
                    const SizedBox(height: 6),
                    controls,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  infoText,
                  controls,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Desktop / Tablet: DataTable com Rolagem Horizontal ─────────────────────
  Widget _buildDataTable(List<VistoriaRelatorioItemModel> itens) {
    final isMaster = Supabase.instance.client.auth.currentUser?.isMaster ?? false;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isMaster ? 1100 : 950),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceVariant),
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          showCheckboxColumn: false,
          columns: [
            if (isMaster) const DataColumn(label: Text('EMPRESA', style: _headerStyle)),
            const DataColumn(label: Text('Nº LAUDO', style: _headerStyle)),
            const DataColumn(label: Text('DATA', style: _headerStyle)),
            const DataColumn(label: Text('VEÍCULO', style: _headerStyle)),
            const DataColumn(label: Text('ANO', style: _headerStyle)),
            const DataColumn(label: Text('PLACA', style: _headerStyle)),
            const DataColumn(label: Text('CLIENTE', style: _headerStyle)),
            const DataColumn(label: Text('SERVIÇO', style: _headerStyle)),
            const DataColumn(label: Text('PERITO', style: _headerStyle)),
            const DataColumn(label: Text('DIGITADOR', style: _headerStyle)),
            const DataColumn(label: Text('VALOR', style: _headerStyle)),
            const DataColumn(label: Text('AÇÃO', style: _headerStyle)),
          ],
          rows: itens.map((it) {
            return DataRow(
              onSelectChanged: (_) => _abrirDetalhes(it),
              cells: [
                if (isMaster)
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        it.empresaNome,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                DataCell(
                  Text(
                    it.numeroLaudo,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                DataCell(Text(it.dataFormatada, style: _cellStyle)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      it.veiculo,
                      style: _cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(it.ano, style: _cellStyle)),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      it.placa,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      it.cliente,
                      style: _cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      it.servico,
                      style: _cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      it.perito,
                      style: _cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      it.digitador,
                      style: _cellStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    it.valor > 0 ? it.valorFormatado : '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: it.valor > 0 ? FontWeight.w700 : FontWeight.w400,
                      color: it.valor > 0 ? AppTheme.conforme : AppTheme.textHint,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        size: 18, color: AppTheme.primary),
                    tooltip: 'Ver Detalhes',
                    onPressed: () => _abrirDetalhes(it),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Mobile: Cards Otimizados para Tela Pequena ─────────────────────────────
  Widget _buildMobileList(List<VistoriaRelatorioItemModel> itens) {
    final isMaster = Supabase.instance.client.auth.currentUser?.isMaster ?? false;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final it = itens[index];
        return InkWell(
          onTap: () => _abrirDetalhes(it),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 0 (Exclusivo Master): Identificação da Empresa
                if (isMaster) ...[
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          it.empresaNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                ],

                // Linha 1: Laudo, Placa e Valor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      it.numeroLaudo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        it.placa,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      it.valorFormatado,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.conforme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Linha 2: Veículo e Ano
                Text(
                  '${it.veiculo} (${it.ano})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Linha 3: Cliente e Perito
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cliente: ${it.cliente}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      it.dataFormatada,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: const [
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text(
              'Nenhuma vistoria encontrada para os filtros aplicados.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tente ajustar o período ou redefinir a busca.',
              style: TextStyle(fontSize: 12, color: AppTheme.textHint),
            ),
          ],
        ),
      ),
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
