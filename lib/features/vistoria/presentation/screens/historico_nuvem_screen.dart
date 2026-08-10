import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/sync_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoricoNuvemScreen extends StatefulWidget {
  const HistoricoNuvemScreen({super.key});

  @override
  State<HistoricoNuvemScreen> createState() => _HistoricoNuvemScreenState();
}

class _HistoricoNuvemScreenState extends State<HistoricoNuvemScreen> {
  late Future<List<Map<String, dynamic>>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    setState(() {
      _futureHistorico = sl<SyncService>().listarVistoriasNuvem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Histórico na Nuvem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureHistorico,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados da nuvem:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma vistoria salva na nuvem ainda.\nSincronize suas vistorias locais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = lista[index];
              final numeroLaudo = item['numero_laudo'] ?? 'Sem Laudo';
              final placa = item['placa'] ?? 'Sem placa';
              final chassi = item['chassi'] ?? 'Sem chassi';
              final status = item['status'] ?? 'desconhecido';
              final createdAtStr = item['created_at'] as String?;
              
              DateTime? data;
              if (createdAtStr != null) {
                data = DateTime.tryParse(createdAtStr);
              }

              final dadosCompletos = item['dados_completos'] as Map<String, dynamic>?;
              final pdfUrl = dadosCompletos?['vistoria']?['pdfUrl'] as String?;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Laudo: $numeroLaudo',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Placa: $placa', style: const TextStyle(fontSize: 14)),
                      Text('Chassi: $chassi', style: const TextStyle(fontSize: 14)),
                      if (data != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Salvo em: ${DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal())}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (pdfUrl != null && pdfUrl.isNotEmpty)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(pdfUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                                label: const Text('Ver PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            )
                          else
                            const Expanded(
                              child: Text(
                                'PDF não enviado',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
