import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/autocred_dao.dart';
import '../../../../core/services/pdf_radar_generator.dart';
import 'dart:convert';

import '../../../../core/services/image_service.dart';
import '../../../../core/services/sync_service.dart';

class HistoricoVistoriasScreen extends StatefulWidget {
  const HistoricoVistoriasScreen({super.key});

  @override
  State<HistoricoVistoriasScreen> createState() =>
      _HistoricoVistoriasScreenState();
}

class _HistoricoVistoriasScreenState extends State<HistoricoVistoriasScreen> {
  late Future<List<Map<String, dynamic>>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    _futureHistorico = _carregarHistorico();
    _iniciarSincronizacaoBackground();
  }

  void _iniciarSincronizacaoBackground() {
    sl<SyncService>().autoSync().then((_) {
      if (mounted) {
        setState(() {
          _futureHistorico = _carregarHistorico();
        });
      }
    }).catchError((e) {
      print('Erro no autoSync background: $e');
    });
  }

  void _recarregar() {
    setState(() {
      _futureHistorico = _carregarHistorico();
    });
    _iniciarSincronizacaoBackground();
  }

  Future<List<Map<String, dynamic>>> _carregarHistorico() async {
    final dao = sl<VistoriaDao>();
    final autocredDao = sl<AutocredDao>();
    final vistorias = await dao.listarVistorias();
    final lista = <Map<String, dynamic>>[];

    for (var v in vistorias) {
      final veiculo = await dao.buscarVeiculoPorVistoria(v.id);
      var consulta = await autocredDao.buscarConsultaPorVistoria(v.id);
      if (consulta == null && veiculo != null && veiculo.placa.isNotEmpty) {
        final placaLimpa =
            veiculo.placa.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
        consulta = await autocredDao.buscarConsultaPorPlaca(placaLimpa);
        if (consulta == null) {
          consulta = await autocredDao.buscarConsultaPorPlaca(veiculo.placa);
        }
      }

      lista.add({
        'vistoria': v,
        'veiculo': veiculo,
        'consulta': consulta,
        'webhookPdfUrl': null,
      });
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Histórico de Laudos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sincronizar',
            onPressed: _recarregar,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recarregar(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureHistorico,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Erro ao carregar laudos'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _recarregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final itens = snapshot.data ?? [];
            if (itens.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Nenhum laudo encontrado.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = itens[index];
                return _VistoriaCard(
                  vistoria: item['vistoria'],
                  veiculo: item['veiculo'],
                  consulta: item['consulta'],
                  webhookPdfUrl: item['webhookPdfUrl'] as String?,
                  onDelete: _recarregar,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VistoriaCard extends StatelessWidget {
  final Vistoria vistoria;
  final dynamic veiculo;
  final dynamic consulta;
  final String? webhookPdfUrl;
  final VoidCallback onDelete;

  const _VistoriaCard({
    required this.vistoria,
    required this.veiculo,
    this.consulta,
    this.webhookPdfUrl,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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

    void _handleEdit() {
      if (vistoria.status == 'concluido') {
        final diff = DateTime.now().difference(vistoria.updatedAt);
        const bool _enableTimeLimit = false; // Deixado falso a pedido do usuário (sem tempo)
        
        if (!_enableTimeLimit || diff.inHours <= 72) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Retificar Vistoria'),
              content: Text(
                  _enableTimeLimit 
                      ? 'Esta vistoria foi concluída. Você tem ${72 - diff.inHours}h restantes para retificá-la. Deseja reabrir a edição?'
                      : 'Esta vistoria foi concluída. Deseja reabrir a edição para retificação?'),
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
              content: const Text(
                  'Esta vistoria foi concluída há mais de 72h e não pode mais ser alterada.'),
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
            onTap: _handleEdit,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEmAndamento
                          ? AppTheme.comObsLight
                          : AppTheme.conformeLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEmAndamento
                          ? Icons.pending_actions_rounded
                          : Icons.check_circle_rounded,
                      color:
                          isEmAndamento ? AppTheme.comObs : AppTheme.conforme,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(vistoria.dataHora),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      vistoria.status == 'concluido'
                          ? Icons.edit_document
                          : Icons.edit_rounded,
                      color: AppTheme.primary,
                    ),
                    tooltip: vistoria.status == 'concluido'
                        ? 'Retificar Vistoria'
                        : 'Continuar Vistoria',
                    onPressed: _handleEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.naoConforme),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Excluir Vistoria?'),
                          content: const Text(
                              'Tem certeza que deseja excluir esta vistoria? Esta ação não pode ser desfeita.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.naoConforme),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final dao = sl<VistoriaDao>();
                                final syncService = sl<SyncService>();
                                final imgService = sl<ImageService>();
                                
                                // Limpar imagens do Supabase antes de excluir a vistoria
                                final fotos = await dao.listarFotosPorVistoria(vistoria.id);
                                final pathsToDel = <String>[];
                                for (final f in fotos) {
                                  if (f.urlSupabase != null) {
                                    final p = imgService.extractStoragePath(f.urlSupabase);
                                    if (p != null) pathsToDel.add(p);
                                  }
                                }
                                if (pathsToDel.isNotEmpty) {
                                  await imgService.deleteImages(pathsToDel);
                                }

                                await dao.excluirVistoriaCompleta(vistoria.id);
                                await syncService.excluirVistoriaNuvem(vistoria.id);
                                onDelete();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Vistoria excluída com sucesso.'),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final placaQuery = Uri.encodeComponent(placa.trim());
                  context.push(
                      '/pdf-preview/${vistoria.id}?path=${vistoria.pdfUrl}&placa=$placaQuery');
                },
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: AppTheme.primary, size: 20),
                label: const Text('Ver Documento em PDF',
                    style: TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          if (consulta != null || webhookPdfUrl != null) ...[
            if ((consulta?.arquivoPesquisaUrl != null &&
                    consulta!.arquivoPesquisaUrl!.isNotEmpty) ||
                (webhookPdfUrl != null && webhookPdfUrl!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Map<String, dynamic> dadosPesquisa = {};
                    if (consulta?.dadosTratadosJson != null && consulta!.dadosTratadosJson.isNotEmpty) {
                      try {
                        final dec = jsonDecode(consulta!.dadosTratadosJson!);
                        if (dec is Map<String, dynamic>) dadosPesquisa = dec;
                      } catch (_) {}
                    } else if (consulta?.retornoBruto != null && consulta!.retornoBruto.isNotEmpty) {
                      try {
                        final dec = jsonDecode(consulta!.retornoBruto);
                        if (dec is Map<String, dynamic>) dadosPesquisa = dec;
                      } catch (_) {}
                    }
                    if (dadosPesquisa.isEmpty) {
                      dadosPesquisa = {
                        'placa': veiculo.placa,
                        'chassi': veiculo.chassiVeiculo ?? '',
                        'motor': veiculo.motorVeiculo ?? '',
                        'marca': veiculo.marca ?? '',
                        'modelo': veiculo.modelo ?? '',
                        'marcamodelo': '${veiculo.marca ?? ''}/${veiculo.modelo ?? ''}',
                        'anofabricacao': veiculo.anoFabricacao?.toString() ?? '',
                        'anomodelo': veiculo.anoModelo?.toString() ?? '',
                        'cor': veiculo.cor ?? '',
                        'renavam': veiculo.renavam ?? '',
                        'municipio': veiculo.municipio ?? '',
                        'uf': veiculo.uf ?? '',
                      };
                    }
                    await PdfRadarGenerator.visualizarPesquisaPdf(
                      context: context,
                      dadosPesquisa: dadosPesquisa,
                      urlPesquisa: webhookPdfUrl ?? consulta?.arquivoPesquisaUrl,
                      placa: veiculo.placa,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.orange, size: 20),
                  label: const Text('Ver Pesquisa Veicular Original',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: null, // Desabilitado
                  icon: const Icon(Icons.cloud_off_rounded,
                      color: AppTheme.textHint, size: 20),
                  label: const Text('Pesquisa Veicular Sem PDF',
                      style: TextStyle(
                          color: AppTheme.textHint,
                          fontWeight: FontWeight.w600)),
                ),
              )
          ],
        ],
      ),
    );
  }
}
