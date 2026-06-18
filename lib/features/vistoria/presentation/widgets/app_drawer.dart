import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          _DrawerHeader(),
          Expanded(
            child: _LaudosRecentes(),
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'VistoriaPro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          BlocBuilder<AuthBloc, AuthBlocState>(
            builder: (context, state) {
              final email = state is AuthAuthenticated
                  ? state.user.email ?? 'Perito'
                  : 'Perito';
              return Text(
                email,
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

// ── Lista de Laudos Recentes ──────────────────────────────────────────────────

class _LaudosRecentes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'LAUDOS RECENTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            // Import injection_container and vistoria_dao if needed, but since we are in drawer, we can just use sl
            future: _buscarVistorias(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final laudos = snapshot.data ?? [];
              if (laudos.isEmpty) {
                return _EmptyLaudos();
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: laudos.length,
                itemBuilder: (context, index) {
                  return _LaudoTile(vistoria: laudos[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> _buscarVistorias() async {
    // Retorna a lista real usando o DAO local
    final dao = sl<VistoriaDao>();
    final vistorias = await dao.listarVistorias();
    // Para obter a placa, poderíamos buscar os veículos, mas para ficar rápido, 
    // vamos listar as vistorias e buscar os veículos associados
    final lista = [];
    for (var v in vistorias) {
      final veiculo = await dao.buscarVeiculoPorVistoria(v.id);
      lista.add({
        'vistoria': v,
        'veiculo': veiculo,
      });
    }
    return lista;
  }
}

class _LaudoTile extends StatelessWidget {
  final dynamic vistoria;
  const _LaudoTile({required this.vistoria});

  @override
  Widget build(BuildContext context) {
    final v = vistoria['vistoria'];
    final veiculo = vistoria['veiculo'];
    
    final isEmAndamento = v.status != 'concluido';
    final placa = veiculo?.placa ?? 'Sem Placa';
    final tipo = v.tipoVistoria ?? 'Vistoria';
    final data = v.createdAt;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Fecha o drawer
        // Redireciona para o fluxo da vistoria usando go_router
        context.push('/vistoria-wizard/${v.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Ícone de status
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEmAndamento
                    ? AppTheme.comObsLight
                    : AppTheme.conformeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEmAndamento
                    ? Icons.pending_rounded
                    : Icons.check_circle_rounded,
                color: isEmAndamento ? AppTheme.comObs : AppTheme.conforme,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Dados do laudo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placa,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tipo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Data
            Text(
              _formatData(data),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatData(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24 && now.day == dt.day) return 'Hoje';
    if (diff.inDays <= 1 && now.day - 1 == dt.day) return 'Ontem';
    return DateFormat('dd/MM').format(dt);
  }
}

class _EmptyLaudos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 48,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum laudo ainda',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
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
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja encerrar a sessão?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.naoConforme,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthLogoutRequested());
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

// ── Modelo temporário ─────────────────────────────────────────────────────────

class _LaudoItem {
  final String placa;
  final String tipo;
  final DateTime data;
  final String status;

  _LaudoItem({
    required this.placa,
    required this.tipo,
    required this.data,
    required this.status,
  });
}
