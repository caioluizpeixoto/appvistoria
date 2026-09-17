import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as import_drift;
import '../../database/daos/vistoria_dao.dart';
import '../../database/app_database.dart' as import_app_database;
import '../../database/daos/autocred_dao.dart';
import '../../injection_container.dart';
import 'empresa_rodape_helper.dart';

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

  Future<void> syncVistoriaPorId(String vistoriaId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('Usuário não logado. Sincronização cancelada.');
      return;
    }

    try {
      final vistoria = await _dao.buscarPorId(vistoriaId);
      if (vistoria != null) {
        await _uploadVistoria(vistoria, user.id);
      }
    } catch (e) {
      print('Erro ao sincronizar vistoria $vistoriaId: $e');
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
    
    final autocredDao = sl<AutocredDao>();
    var consulta = await autocredDao.buscarConsultaPorVistoria(id);
    if (consulta == null && veiculo != null && veiculo.placa.isNotEmpty) {
      final placaLimpa = veiculo.placa.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      consulta = await autocredDao.buscarConsultaPorPlaca(placaLimpa);
      if (consulta == null) {
        consulta = await autocredDao.buscarConsultaPorPlaca(veiculo.placa);
      }
    }

    // 2. Fazer upload das fotos pendentes
    List<Map<String, dynamic>> fotosJson = [];
    for (var f in fotos) {
      String? cloudUrl = f.urlSupabase;
      if (f.pathLocal != null && (cloudUrl == null || cloudUrl.isEmpty)) {
        // Salva na pasta do usuário e na pasta direta da vistoria
        await _uploadFile(f.pathLocal!, '${vistoria.id}/fotos/${f.id}.jpg');
        cloudUrl = await _uploadFile(f.pathLocal!, '$userId/fotos/${vistoria.id}/${f.id}.jpg');
        cloudUrl ??= _supabase.storage.from('laudos-pdf').getPublicUrl('${vistoria.id}/fotos/${f.id}.jpg');
        
        // Atualiza a URL no banco local
        if (cloudUrl != null) {
          try {
            await _dao.atualizarFoto(
              f.toCompanion(true).copyWith(
                urlSupabase: import_drift.Value(cloudUrl),
              ),
            );
          } catch (_) {}
        }
      }
      fotosJson.add({
        'id': f.id,
        'vistoriaId': f.vistoriaId,
        'itemId': f.itemId,
        'legenda': f.legenda,
        'etapa': f.etapa,
        'statusFoto': f.statusFoto,
        'observacao': f.observacao,
        'obrigatoria': f.obrigatoria,
        'url': cloudUrl,
        'urlSupabase': cloudUrl,
        'pathLocal': f.pathLocal,
        'ordem': f.ordem,
      });
    }

    // 3. Fazer upload do PDF do laudo se existir localmente
    String? pdfCloudUrl;
    if (vistoria.pdfUrl != null && (vistoria.pdfUrl as String).isNotEmpty) {
      final currentPdf = vistoria.pdfUrl as String;
      if (currentPdf.startsWith('http')) {
        pdfCloudUrl = currentPdf;
      } else {
        final f = File(currentPdf);
        if (f.existsSync()) {
          final fileName = f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : 'laudo.pdf';
          await _uploadFile(currentPdf, '${vistoria.id}/$fileName');
          pdfCloudUrl = await _uploadFile(currentPdf, '$userId/${vistoria.id}/$fileName');
          pdfCloudUrl ??= _supabase.storage.from('laudos-pdf').getPublicUrl('${vistoria.id}/$fileName');
        }
      }
    }

    // 4. Montar JSON completo
    final vistoriaMap = vistoria.toJson() as Map<String, dynamic>;
    if (pdfCloudUrl != null && pdfCloudUrl.isNotEmpty) {
      vistoriaMap['pdfUrl'] = pdfCloudUrl;
    }
    final precoLocal = await _dao.obterValorVistoria(id);
    if (precoLocal != null) {
      vistoriaMap['valor'] = precoLocal;
    }

    final veiculoMap = veiculo?.toJson() as Map<String, dynamic>?;
    if (veiculoMap != null) {
      veiculoMap.remove('aiImage3dBase64');
    }

    final Map<String, dynamic> dadosCompletos = {
      'vistoria': vistoriaMap,
      'veiculo': veiculoMap,
      'itens': itens.map((e) => e.toJson()).toList(),
      'fotos': fotosJson,
      'pintura': pintura.map((e) => e.toJson()).toList(),
      'estrutura': estrutura.map((e) => e.toJson()).toList(),
      'vidros': vidros.map((e) => e.toJson()).toList(),
      'consulta': consulta?.toJson(),
    };

    // 5. Enviar para a tabela `vistorias_cloud`
    final currentUser = _supabase.auth.currentUser;
    var cnpj = (currentUser?.userMetadata?['cnpj'] as String?) ?? '';
    if (cnpj.isEmpty && currentUser?.email != null) {
      final emailPrefix = currentUser!.email!.split('@').first.replaceAll(RegExp(r'[^0-9]'), '');
      if (emailPrefix.length == 14) cnpj = emailPrefix;
    }

    final empresaInfo = EmpresaRodapeInfo.obterAtual();
    var empresaNome = empresaInfo.razaoSocial;
    if (empresaNome.contains('NÃO CADASTRADA') || empresaNome.contains('CARREGANDO') || empresaNome == 'APP VISTORIA') {
      if (cnpj == '11977969000133') {
        empresaNome = 'SUMARÉ VISTORIAS';
      } else {
        final metaName = (currentUser?.userMetadata?['name'] as String? ?? '').trim();
        if (metaName.isNotEmpty) {
          empresaNome = metaName.toUpperCase();
        }
      }
    }

    await _supabase.from('vistorias_cloud').upsert({
      'id': vistoria.id,
      'user_id': userId,
      'numero_laudo': vistoria.numeroLaudo,
      'placa': veiculo?.placa,
      'chassi': veiculo?.chassiVeiculo,
      'status': vistoria.status,
      'tipo_vistoria': vistoria.tipoVistoria,
      'empresa_nome': empresaNome,
      'empresa_cnpj': cnpj,
      'dados_completos': dadosCompletos,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // 6. Marcar como sincronizado localmente
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

  /// Lista todas as vistorias de todas as empresas (Acesso exclusivo Master)
  Future<List<Map<String, dynamic>>> listarTodasVistoriasMaster({
    String? empresaFiltro,
    String? statusFiltro,
    String? queryBusca,
    int limit = 100,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    var query = _supabase.from('vistorias_cloud').select();

    if (empresaFiltro != null &&
        empresaFiltro.isNotEmpty &&
        empresaFiltro != 'todas') {
      query = query.ilike('empresa_nome', empresaFiltro);
    }

    if (statusFiltro != null &&
        statusFiltro.isNotEmpty &&
        statusFiltro != 'todos') {
      query = query.eq('status', statusFiltro);
    }

    if (queryBusca != null && queryBusca.trim().isNotEmpty) {
      final term = queryBusca.trim().toUpperCase();
      query = query.or('placa.ilike.%$term%,chassi.ilike.%$term%,numero_laudo.ilike.%$term%');
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Retorna lista de empresas que já emitiram laudos
  Future<List<String>> listarEmpresasComLaudos() async {
    try {
      final res = await _supabase
          .from('empresas')
          .select('razao_social');

      final Set<String> empresas = {};
      for (final item in res) {
        String? nome = item['razao_social'] as String?;
        if (nome != null && nome.trim().isNotEmpty) {
          empresas.add(nome.trim());
        }
      }
      return empresas.toList()..sort();
    } catch (e) {
      print('Erro ao listar empresas: $e');
      return [];
    }
  }

  /// Retorna métricas consolidadas para o Painel Master
  Future<Map<String, int>> obterMetricasMaster() async {
    try {
      final res = await _supabase
          .from('vistorias_cloud')
          .select('status, empresa_nome');

      int total = res.length;
      int aprovados = 0;
      int reprovados = 0;
      int apontamentos = 0;
      int emAndamento = 0;
      final Set<String> empresas = {};

      for (final row in res) {
        final st = (row['status'] as String? ?? '').toLowerCase();
        if (st.contains('aprovado') && !st.contains('apontamento')) {
          aprovados++;
        } else if (st.contains('reprovado')) {
          reprovados++;
        } else if (st.contains('apontamento')) {
          apontamentos++;
        } else {
          emAndamento++;
        }

        String? emp = row['empresa_nome'] as String?;
        if (emp != null && emp.trim().isNotEmpty) {
          empresas.add(emp.trim().toUpperCase());
        }
      }

      return {
        'total': total,
        'aprovados': aprovados,
        'reprovados': reprovados,
        'apontamentos': apontamentos,
        'emAndamento': emAndamento,
        'totalEmpresas': empresas.length,
      };
    } catch (e) {
      print('Erro ao obter métricas master: $e');
      return {
        'total': 0,
        'aprovados': 0,
        'reprovados': 0,
        'apontamentos': 0,
        'emAndamento': 0,
        'totalEmpresas': 0,
      };
    }
  }

  bool _isSyncing = false;

  Future<void> excluirVistoriaNuvem(String vistoriaId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Deleta do banco de dados na nuvem
      final res = await _supabase
          .from('vistorias_cloud')
          .delete()
          .eq('id', vistoriaId)
          .select();
      print('Vistoria $vistoriaId excluída da nuvem: ${res.length} registro(s) afetado(s).');

      // 2. Remove arquivos do storage associados (pasta do usuário e pasta direta)
      try {
        final folderPath = '${user.id}/$vistoriaId';
        final files = await _supabase.storage.from('laudos-pdf').list(path: folderPath);
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$folderPath/${f.name}').toList();
          await _supabase.storage.from('laudos-pdf').remove(paths);
        }
      } catch (_) {}

      try {
        final files = await _supabase.storage.from('laudos-pdf').list(path: vistoriaId);
        if (files.isNotEmpty) {
          final paths = files.map((f) => '$vistoriaId/${f.name}').toList();
          await _supabase.storage.from('laudos-pdf').remove(paths);
        }
      } catch (_) {}

      print('Arquivos de $vistoriaId limpos do storage.');
    } catch (e) {
      print('Erro ao excluir vistoria da nuvem: $e');
    }
  }

  Future<void> syncClientes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Enviar clientes locais para a nuvem
      final clientesLocais = await _dao.listarClientes();
      for (final c in clientesLocais) {
        await _supabase.from('clientes_cloud').upsert({
          'id': c.id,
          'user_id': user.id,
          'nome': c.nome,
          'cpf_cnpj': c.cpfCnpj,
          'email': c.email,
          'telefone': c.telefone,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Baixar clientes da nuvem para o banco local
      final clientesCloud = await _supabase.from('clientes_cloud').select();
      for (final c in clientesCloud) {
        await _dao.upsertCliente(
          import_app_database.ClientesCompanion(
            id: import_drift.Value(c['id']),
            userId: import_drift.Value(c['user_id']),
            nome: import_drift.Value(c['nome'] ?? ''),
            cpfCnpj: import_drift.Value(c['cpf_cnpj']),
            email: import_drift.Value(c['email']),
            telefone: import_drift.Value(c['telefone']),
          ),
        );
      }
    } catch (e) {
      print('Erro ao sincronizar clientes: $e');
    }
  }

  Future<void> deletarClienteCloud(String id) async {
    try {
      await _supabase.from('clientes_cloud').delete().eq('id', id);
    } catch (e) {
      print('Erro ao deletar cliente da nuvem: $e');
    }
  }

  Future<void> syncVistoriadores() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Enviar vistoriadores locais para a nuvem
      final vistoriadoresLocais = await _dao.listarVistoriadores();
      for (final v in vistoriadoresLocais) {
        await _supabase.from('vistoriadores_cloud').upsert({
          'id': v.id,
          'user_id': user.id,
          'nome': v.nome,
          'cpf': v.cpf,
          'unidade_nome': v.unidadeNome,
          'unidade_cnpj': v.unidadeCnpj,
          'cargo': v.cargo,
          'ativo': v.ativo,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Baixar vistoriadores da nuvem para o banco local
      final vistoriadoresCloud = await _supabase.from('vistoriadores_cloud').select();
      for (final v in vistoriadoresCloud) {
        await _dao.upsertVistoriador(
          import_app_database.VistoriadoresCompanion(
            id: import_drift.Value(v['id']),
            userId: import_drift.Value(v['user_id']),
            nome: import_drift.Value(v['nome'] ?? ''),
            cpf: import_drift.Value(v['cpf']),
            unidadeNome: import_drift.Value(v['unidade_nome']),
            unidadeCnpj: import_drift.Value(v['unidade_cnpj']),
            cargo: import_drift.Value(v['cargo'] ?? 'vistoriador'),
            ativo: import_drift.Value(v['ativo'] ?? true),
          ),
        );
      }
    } catch (e) {
      print('Erro ao sincronizar vistoriadores: $e');
    }
  }

  Future<void> deletarVistoriadorCloud(String id) async {
    try {
      await _supabase.from('vistoriadores_cloud').delete().eq('id', id);
    } catch (e) {
      print('Erro ao deletar vistoriador da nuvem: $e');
    }
  }

  Future<void> autoSync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (_isSyncing) {
      print('SyncService: autoSync já está em execução. Ignorando.');
      return;
    }
    _isSyncing = true;

    try {
      // 1. Enviar vistorias pendentes (se houver offline)
      await syncVistoriasPendentes();

      // 2. Baixar vistorias da nuvem (Sincronização Bidirecional para múltiplos aparelhos)
      try {
        final vistoriasCloud = await _supabase
            .from('vistorias_cloud')
            .select()
            .order('created_at', ascending: false);

        // 2a. Reconciliação: se uma vistoria local já foi sincronizada, mas não existe mais na nuvem, foi excluída
        final cloudIds = vistoriasCloud
            .map((e) => e['id']?.toString())
            .whereType<String>()
            .toSet();
        final vistoriasLocais = await _dao.listarVistorias();
        for (final local in vistoriasLocais) {
          if (local.sincronizado && !cloudIds.contains(local.id)) {
            print('Removendo vistoria local excluída da nuvem: ${local.id}');
            await _dao.excluirVistoriaCompleta(local.id);
          }
        }

        for (final vc in vistoriasCloud) {
          final dadosCompletos = vc['dados_completos'] as Map<String, dynamic>?;
          if (dadosCompletos != null) {
            final vistoriaJson = dadosCompletos['vistoria'] as Map<String, dynamic>?;
            final veiculoJson = dadosCompletos['veiculo'] as Map<String, dynamic>?;

            // 2a. Importar Vistoria
            if (vistoriaJson != null) {
              try {
                final cloudPdf = vc['pdf_url'] as String? ?? vistoriaJson['pdfUrl'] as String?;
                final vistoriaObj = import_app_database.Vistoria.fromJson(vistoriaJson);
                var companion = vistoriaObj.toCompanion(true).copyWith(
                  sincronizado: const import_drift.Value(true),
                );
                if (cloudPdf != null && cloudPdf.isNotEmpty) {
                  companion = companion.copyWith(pdfUrl: import_drift.Value(cloudPdf));
                }
                await _dao.upsertVistoria(companion);
                final valorCloud = (vistoriaJson['valor'] as num?)?.toDouble() ??
                    (vc['valor'] as num?)?.toDouble();
                if (valorCloud != null && valorCloud > 0) {
                  await _dao.salvarValorVistoria(vc['id'], valorCloud);
                }
              } catch (e) {
                print('Erro ao importar vistoria ${vc['id']}: $e');
              }
            }

            // 2b. Importar Veículo
            if (veiculoJson != null) {
              try {
                final veiculoObj = import_app_database.Veiculo.fromJson(veiculoJson);
                await _dao.upsertVeiculo(veiculoObj.toCompanion(true));
              } catch (e) {
                print('Erro ao importar veiculo da vistoria ${vc['id']}: $e');
              }
            }

            // 2c. Importar Itens do Checklist
            final itensList = dadosCompletos['itens'] as List?;
            if (itensList != null) {
              for (final i in itensList) {
                if (i is Map<String, dynamic>) {
                  try {
                    final itemObj = import_app_database.ItensVistoriaData.fromJson(i);
                    await _dao.inserirOuAtualizarItem(itemObj.toCompanion(true));
                  } catch (_) {}
                }
              }
            }

            // 2d. Importar Fotos e baixar localmente
            final fotosList = dadosCompletos['fotos'] as List?;
            if (fotosList != null) {
              for (final f in fotosList) {
                if (f is Map<String, dynamic>) {
                  try {
                    final fotoId = f['id']?.toString() ?? '';
                    final url = f['url']?.toString() ?? f['urlSupabase']?.toString();
                    String? localPath = f['pathLocal']?.toString();

                    if (url != null && url.isNotEmpty) {
                      final fileExists = localPath != null && File(localPath).existsSync();
                      if (!fileExists) {
                        try {
                          final dir = await getApplicationDocumentsDirectory();
                          final targetPath = '${dir.path}/foto_${vc['id']}_$fotoId.jpg';
                          final targetFile = File(targetPath);
                          if (!targetFile.existsSync()) {
                            if (url.contains('/laudos-pdf/')) {
                              final storagePath = url.split('/laudos-pdf/').last.split('?').first;
                              final bytes = await _supabase.storage.from('laudos-pdf').download(storagePath);
                              await targetFile.writeAsBytes(bytes);
                              localPath = targetPath;
                            } else {
                              final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
                              if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
                                await targetFile.writeAsBytes(res.bodyBytes);
                                localPath = targetPath;
                              }
                            }
                          } else {
                            localPath = targetPath;
                          }
                        } catch (err) {
                          print('Erro ao baixar foto ($url): $err');
                        }
                      }
                    }

                    await _dao.inserirOuAtualizarFoto(
                      import_app_database.FotosVistoriaCompanion(
                        id: import_drift.Value(fotoId),
                        vistoriaId: import_drift.Value(vc['id']),
                        itemId: import_drift.Value(f['itemId']?.toString()),
                        legenda: import_drift.Value(f['legenda']?.toString() ?? ''),
                        etapa: import_drift.Value(f['etapa']?.toString()),
                        statusFoto: import_drift.Value(f['statusFoto']?.toString()),
                        observacao: import_drift.Value(f['observacao']?.toString()),
                        obrigatoria: import_drift.Value(f['obrigatoria'] == true),
                        pathLocal: import_drift.Value(localPath),
                        urlSupabase: import_drift.Value(url),
                        ordem: import_drift.Value(f['ordem'] is int ? f['ordem'] : 0),
                      ),
                    );
                  } catch (err) {
                    print('Erro ao importar foto ${f['id']}: $err');
                  }
                }
              }
            }

            // 2e. Importar Pintura
            final pinturaList = dadosCompletos['pintura'] as List?;
            if (pinturaList != null) {
              for (final p in pinturaList) {
                if (p is Map<String, dynamic>) {
                  try {
                    final pObj = import_app_database.ItensPinturaData.fromJson(p);
                    await _dao.inserirOuAtualizarPintura(pObj.toCompanion(true));
                  } catch (_) {}
                }
              }
            }

            // 2f. Importar Estrutura
            final estruturaList = dadosCompletos['estrutura'] as List?;
            if (estruturaList != null) {
              for (final e in estruturaList) {
                if (e is Map<String, dynamic>) {
                  try {
                    final eObj = import_app_database.ItensEstruturaData.fromJson(e);
                    await _dao.inserirOuAtualizarEstrutura(eObj.toCompanion(true));
                  } catch (_) {}
                }
              }
            }

            // 2g. Importar Vidros
            final vidrosList = dadosCompletos['vidros'] as List?;
            if (vidrosList != null) {
              for (final v in vidrosList) {
                if (v is Map<String, dynamic>) {
                  try {
                    final vObj = import_app_database.VidrosVistoriaData.fromJson(v);
                    await _dao.inserirOuAtualizarVidro(vObj.toCompanion(true));
                  } catch (_) {}
                }
              }
            }

            // 2h. Importar Consulta Autocred
            final consultaJson = dadosCompletos['consulta'] as Map<String, dynamic>?;
            if (consultaJson != null) {
              try {
                final cObj = import_app_database.ConsultasAutocredData.fromJson(consultaJson);
                final autocredDao = sl<AutocredDao>();
                await autocredDao.inserirOuAtualizarConsulta(cObj.toCompanion(true));
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        print('Erro ao baixar vistorias da nuvem: $e');
      }

      // 3. Sincronizar clientes (Upload + Download)
      await syncClientes();
      
      // 4. Sincronizar vistoriadores (Upload + Download)
      await syncVistoriadores();

      print('Auto-sync finalizado com sucesso.');
    } catch (e) {
      print('Erro no autoSync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Gestão de Dispositivos (Master) ──────────────────────────────────────────

  /// Lista todos os aparelhos registrados para análise do Master
  Future<List<Map<String, dynamic>>> listarDispositivosMaster() async {
    try {
      final res = await _supabase.rpc('listar_dispositivos_master');
      if (res is List) {
        return res.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao listar dispositivos master: $e');
      try {
        final res = await _supabase
            .from('dispositivos_autorizados')
            .select('*')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (e2) {
        print('Erro no fallback de listar dispositivos: $e2');
        return [];
      }
    }
  }

  /// Aprova um dispositivo pelo seu device_id
  Future<bool> aprovarDispositivoMaster(String deviceId) async {
    try {
      final res = await _supabase.rpc('aprovar_dispositivo', params: {
        'p_device_id': deviceId,
      });
      return res == true;
    } catch (e) {
      print('Erro ao aprovar dispositivo via RPC: $e');
      try {
        await _supabase.from('dispositivos_autorizados').update({
          'status': 'aprovado',
          'aprovado_em': DateTime.now().toIso8601String(),
          'aprovado_por': _supabase.auth.currentUser?.id,
          'motivo_bloqueio': null,
        }).eq('device_id', deviceId);
        return true;
      } catch (e2) {
        print('Erro ao aprovar dispositivo direto na tabela: $e2');
        return false;
      }
    }
  }

  /// Bloqueia/revoga o acesso de um aparelho
  Future<bool> bloquearDispositivoMaster(String deviceId, {String? motivo}) async {
    try {
      final res = await _supabase.rpc('bloquear_dispositivo', params: {
        'p_device_id': deviceId,
        'p_motivo': motivo ?? 'Acesso revogado pelo Administrador Master',
      });
      return res == true;
    } catch (e) {
      print('Erro ao bloquear dispositivo via RPC: $e');
      try {
        await _supabase.from('dispositivos_autorizados').update({
          'status': 'bloqueado',
          'motivo_bloqueio': motivo ?? 'Acesso revogado pelo Administrador Master',
        }).eq('device_id', deviceId);
        return true;
      } catch (e2) {
        print('Erro ao bloquear dispositivo direto na tabela: $e2');
        return false;
      }
    }
  }

  /// Remove permanentemente o registro de um aparelho
  Future<bool> removerDispositivoMaster(String deviceId) async {
    try {
      final res = await _supabase.rpc('remover_dispositivo_master', params: {
        'p_device_id': deviceId,
      });
      return res == true;
    } catch (e) {
      print('Erro ao remover dispositivo: $e');
      try {
        await _supabase.from('dispositivos_autorizados').delete().eq('device_id', deviceId);
        return true;
      } catch (e2) {
        print('Erro no fallback ao deletar dispositivo: $e2');
        return false;
      }
    }
  }
}

