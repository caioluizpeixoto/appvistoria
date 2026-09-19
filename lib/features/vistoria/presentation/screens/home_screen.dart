import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/bloc/background_tasks/background_tasks_cubit.dart';
import '../../../../core/bloc/background_tasks/background_tasks_state.dart';
import '../../domain/vistoria_type.dart';
import '../widgets/app_drawer.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../wallet/data/repositories/wallet_repository.dart';
import '../../../wallet/domain/models/wallet_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _abrirModalCautelar(BuildContext context, String? produtoPesquisa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Selecione o tipo de vistoria cautelar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _VistoriaCard(
                  tipo: TipoVistoria.cautelarCarro,
                  produtoPesquisa: produtoPesquisa),
              _VistoriaCard(
                  tipo: TipoVistoria.cautelarCaminhao,
                  produtoPesquisa: produtoPesquisa),
              _VistoriaCard(
                  tipo: TipoVistoria.carroComCroqui,
                  produtoPesquisa: produtoPesquisa),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalTipoPesquisa(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Selecione o tipo de pesquisa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _PesquisaCard(
                titulo: 'AUTO BIN (Simples)',
                codigo: 'auto_bin',
                preco: 7.66,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_bin');
                },
              ),
              _PesquisaCard(
                titulo: 'PESQUISA DE MOTOR',
                codigo: 'bin_por_motor',
                preco: 7.90,
                icone: Icons.tune_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'bin_por_motor');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO PERÍCIA',
                codigo: 'auto_pericia',
                preco: 35.80,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_pericia');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO PERÍCIA HRF',
                codigo: 'auto_pericia_hrf',
                preco: 28.90,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_pericia_hrf');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO COMPLETA',
                codigo: 'auto_completa',
                preco: 60.91,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_completa');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO LEILÃO',
                codigo: 'auto_leilao',
                preco: 21.24,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_leilao');
                },
              ),
              _PesquisaCard(
                titulo: 'SEM PESQUISA PRÉVIA',
                codigo: 'nenhuma',
                icone: Icons.block_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'nenhuma');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirModalPesquisaAvulsa(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pesquisa Avulsa - Selecione o Tipo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _PesquisaCard(
                titulo: 'AUTO BIN (Placa ou Chassi)',
                codigo: 'auto_bin',
                preco: 7.66,
                icone: Icons.directions_car_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'produtoSelecionado': 'auto_bin',
                      'modoEntrada': 'placa',
                      'precoPesquisa': 7.66,
                    },
                  );
                },
              ),
              _PesquisaCard(
                titulo: 'PESQUISA DE MOTOR',
                codigo: 'bin_por_motor',
                preco: 7.90,
                icone: Icons.tune_rounded,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'somenteMotor': true,
                      'produtoSelecionado': 'bin_por_motor',
                      'modoEntrada': 'motor',
                      'precoPesquisa': 7.90,
                    },
                  );
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO PERÍCIA (Placa)',
                codigo: 'auto_pericia',
                preco: 35.80,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'produtoSelecionado': 'auto_pericia',
                      'modoEntrada': 'placa',
                      'precoPesquisa': 35.80,
                    },
                  );
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO PERÍCIA HRF (Placa)',
                codigo: 'auto_pericia_hrf',
                preco: 28.90,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'produtoSelecionado': 'auto_pericia_hrf',
                      'modoEntrada': 'placa',
                      'precoPesquisa': 28.90,
                    },
                  );
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO COMPLETA (Placa)',
                codigo: 'auto_completa',
                preco: 60.91,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'produtoSelecionado': 'auto_completa',
                      'modoEntrada': 'placa',
                      'precoPesquisa': 60.91,
                    },
                  );
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO LEILÃO (Placa ou Chassi)',
                codigo: 'auto_leilao',
                preco: 21.24,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(
                    '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                    extra: {
                      'somentePesquisa': true,
                      'produtoSelecionado': 'auto_leilao',
                      'modoEntrada': 'placa',
                      'precoPesquisa': 21.24,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isMaster = user?.isMaster ?? false;
    final role = user?.appRole ?? 'empresa';
    final isUsuarioOnly = !isMaster && role == 'usuario';

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(user?.userMetadata?['name'] as String? ?? 'App Vistoria'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          ValueListenableBuilder<WalletModel?>(
            valueListenable: sl<WalletRepository>().getWalletNotifier(),
            builder: (context, wallet, child) {
              String balanceText = '';
              double currentBalance = 0;
              if (wallet != null) {
                currentBalance = wallet.balance;
                balanceText = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(currentBalance);
              }
              
              return InkWell(
                onTap: () => context.push('/carteira'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (balanceText.isNotEmpty) ...[
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: currentBalance < 0 ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
          _NotificationBell(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _WelcomeBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'O que deseja fazer?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Escolha o serviço para iniciar no sistema',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 0. CARD LIBERAR APARELHOS (Exclusivo para Master)
                if (isMaster) ...[
                  _MainActionCard(
                    title: 'Liberar Aparelhos',
                    subtitle:
                        'Autorizar e gerenciar aparelhos para acesso ao sistema',
                    icon: Icons.phonelink_lock_rounded,
                    badgeColor: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    onTap: () => context.push('/master/painel'),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. CARD CAUTELAR (Oculto se for apenas 'usuario')
                if (!isUsuarioOnly) ...[
                  _MainActionCard(
                    title: 'Cautelar',
                    subtitle:
                        'Realizar laudo e vistoria cautelar veicular completa',
                    icon: Icons.assignment_turned_in_rounded,
                    badgeColor: const Color(0xFFE3F2FD),
                    iconColor: AppTheme.primary,
                    onTap: () => _abrirModalTipoPesquisa(context),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. CARD PESQUISA (Oculto se for apenas 'usuario')
                if (!isUsuarioOnly) ...[
                  _MainActionCard(
                    title: 'Pesquisa Avulsa',
                    subtitle:
                        'Realizar consulta rápida de dados veiculares, histórico, BIN ou Motor',
                    icon: Icons.manage_search_rounded,
                    badgeColor: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    onTap: () => _abrirModalPesquisaAvulsa(context),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. CARD VISTORIA DE ENTRADA (antigo Checklist Veicular)
                _MainActionCard(
                  title: 'Vistoria de Entrada',
                  subtitle:
                      'Realizar vistoria de entrada para veículos pesados ou de passeio',
                  icon: Icons.fact_check_rounded,
                  badgeColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF388E3C), // verde
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.background,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Selecione o tipo de Vistoria',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              _VistoriaCard(
                                  tipo: TipoVistoria.checklistPasseio),
                              _VistoriaCard(tipo: TipoVistoria.checklistPesado),
                              _VistoriaCard(tipo: TipoVistoria.checklistOnibus),
                              _VistoriaCard(
                                  tipo: TipoVistoria.checklistMicroOnibus),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. CARD RELATÓRIOS & DASHBOARD
                _MainActionCard(
                  title: 'Relatórios & Dashboard',
                  subtitle:
                      'Acompanhe produção, faturamento, gráficos e fechamento por cliente',
                  icon: Icons.insights_rounded,
                  badgeColor: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () => context.push('/relatorios'),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão de Notificações com Badge ──────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackgroundTasksCubit, BackgroundTasksState>(
      builder: (context, state) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notificações',
              onPressed: () {
                _abrirModalNotificacoes(context, state);
              },
            ),
            if (state.hasRunningTasks)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else if (state.hasUnreadCompletedTasks)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${state.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _abrirModalNotificacoes(BuildContext context, BackgroundTasksState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tarefas e Pesquisas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma pesquisa na sessão atual.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          itemCount: state.tasks.length,
                          itemBuilder: (context, index) {
                            final task = state.tasks[index];
                            IconData icon;
                            Color color;

                            if (task.status == BackgroundTaskStatus.running) {
                              icon = Icons.hourglass_top_rounded;
                              color = Colors.blueAccent;
                            } else if (task.status == BackgroundTaskStatus.success) {
                              icon = Icons.check_circle_rounded;
                              color = AppTheme.primary;
                            } else {
                              icon = Icons.error_rounded;
                              color = Colors.redAccent;
                            }

                            return ListTile(
                              leading: Icon(icon, color: color),
                              title: Text(task.title, style: TextStyle(fontWeight: task.isRead ? FontWeight.normal : FontWeight.bold)),
                              subtitle: Text(task.subtitle),
                              tileColor: task.isRead ? null : AppTheme.primary.withValues(alpha: 0.05),
                              onTap: () {
                                context.read<BackgroundTasksCubit>().marcarComoLida(task.id);
                                if (task.status == BackgroundTaskStatus.success) {
                                  Navigator.pop(ctx);
                                  if (task.redirectPath != null) {
                                    context.push(task.redirectPath!, extra: task.redirectExtra);
                                  } else {
                                    context.push('/historico-consultas');
                                  }
                                } else if (task.status == BackgroundTaskStatus.error) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(task.errorMessage ?? 'Erro')));
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Card Principal de Ação ───────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner de boas-vindas ─────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, state) {
          String displayValue = 'Vistoriador';
          if (state is AuthAuthenticated) {
            final name = state.user.userMetadata?['name'] as String?;
            if (name != null && name.trim().isNotEmpty) {
              displayValue = name;
            } else {
              final email = state.user.email ?? '';
              if (email.isNotEmpty) {
                // Remove o @appvistoria.com.br
                displayValue = email.split('@').first;
              }
            }
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (state is AuthAuthenticated && state.user.isMaster) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MASTER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/logo.pdf.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.primary,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Card de tipo de vistoria (Modal) ─────────────────────────────────────────

class _VistoriaCard extends StatelessWidget {
  final TipoVistoria tipo;
  final String? produtoPesquisa;

  const _VistoriaCard({required this.tipo, this.produtoPesquisa});

  Color get _accentColor {
    switch (tipo) {
      case TipoVistoria.cautelarCarro:
        return AppTheme.primary;
      case TipoVistoria.cautelarCaminhao:
        return const Color(0xFF00796B); // teal
      case TipoVistoria.carroComCroqui:
        return const Color(0xFF6A1B9A); // roxo
      case TipoVistoria.vistoriaEntrada:
        return const Color(0xFF388E3C); // verde
      case TipoVistoria.checklistPesado:
        return const Color(0xFFE65100); // laranja escuro
      case TipoVistoria.checklistOnibus:
        return const Color(0xFFD84315); // deep orange
      case TipoVistoria.checklistMicroOnibus:
        return const Color(0xFFEF6C00); // orange
      case TipoVistoria.checklistPasseio:
        return const Color(0xFFF57C00); // laranja
    }
  }

  Color get _bgColor {
    switch (tipo) {
      case TipoVistoria.cautelarCarro:
        return const Color(0xFFE3F2FD);
      case TipoVistoria.cautelarCaminhao:
        return const Color(0xFFE0F2F1);
      case TipoVistoria.carroComCroqui:
        return const Color(0xFFF3E5F5);
      case TipoVistoria.vistoriaEntrada:
        return const Color(0xFFE8F5E9); // verde claro
      case TipoVistoria.checklistPesado:
        return const Color(0xFFFFF3E0); // laranja claro
      case TipoVistoria.checklistOnibus:
        return const Color(0xFFFBE9E7); // deep orange claro
      case TipoVistoria.checklistMicroOnibus:
        return const Color(0xFFFFF3E0); // orange claro
      case TipoVistoria.checklistPasseio:
        return const Color(0xFFFFF8E1); // amarelado claro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (tipo == TipoVistoria.checklistPesado ||
                tipo == TipoVistoria.checklistPasseio) {
              // Pula a tela de pesquisa (IdentificacaoScreen) e cria a vistoria direto
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final dao = sl<VistoriaDao>();
                final vistoriaId = const Uuid().v4();
                final shortCode = vistoriaId.substring(0, 8).toUpperCase();
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id ??
                        'usuario-deslogado';

                await dao.inserirVistoria(VistoriasCompanion.insert(
                  id: vistoriaId,
                  numeroLaudo: 'CHK-$shortCode',
                  vistoriadorId: currentUserId,
                  tipoVistoria: drift.Value(tipo.titulo),
                ));

                await dao.inserirVeiculo(VeiculosCompanion.insert(
                  id: vistoriaId,
                  vistoriaId: vistoriaId,
                  placa: '',
                ));

                if (context.mounted) {
                  Navigator.of(context).pop(); // fecha o loading
                  Navigator.of(context).pop(); // fecha o modal de checklist
                  context.push('/vistoria-wizard/$vistoriaId', extra: {
                    'dadosIniciais': <String, dynamic>{},
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // fecha o loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar checklist: $e')),
                  );
                }
              }
            } else {
              Navigator.of(context).pop(); // fecha o modal
              context.push('/identificacao/${tipo.slug}', extra: {
                if (produtoPesquisa != null) ...{
                  'produtoSelecionado': produtoPesquisa,
                  'precoPesquisa': produtoPesquisa == 'auto_bin' ? 7.66 :
                                   produtoPesquisa == 'bin_por_motor' ? 7.90 :
                                   produtoPesquisa == 'auto_pericia' ? 35.80 :
                                   produtoPesquisa == 'auto_pericia_hrf' ? 28.90 :
                                   produtoPesquisa == 'auto_completa' ? 60.91 :
                                   produtoPesquisa == 'auto_leilao' ? 21.24 : 0.00,
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tipo.icone, color: _accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipo.descricao,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: _accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PesquisaCard extends StatelessWidget {
  final String titulo;
  final String codigo;
  final IconData? icone;
  final VoidCallback onTap;
  final double? preco;

  const _PesquisaCard({
    required this.titulo,
    required this.codigo,
    required this.onTap,
    this.icone,
    this.preco,
  });

  @override
  Widget build(BuildContext context) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icone ?? Icons.search_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (preco != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatador.format(preco),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
