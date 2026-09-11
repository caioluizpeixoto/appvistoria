import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../database/app_database.dart';
import '../../../../database/daos/autocred_dao.dart';

class RadarRepository {
  final SupabaseClient supabase;
  final AutocredDao localDao;

  RadarRepository({required this.supabase, required this.localDao});

  Future<void> salvarConsulta({
    String? vistoriaId,
    required String placa,
    String? chassi,
    String? motor,
    required int codigoConsulta,
    required String idPesquisaRadar,
    required String status,
    required String retornoBruto,
    required Map<String, dynamic> dadosTratados,
    String? arquivoPesquisaUrl,
  }) async {
    try {
      // Salvamento local (offline first) usando a mesma tabela de consultas
      final localId = const Uuid().v4();

      await localDao
          .inserirOuAtualizarConsulta(ConsultasAutocredCompanion.insert(
        id: localId,
        vistoriaId: drift.Value(vistoriaId),
        placa: drift.Value(placa),
        chassi: drift.Value(chassi),
        motor: drift.Value(motor),
        codigoConsulta: codigoConsulta,
        idPesquisaAutocred: drift.Value(idPesquisaRadar),
        status: drift.Value(status),
        retornoBruto: drift.Value(retornoBruto),
        dadosTratadosJson: drift.Value(jsonEncode(dadosTratados)),
        arquivoPesquisaUrl: drift.Value(arquivoPesquisaUrl),
      ));

      // Salvamento na nuvem (Supabase)
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      final isUuid = vistoriaId != null &&
          RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
              .hasMatch(vistoriaId);

      try {
        await supabase.from('autocred_consultas').insert({
          'vistoria_id': isUuid ? vistoriaId : null,
          'user_id': userId,
          'placa': placa,
          'chassi': chassi,
          'motor': motor,
          'codigo_consulta': codigoConsulta,
          'id_pesquisa_autocred': idPesquisaRadar,
          'status': status,
          'retorno_bruto': retornoBruto,
          'dados_tratados': dadosTratados,
          if (arquivoPesquisaUrl != null)
            'arquivo_pesquisa_url': arquivoPesquisaUrl,
        });
      } catch (cloudError) {
        print('Erro ao salvar no supabase (ignorado): $cloudError');
      }
    } catch (e) {
      print('Erro ao salvar histórico de consulta: $e');
      throw Exception('Erro interno ao salvar histórico: $e');
    }
  }

