import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/daos/vistoria_dao.dart';
import '../../injection_container.dart';

class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VistoriaDao _dao = sl<VistoriaDao>();

  Future<void> syncVistoriasPendentes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('Usuário não logado. Sincronização cancelada.');
      return;
    }

    try {
      final naoSync = await _dao.listarNaoSincronizadas();
      print('Vistorias pendentes para sync: ${naoSync.length}');

      for (final v in naoSync) {
        await _uploadVistoria(v, user.id);
      }
    } catch (e) {
      print('Erro ao sincronizar vistorias: $e');
      rethrow;
    }
  }

  Future<void> _uploadVistoria(var vistoria, String userId) async {
    final id = vistoria.id;

    // 1. Coletar todos os dados locais
    final veiculo = await _dao.buscarVeiculoPorVistoria(id);
    final itens = await _dao.listarItensPorVistoria(id);
    final fotos = await _dao.listarFotosPorVistoria(id);
    final pintura = await _dao.listarPinturaPorVistoria(id);
    final estrutura = await _dao.listarEstruturaPorVistoria(id);
    final vidros = await _dao.listarVidrosPorVistoria(id);

    // 2. Fazer upload das fotos pendentes
    List<Map<String, dynamic>> fotosJson = [];
    for (var f in fotos) {
      String? cloudUrl = f.urlSupabase;
      if (f.pathLocal != null && (cloudUrl == null || cloudUrl.isEmpty)) {
        cloudUrl = await _uploadFile(f.pathLocal!, 'fotos/${vistoria.id}/${f.id}.jpg');
      }
      fotosJson.add({
        'id': f.id,
        'legenda': f.legenda,
        'url': cloudUrl,
        'ordem': f.ordem,
        'obrigatoria': f.obrigatoria,
        'observacao': f.observacao,
      });
    }

    // 3. Montar JSON completo
    final Map<String, dynamic> dadosCompletos = {
      'vistoria': vistoria.toJson(),
      'veiculo': veiculo?.toJson(),
      'itens': itens.map((e) => e.toJson()).toList(),
      'fotos': fotosJson,
      'pintura': pintura.map((e) => e.toJson()).toList(),
      'estrutura': estrutura.map((e) => e.toJson()).toList(),
      'vidros': vidros.map((e) => e.toJson()).toList(),
    };

    // 4. Enviar para a tabela `vistorias_cloud`
    await _supabase.from('vistorias_cloud').upsert({
      'id': vistoria.id,
      'user_id': userId,
      'numero_laudo': vistoria.numeroLaudo,
      'placa': veiculo?.placa,
      'chassi': veiculo?.chassiVeiculo,
      'status': vistoria.status,
      'tipo_vistoria': vistoria.tipoVistoria,
      'dados_completos': dadosCompletos,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 5. Marcar como sincronizado localmente
    await _dao.marcarSincronizado(vistoria.id);
  }

  Future<String?> _uploadFile(String localPath, String storagePath) async {
    final file = File(localPath);
    if (!await file.exists()) return null;

    try {
      await _supabase.storage.from('laudos-pdf').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('laudos-pdf').getPublicUrl(storagePath);
    } catch (e) {
      print('Erro no upload de arquivo $localPath: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listarVistoriasNuvem() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final res = await _supabase
        .from('vistorias_cloud')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}
