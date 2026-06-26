import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';

/// Step 12 — Fotos Extras
class StepFotosExtras extends StatefulWidget {
  const StepFotosExtras({super.key});
  @override
  State<StepFotosExtras> createState() => _StepFotosExtrasState();
}

class _StepFotosExtrasState extends State<StepFotosExtras> {
  final _imagePicker = ImagePicker();

  Future<void> _adicionarFoto(VistoriaWizardState state, ImageSource source) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xFile == null || !mounted) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: xFile.path,
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
    if (croppedFile == null || !mounted) return;

    // Copia para diretório persistente
    final tempFile = File(croppedFile.path);
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'vistoria_img_extra_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempFile.path)}';
    final savedFile = await tempFile.copy('${appDir.path}/$fileName');

    // Pede título e categoria
    final result = await _showFotoDialog(savedFile.path);
    if (result == null) return;

    state.addFotoExtra(
      pathLocal: savedFile.path,
      titulo: result['titulo']!,
      categoria: result['categoria']!,
    );
  }

  Future<Map<String, String>?> _showFotoDialog(String path) async {
    final tituloCtrl = TextEditingController();
    String categoriaSelected = 'Avaria';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Adicionar Foto Extra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview da foto
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(path),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título da foto',
                    hintText: 'Ex: Amassado porta traseira',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoriaSelected,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Avaria','Estrutura','Pintura','Documento','Interior','Motor','Chassi','Outro']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setStateDialog(() {
                    if (v != null) categoriaSelected = v;
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'titulo': tituloCtrl.text,
                'categoria': categoriaSelected,
              }),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_photo_alternate_rounded,
                  color: AppTheme.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fotos Extras',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text('${state.fotosExtras.length} foto(s) adicionada(s)',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botões adicionar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _adicionarFoto(state, ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Câmera'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _adicionarFoto(state, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Galeria'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Lista de fotos extras
        if (state.fotosExtras.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: const Column(
              children: [
                Icon(Icons.photo_outlined, size: 48, color: AppTheme.textHint),
                SizedBox(height: 12),
                Text('Nenhuma foto extra adicionada',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Text('Adicione fotos de avarias, documentos, etc.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textHint)),
              ],
            ),
          )
        else
          ...state.fotosExtras.asMap().entries.map((entry) {
            final i = entry.key;
            final foto = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.file(
                      File(foto['pathLocal']),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foto['titulo']!.isEmpty ? 'Sem título' : foto['titulo']!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            foto['categoria']!,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.naoConforme),
                    onPressed: () => state.removeFotoExtra(i),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 32),
      ],
    );
  }
}
