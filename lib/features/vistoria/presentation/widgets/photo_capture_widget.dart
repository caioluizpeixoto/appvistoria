import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';

class PhotoCaptureWidget extends StatefulWidget {
  final String label;
  final String itemId;
  final bool isMandatory;
  final bool enableOcr;
  final String? initialPhotoPath;
  final Function(File photo)? onPhotoCaptured;
  final VoidCallback? onPhotoDeleted;

  const PhotoCaptureWidget({
    super.key,
    required this.label,
    required this.itemId,
    this.isMandatory = false,
    this.enableOcr = false,
    this.initialPhotoPath,
    this.onPhotoCaptured,
    this.onPhotoDeleted,
  });

  @override
  State<PhotoCaptureWidget> createState() => _PhotoCaptureWidgetState();
}

class _PhotoCaptureWidgetState extends State<PhotoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _currentPhoto;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhotoPath != null) {
      _currentPhoto = File(widget.initialPhotoPath!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isProcessing = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100, // Deixamos a compressão pesada para o ImageService depois
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Editar Foto',
              toolbarColor: AppTheme.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Editar Foto',
            ),
          ],
        );
        if (croppedFile != null) {
          final tempFile = File(croppedFile.path);
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'vistoria_img_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempFile.path)}';
          final savedFile = await tempFile.copy('${appDir.path}/$fileName');

          setState(() => _currentPhoto = savedFile);
          if (widget.onPhotoCaptured != null) {
            widget.onPhotoCaptured!(savedFile);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar imagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _deletePhoto() {
    setState(() => _currentPhoto = null);
    if (widget.onPhotoDeleted != null) {
      widget.onPhotoDeleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.isMandatory && _currentPhoto == null
              ? Colors.red.shade300
              : AppTheme.surfaceVariant,
          width: widget.isMandatory && _currentPhoto == null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (widget.isMandatory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Obrigatório',
                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (widget.enableOcr)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OCR Ativo',
                      style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_currentPhoto != null)
              _buildPhotoPreview()
            else
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _currentPhoto!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Substituir'),
            ),
            TextButton.icon(
              onPressed: _deletePhoto,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Tirar Foto'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
            ),
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Galeria'),
          ),
        ),
      ],
    );
  }
}
