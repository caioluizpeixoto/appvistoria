import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/speech_recognizer.dart';
import '../../../domain/vistoria_wizard_state.dart';
import '../../../domain/vistoria_type.dart';
import '../../widgets/inspecao_item_widget.dart';

/// Step 11 — Pintura e Lataria
class StepPintura extends StatelessWidget {
  const StepPintura({super.key});

  static const List<String> _pecas = [
    'peca_capo_dianteiro',
    'peca_paralama_dianteiro_esquerdo',
    'peca_porta_dianteira_esquerda',
    'peca_porta_traseira_esquerda',
    'peca_lateral_traseira_esquerda',
    'peca_tampa_traseira',
    'peca_teto',
    'peca_lateral_traseira_direita',
    'peca_porta_traseira_direita',
    'peca_porta_dianteira_direita',
    'peca_paralama_dianteiro_direito',
  ];

  static const Map<String, String> _labels = {
    'peca_capo_dianteiro': 'Capô Dianteiro',
    'peca_paralama_dianteiro_esquerdo': 'Para-lama Dianteiro Esquerdo',
    'peca_porta_dianteira_esquerda': 'Porta Dianteira Esquerda',
    'peca_porta_traseira_esquerda': 'Porta Traseira Esquerda',
    'peca_lateral_traseira_esquerda': 'Lateral Traseira Esquerda',
    'peca_tampa_traseira': 'Capô Traseiro / Porta-malas',
    'peca_teto': 'Teto',
    'peca_lateral_traseira_direita': 'Lateral Traseira Direita',
    'peca_porta_traseira_direita': 'Porta Traseira Direita',
    'peca_porta_dianteira_direita': 'Porta Dianteira Direita',
    'peca_paralama_dianteiro_direito': 'Para-lama Dianteiro Direito',
  };

  static const List<String> _statusOpcoes = [
    'Padrão do fabricante',
    'Repintura',
    'Repintura e/ou massa',
    'Substituído',
    'Envelopado',
    'Danificado',
    'Amassado',
    'Riscado',
  ];