  Future<void> atualizarConsulta({
    required String idPesquisaRadar,
    String? status,
    String? retornoBruto,
    Map<String, dynamic>? dadosTratados,
    String? arquivoPesquisaUrl,
  }) async {
    try {
      // Atualiza localmente
      final localItem =
          await localDao.buscarConsultaPorIdPesquisa(idPesquisaRadar);
      if (localItem != null) {
        await localDao
            .inserirOuAtualizarConsulta(ConsultasAutocredCompanion.insert(
          id: localItem.id,
          vistoriaId: drift.Value(localItem.vistoriaId),
          placa: drift.Value(localItem.placa),
          chassi: drift.Value(localItem.chassi),
          motor: drift.Value(localItem.motor),
          codigoConsulta: localItem.codigoConsulta,
          idPesquisaAutocred: drift.Value(idPesquisaRadar),
          status: status != null
              ? drift.Value(status)
              : drift.Value(localItem.status),
          retornoBruto: retornoBruto != null
              ? drift.Value(retornoBruto)
              : drift.Value(localItem.retornoBruto),
          dadosTratadosJson: dadosTratados != null
              ? drift.Value(jsonEncode(dadosTratados))
              : drift.Value(localItem.dadosTratadosJson),
          arquivoPesquisaUrl: arquivoPesquisaUrl != null
              ? drift.Value(arquivoPesquisaUrl)
              : drift.Value(localItem.arquivoPesquisaUrl),
          createdAt: drift.Value(localItem.createdAt),
        ));
      }

      // Atualiza no Supabase
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (retornoBruto != null) updates['retorno_bruto'] = retornoBruto;
      if (dadosTratados != null) updates['dados_tratados'] = dadosTratados;
      if (arquivoPesquisaUrl != null)
        updates['arquivo_pesquisa_url'] = arquivoPesquisaUrl;

      if (updates.isEmpty) return;

      try {
        await supabase
            .from('autocred_consultas')
            .update(updates)
            .eq('id_pesquisa_autocred', idPesquisaRadar)
            .eq('user_id', userId);
      } catch (cloudError) {
        print('Erro ao atualizar no supabase (ignorado): $cloudError');
      }
    } catch (e) {
      print('Erro ao atualizar consulta: $e');
      throw Exception('Erro interno ao atualizar histórico: $e');
    }
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoConsultas() async {
    try {
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
          'id_pesquisa_radar': c.idPesquisaAutocred,
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

  Future<List<Map<String, dynamic>>> buscarConsultasRecentesNuvem(
      String coluna, String valor) async {
    final lista = <Map<String, dynamic>>[];
    final valorLimpo = valor.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final valorOriginal = valor.trim().toUpperCase();

    // 1. Busca no banco local (Drift/SQLite)
    try {
      ConsultasAutocredData? local;
      if (coluna == 'placa') {
        local = await localDao.buscarConsultaPorPlaca(valorLimpo);
      } else if (coluna == 'chassi') {
        local = await localDao.buscarConsultaPorChassi(valorLimpo);
      } else if (coluna == 'motor') {
        local = await localDao.buscarConsultaPorMotor(valorLimpo);
      }

      if (local != null && local.dadosTratadosJson != null && local.dadosTratadosJson!.isNotEmpty) {
        try {
          final dados = jsonDecode(local.dadosTratadosJson!);
          lista.add({
            'id': local.id,
            'vistoria_id': local.vistoriaId,
            'placa': local.placa,
            'chassi': local.chassi,
            'motor': local.motor,
            'status': local.status,
            'dados_tratados': dados,
            'arquivo_pesquisa_url': local.arquivoPesquisaUrl,
            'created_at': local.createdAt.toIso8601String(),
            'fonte': 'local',
          });
        } catch (_) {}
      }
    } catch (e) {
      print('Erro ao buscar consulta local: $e');
    }

    // 2. Busca na Nuvem (Supabase)
    try {
      var query = supabase
          .from('autocred_consultas')
          .select()
          .not('dados_tratados', 'is', null);

      if (coluna == 'placa') {
        final comTraco = valorLimpo.length == 7
            ? '${valorLimpo.substring(0, 3)}-${valorLimpo.substring(3)}'
            : valorLimpo;
        query = query.or('placa.ilike.$valorLimpo,placa.ilike.$comTraco,placa.ilike.$valorOriginal');
      } else {
        query = query.ilike(coluna, '%$valorLimpo%');
      }

      final response = await query.order('created_at', ascending: false).limit(10);

      if (response != null && response is List) {
        for (var item in response) {
          final jaExiste = lista.any((l) =>
              (l['id_pesquisa_radar'] != null && l['id_pesquisa_radar'] == item['id_pesquisa_autocred']) ||
              l['id'] == item['id']);
          if (!jaExiste) {
            lista.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar nuvem: $e');
    }

    return lista;
  }

  Future<bool> existeConsultaPendente(String coluna, String valor) async {
    try {
      final response = await supabase
          .from('autocred_consultas')
          .select()
          .eq(coluna, valor)
          .eq('status', 'pendente')
          .order('created_at', ascending: false)
          .limit(1);

      if (response != null && response is List && response.isNotEmpty) {
        final createdAt = DateTime.parse(response.first['created_at'].toString());
        final now = DateTime.now();
        if (now.difference(createdAt).inMinutes < 5) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erro ao verificar consultas pendentes: $e');
      return false;
    }
  }
}

