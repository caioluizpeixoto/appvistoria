import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../consulta_bin/data/services/radar_service.dart';

import 'package:url_launcher/url_launcher.dart';

class HistoricoRadarScreen extends StatefulWidget {
  const HistoricoRadarScreen({Key? key}) : super(key: key);

  @override
  State<HistoricoRadarScreen> createState() => _HistoricoRadarScreenState();
}

class _HistoricoRadarScreenState extends State<HistoricoRadarScreen> {
  final RadarService _radarService = sl<RadarService>();
  bool _isLoading = true;
  List<dynamic> _consultas = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final consultas = await _radarService.listarConsultasRadar();
      setState(() {
        _consultas = consultas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  Future<void> _baixarEVisualizar(Map<String, dynamic> consulta) async {
    final token = consulta['token'];

    if (token == null) return;

    // Se tiver o link de visualização, abre direto
    if (consulta['view'] != null && consulta['view']['full'] != null) {
      final url = Uri.parse(consulta['view']['full']);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Não foi possível abrir o link da consulta: $e')),
          );
        }
      }
    }

    // Aproveita para baixar e fazer cache em background silenciosamente
    try {
      await _radarService.consultarVeiculo(
        produto: 'auto_bin',
        param: 'placa',
        value: consulta['parametro_valor'] ?? '',
        vistoriaId: '',
        forcarNova: true,
        tokenConsulta: token,
      );
    } catch (_) {
      // Falha silenciosa no background
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Global Radar'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultas.isEmpty
              ? const Center(
                  child:
                      Text('Nenhuma consulta encontrada na sua conta Radar.'))
              : ListView.builder(
                  itemCount: _consultas.length,
                  itemBuilder: (context, index) {
                    final c = _consultas[index];
                    final dataString = c['ctime'] ?? c['data_hora'];
                    DateTime? data;
                    if (dataString != null) {
                      data = DateTime.tryParse(dataString.toString());
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history,
                              color: AppTheme.primary),
                        ),
                        title:
                            Text('${c['parametro']}: ${c['parametro_valor']}'),
                        subtitle: Text(
                          '${c['titulo']} - ' +
                              (data != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(data)
                                  : ''),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download,
                              color: AppTheme.primary),
                          tooltip: 'Baixar Consulta',
                          onPressed: () =>
                              _baixarEVisualizar(c as Map<String, dynamic>),
                        ),
                        onTap: () =>
                            _baixarEVisualizar(c as Map<String, dynamic>),
                      ),
                    );
                  },
                ),
    );
  }
}
