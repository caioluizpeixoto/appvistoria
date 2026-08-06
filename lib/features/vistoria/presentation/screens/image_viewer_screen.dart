import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _salvarNaGaleria(context, file),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: file.existsSync() 
            ? Image.file(file) 
            : const Icon(Icons.broken_image, color: Colors.white, size: 50),
        ),
      ),
    );
  }

  Future<void> _salvarNaGaleria(BuildContext context, File file) async {
    try {
      if (!file.existsSync()) return;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'VISTORIA_$timestamp.jpg';
      
      // Tentar salvar na pasta pública de Imagens do Android
      final defaultPath = '/storage/emulated/0/Pictures/AppVistoria';
      final dir = Directory(defaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final savedFile = await file.copy('${dir.path}/$fileName');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto salva na galeria!'),
            backgroundColor: AppTheme.conforme,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e. Verifique as permissões de armazenamento.'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    }
  }
}
