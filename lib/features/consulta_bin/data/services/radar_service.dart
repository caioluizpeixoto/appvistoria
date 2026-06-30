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

  Future<RadarVeiculo> consultarVeiculo({
    required String produto, // ex: "auto_bin"
    required String param,   // ex: "placa", "chassi"
    required String value,   // ex: "ABC1234"
    String vistoriaId = '',
    int codigoConsulta = 0,
    bool forcarNova = false,
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
        },
      ).timeout(const Duration(minutes: 15));

      if (response.data is Map<String, dynamic> && response.data['sucesso'] == false) {
        throw Exception(response.data['error'] ?? 'Erro desconhecido na Radar Consultas');
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
        mensagemErro = 'A consulta demorou muito para responder. Verifique sua conexão ou tente novamente.';
      } else if (mensagemErro.contains('ClientSoftware caused connection abort') || 
                 mensagemErro.contains('SocketException') || 
                 mensagemErro.contains('Failed host lookup')) {
        mensagemErro = 'Falha de conexão. Verifique sua internet e tente novamente.';
      } else if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details.containsKey('error')) {
          mensagemErro = details['error'].toString();
        }
      } else {
        mensagemErro = mensagemErro.replaceAll('Exception: ', '').replaceAll('Erro na consulta: ', '');
      }

      throw Exception(mensagemErro);
    }
  }

  Future<List<RadarHistorico>> getHistorico() async {
    final data = await repository.buscarHistoricoConsultas();
    return data.map((json) => RadarHistorico.fromJson(json)).toList();
  }
}
