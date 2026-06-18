import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../domain/vistoria_type.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('VistoriaPro'),
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Selecione o tipo de vistoria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Escolha a modalidade para iniciar o laudo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MenuActionCard(
                      titulo: 'Histórico\nConsultas',
                      icone: Icons.search_rounded,
                      cor: const Color(0xFF0277BD), // light blue
                      onTap: () => context.push('/historico-consultas'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MenuActionCard(
                      titulo: 'Histórico\nVistorias',
                      icone: Icons.fact_check_rounded,
                      cor: const Color(0xFF2E7D32), // green
                      onTap: () => context.push('/historico-vistorias'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _VistoriaCard(tipo: TipoVistoria.carroComCroqui),
              _VistoriaCard(tipo: TipoVistoria.cautelarCarro),
              _VistoriaCard(tipo: TipoVistoria.cautelarCaminhao),
              const SizedBox(height: 32),
            ]),
          ),
        ],
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Laudos de hoje: 0',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Card de tipo de vistoria ──────────────────────────────────────────────────

class _VistoriaCard extends StatelessWidget {
  final TipoVistoria tipo;

  const _VistoriaCard({required this.tipo});

  // Cores de destaque por tipo
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
          onTap: () => context.push('/identificacao/${tipo.slug}'),
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

// ── Botões de Ação do Menu ────────────────────────────────────────────────────

class _MenuActionCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cor.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 28),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cor.withAlpha(200),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
