import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../domain/vistoria_type.dart';
import '../widgets/app_drawer.dart';

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
              _VistoriaCard(tipo: TipoVistoria.cautelarCarro, produtoPesquisa: produtoPesquisa),
              _VistoriaCard(tipo: TipoVistoria.cautelarCaminhao, produtoPesquisa: produtoPesquisa),
              _VistoriaCard(tipo: TipoVistoria.carroComCroqui, produtoPesquisa: produtoPesquisa),
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
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_bin');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO PERÍCIA',
                codigo: 'auto_pericia',
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_pericia');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO COMPLETA',
                codigo: 'auto_completa',
                onTap: () {
                  Navigator.pop(ctx);
                  _abrirModalCautelar(context, 'auto_completa');
                },
              ),
              _PesquisaCard(
                titulo: 'AUTO LEILÃO',
                codigo: 'auto_leilao',
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
                  _abrirModalCautelar(context, null);
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Home Auto'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notificações',
            onPressed: () {},
          ),
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
                // 1. CARD CAUTELAR
                _MainActionCard(
                  title: 'Cautelar',
                  subtitle: 'Realizar laudo e vistoria cautelar veicular completa',
                  icon: Icons.assignment_turned_in_rounded,
                  badgeColor: const Color(0xFFE3F2FD),
                  iconColor: AppTheme.primary,
                  onTap: () => _abrirModalTipoPesquisa(context),
                ),
                const SizedBox(height: 16),

                // 2. CARD PESQUISA
                _MainActionCard(
                  title: 'Pesquisa',
                  subtitle: 'Realizar consulta rápida de dados veiculares, histórico e BIN',
                  icon: Icons.manage_search_rounded,
                  badgeColor: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFF57C00),
                  onTap: () {
                    context.push(
                      '/identificacao/${TipoVistoria.cautelarCarro.slug}',
                      extra: {'somentePesquisa': true},
                    );
                  },
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
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
          final email =
              state is AuthAuthenticated ? state.user.email ?? '' : '';
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
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty ? email : 'Perito',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                  'assets/images/logo.pdf.png',
                  fit: BoxFit.contain,
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
          onTap: () {
            Navigator.of(context).pop(); // fecha o modal
            context.push('/identificacao/${tipo.slug}', extra: {
              if (produtoPesquisa != null) 'produtoSelecionado': produtoPesquisa,
            });
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

  const _PesquisaCard({
    required this.titulo,
    required this.codigo,
    required this.onTap,
    this.icone,
  });

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
                  child: Icon(icone ?? Icons.search_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
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

