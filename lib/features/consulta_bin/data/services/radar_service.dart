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
          .timeout(const Duration(
              minutes: 10)); // Usando um timeout de 10 min, igual ao consultar

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

      final response = await supabase.functions.invoke(
        'radar-consultar',
        body: {
          'produto': produto,
          'param': param,
          'value': value,
          'forcarNova': forcarNova,
          'tokenConsulta': tokenConsulta,
        },
      ).timeout(const Duration(minutes: 35));

      if (response.data is Map<String, dynamic> &&
          response.data['sucesso'] == false) {
        throw Exception(
            response.data['error'] ?? 'Erro desconhecido na Radar Consultas');
      }

      final data = response.data;
      final parsed = data['parsed'] as Map<String, dynamic>;
      final raw = data['raw'];

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
      await repository.atualizarConsulta(
        idPesquisaRadar: idPesquisa,
        status: 'erro',
        retornoBruto: e.toString(),
      );

      String mensagemErro = e.toString();

      if (e is TimeoutException) {
        mensagemErro =
            'A consulta demorou muito para responder. Verifique sua conexão ou tente novamente.';
      } else if (mensagemErro
              .contains('ClientSoftware caused connection abort') ||
          mensagemErro.contains('SocketException') ||
          mensagemErro.contains('Failed host lookup')) {
        mensagemErro =
            'Falha de conexão. Verifique sua internet e tente novamente.';
      } else if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details.containsKey('error')) {
          mensagemErro = details['error'].toString();
        }
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
