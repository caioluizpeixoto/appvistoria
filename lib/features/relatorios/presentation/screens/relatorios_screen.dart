import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../data/repositories/relatorios_repository.dart';
import '../cubit/relatorios_cubit.dart';
import '../cubit/relatorios_state.dart';
import '../widgets/relatorio_filtros_bar.dart';
import '../widgets/relatorio_metric_cards_grid.dart';
import '../widgets/relatorio_graficos_section.dart';
import '../widgets/relatorio_tabela_section.dart';
import '../widgets/relatorio_fechamento_section.dart';
import '../widgets/gerar_relatorio_modal.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RelatoriosCubit(
        repository: sl<RelatoriosRepository>(),
        supabase: sl<SupabaseClient>(),
      )..inicializar(),
      child: const _RelatoriosView(),
    );
  }
}

class _RelatoriosView extends StatelessWidget {
  const _RelatoriosView();

  void _abrirModalGerarRelatorio(BuildContext context, RelatoriosCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => GerarRelatorioModal(cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isMaster = user?.isMaster ?? false;
    final cubit = context.read<RelatoriosCubit>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Relatórios & Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              isMaster
                  ? 'Visão Administrativa Consolidada'
                  : (user?.userMetadata?['name'] as String? ?? 'Ultra Prime'),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar dados',
            onPressed: () => cubit.inicializar(),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Gerar Relatório',
            onPressed: () => _abrirModalGerarRelatorio(context, cubit),
          ),
        ],
      ),
      body: BlocConsumer<RelatoriosCubit, RelatoriosState>(
        listener: (context, state) {
          if (state is RelatoriosLoaded && state.mensagemExportacao != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagemExportacao!),
                backgroundColor: state.mensagemExportacao!.contains('Erro')
                    ? AppTheme.naoConforme
                    : AppTheme.primary,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RelatoriosLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Carregando dados da empresa...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is RelatoriosError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 56, color: AppTheme.naoConforme),
                    const SizedBox(height: 16),
                    Text(
                      state.mensagem,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => cubit.inicializar(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is RelatoriosLoaded) {
            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => cubit.inicializar(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Barra Superior de Filtros e Empresa
                    RelatorioFiltrosBar(
                      cubit: cubit,
                      filtros: state.filtros,
                      empresasMaster: state.empresasMaster,
                      isMaster: isMaster,
                      onGerarRelatorio: () =>
                          _abrirModalGerarRelatorio(context, cubit),
                    ),

                    const SizedBox(height: 16),

                    // 2. Cards de Métricas Superiores
                    RelatorioMetricCardsGrid(dashboard: state.dashboard),

                    const SizedBox(height: 16),

                    // 3. Gráficos Interativos (fl_chart)
                    RelatorioGraficosSection(dashboard: state.dashboard),

                    const SizedBox(height: 16),

                    // 4. Tabela Responsiva com Busca e Paginação
                    RelatorioTabelaSection(state: state, cubit: cubit),

                    const SizedBox(height: 16),

                    // 5. Fechamento por Cliente
                    RelatorioFechamentoSection(
                      clientes: state.dashboard.fechamentoClientes,
                      faturamentoTotal: state.dashboard.faturamentoTotal,
                      cubit: cubit,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
