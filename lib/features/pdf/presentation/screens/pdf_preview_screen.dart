import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../database/daos/vistoria_dao.dart';
import '../../../../injection_container.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String vistoriaId;
  final String? pdfPath;
  final String? placa;
  const PdfPreviewScreen({
    super.key,
    required this.vistoriaId,
    this.pdfPath,
    this.placa,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfBytes;
  String? _localSavedPath;
  String? _placa;
  bool _isLoading = true;
  String? _errorMessage;
  String _loadingMessage = 'Carregando PDF...';

  String get _nomeArquivoFinal {
    final raw = _placa ?? widget.placa ?? '';
    final clean = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.isNotEmpty) {
      return '$clean.pdf';
    }
    return 'Laudo_${widget.vistoriaId}.pdf';
  }

  @override
  void initState() {
    super.initState();
    _placa = widget.placa;
    _carregarPdf();
  }

  Future<void> _carregarPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dao = sl<VistoriaDao>();

      // Carrega placa do veículo se ainda não tiver
      if (_placa == null || _placa!.isEmpty) {
        try {
          final veiculo = await dao.buscarVeiculoPorVistoria(widget.vistoriaId);
          if (veiculo != null && veiculo.placa.trim().isNotEmpty) {
            _placa = veiculo.placa.trim();
          }
        } catch (_) {}
      }
      String? pathOrUrl = widget.pdfPath;

      // 1. Se não foi passado caminho ou se for vazio, busca no banco local
      if (pathOrUrl == null || pathOrUrl.isEmpty) {
        final dao = sl<VistoriaDao>();
        final vistoria = await dao.buscarPorId(widget.vistoriaId);
        pathOrUrl = vistoria?.pdfUrl;
      }

      // 2. Se for arquivo local e existir no aparelho
      if (pathOrUrl != null && !pathOrUrl.startsWith('http')) {
        final localFile = File(pathOrUrl);
        if (await localFile.exists()) {
          final bytes = await localFile.readAsBytes();
          if (mounted) {
            setState(() {
              _pdfBytes = bytes;
              _localSavedPath = pathOrUrl;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // 3. Se for URL HTTP/HTTPS
      if (pathOrUrl != null && pathOrUrl.startsWith('http')) {
        try {
          if (pathOrUrl.contains('/laudos-pdf/')) {
            final storagePath = pathOrUrl.split('/laudos-pdf/').last.split('?').first;
            final bytes = await Supabase.instance.client.storage.from('laudos-pdf').download(storagePath);
            final dir = await getApplicationDocumentsDirectory();
            final cacheFile = File('${dir.path}/$_nomeArquivoFinal');
            await cacheFile.writeAsBytes(bytes);

            if (mounted) {
              setState(() {
                _pdfBytes = bytes;
                _localSavedPath = cacheFile.path;
                _isLoading = false;
              });
            }
            return;
          } else {
            final res = await http.get(Uri.parse(pathOrUrl)).timeout(const Duration(seconds: 15));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              final dir = await getApplicationDocumentsDirectory();
              final cacheFile = File('${dir.path}/$_nomeArquivoFinal');
              await cacheFile.writeAsBytes(res.bodyBytes);

              if (mounted) {
                setState(() {
                  _pdfBytes = res.bodyBytes;
                  _localSavedPath = cacheFile.path;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        } catch (_) {}
      }

      // 4. Buscar registro atualizado na tabela vistorias_cloud do Supabase
      final supabase = Supabase.instance.client;
      String? cloudUserId;
      try {
        final row = await supabase
            .from('vistorias_cloud')
            .select('dados_completos, user_id')
            .eq('id', widget.vistoriaId)
            .maybeSingle();

        if (row != null) {
          cloudUserId = row['user_id']?.toString();
          final dados = row['dados_completos'] as Map<String, dynamic>?;
          final remotePdfUrl = dados?['vistoria']?['pdfUrl'] as String?;
          if (remotePdfUrl != null && remotePdfUrl.startsWith('http')) {
            if (remotePdfUrl.contains('/laudos-pdf/')) {
              final storagePath = remotePdfUrl.split('/laudos-pdf/').last.split('?').first;
              final bytes = await Supabase.instance.client.storage.from('laudos-pdf').download(storagePath);
              final dir = await getApplicationDocumentsDirectory();
              final cacheFile = File('${dir.path}/$_nomeArquivoFinal');
              await cacheFile.writeAsBytes(bytes);

              if (mounted) {
                setState(() {
                  _pdfBytes = bytes;
                  _localSavedPath = cacheFile.path;
                  _isLoading = false;
                });
              }
              return;
            } else {
              final res = await http.get(Uri.parse(remotePdfUrl)).timeout(const Duration(seconds: 15));
              if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
                final dir = await getApplicationDocumentsDirectory();
                final cacheFile = File('${dir.path}/$_nomeArquivoFinal');
                await cacheFile.writeAsBytes(res.bodyBytes);

                if (mounted) {
                  setState(() {
                    _pdfBytes = res.bodyBytes;
                    _localSavedPath = cacheFile.path;
                    _isLoading = false;
                  });
                }
                return;
              }
            }
          }
        }
      } catch (_) {}

      // 5. Buscar diretamente nas pastas do Storage laudos-pdf
      final currentUserId = supabase.auth.currentUser?.id ?? cloudUserId;
      final possiblePaths = <String>[
        widget.vistoriaId,
        if (currentUserId != null) '$currentUserId/${widget.vistoriaId}',
        if (cloudUserId != null && cloudUserId != currentUserId) '$cloudUserId/${widget.vistoriaId}',
      ];

      for (final folder in possiblePaths) {
        try {
          final files = await supabase.storage.from('laudos-pdf').list(path: folder);
          if (files.isNotEmpty) {
            final pdfItem = files.firstWhere(
              (f) => f.name.toLowerCase().endsWith('.pdf'),
              orElse: () => files.first,
            );
            final fullStoragePath = '$folder/${pdfItem.name}';
            final bytes = await supabase.storage.from('laudos-pdf').download(fullStoragePath);
            
            final dir = await getApplicationDocumentsDirectory();
            final cacheFile = File('${dir.path}/$_nomeArquivoFinal');
            await cacheFile.writeAsBytes(bytes);

            if (mounted) {
              setState(() {
                _pdfBytes = bytes;
                _localSavedPath = cacheFile.path;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (_) {}
      }

      // 6. Fallback final: Se os dados existirem no banco local, gerar o laudo na hora
      try {
        final dao = sl<VistoriaDao>();
        final vistoria = await dao.buscarPorId(widget.vistoriaId);
        final veiculo = await dao.buscarVeiculoPorVistoria(widget.vistoriaId);
        if (vistoria != null && veiculo != null) {
          if (mounted) {
            setState(() {
              _loadingMessage = 'Gerando 2ª via do laudo...';
            });
          }
          final pdfService = sl<PdfGeneratorService>();
          final generatedPath = await pdfService.generateLaudoCompleto(
            vistoria: vistoria,
            veiculo: veiculo,
          );
          if (generatedPath != null) {
            final generatedFile = File(generatedPath);
            if (await generatedFile.exists()) {
              final bytes = await generatedFile.readAsBytes();
              if (mounted) {
                setState(() {
                  _pdfBytes = bytes;
                  _localSavedPath = generatedPath;
                  _isLoading = false;
                });
              }
              return;
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _errorMessage = 'Arquivo PDF não encontrado. O laudo pode ainda estar sendo gerado ou sincronizado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documento PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Voltar ao Início',
            onPressed: () => context.go('/home'),
          ),
          if (_pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Compartilhar',
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                final tempFile = File('${dir.path}/$_nomeArquivoFinal');
                await tempFile.writeAsBytes(_pdfBytes!);
                await Share.shareXFiles(
                  [XFile(tempFile.path, name: _nomeArquivoFinal)],
                  text: 'Laudo de Vistoria${_placa != null && _placa!.isNotEmpty ? " - $_placa" : ""}',
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _carregarPdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _pdfBytes!,
                  pdfFileName: _nomeArquivoFinal,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                ),
    );
  }
}
