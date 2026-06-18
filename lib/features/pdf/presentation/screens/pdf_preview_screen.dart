import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

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
          // Remove default printing actions if desired, or keep them
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
