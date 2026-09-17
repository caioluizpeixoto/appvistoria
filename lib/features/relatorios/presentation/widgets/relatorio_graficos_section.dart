import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/relatorio_dashboard_model.dart';

class RelatorioGraficosSection extends StatefulWidget {
  final RelatorioDashboardModel dashboard;

  const RelatorioGraficosSection({super.key, required this.dashboard});

  @override
  State<RelatorioGraficosSection> createState() =>
      _RelatorioGraficosSectionState();
}

class _RelatorioGraficosSectionState extends State<RelatorioGraficosSection> {
  int _abaSelecionada = 0; // 0: Vistorias, 1: Faturamento, 2: Serviços, 3: Clientes, 4: Peritos

  final List<Color> _paletaCores = const [
    Color(0xFF234B32), // Verde Musgo Ultra Prime
    Color(0xFF0D9488), // Teal
    Color(0xFF2563EB), // Azul Royal
    Color(0xFFD97706), // Âmbar / Laranja
    Color(0xFF7C3AED), // Roxo
    Color(0xFFDB2777), // Rosa Escuro
    Color(0xFF4B5563), // Grafite
  ];

  @override
  Widget build(BuildContext context) {
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
          // Cabeçalho dos Gráficos com Seletor de Abas
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.insights_rounded,
                          color: AppTheme.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Gráficos & Análise Visual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Abas de seleção de gráfico
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, 'Vistorias / Dia', Icons.bar_chart_rounded),
                    const SizedBox(width: 6),
                    _buildTabButton(1, 'Faturamento / Dia', Icons.show_chart_rounded),
                    const SizedBox(width: 6),
                    _buildTabButton(2, 'Serviços Realizados', Icons.pie_chart_outline_rounded),
                    const SizedBox(width: 6),
                    _buildTabButton(3, 'Por Cliente', Icons.people_outline_rounded),
                    const SizedBox(width: 6),
                    _buildTabButton(4, 'Por Perito', Icons.engineering_outlined),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Área do Gráfico Ativo Responsiva
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 580;
              final chartHeight = (_abaSelecionada == 2 && isNarrow) ? 380.0 : 280.0;
              return SizedBox(
                height: chartHeight,
                child: _buildGraficoAtivo(constraints.maxWidth),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _abaSelecionada == index;
    return InkWell(
      onTap: () => setState(() => _abaSelecionada = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoAtivo(double maxWidth) {
    switch (_abaSelecionada) {
      case 0:
        return _buildGraficoVistoriasPorDia();
      case 1:
        return _buildGraficoFaturamentoPorDia();
      case 2:
        return _buildGraficoServicos(maxWidth);
      case 3:
        return _buildGraficoClientes();
      case 4:
        return _buildGraficoPeritos();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Vistorias por Dia (BarChart) ────────────────────────────────────────
  Widget _buildGraficoVistoriasPorDia() {
    final mapa = widget.dashboard.vistoriasPorDia;
    if (mapa.isEmpty) {
      return _buildEmptyChart('Nenhuma vistoria registrada no período selecionado.');
    }

    final diasOrdenados = mapa.keys.toList()..sort((a, b) => a.compareTo(b));
    final maxY = mapa.values.fold<int>(0, (prev, val) => val > prev ? val : prev).toDouble();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < diasOrdenados.length; i++) {
      final dia = diasOrdenados[i];
      final valor = mapa[dia]?.toDouble() ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: valor,
              color: AppTheme.primary,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B6E4C), Color(0xFF234B32)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? (maxY * 1.2) : 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dia = diasOrdenados[group.x.toInt()];
              final dataStr = DateFormat('dd/MM').format(dia);
              return BarTooltipItem(
                '$dataStr\n${rod.toY.toInt()} vistorias',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= diasOrdenados.length) return const SizedBox.shrink();
                // Mostrar a cada N dias para não embolar
                if (diasOrdenados.length > 10 && idx % 2 != 0) {
                  return const SizedBox.shrink();
                }
                final dia = diasOrdenados[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('dd/MM').format(dia),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: AppTheme.border.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // ── 2. Faturamento por Dia (LineChart com Gradiente) ────────────────────────
  Widget _buildGraficoFaturamentoPorDia() {
    final mapa = widget.dashboard.faturamentoPorDia;
    if (mapa.isEmpty) {
      return _buildEmptyChart('Nenhum faturamento registrado no período selecionado.');
    }

    final diasOrdenados = mapa.keys.toList()..sort((a, b) => a.compareTo(b));
    final spots = <FlSpot>[];
    double maxY = 0.0;

    for (int i = 0; i < diasOrdenados.length; i++) {
      final valor = mapa[diasOrdenados[i]] ?? 0.0;
      if (valor > maxY) maxY = valor;
      spots.add(FlSpot(i.toDouble(), valor));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? (maxY * 1.25) : 500,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= diasOrdenados.length) return null;
                final dia = diasOrdenados[idx];
                final formatador =
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
                return LineTooltipItem(
                  '${DateFormat('dd/MM').format(dia)}\n${formatador.format(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              getTitlesWidget: (val, meta) => Text(
                'R\$ ${val.toInt()}',
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= diasOrdenados.length) return const SizedBox.shrink();
                if (diasOrdenados.length > 10 && idx % 2 != 0) {
                  return const SizedBox.shrink();
                }
                final dia = diasOrdenados[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('dd/MM').format(dia),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: AppTheme.border.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.35),
                  AppTheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Serviços Mais Realizados (Donut Chart com Legenda) ───────────────────
  Widget _buildGraficoServicos(double maxWidth) {
    final mapa = widget.dashboard.servicosMaisRealizados;
    if (mapa.isEmpty) {
      return _buildEmptyChart('Nenhum serviço registrado.');
    }

    final entries = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = widget.dashboard.totalVistorias;
    final isMobile = maxWidth < 580;

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final cor = _paletaCores[i % _paletaCores.length];
      final perc = total > 0 ? (entries[i].value / total * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          color: cor,
          value: entries[i].value.toDouble(),
          title: perc >= 6 ? '${perc.toStringAsFixed(0)}%' : '',
          radius: isMobile ? 38 : 50,
          titleStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    final pieWidget = SizedBox(
      height: isMobile ? 160 : null,
      child: Center(
        child: PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: isMobile ? 32 : 38,
            sectionsSpace: 2,
          ),
        ),
      ),
    );

    final legendWidget = ListView.separated(
      shrinkWrap: isMobile,
      physics: isMobile
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final e = entries[index];
        final cor = _paletaCores[index % _paletaCores.length];
        final perc = total > 0 ? (e.value / total * 100) : 0.0;
        return Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${e.value} (${perc.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            pieWidget,
            const SizedBox(height: 12),
            legendWidget,
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: pieWidget,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: legendWidget,
        ),
      ],
    );
  }

  // ── 4. Produção por Cliente (Barras de Progresso / Ranking) ─────────────────
  Widget _buildGraficoClientes() {
    final mapa = widget.dashboard.producaoPorCliente;
    if (mapa.isEmpty) {
      return _buildEmptyChart('Nenhum cliente registrado.');
    }

    final entries = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return ListView.builder(
      itemCount: entries.length.clamp(0, 8),
      itemBuilder: (context, index) {
        final item = entries[index];
        final ratio = maxVal > 0 ? (item.value / maxVal) : 0.0;
        final cor = _paletaCores[index % _paletaCores.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. ${item.key}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.value} laudos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 5. Produção por Perito (Ranking e Produtividade) ────────────────────────
  Widget _buildGraficoPeritos() {
    final mapa = widget.dashboard.producaoPorPerito;
    if (mapa.isEmpty) {
      return _buildEmptyChart('Nenhum perito registrado.');
    }

    final entries = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return ListView.builder(
      itemCount: entries.length.clamp(0, 8),
      itemBuilder: (context, index) {
        final item = entries[index];
        final ratio = maxVal > 0 ? (item.value / maxVal) : 0.0;
        const cor = AppTheme.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.value} laudos',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(cor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChart(String mensagem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pie_chart_outline_rounded,
              size: 40, color: AppTheme.textHint),
          const SizedBox(height: 8),
          Text(
            mensagem,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
