import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../consulta_bin/data/services/radar_service.dart';
import '../../../../core/services/pdf_radar_generator.dart';

class HistoricoRadarScreen extends StatefulWidget {
  const HistoricoRadarScreen({Key? key}) : super(key: key);

  @override
  State<HistoricoRadarScreen> createState() => _HistoricoRadarScreenState();
}

class _HistoricoRadarScreenState extends State<HistoricoRadarScreen> {
  final RadarService _radarService = sl<RadarService>();
  bool _isLoading = true;
  String? _tokenEmDownload;
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
      if (mounted) {
        setState(() {
          _consultas = consultas;
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

  Future<void> _baixarEVisualizar(Map<String, dynamic> consulta) async {
    final token = consulta['token']?.toString();
    if (token == null || token.isEmpty) return;

    final paramValor = consulta['parametro_valor']?.toString() ?? '';
    final param = consulta['parametro']?.toString() ?? 'placa';
    final titulo = consulta['titulo']?.toString() ?? '';

    String produto = 'auto_bin';
    if (param.toLowerCase() == 'motor' ||
        titulo.toLowerCase().contains('motor')) {
      produto = 'bin_por_motor';
    } else if (titulo.toLowerCase().contains('crv')) {
      produto = 'numero_crv';
    } else if (titulo.toLowerCase().contains('perícia') ||
        titulo.toLowerCase().contains('pericia')) {
      produto = 'auto_pericia_hrf';
    }

    setState(() => _tokenEmDownload = token);

    try {
      final veiculo = await _radarService.consultarVeiculo(
        produto: produto,
        param: param,
        value: paramValor,
        vistoriaId: '',
        forcarNova: false,
        tokenConsulta: token,
      );

      if (mounted) {
        setState(() => _tokenEmDownload = null);
        final bool isMotor = param.toLowerCase() == 'motor';
        final urlView = isMotor
            ? (veiculo.arquivoPesquisaUrl ??
                consulta['view']?['full']?.toString() ??
                consulta['arquivo_pesquisa_url']?.toString())
            : (consulta['view']?['full']?.toString() ??
                veiculo.arquivoPesquisaUrl ??
                consulta['arquivo_pesquisa_url']?.toString());

        await PdfRadarGenerator.visualizarPesquisaPdf(
          context: context,
          dadosPesquisa: veiculo.resultadoCompleto,
          urlPesquisa: urlView,
          placa: veiculo.placa,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _tokenEmDownload = null);
        final msg = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: msg.contains('análise técnica') ||
                    msg.contains('em andamento') ||
                    msg.contains('processamento')
                ? const Color(0xFFD97706)
                : AppTheme.naoConforme,
          ),
        );
      }
    }
  }

  Widget _buildBadge(dynamic statusRaw) {
    final status = statusRaw?.toString();
    final bool isConcluida = status == '1';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isConcluida
            ? AppTheme.conforme.withValues(alpha: 0.12)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isConcluida
              ? AppTheme.conforme.withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isConcluida ? 'CONCLUÍDA' : 'EM ANDAMENTO',
        style: TextStyle(
          color: isConcluida ? AppTheme.conforme : const Color(0xFFB45309),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Consultas'),
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
              ? const Center(child: Text('Nenhuma consulta veicular encontrada.'))
              : ListView.builder(
                  itemCount: _consultas.length,
                  itemBuilder: (context, index) {
                    final c = _consultas[index] as Map<String, dynamic>;
                    final token = c['token']?.toString();
                    final isDownloading = _tokenEmDownload == token;
                    final dataString = c['ctime'] ?? c['data_hora'];
                    DateTime? data;
                    if (dataString != null) {
                      data = DateTime.tryParse(dataString.toString());
                      if (data != null) {
                        final str = dataString.toString().toUpperCase();
                        if (!str.endsWith('Z') && !str.contains('+') && !str.contains('-')) {
                           data = DateTime.utc(data.year, data.month, data.day, data.hour, data.minute, data.second);
                        }
                        data = data.toLocal();
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.surfaceVariant),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history,
                              color: AppTheme.primary),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c['parametro']}: ${c['parametro_valor']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _buildBadge(c['status']),
                          ],
                        ),
                        subtitle: Text(
                          '${c['titulo']} - ' +
                              (data != null
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(data)
                                  : ''),
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: isDownloading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.download,
                                    color: AppTheme.primary),
                                tooltip: 'Visualizar / Baixar Relatório',
                                onPressed: () => _baixarEVisualizar(c),
                              ),
                        onTap: isDownloading ? null : () => _baixarEVisualizar(c),
                      ),
                    );
                  },
                ),
    );
  }
}
