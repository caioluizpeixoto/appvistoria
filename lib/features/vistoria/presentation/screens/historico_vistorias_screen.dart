import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';

class HistoricoVistoriasScreen extends StatefulWidget {
  const HistoricoVistoriasScreen({super.key});

  @override
  State<HistoricoVistoriasScreen> createState() => _HistoricoVistoriasScreenState();
}

class _HistoricoVistoriasScreenState extends State<HistoricoVistoriasScreen> {
  late Future<List<Map<String, dynamic>>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    _futureHistorico = _carregarHistorico();
  }

  void _recarregar() {
    setState(() {
      _futureHistorico = _carregarHistorico();
    });
  }

  Future<List<Map<String, dynamic>>> _carregarHistorico() async {
    final dao = sl<VistoriaDao>();
    final vistorias = await dao.listarVistorias();
    final lista = <Map<String, dynamic>>[];
    for (var v in vistorias) {
      final veiculo = await dao.buscarVeiculoPorVistoria(v.id);
      lista.add({
        'vistoria': v,
        'veiculo': veiculo,
      });
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Histórico de Vistorias'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureHistorico,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar vistorias'));
          }

          final itens = snapshot.data ?? [];
          if (itens.isEmpty) {
            return const Center(child: Text('Nenhuma vistoria encontrada.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: itens.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _VistoriaCard(
                item: itens[index],
                onDelete: _recarregar,
              );
            },
          );
        },
      ),
    );
  }
}

class _VistoriaCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _VistoriaCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final Vistoria vistoria = item['vistoria'];
    final Veiculo? veiculo = item['veiculo'];

    final isEmAndamento = vistoria.status != 'concluido';
    final placa = (veiculo?.placa != null && veiculo!.placa.isNotEmpty) 
        ? veiculo.placa.toUpperCase() 
        : 'S/ Placa';
    final tipo = vistoria.tipoVistoria;
    
    String formatLaudo(String num) {
      if (num.length > 20) {
        return '${num.substring(0, 12).toUpperCase()}...';
      }
      return num;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (vistoria.status == 'concluido') {
                final diff = DateTime.now().difference(vistoria.updatedAt);
                if (diff.inHours <= 72) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Retificar Laudo'),
                      content: Text('Este laudo foi concluído. Você tem ${72 - diff.inHours}h restantes para retificá-lo. Deseja reabrir a edição?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/vistoria-wizard/${vistoria.id}');
                          },
                          child: const Text('Retificar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Prazo Expirado'),
                      content: const Text('Este laudo foi concluído há mais de 72h e não pode mais ser alterado.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                context.push('/vistoria-wizard/${vistoria.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone de status
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEmAndamento ? AppTheme.comObsLight : AppTheme.conformeLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEmAndamento ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                      color: isEmAndamento ? AppTheme.comObs : AppTheme.conforme,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Dados do laudo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placa,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$tipo • ${formatLaudo(vistoria.numeroLaudo)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(vistoria.dataHora),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.naoConforme),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir Laudo?'),
                          content: const Text('Tem certeza que deseja excluir esta vistoria? Esta ação não pode ser desfeita.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.naoConforme),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final dao = sl<VistoriaDao>();
                                await dao.excluirVistoriaCompleta(vistoria.id);
                                onDelete();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vistoria excluída com sucesso.'),
                                      backgroundColor: AppTheme.conforme,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (vistoria.pdfUrl != null && vistoria.pdfUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  context.push('/pdf-preview/${vistoria.id}?path=${vistoria.pdfUrl}');
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary, size: 20),
                label: const Text('Ver Laudo em PDF', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
