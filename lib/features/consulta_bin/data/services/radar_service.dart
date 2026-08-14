import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/radar_veiculo.dart';
import '../../domain/entities/radar_historico.dart';
import '../repositories/radar_repository.dart';

class RadarService {
  final SupabaseClient supabase;
  final RadarRepository repository;

  RadarService({required this.supabase, required this.repository});

  Future<List<dynamic>> listarConsultasRadar({
    String? produto,
    String? param,
    String? value,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (param != null && value != null) {
        body['param'] = param;
        body['value'] = value;
        if (produto != null) {
          body['produto'] = produto;
        }
      }

      final response = await supabase.functions
          .invoke('radar-listar-consultas', body: body)
          .timeout(const Duration(seconds: 5));

      final data = response.data;
      if (data != null &&
          data is Map<String, dynamic> &&
          data['sucesso'] == true) {
        return data['consultas'] as List<dynamic>;
      } else {
        print('Erro na Radar (API não retornou sucesso): $data');
        return [];
      }
    } catch (e) {
      print('Erro ao listar consultas da Radar: $e');
      return [];
    }
  }

  Future<RadarVeiculo> consultarVeiculo({
    required String produto, // ex: "auto_bin"
    required String param, // ex: "placa", "chassi"
    required String value, // ex: "ABC1234"
    String vistoriaId = '',
    int codigoConsulta = 0,
    bool forcarNova = false,
    String? tokenConsulta,
  }) async {
    final idPesquisa = const Uuid().v4();

    try {
      await repository.salvarConsulta(
        vistoriaId: vistoriaId,
        placa: param == 'placa' ? value : '',
        chassi: param == 'chassi' ? value : '',
        motor: param == 'motor' ? value : '',
        codigoConsulta: codigoConsulta,
        idPesquisaRadar: idPesquisa,
        status: 'pendente',
        retornoBruto: 'Consultando Radar...',
        dadosTratados: {},
      );

      String? currentToken = tokenConsulta;
      Map<String, dynamic>? finalData;
      bool isForcarNova = forcarNova;
      int retryCount = 0;

      while (true) {
        try {
          final response = await supabase.functions.invoke(
            'radar-consultar',
            body: {
              'produto': produto,
              'param': param,
              'value': value,
              'forcarNova': isForcarNova,
              'tokenConsulta': currentToken,
              'aguardarRetorno': false,
            },
          );

          isForcarNova = false;
          retryCount = 0;

          final data = response.data;
          if (data is Map<String, dynamic>) {
            if (data['sucesso'] == false) {
              final erroMsg = data['error']?.toString() ?? 'Erro desconhecido na Radar Consultas';
              if (erroMsg.contains('já está em andamento')) {
                // Ao invés de morrer, continua aguardando
                await Future.delayed(const Duration(seconds: 10));
                continue;
              }
              throw Exception(erroMsg);
            }

            if (data['emProcessamento'] == true) {
              currentToken = data['tokenConsulta'];
              await Future.delayed(const Duration(seconds: 10)); // Consulta a cada 10s
              continue;
            }

            finalData = data;
            break;
          } else {
            throw Exception('Resposta inválida da API Radar.');
          }
        } catch (innerError) {
          String errStr = innerError.toString();
          if (innerError is FunctionException) {
            final details = innerError.details;
            if (details is Map && details.containsKey('error')) {
              errStr = details['error'].toString();
            }
          }
          
          bool isNetworkError = errStr.contains('ClientSoftware caused connection abort') ||
                                errStr.contains('SocketException') ||
                                errStr.contains('Failed host lookup') ||
                                innerError is TimeoutException ||
                                errStr.toLowerCase().contains('timeout') ||
                                errStr.contains('502') ||
                                errStr.contains('503') ||
                                errStr.contains('504') ||
                                errStr.contains('Relay Error') ||
                                errStr.contains('upstream request');
                                
          if (!isNetworkError) {
             rethrow; 
          }
          
          retryCount++;
          if (currentToken == null && retryCount > 5) {
             throw Exception('Falha de conexão ao iniciar a pesquisa. Verifique sua internet e tente novamente.');
          }
          // Se currentToken != null, mantemos consultando indefinidamente pois está em processamento no backend.
          await Future.delayed(const Duration(seconds: 10));
        }
      }

      final parsed = finalData!['parsed'] as Map<String, dynamic>;
      final raw = finalData['raw'];

      final veiculo = RadarVeiculo.fromJson(parsed);

      await repository.atualizarConsulta(
        idPesquisaRadar: idPesquisa,
        status: 'concluida',
        retornoBruto: jsonEncode(raw),
        dadosTratados: parsed,
        arquivoPesquisaUrl: parsed['radar_pdf_url'],
      );

      return veiculo;
    } catch (e) {
      String mensagemErro = e.toString();
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details.containsKey('error')) {
          mensagemErro = details['error'].toString();
        }
      }

      bool isTimeout = e is TimeoutException ||
          mensagemErro.toLowerCase().contains('timeout') ||
          mensagemErro.contains('504') ||
          mensagemErro.contains('503') ||
          mensagemErro.contains('já está em andamento');

      await repository.atualizarConsulta(
        idPesquisaRadar: idPesquisa,
        status: isTimeout ? 'timeout' : 'erro',
        retornoBruto: e.toString(),
      );

      if (isTimeout) {
        mensagemErro =
            'A consulta está demorando muito para responder. Clique no relógio amarelo para puxar os dados.';
        throw TimeoutException(mensagemErro);
      } else if (mensagemErro.contains('ClientSoftware caused connection abort') ||
          mensagemErro.contains('SocketException') ||
          mensagemErro.contains('Failed host lookup')) {
        mensagemErro =
            'Falha de conexão. Verifique sua internet e tente novamente.';
      } else {
        mensagemErro = mensagemErro
            .replaceAll('Exception: ', '')
            .replaceAll('Erro na consulta: ', '');
      }

      throw Exception(mensagemErro);
    }
  }

  Future<List<RadarHistorico>> getHistorico() async {
    final data = await repository.buscarHistoricoConsultas();
    return data.map((json) => RadarHistorico.fromJson(json)).toList();
  }

  Future<String> consultarSaldo() async {
    try {
      final response = await supabase.functions.invoke('radar-saldo');
      if (response.data is Map<String, dynamic> &&
          response.data['sucesso'] == true) {
        return response.data['saldo'].toString();
      }
      return 'Indisponível';
    } catch (e) {
      return 'Erro';
    }
  }
}
