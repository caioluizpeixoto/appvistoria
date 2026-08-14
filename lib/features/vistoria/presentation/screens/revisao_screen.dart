import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/consulta_bin/data/repositories/radar_repository.dart';
import '../../../../features/consulta_bin/domain/entities/radar_veiculo.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../injection_container.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';
import '../../../../core/utils/veiculo_parser.dart';
import '../../domain/vistoria_wizard_state.dart';

class RevisaoScreen extends StatefulWidget {
  final String vistoriaId;
  const RevisaoScreen({super.key, required this.vistoriaId});

  @override
  State<RevisaoScreen> createState() => _RevisaoScreenState();
}

class _RevisaoScreenState extends State<RevisaoScreen> {
  final _dao = sl<VistoriaDao>();
  bool _gerandoPdf = false;
  bool _verificandoRadar = false;
  bool _pesquisaPendente = false;
  VistoriaWizardState? _state;
  Vistoria? _vistoria;
  Veiculo? _veiculo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final v = await _dao.buscarPorId(widget.vistoriaId);
    final veiculo = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
    if (mounted) {
      setState(() {
        _vistoria = v;
        _veiculo = veiculo;
      });
      if (v?.tipoVistoria == 'Cautelar' && veiculo != null) {
        _verificarStatusRadar(veiculo.placa);
      }
    }
  }

  Future<void> _verificarStatusRadar(String placa) async {
    setState(() => _verificandoRadar = true);
    try {
      final repo = sl<RadarRepository>();
      final pendente = await repo.existeConsultaPendente('placa', placa);
      if (mounted) {
        setState(() {
          _pesquisaPendente = pendente;
          _verificandoRadar = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verificandoRadar = false);
    }
  }

  Future<void> _atualizarRadar() async {
    if (_veiculo == null) return;
    setState(() => _verificandoRadar = true);
    
    try {
      final repo = sl<RadarRepository>();
      final pendente = await repo.existeConsultaPendente('placa', _veiculo!.placa);
      
      if (!pendente) {
        // Tenta puxar da nuvem e atualizar o local
        final nuvem = await repo.buscarConsultasRecentesNuvem('placa', _veiculo!.placa);
        if (nuvem.isNotEmpty) {
          try {
            final radarData = RadarVeiculo.fromJson(nuvem.first['dados_tratados']);
            final mm = VeiculoParser.extrairMarcaModelo(radarData.marcaModelo);
            final marca = mm.marca;
            final modelo = mm.modelo;
            
            await _dao.atualizarVeiculo(VeiculosCompanion(
              id: drift.Value(_veiculo!.id),
              vistoriaId: drift.Value(_veiculo!.vistoriaId),
              placa: drift.Value(radarData.placa.isNotEmpty ? radarData.placa : _veiculo!.placa),
              chassiVeiculo: drift.Value(radarData.chassi.isNotEmpty ? radarData.chassi : _veiculo!.chassiVeiculo),
              motorVeiculo: drift.Value(radarData.motor.isNotEmpty ? radarData.motor : _veiculo!.motorVeiculo),
              marca: drift.Value(marca.isNotEmpty ? marca : _veiculo!.marca),
              modelo: drift.Value(modelo.isNotEmpty ? modelo : _veiculo!.modelo),
              anoFabricacao: drift.Value(int.tryParse(radarData.anoFabricacao) ?? _veiculo!.anoFabricacao),
              anoModelo: drift.Value(int.tryParse(radarData.anoModelo) ?? _veiculo!.anoModelo),
              cor: drift.Value(radarData.cor.isNotEmpty ? radarData.cor : _veiculo!.cor),
              renavam: drift.Value(radarData.renavam.isNotEmpty ? radarData.renavam : _veiculo!.renavam),
              chassiBin: drift.Value(radarData.chassi.isNotEmpty ? radarData.chassi : _veiculo!.chassiBin),
              motorBin: drift.Value(radarData.motor.isNotEmpty ? radarData.motor : _veiculo!.motorBin),
              municipio: drift.Value(radarData.municipio.isNotEmpty ? radarData.municipio : _veiculo!.municipio),
              uf: drift.Value(radarData.estado.isNotEmpty ? radarData.estado : _veiculo!.uf),
            ));
            
            // Recarrega os dados
            final v = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
            if (mounted) {
              setState(() {
                _veiculo = v;
                _pesquisaPendente = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesquisa concluída e dados atualizados!'), backgroundColor: AppTheme.conforme)
              );
            }
          } catch (_) {}
        } else {
          if (mounted) setState(() => _pesquisaPendente = false);
        }
      } else {
        if (mounted) {
          setState(() => _pesquisaPendente = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A pesquisa ainda está em andamento. Aguarde mais um pouco.'), backgroundColor: AppTheme.comObs)
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _verificandoRadar = false);
    }
  }

  Future<void> _gerarPdf() async {
    if (_state == null) return;
    final state = _state!;

    final faltando = state.fotasObrigatoriasFaltando;
    // TEMPORÁRIO: Ignora a falta de fotos obrigatórias para testes
    if (false && faltando.isNotEmpty) {
      _showBloqueio(faltando);
      return;
    }

    setState(() => _gerandoPdf = true);
    try {
      final pdfService = sl<PdfGeneratorService>();
      if (_vistoria != null && _veiculo != null) {
        final pdfPath = await pdfService.generateLaudoCompleto(
          vistoria: _vistoria!,
          veiculo: _veiculo!,
          wizardState: state,
        );

        if (mounted && pdfPath != null) {
          // Atualiza status para concluído e salva o PDF
          await _dao.atualizarConclusao(
            id: widget.vistoriaId,
            statusFinal: state.resultadoFinal,
            parecerTecnico: state.parecerTecnico,
            assinaturaPath: state.assinaturaPath,
            assinaturaClientePath: state.assinaturaClientePath,
            vistoriadorNome: state.vistoriadorNome,
            vistoriadorCpf: state.vistoriadorCpf,
            pdfUrl: pdfPath,
          );

          context.push('/pdf-preview/${widget.vistoriaId}?path=$pdfPath');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  void _showBloqueio(List<String> faltando) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: AppTheme.naoConforme),
            SizedBox(width: 8),
            Text('Não é possível gerar o laudo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fotos obrigatórias faltando:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...faltando.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_camera_rounded,
                          size: 14, color: AppTheme.naoConforme),
                      const SizedBox(width: 6),
                      Text(f.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar e corrigir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tenta obter state da rota
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _state = extra?['wizardState'] as VistoriaWizardState?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Revisão Final'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _vistoria == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status geral ────────────────────────────────────────
                  _StatusCard(state: _state),

                  const SizedBox(height: 16),

                  // ── Dados do veículo ────────────────────────────────────
                  if (_veiculo != null) _VeiculoCard(veiculo: _veiculo!),

                  const SizedBox(height: 16),

                  // ── Checklist de fotos ──────────────────────────────────
                  if (_state != null && _state!.fotosObrigatorias.isNotEmpty)
                    _FotosChecklist(state: _state!),

                  const SizedBox(height: 16),

                  // ── Itens com divergência ───────────────────────────────
                  if (_state != null && _state!.itensDivergentes.isNotEmpty)
                    _DivergenciasCard(divergentes: _state!.itensDivergentes),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: (_vistoria?.tipoVistoria == 'Cautelar' && _pesquisaPendente)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.comObs.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.comObs.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: AppTheme.comObs),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesquisa ainda em andamento. Aguarde a conclusão para gerar o Laudo.',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _verificandoRadar ? null : _atualizarRadar,
                    icon: _verificandoRadar
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(_verificandoRadar ? 'Atualizando...' : 'Atualizar Resultado', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.conforme,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _gerandoPdf ? null : _gerarPdf,
          icon: _gerandoPdf
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_rounded, size: 22),
          label: Text(
            _gerandoPdf ? 'Gerando PDF...' : 'Gerar Laudo em PDF',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final VistoriaWizardState? state;
  const _StatusCard({this.state});

  @override
  Widget build(BuildContext context) {
    final statusFinal = (state != null && state!.resultadoFinal.isNotEmpty)
        ? state!.resultadoFinal
        : (state?.statusSugerido ?? 'Em andamento');
    final totalFotos = state?.totalFotos ?? 0;

    Color statusColor;
    switch (statusFinal) {
      case 'Conforme':
        statusColor = AppTheme.conforme;
        break;
      case 'Conforme com observações':
        statusColor = AppTheme.comObs;
        break;
      case 'Reprovado':
        statusColor = AppTheme.naoConforme;
        break;
      default:
        statusColor = AppTheme.emAndamento;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resultado Final do Laudo',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            statusFinal.toUpperCase(),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                  icon: Icons.photo_camera_rounded, label: '$totalFotos fotos'),
              const SizedBox(width: 8),
              _StatChip(
                  icon: Icons.warning_rounded,
                  label: '${state?.itensDivergentes.length ?? 0} divergências'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _VeiculoCard extends StatelessWidget {
  final Veiculo veiculo;
  const _VeiculoCard({required this.veiculo});

  bool _hasVal(String? val) =>
      val != null && val.trim().isNotEmpty && val.trim() != '-';

  @override
  Widget build(BuildContext context) {
    final marcaModelo =
        '${veiculo.marca ?? ''} ${veiculo.modelo ?? ''}'.trim();

    return _Card(
      title: 'Dados do Veículo',
      icon: Icons.directions_car_rounded,
      children: [
        if (_hasVal(veiculo.placa)) _Row('Placa', veiculo.placa),
        if (_hasVal(marcaModelo)) _Row('Marca/Modelo', marcaModelo),
        if (_hasVal(veiculo.chassiVeiculo))
          _Row('Chassi no Veículo', veiculo.chassiVeiculo!),
        if (_hasVal(veiculo.chassiBin))
          _Row('Chassi na BIN', veiculo.chassiBin!),
        if (_hasVal(veiculo.motorVeiculo))
          _Row('Motor no Veículo', veiculo.motorVeiculo!),
        if (_hasVal(veiculo.motorBin)) _Row('Motor na BIN', veiculo.motorBin!),
        if (_hasVal(veiculo.km?.toString()))
          _Row('KM', veiculo.km!.toString()),
      ],
    );
  }
}

class _FotosChecklist extends StatelessWidget {
  final VistoriaWizardState state;
  const _FotosChecklist({required this.state});
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Fotos Obrigatórias',
      icon: Icons.camera_alt_rounded,
      children: state.fotosObrigatorias.map((id) {
        final has = state.hasFoto(id);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                has
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: has ? AppTheme.conforme : AppTheme.naoConforme,
              ),
              const SizedBox(width: 10),
              Text(
                id.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: has ? AppTheme.textPrimary : AppTheme.naoConforme,
                  fontWeight: has ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DivergenciasCard extends StatelessWidget {
  final List<String> divergentes;
  const _DivergenciasCard({required this.divergentes});
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: '⚠️ Divergências Encontradas',
      icon: Icons.warning_rounded,
      color: AppTheme.naoConforme,
      children: divergentes
          .map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${d.replaceAll('_', ' ')}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.naoConforme),
                ),
              ))
          .toList(),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final List<Widget> children;
  const _Card(
      {required this.title,
      required this.icon,
      this.color,
      required this.children});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: c)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
