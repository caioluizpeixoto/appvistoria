import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ImageService {
  final SupabaseClient supabase;

  ImageService({required this.supabase});

  /// Comprime a imagem mantendo uma boa qualidade para OCR/Vistoria
  Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final outPath = '${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg';

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Erro ao comprimir imagem: $e');
      return file; // Em caso de falha, retorna a original
    }
  }

  /// Faz o upload para o Supabase Storage e retorna a URL pública
  Future<String?> uploadImage({
    required String vistoriaId,
    required String categoria,
    required File imageFile,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}';
      final storagePath = '$vistoriaId/$categoria/$fileName';

      await supabase.storage.from('vistorias').upload(
        storagePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from('vistorias').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print('Erro no upload da imagem: $e');
      return null;
    }
  }
}
