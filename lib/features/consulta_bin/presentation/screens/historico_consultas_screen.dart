import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../data/services/radar_service.dart';
import '../../domain/entities/radar_historico.dart';
import '../../../../core/services/pdf_radar_generator.dart';
import 'dart:convert';

class HistoricoConsultasScreen extends StatefulWidget {
  const HistoricoConsultasScreen({super.key});

  @override
  State<HistoricoConsultasScreen> createState() =>
      _HistoricoConsultasScreenState();
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

  Future<void> _verificarOuRetificar(RadarHistorico item) async {
    final hasDados = (item.placa != null && item.placa!.isNotEmpty) ||
        (item.chassi != null && item.chassi!.isNotEmpty);
    final isPendente = item.status == 'pendente' || !hasDados;

    if (isPendente) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Checando status na Radar...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final service = sl<RadarService>();
        final tokenParaConsultar = item.tokenRadarOficial;
        final veiculo = await service.consultarVeiculo(
          produto: item.motor != null && item.motor!.isNotEmpty
              ? 'bin_por_motor'
              : 'auto_bin',
          param: item.motor != null && item.motor!.isNotEmpty
              ? 'motor'
              : (item.placa != null && item.placa!.isNotEmpty
                  ? 'placa'
                  : 'chassi'),
          value: item.motor ?? item.placa ?? item.chassi ?? '',
          tokenConsulta: tokenParaConsultar,
        );

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // fecha dialog
          await _carregarHistorico();
          context.push('/identificacao/cautelar-carro',
              extra: veiculo.resultadoCompleto);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          final erroMsg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(erroMsg),
              backgroundColor: erroMsg.contains('análise técnica')
                  ? const Color(0xFFD97706)
                  : AppTheme.naoConforme,
            ),
          );
        }
      }
    } else {
      context.push('/identificacao/cautelar-carro', extra: item.dadosTratados);
    }
  }

  Widget _buildStatusBadge(String status, bool hasDados) {
    if (status == 'pendente' || !hasDados) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD97706),
              ),
            ),
            SizedBox(width: 5),
            Text(
              'EM ANDAMENTO',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'erro') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.naoConformeLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'ERRO',
          style: TextStyle(
            color: AppTheme.naoConforme,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.conformeLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'CONCLUÍDA',
        style: TextStyle(
          color: AppTheme.conforme,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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

                    final hasDados =
                        (item.placa != null && item.placa!.isNotEmpty) ||
                            (item.chassi != null && item.chassi!.isNotEmpty);
                    final isPendente = item.status == 'pendente' || !hasDados;

                    final String tituloCard;
                    if (item.placa?.isNotEmpty == true) {
                      tituloCard = item.placa!;
                    } else if (item.motor?.isNotEmpty == true) {
                      tituloCard = 'MOTOR: ${item.motor}';
                    } else if (item.chassi?.isNotEmpty == true) {
                      tituloCard = item.chassi!;
                    } else {
                      tituloCard = item.codigoConsulta > 0
                          ? 'Consulta #${item.codigoConsulta}'
                          : 'Pesquisa Realizada';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.surfaceVariant),
                      ),
                      elevation: 0,
                      color: AppTheme.surface,
                      child: InkWell(
                        onTap: () => _verificarOuRetificar(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tituloCard,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(item.status, hasDados),
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
                              const SizedBox(height: 12),
                              if (isPendente) ...[
                                Row(
                                  children: const [
                                    Icon(Icons.refresh_rounded,
                                        size: 16, color: Color(0xFFD97706)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Verificar Status / Puxar Veículo',
                                      style: TextStyle(
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: const [
                                    Icon(Icons.edit_document,
                                        size: 16, color: AppTheme.primary),
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
                              if (item.arquivoPesquisaUrl != null &&
                                  item.arquivoPesquisaUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () async {
                                    Map<String, dynamic> dados = {};
                                    if (item.dadosTratados.isNotEmpty) {
                                      dados = item.dadosTratados;
                                    } else if (item.retornoBruto != null &&
                                        item.retornoBruto!.isNotEmpty) {
                                      try {
                                        final dec =
                                            jsonDecode(item.retornoBruto!);
                                        if (dec is Map<String, dynamic>) {
                                          dados = dec;
                                        }
                                      } catch (_) {}
                                    }
                                    if (dados.isEmpty) {
                                      dados = {
                                        'placa': item.placa ?? '',
                                        'chassi': item.chassi ?? '',
                                        'motor': item.motor ?? '',
                                      };
                                    }
                                    await PdfRadarGenerator.visualizarPesquisaPdf(
                                      context: context,
                                      dadosPesquisa: dados,
                                      urlPesquisa: item.arquivoPesquisaUrl,
                                      placa: item.placa,
                                    );
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(Icons.picture_as_pdf_rounded,
                                          size: 16, color: AppTheme.conforme),
                                      SizedBox(width: 6),
                                      Text(
                                        'Ver Relatório da Pesquisa Veicular',
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