  Color _statusColor(String status) {
    if (status.isEmpty) return AppTheme.naoAplicavel;
    final s = status.toLowerCase();
    if (s.contains('original') || s.contains('padrão') || s.contains('fabricante')) return AppTheme.conforme;
    if (s.contains('substituído') ||
        s.contains('danificado') ||
        s.contains('massa')) return AppTheme.naoConforme;
    if (s.contains('repintura') ||
        s.contains('amassado') ||
        s.contains('riscado') ||
        s.contains('envelopado')) return AppTheme.comObs;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();

    // Resumo de status
    final repinturas = _pecas
        .where((id) => state.getStatus(id).toLowerCase().contains('repintura'))
        .length;
    final originais =
        _pecas.where((id) => state.getStatus(id) == 'Padrão do fabricante' || state.getStatus(id) == 'Pintura original').length;

    final isOpcionalLojista = state.tipoEnum == TipoVistoria.cautelarCarro;
    final deveExibir = state.deveAvaliarPintura;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isOpcionalLojista)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Realizar Avaliação de Pintura e Lataria?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se ativado, as informações preenchidas constarão na seção de pintura no PDF gerado.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: AppTheme.primary,
                  value: state.realizarAvaliacaoPintura,
                  onChanged: (val) {
                    state.setRealizarAvaliacaoPintura(val);
                  },
                )
              ],
            ),
          ),
        if (deveExibir) ...[
          if (isOpcionalLojista) const SizedBox(height: 12),
          // ── Resumo visual ──────────────────────────────────────────────────
          _PinturaResumoCard(
              originais: originais, repinturas: repinturas, total: _pecas.length),
          const SizedBox(height: 12),

          // ── Verificação de Cor e Pintura (Estilo BIN) ─────────────────────
          const _CorVeiculoCard(),
          const SizedBox(height: 8),

          // ── Lista de itens ─────────────────────────────────────────────────
          ..._pecas.map((id) => InspecaoItemWidget(
                itemId: id,
                label: _labels[id]!,
                statusOptions: _statusOpcoes,
                obrigatoria: false,
              )),
          const SizedBox(height: 24),

          // ── Visualização 3D por IA ─────────────────────────────────────────
          _AiImagePreview(
            marca: state.marca,
            modelo: state.modelo,
            ano: state.anoModelo.isNotEmpty
                ? state.anoModelo
                : state.anoFabricacao,
            pecas: _pecas,
            statusFn: state.getStatus,
            initialBase64: state.aiImage3dBase64,
            isGenerating: state.isGeneratingAiImage,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _PinturaResumoCard extends StatelessWidget {
  final int originais;
  final int repinturas;
  final int total;
  const _PinturaResumoCard(
      {required this.originais, required this.repinturas, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_paint_rounded,
              color: AppTheme.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Análise de Pintura e Lataria',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '$originais originais · $repinturas repinturas · ${total - originais - repinturas} outros',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagrama simplificado de pintura (grid visual)
class _DiagramaPintura extends StatelessWidget {
  final List<String> pecas;
  final Map<String, String> labels;
  final String Function(String) statusFn;
  final Color Function(String) colorFn;

  const _DiagramaPintura({
    required this.pecas,
    required this.labels,
    required this.statusFn,
    required this.colorFn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text('Mapa de Pintura',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pecas.map((id) {
              final status = statusFn(id);
              final color = colorFn(status);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  labels[id]!
                      .replaceAll('Para-lama', 'P-lama')
                      .replaceAll('Dianteiro', 'Diant.')
                      .replaceAll('Traseiro', 'Tras.')
                      .replaceAll(' Direito', ' D.')
                      .replaceAll(' Esquerdo', ' E.'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: status.isEmpty ? AppTheme.textHint : color,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legenda(color: AppTheme.conforme, label: 'Original'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.comObs, label: 'Repintura'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.naoConforme, label: 'Danificado'),
              const SizedBox(width: 10),
              _Legenda(color: AppTheme.naoAplicavel, label: 'N/A'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Legenda({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _AiImagePreview extends StatefulWidget {
  final String marca;
  final String modelo;
  final String ano;
  final List<String> pecas;
  final String Function(String) statusFn;
  final String? initialBase64;
  final bool isGenerating;

  const _AiImagePreview({
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.pecas,
    required this.statusFn,
    this.initialBase64,
    required this.isGenerating,
  });

  @override
  State<_AiImagePreview> createState() => _AiImagePreviewState();
}

class _AiImagePreviewState extends State<_AiImagePreview> {
  String? _base64Image;
  String? _errorMessage;
  final TextEditingController _customInstructionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _base64Image = widget.initialBase64;
  }

  @override
  void dispose() {
    _customInstructionController.dispose();
    super.dispose();
  }

  static const Map<String, String> _partToEnglish = {
    'peca_capo_dianteiro': 'front hood',
    'peca_paralama_dianteiro_esquerdo': 'front left (driver side) fender',
    'peca_porta_dianteira_esquerda': 'front left (driver side) door',
    'peca_porta_traseira_esquerda': 'rear left (driver side) door',
    'peca_lateral_traseira_esquerda': 'rear left (driver side) quarter panel',
    'peca_tampa_traseira': 'rear trunk / tailgate',
    'peca_teto': 'roof',
    'peca_lateral_traseira_direita':
        'rear right (passenger side) quarter panel',
    'peca_porta_traseira_direita': 'rear right (passenger side) door',
    'peca_porta_dianteira_direita': 'front right (passenger side) door',
    'peca_paralama_dianteiro_direito': 'front right (passenger side) fender',
  };

  Future<void> _gerarImagem() async {
    final wizardState = context.read<VistoriaWizardState>();

    // Check if already generating to prevent double calls
    if (wizardState.isGeneratingAiImage) return;

    wizardState.setGeneratingAiImage(true);

    setState(() {
      _errorMessage = null;
    });

    try {
      final List<Map<String, String>> partsToColor = [];
      for (final pecaId in widget.pecas) {
        final status = widget.statusFn(pecaId).toLowerCase();
        String? color;
        if (status.contains('substituído') ||
            status.contains('danificado') ||
            status.contains('massa')) {
          color = 'red';
        } else if (status.contains('repintura') ||
            status.contains('amassado') ||
            status.contains('riscado') ||
            status.contains('envelopado')) {
          color = 'yellow';
        }

        if (color != null && _partToEnglish.containsKey(pecaId)) {
          partsToColor.add({
            'part': _partToEnglish[pecaId]!,
            'color': color,
          });
        }
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 120),
          receiveTimeout:
              const Duration(seconds: 300), // Aumentado para 5 minutos
          sendTimeout: const Duration(seconds: 120),
        ),
      );
      final url =
          'https://cmcpmppgpbrufrxznost.supabase.co/functions/v1/gerar-imagem-veiculo';
      final apiKey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq';

      final customInstruction = _customInstructionController.text.trim();

      final response = await dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'apikey': apiKey,
          },
        ),
        data: {
          'brand': widget.marca.isNotEmpty ? widget.marca : 'Jeep',
          'model': widget.modelo.isNotEmpty ? widget.modelo : 'Compass',
          'year': widget.ano.isNotEmpty ? widget.ano : '2022',
          'parts': partsToColor,
          if (customInstruction.isNotEmpty)
            'customInstruction': customInstruction,
        },
      );

      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }

      if (response.statusCode == 200 &&
          responseData != null &&
          responseData is Map &&
          responseData['base64'] != null) {
        var b64 = responseData['base64'] as String;

        // Limpar prefixo data URI se existir
        if (b64.contains(',')) {
          b64 = b64.split(',').last;
        }
        // Remover espaços em branco ou quebras de linha
        b64 = b64.replaceAll(RegExp(r'\s+'), '');
        // Adicionar padding necessário para o Dart base64Decode
        while (b64.length % 4 != 0) {
          b64 += '=';
        }

        wizardState.aiImage3dBase64 = b64;

        if (mounted) {
          setState(() {
            _base64Image = b64;
          });
        }
      } else {
        var rawErr = response.data.toString();
        if (rawErr.length > 500) {
          rawErr = rawErr.substring(0, 500) + '...';
        }
        final isHtml = rawErr.contains('<html>') || rawErr.contains('502');
        if (mounted) {
          setState(() {
            _errorMessage = isHtml
                ? 'Tempo limite esgotado no servidor. Clique em "Regerar com Ajustes" para tentar novamente.'
                : 'Erro ao gerar imagem: $rawErr';
          });
        }
      }
    } on DioException catch (e) {
      var rawErr = e.response?.data?.toString() ?? e.message ?? '';
      if (rawErr.length > 500) {
        rawErr = rawErr.substring(0, 500) + '...';
      }
      final isHtml = rawErr.contains('<html>') || rawErr.contains('502');
      if (mounted) {
        setState(() {
          _errorMessage = isHtml
              ? 'Tempo limite esgotado no servidor (502). Clique em "Regerar com Ajustes" para tentar novamente.'
              : 'Erro do Servidor: $rawErr';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha: $e';
        });
      }
    } finally {
      // Must read context again or use the reference we captured
      wizardState.setGeneratingAiImage(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Ilustração 3D Técnica (IA)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gera o modelo 3D oficial do veículo com o mapa de lataria e pintura para ser exibido no laudo PDF.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_base64Image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(_base64Image!),
                fit: BoxFit.cover,
              ),
            ),
          if (widget.isGenerating)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: AppTheme.naoConforme)),
            ),
          if (_base64Image != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customInstructionController,
              decoration: InputDecoration(
                labelText: 'Ajuste / Correção para a IA (Opcional)',
                hintText:
                    'Ex: "destacar mais a repintura amarela do capô", "deixar a roda original"',
                prefixIcon: const Icon(Icons.edit_note_rounded,
                    color: AppTheme.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isGenerating ? null : () {
                    setState(() {
                      _base64Image = null;
                      _errorMessage = null;
                    });
                    context.read<VistoriaWizardState>().aiImage3dBase64 = null;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Uso de Imagem 2D confirmado. Pode prosseguir no botão ao final da página.'),
                        backgroundColor: AppTheme.conforme,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Usar 2D Padrão', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isGenerating ? null : _gerarImagem,
                  icon: Icon(_base64Image == null
                      ? Icons.auto_awesome
                      : Icons.refresh_rounded),
                  label: Text(
                    _base64Image == null ? 'Gerar 3D (IA)' : 'Regerar 3D (IA)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de verificação de cor e pintura estilo BIN (sem foto, com observações e campo editável)
class _CorVeiculoCard extends StatefulWidget {
  const _CorVeiculoCard();

  @override
  State<_CorVeiculoCard> createState() => _CorVeiculoCardState();
}

class _CorVeiculoCardState extends State<_CorVeiculoCard> {
  final _corCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<VistoriaWizardState>();
      final corAtual = state.getCodigo('cor_veiculo').isNotEmpty
          ? state.getCodigo('cor_veiculo')
          : state.cor;
      _corCtrl.text = corAtual;
      if (corAtual.isEmpty) {
        _isEditing = true;
      }
      _obsCtrl.text = state.getObs('cor_veiculo');
      final savedStatus = state.getStatus('cor_veiculo');
      if (savedStatus.isEmpty ||
          !const [
            'Pintura original',
            'Veículo com envelopamento',
            'Cor divergente do documento',
            'Fantasia',
          ].contains(savedStatus)) {
        state.setStatus('cor_veiculo', 'Pintura original');
      }
    });
  }

  @override
  void dispose() {
    _corCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _onMicLongPress() async {
    setState(() => _isListening = true);
    await SpeechRecognizer.startListening();
  }

  void _onMicLongPressEnd(LongPressEndDetails details) async {
    setState(() => _isListening = false);
    String rawText = await SpeechRecognizer.stopListening();
    if (rawText.isNotEmpty) {
      final currentText = _obsCtrl.text;
      final newText = currentText.isEmpty ? rawText : '$currentText $rawText';
      _obsCtrl.text = newText;
      if (mounted) {
        context.read<VistoriaWizardState>().setObs('cor_veiculo', newText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final corDoc = state.corBin.isNotEmpty
        ? state.corBin
        : (state.cor.isNotEmpty ? state.cor : '');
    final statusAtual = state.getStatus('cor_veiculo');
    final corConstatada = _corCtrl.text.trim();
    final isDivergente = corDoc.isNotEmpty &&
        corConstatada.isNotEmpty &&
        corDoc.trim().toUpperCase() != corConstatada.toUpperCase();

    final opcoesStatus = const [
      'Pintura original',
      'Veículo com envelopamento',
      'Cor divergente do documento',
      'Fantasia',
    ];

    final statusValido = opcoesStatus.contains(statusAtual)
        ? statusAtual
        : 'Pintura original';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDivergente
              ? AppTheme.naoConforme.withValues(alpha: 0.5)
              : AppTheme.border,
          width: isDivergente ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.palette_rounded,
                    color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cor do Veículo e Pintura Geral',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isDivergente)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.naoConformeLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.naoConforme.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.naoConforme, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Divergente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.naoConforme,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Info BIN / Documento
          if (corDoc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cor no Documento / BIN: $corDoc',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Campo editável de cor constatada
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextFormField(
              controller: _corCtrl,
              readOnly: !_isEditing,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                fontSize: 15,
                color: !_isEditing
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontWeight:
                    !_isEditing ? FontWeight.w600 : FontWeight.normal,
              ),
              decoration: InputDecoration(
                labelText: 'Cor constatada no veículo',
                hintText: 'Ex: BRANCA, AZUL, PRATA...',
                filled: !_isEditing,
                fillColor: !_isEditing
                    ? AppTheme.surfaceVariant
                    : AppTheme.surface,
                prefixIcon: Icon(
                  Icons.color_lens_rounded,
                  size: 20,
                  color:
                      !_isEditing ? AppTheme.textSecondary : AppTheme.primary,
                ),
                suffixIcon: !_isEditing
                    ? IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            size: 20, color: AppTheme.primary),
                        tooltip: 'Editar cor constatada',
                        onPressed: () => setState(() => _isEditing = true),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) {
                state.cor = v;
                state.setCodigo('cor_veiculo', v);
                if (isDivergente && (statusAtual == 'Pintura original' || statusAtual.isEmpty)) {
                  state.setStatus('cor_veiculo', 'Cor divergente do documento');
                }
              },
            ),
          ),

          // Status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: DropdownButtonFormField<String>(
              value: statusValido,
              decoration: const InputDecoration(
                labelText: 'Status da Cor / Pintura',
                prefixIcon: Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: AppTheme.primary),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: opcoesStatus.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) state.setStatus('cor_veiculo', v);
              },
            ),
          ),

          // Observação
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextFormField(
              controller: _obsCtrl,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Observação da Pintura / Cor (opcional)',
                hintText:
                    'Descreva detalhes da pintura ou divergências...',
                prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                suffixIcon: GestureDetector(
                  onLongPress: _onMicLongPress,
                  onLongPressEnd: _onMicLongPressEnd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      color: _isListening
                          ? Colors.red
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => state.setObs('cor_veiculo', v),
            ),
          ),
        ],
      ),
    );
  }
}

