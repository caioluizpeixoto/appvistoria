import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../database/app_database.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../widgets/photo_capture_widget.dart';
import 'package:drift/drift.dart' as drift;

class InspecaoScreen extends StatefulWidget {
  final String vistoriaId;
  const InspecaoScreen({super.key, required this.vistoriaId});

  @override
  State<InspecaoScreen> createState() => _InspecaoScreenState();
}

class _InspecaoScreenState extends State<InspecaoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dao = sl<VistoriaDao>();
  final _ocrService = sl<OcrService>();
  final _imageService = sl<ImageService>();

  Veiculo? _veiculo;
  Map<String, String> _ocrResults = {};
  Map<String, String> _uploadedPhotos = {}; // itemId -> urlSupabase
  bool _isLoading = true;

  final List<Map<String, dynamic>> _identificacaoItems = [
    {'id': 'placa_dianteira', 'label': 'Placa Dianteira', 'mandatory': true, 'ocr': true},
    {'id': 'placa_traseira', 'label': 'Placa Traseira', 'mandatory': true, 'ocr': false},
    {'id': 'chassi', 'label': 'Chassi', 'mandatory': true, 'ocr': true},
    {'id': 'motor', 'label': 'Motor', 'mandatory': true, 'ocr': true},
    {'id': 'etiqueta_chassi', 'label': 'Etiqueta do Chassi', 'mandatory': true, 'ocr': false},
    {'id': 'etiqueta_coluna', 'label': 'Etiqueta da Coluna', 'mandatory': true, 'ocr': false},
  ];

  final List<Map<String, dynamic>> _externasItems = [
    {'id': 'frente', 'label': 'Frente', 'mandatory': true, 'ocr': false},
    {'id': 'traseira', 'label': 'Traseira', 'mandatory': true, 'ocr': false},
    {'id': 'lateral_direita', 'label': 'Lateral Direita', 'mandatory': true, 'ocr': false},
    {'id': 'lateral_esquerda', 'label': 'Lateral Esquerda', 'mandatory': true, 'ocr': false},
    {'id': 'diag_frente_dir', 'label': 'Diagonal Frente Direita', 'mandatory': true, 'ocr': false},
    {'id': 'diag_frente_esq', 'label': 'Diagonal Frente Esquerda', 'mandatory': true, 'ocr': false},
    {'id': 'diag_tras_dir', 'label': 'Diagonal Traseira Direita', 'mandatory': true, 'ocr': false},
    {'id': 'diag_tras_esq', 'label': 'Diagonal Traseira Esquerda', 'mandatory': true, 'ocr': false},
  ];

  final List<Map<String, dynamic>> _internasItems = [
    {'id': 'painel_ligado', 'label': 'Painel Ligado', 'mandatory': true, 'ocr': false},
    {'id': 'quilometragem', 'label': 'Quilometragem', 'mandatory': true, 'ocr': false},
    {'id': 'interior_frontal', 'label': 'Interior Frontal', 'mandatory': true, 'ocr': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final veiculo = await _dao.buscarVeiculoPorVistoria(widget.vistoriaId);
    final fotos = await _dao.listarFotosPorVistoria(widget.vistoriaId);
    
    // Load previously saved photos
    final Map<String, String> photosMap = {};
    for (var f in fotos) {
      if (f.itemId != null && f.pathLocal != null) {
        photosMap[f.itemId!] = f.pathLocal!;
      }
    }

    if (mounted) {
      setState(() {
        _veiculo = veiculo;
        _uploadedPhotos = photosMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _processPhoto(String itemId, File file, bool enableOcr) async {
    // 1. OCR (se ativado)
    if (enableOcr) {
      final rawText = await _ocrService.extractText(file);
      if (rawText != null) {
        String? extracted;
        if (itemId == 'chassi') {
          extracted = _ocrService.extractChassi(rawText);
        } else if (itemId == 'placa_dianteira' || itemId == 'placa_traseira') {
          extracted = _ocrService.extractPlaca(rawText);
        } else if (itemId == 'motor') {
          extracted = _ocrService.extractMotor(rawText);
        }

        if (extracted != null && extracted.isNotEmpty) {
          setState(() {
            _ocrResults[itemId] = extracted!;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OCR: Texto identificado -> $extracted'), backgroundColor: AppTheme.conforme),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OCR: Padrão não encontrado na imagem'), backgroundColor: AppTheme.comObs),
            );
          }
        }
      }
    }

    // 2. Compress e Upload
    final compressedFile = await _imageService.compressImage(file);
    final finalFile = compressedFile ?? file;
    
    // Atualiza UI com foto local
    setState(() {
      _uploadedPhotos[itemId] = finalFile.absolute.path;
    });

    // 3. Upload pro Supabase
    final url = await _imageService.uploadImage(
      vistoriaId: widget.vistoriaId,
      categoria: 'fotos',
      imageFile: finalFile,
    );

    // 4. Salva no banco (Drift)
    await _dao.inserirFoto(FotosVistoriaCompanion.insert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vistoriaId: widget.vistoriaId,
      itemId: drift.Value(itemId),
      legenda: itemId.replaceAll('_', ' ').toUpperCase(),
      pathLocal: drift.Value(finalFile.absolute.path),
      urlSupabase: drift.Value(url),
      storagePath: drift.Value('${widget.vistoriaId}/fotos/${finalFile.uri.pathSegments.last}'),
    ));
    
    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto enviada pra nuvem com sucesso!'), backgroundColor: AppTheme.conforme),
      );
    }
  }

  Widget _buildOcrResult(String itemId, String label) {
    if (!_ocrResults.containsKey(itemId) || _veiculo == null) return const SizedBox.shrink();
    
    final extracted = _ocrResults[itemId]!;
    String expected = '';
    
    if (itemId == 'chassi') expected = _veiculo!.chassiVeiculo ?? '';
    if (itemId == 'placa_dianteira') expected = _veiculo!.placa;
    if (itemId == 'motor') expected = _veiculo!.motorVeiculo ?? '';

    bool isMatch = extracted.replaceAll('-', '') == expected.replaceAll('-', '');
    if (expected.isEmpty) isMatch = true; // Se não temos o dado oficial, aceitamos o OCR como verdade temporária

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMatch ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(color: isMatch ? Colors.green : Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resultado OCR ($label)', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Encontrado: $extracted'),
          if (expected.isNotEmpty) Text('Esperado: $expected'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isMatch ? Icons.check_circle : Icons.warning, color: isMatch ? Colors.green : Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                isMatch ? 'Compatível' : 'Divergente',
                style: TextStyle(color: isMatch ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemId = item['id'] as String;
        return Column(
          children: [
            PhotoCaptureWidget(
              label: item['label'],
              itemId: itemId,
              isMandatory: item['mandatory'],
              enableOcr: item['ocr'],
              initialPhotoPath: _uploadedPhotos[itemId],
              onPhotoCaptured: (file) => _processPhoto(itemId, file, item['ocr']),
              onPhotoDeleted: () {
                setState(() {
                  _uploadedPhotos.remove(itemId);
                  _ocrResults.remove(itemId);
                });
              },
            ),
            _buildOcrResult(itemId, item['label']),
          ],
        );
      },
    );
  }

  Future<void> _validarEConcluir() async {
    final allItems = [..._identificacaoItems, ..._externasItems, ..._internasItems];
    final missing = allItems.where((i) => i['mandatory'] == true && !_uploadedPhotos.containsKey(i['id'])).toList();

    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Fotos Obrigatórias Faltando'),
          content: Text('Você precisa capturar as seguintes fotos:\n\n${missing.map((e) => '- ${e['label']}').join('\n')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    // Se tudo certo, gera o PDF ou finaliza
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando laudo em PDF... aguarde.')));
    
    try {
      final pdfService = sl<PdfGeneratorService>();
      final vistoria = await _dao.buscarPorId(widget.vistoriaId);
      if (vistoria != null && _veiculo != null) {
        await pdfService.generateLaudoPdf(
          vistoria: vistoria,
          veiculo: _veiculo!,
          uploadedPhotos: _uploadedPhotos,
          ocrResults: _ocrResults,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura de Evidências'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'IDENTIFICAÇÃO'),
            Tab(text: 'EXTERNAS'),
            Tab(text: 'INTERNAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_identificacaoItems),
          _buildList(_externasItems),
          _buildList(_internasItems),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _validarEConcluir,
        icon: const Icon(Icons.check),
        label: const Text('Concluir'),
      ),
    );
  }
}
