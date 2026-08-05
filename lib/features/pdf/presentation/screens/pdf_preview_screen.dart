import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String vistoriaId;
  final String? pdfPath;
  const PdfPreviewScreen({
    super.key,
    required this.vistoriaId,
    this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    if (pdfPath == null || !File(pdfPath!).existsSync()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documento PDF')),
        body: const Center(child: Text('Arquivo PDF não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documento PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Voltar ao Início',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartilhar',
            onPressed: () {
              if (pdfPath != null && File(pdfPath!).existsSync()) {
                Share.shareXFiles([XFile(pdfPath!)],
                    text: 'Documento Vistoria');
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => File(pdfPath!).readAsBytes(),
        pdfFileName: pdfPath!.split(Platform.pathSeparator).last,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
