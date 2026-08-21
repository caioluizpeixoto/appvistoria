import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/sync_service.dart';
import '../screens/historico_nuvem_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'empresa';
    final isUsuarioOnly = role == 'usuario';

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.fact_check_rounded,
                      color: AppTheme.textSecondary),
                  title: const Text(
                    'Laudos Locais',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/historico-vistorias');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_rounded,
                      color: AppTheme.textSecondary),
                  title: const Text(
                    'Histórico de Consultas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/historico-radar');
                  },
                ),
                const Divider(),
                /* Ocultado temporariamente para testes de produção sem nuvem
                if (!isUsuarioOnly) ...[
                  ListTile(
                    leading: const Icon(Icons.cloud_done_rounded,
                        color: AppTheme.textSecondary),
                    title: const Text(
                      'Histórico na Nuvem',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoricoNuvemScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync_rounded,
                        color: AppTheme.textSecondary),
                    title: const Text(
                      'Sincronizar Vistorias',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // fecha o drawer primeiro
                      // mostra a mensagem
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sincronizando vistorias...')),
                      );
                      try {
                        await sl<SyncService>().syncVistoriasPendentes();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vistorias enviadas para a nuvem com sucesso!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao sincronizar: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                ],
                */
              ],
            ),
          ),
          _DrawerFooter(),
        ],
      ),
    );
  }
}

// ── Cabeçalho ─────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
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
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone do app
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ultra Prime',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          BlocBuilder<AuthBloc, AuthBlocState>(
            builder: (context, state) {
              String displayValue = 'Perito';
              if (state is AuthAuthenticated) {
                final name = state.user.userMetadata?['name'] as String?;
                if (name != null && name.trim().isNotEmpty) {
                  displayValue = name;
                } else {
                  final email = state.user.email ?? '';
                  if (email.isNotEmpty) {
                    displayValue = email.split('@').first;
                  }
                }
              }
              return Text(
                displayValue,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Rodapé ────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.logout_rounded,
              color: AppTheme.naoConforme,
              size: 20,
            ),
            title: const Text(
              'Sair',
              style: TextStyle(
                color: AppTheme.naoConforme,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: () {
              // Capture o BLoC antes de fechar o drawer/contexto atual
              final authBloc = context.read<AuthBloc>();
              // Fechar o drawer primeiro
              Navigator.pop(context);

              showDialog(
                context:
                    context, // Nota: idealmente não se usa context após pop, mas como o flutter ainda encontra o navigator raiz, funciona.
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja encerrar a sessão?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.naoConforme,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx); // Fechar dialog
                        authBloc.add(AuthLogoutRequested());
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
