import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../data/services/radar_service.dart';
import '../../domain/entities/radar_historico.dart';

class HistoricoConsultasScreen extends StatefulWidget {
  const HistoricoConsultasScreen({super.key});

  @override
  State<HistoricoConsultasScreen> createState() => _HistoricoConsultasScreenState();
}

class _HistoricoConsultasScreenState extends State<HistoricoConsultasScreen> {
  List<RadarHistorico> _historico = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final data = await sl<RadarService>().getHistorico();
      if (mounted) {
        setState(() {
          _historico = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  void _retificarConsulta(RadarHistorico item) {
    if (!item.permiteRetificacao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prazo de 72h expirado. É necessário realizar nova consulta.'),
          backgroundColor: AppTheme.naoConforme,
        ),
      );
      return;
    }

    // Passamos os dadosTratados como 'extra' para a rota de Identificacao
    context.push('/identificacao/cautelar-carro', extra: item.dadosTratados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pesquisas Realizadas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historico.isEmpty
              ? const Center(child: Text('Nenhuma pesquisa encontrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historico.length,
                  itemBuilder: (context, index) {
                    final item = _historico[index];
                    final formatador = DateFormat('dd/MM/yyyy HH:mm');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.surfaceVariant),
                      ),
                      elevation: 0,
                      color: AppTheme.surface,
                      child: InkWell(
                        onTap: () => _retificarConsulta(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.placa?.isNotEmpty == true ? item.placa! : (item.chassi ?? 'Sem Placa/Chassi'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.permiteRetificacao ? AppTheme.conformeLight : AppTheme.naoConformeLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.permiteRetificacao ? 'No Prazo (72h)' : 'Expirado',
                                      style: TextStyle(
                                        color: item.permiteRetificacao ? AppTheme.conforme : AppTheme.naoConforme,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cód: ${item.codigoConsulta} • ${formatador.format(item.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (item.permiteRetificacao) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: const [
                                    Icon(Icons.edit_document, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Retificar / Continuar Vistoria',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.arquivoPesquisaUrl != null && item.arquivoPesquisaUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri.parse(item.arquivoPesquisaUrl!);
                                    try {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
                                      }
                                    }
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppTheme.conforme),
                                      SizedBox(width: 6),
                                      Text(
                                        'Ver Relatório Radar Consultas',
                                        style: TextStyle(
                                          color: AppTheme.conforme,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
