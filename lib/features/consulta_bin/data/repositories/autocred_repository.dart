import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../database/app_database.dart';
import '../../../../database/daos/autocred_dao.dart';
class AutoCredRepository {
  final SupabaseClient supabase;
  final AutocredDao localDao;

  AutoCredRepository({required this.supabase, required this.localDao});

  Future<void> salvarConsulta({
    String? vistoriaId,
    required String placa,
    String? chassi,
    String? motor,
    required int codigoConsulta,
    required String idPesquisaAutocred,
    required String status,
    required String retornoBruto,
    required Map<String, dynamic> dadosTratados,
    String? arquivoPesquisaUrl,
  }) async {
    try {
      // Salvamento local (offline first)
      final localId = const Uuid().v4();
      
      await localDao.inserirOuAtualizarConsulta(ConsultasAutocredCompanion.insert(
        id: localId,
        vistoriaId: drift.Value(vistoriaId),
        placa: drift.Value(placa),
        chassi: drift.Value(chassi),
        motor: drift.Value(motor),
        codigoConsulta: codigoConsulta,
        idPesquisaAutocred: drift.Value(idPesquisaAutocred),
        status: drift.Value(status),
        retornoBruto: drift.Value(retornoBruto),
        dadosTratadosJson: drift.Value(jsonEncode(dadosTratados)),
        arquivoPesquisaUrl: drift.Value(arquivoPesquisaUrl),
      ));

      // Salvamento na nuvem (Supabase)
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        // Retorna sem erro pois salvou localmente!
        return;
      }
      
      await supabase.from('autocred_consultas').insert({
        'vistoria_id': (vistoriaId != null && vistoriaId.isNotEmpty) ? vistoriaId : null,
        'user_id': userId,
        'placa': placa,
        'chassi': chassi,
        'motor': motor,
        'codigo_consulta': codigoConsulta,
        'id_pesquisa_autocred': idPesquisaAutocred,
        'status': status,
        'retorno_bruto': retornoBruto,
        'dados_tratados': dadosTratados,
        if (arquivoPesquisaUrl != null) 'arquivo_pesquisa_url': arquivoPesquisaUrl,
      });
    } on PostgrestException catch (e) {
      print('Erro no banco de dados ao salvar consulta: ${e.message}');
      throw Exception('Erro no banco de dados. Contate o suporte. (${e.message})');
    } catch (e) {
      if (e is Exception && e.toString().contains('Usuário não autenticado')) {
        rethrow;
      }
      print('Erro ao salvar histórico de consulta: $e');
      throw Exception('Erro interno ao salvar histórico: $e');
    }
  }

  Future<void> atualizarConsulta({
    required String idPesquisaAutocred,
    String? status,
    String? retornoBruto,
    Map<String, dynamic>? dadosTratados,
    String? arquivoPesquisaUrl,
  }) async {
    try {
      // Atualiza localmente
      final localItem = await localDao.buscarConsultaPorIdPesquisa(idPesquisaAutocred);
      if (localItem != null) {
        await localDao.inserirOuAtualizarConsulta(
          ConsultasAutocredCompanion.insert(
            id: localItem.id,
            vistoriaId: drift.Value(localItem.vistoriaId),
            placa: drift.Value(localItem.placa),
            chassi: drift.Value(localItem.chassi),
            motor: drift.Value(localItem.motor),
            codigoConsulta: localItem.codigoConsulta,
            idPesquisaAutocred: drift.Value(idPesquisaAutocred),
            status: status != null ? drift.Value(status) : drift.Value(localItem.status),
            retornoBruto: retornoBruto != null ? drift.Value(retornoBruto) : drift.Value(localItem.retornoBruto),
            dadosTratadosJson: dadosTratados != null ? drift.Value(jsonEncode(dadosTratados)) : drift.Value(localItem.dadosTratadosJson),
            arquivoPesquisaUrl: arquivoPesquisaUrl != null ? drift.Value(arquivoPesquisaUrl) : drift.Value(localItem.arquivoPesquisaUrl),
            createdAt: drift.Value(localItem.createdAt),
          )
        );
      }

      // Atualiza no Supabase
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (retornoBruto != null) updates['retorno_bruto'] = retornoBruto;
      if (dadosTratados != null) updates['dados_tratados'] = dadosTratados;
      if (arquivoPesquisaUrl != null) updates['arquivo_pesquisa_url'] = arquivoPesquisaUrl;

      if (updates.isEmpty) return;

      await supabase
          .from('autocred_consultas')
          .update(updates)
          .eq('id_pesquisa_autocred', idPesquisaAutocred)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      print('Erro no banco de dados ao atualizar consulta: ${e.message}');
      throw Exception('Erro no banco de dados. Contate o suporte. (${e.message})');
    } catch (e) {
      if (e is Exception && e.toString().contains('Usuário não autenticado')) {
        rethrow;
      }
      print('Erro ao atualizar consulta: $e');
      throw Exception('Erro interno ao atualizar histórico: $e');
    }
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoConsultas() async {
    try {
      // Busca do banco local (offline)
      final locais = await localDao.listarConsultas();
      return locais.map((c) {
        Map<String, dynamic> dados = {};
        if (c.dadosTratadosJson != null && c.dadosTratadosJson!.isNotEmpty) {
          try {
            dados = jsonDecode(c.dadosTratadosJson!);
          } catch (_) {}
        }
        return {
          'id': c.id,
          'vistoria_id': c.vistoriaId,
          'placa': c.placa,
          'chassi': c.chassi,
          'motor': c.motor,
          'codigo_consulta': c.codigoConsulta,
          'id_pesquisa_autocred': c.idPesquisaAutocred,
          'status': c.status,
          'retorno_bruto': c.retornoBruto,
          'dados_tratados': dados,
          'arquivo_pesquisa_url': c.arquivoPesquisaUrl,
          'created_at': c.createdAt.toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('Erro ao buscar histórico: $e');
      return [];
    }
  }
}
