import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';

class HistoricoVistoriasScreen extends StatelessWidget {
  const HistoricoVistoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Histórico de Vistorias'),
      ),
      body: FutureBuilder<List<Vistoria>>(
        future: sl<VistoriaDao>().listarVistorias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar vistorias'));
          }

          final vistorias = snapshot.data ?? [];
          if (vistorias.isEmpty) {
            return const Center(child: Text('Nenhuma vistoria encontrada.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vistorias.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final v = vistorias[index];
              return _VistoriaCard(vistoria: v);
            },
          );
        },
      ),
    );
  }
}

class _VistoriaCard extends StatelessWidget {
  final Vistoria vistoria;

  const _VistoriaCard({required this.vistoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          vistoria.numeroLaudo,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(vistoria.dataHora)}\nStatus: ${vistoria.status}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar para revisar ou editar
          context.push('/vistoria-wizard/${vistoria.id}');
        },
      ),
    );
  }
}
