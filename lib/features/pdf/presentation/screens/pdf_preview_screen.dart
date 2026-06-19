import 'dart:io';
import 'package:flutter/material.dart';
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
        appBar: AppBar(title: const Text('Laudo PDF')),
        body: const Center(child: Text('Arquivo PDF não encontrado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laudo PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartilhar',
            onPressed: () {
              if (pdfPath != null && File(pdfPath!).existsSync()) {
                Share.shareXFiles([XFile(pdfPath!)], text: 'Laudo Vistoria');
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => File(pdfPath!).readAsBytes(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
