import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final isHttp = imagePath.startsWith('http');
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Salvar na Galeria',
            onPressed: () => _salvarNaGaleria(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: isHttp
              ? Image.network(
                  imagePath,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 50),
                )
              : file.existsSync()
                  ? Image.file(file)
                  : const Icon(Icons.broken_image, color: Colors.white, size: 50),
        ),
      ),
    );
  }

  Future<void> _salvarNaGaleria(BuildContext context) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'VISTORIA_$timestamp.jpg';
      final defaultPath = '/storage/emulated/0/Pictures/AppVistoria';
      final dir = Directory(defaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final targetPath = '${dir.path}/$fileName';
      if (imagePath.startsWith('http')) {
        final res = await http.get(Uri.parse(imagePath));
        if (res.statusCode == 200) {
          await File(targetPath).writeAsBytes(res.bodyBytes);
        }
      } else {
        final file = File(imagePath);
        if (!file.existsSync()) return;
        await file.copy(targetPath);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto salva na galeria!'),
            backgroundColor: AppTheme.conforme,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }
}
