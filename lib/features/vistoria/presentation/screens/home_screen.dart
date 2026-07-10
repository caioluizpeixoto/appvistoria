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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Selecione a pesquisa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Escolha o tipo de pesquisa antes do laudo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              _RadarCard(nome: 'AUTO BIN', codigo: 'auto_bin'),
              _RadarCard(nome: 'AUTO PERÍCIA', codigo: 'auto_pericia'),
              _RadarCard(nome: 'AUTO COMPLETA', codigo: 'auto_completa'),
              _RadarCard(nome: 'AUTO LEILÃO', codigo: 'auto_leilao'),
              _RadarCard(nome: 'AUTO BASE ESTADUAL', codigo: 'auto_base_estadual'),
              _RadarCard(nome: 'AUTO DÉBITOS E RECALL', codigo: 'auto_debitos_recall'),
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
  final String? codigoRadar;

  const _VistoriaCard({required this.tipo, this.codigoRadar});

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
          onTap: () {
            if (codigoRadar != null) {
              Navigator.of(context).pop(); // fecha o modal
            }
            context.push('/identificacao/${tipo.slug}',
                extra: codigoRadar != null
                    ? {'produtoSelecionado': codigoRadar}
                    : null);
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

// ── Card de Pesquisa ────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final String nome;
  final String codigo;

  const _RadarCard({required this.nome, required this.codigo});

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
                          'Selecione o tipo de vistoria',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      _VistoriaCard(tipo: TipoVistoria.carroComCroqui, codigoRadar: codigo),
                      _VistoriaCard(tipo: TipoVistoria.cautelarCarro, codigoRadar: codigo),
                      _VistoriaCard(tipo: TipoVistoria.cautelarCaminhao, codigoRadar: codigo),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
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
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
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
