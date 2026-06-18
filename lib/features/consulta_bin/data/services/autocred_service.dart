import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/autocred_xml_parser.dart';
import '../../domain/entities/autocred_veiculo.dart';
import '../../domain/entities/autocred_historico.dart';
import '../repositories/autocred_repository.dart';

class AutoCredService {
  final SupabaseClient supabase;
  final AutoCredRepository repository;

  AutoCredService({required this.supabase, required this.repository});

  void _checkError(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      throw Exception(data['error'] ?? 'Erro desconhecido na API');
    }
  }

  Future<AutoCredVeiculo> consultarVeiculo({
    required int codigoConsulta,
    required String tipoConsulta,
    required String valorConsulta,
    String vistoriaId = '',
  }) async {
    String idPesquisa = '';

    try {
      // 1. GERAR CONSULTA
      final resConsulta = await supabase.functions.invoke(
        'autocred-consulta',
        body: {
          'action': 'gerar_consulta',
          'tipoConsulta': tipoConsulta,
          'valorConsulta': valorConsulta,
          'codigoConsulta': codigoConsulta,
        },
      );

      _checkError(resConsulta.data);

      idPesquisa = resConsulta.data['idPesquisa'] as String;
      final xmlConsulta = resConsulta.data['rawXml'] as String;

      try {
        // Salva no banco de dados com status pendente
        await repository.salvarConsulta(
          vistoriaId: vistoriaId,
          placa: tipoConsulta == 'placa' ? valorConsulta : '',
          chassi: tipoConsulta == 'chassi' ? valorConsulta : '',
          motor: tipoConsulta == 'motor' ? valorConsulta : '',
          codigoConsulta: codigoConsulta,
          idPesquisaAutocred: idPesquisa,
          status: 'pendente',
          retornoBruto: xmlConsulta,
          dadosTratados: {},
        );
      } catch (e) {
        print('Falha não crítica ao salvar consulta inicial: $e');
      }

      // 2. OBTER RESULTADO (com polling)
      int maxTentativas = 15; // Aumentado para 15 tentativas (15 * 4s = 60s)
      int tentativas = 0;
      AutoCredVeiculo? veiculoFinal;
      String xmlResultadoFinal = '';

      while (tentativas < maxTentativas) {
        // Esperar alguns segundos antes de tentar (ou tentar novamente)
        await Future.delayed(const Duration(seconds: 4));

        final resResultado = await supabase.functions.invoke(
          'autocred-consulta',
          body: {
            'action': 'obter_resultado',
            'idPesquisa': idPesquisa,
          },
        );

        _checkError(resResultado.data);

        final xmlResultado = resResultado.data['xmlData'] as String;
        final veiculo = AutoCredXmlParser.parse(xmlResultado);

        // Se houver mensagem de erro (ex: saldo insuficiente), não precisamos fazer polling
        if (veiculo.dadosExtras['msgErro'] != null && veiculo.dadosExtras['msgErro']!.isNotEmpty) {
          throw Exception(veiculo.dadosExtras['msgErro']);
        }

        // Se encontrou a placa, a consulta terminou com sucesso
        if (veiculo.placa.isNotEmpty) {
          veiculoFinal = veiculo;
          xmlResultadoFinal = xmlResultado;
          break;
        }

        // Se não tem placa e não tem erro, pode ainda estar processando
        tentativas++;
        if (tentativas >= maxTentativas) {
          // Última tentativa falhou, vamos lançar erro ou usar o XML atual para debug
          throw Exception('A consulta demorou muito para responder ou não retornou dados. Tente novamente no histórico ou verifique se os dados estão corretos.\nRetorno bruto: \${xmlResultado.substring(0, xmlResultado.length < 100 ? xmlResultado.length : 100)}');
        }
      }

      if (veiculoFinal == null) {
        throw Exception('Falha inesperada ao obter resultado da consulta.');
      }

      final veiculo = veiculoFinal;
      final xmlResultado = xmlResultadoFinal;

      // 3. GERAR PDF
      String? urlPdf;
      try {
        final resPdf = await supabase.functions.invoke(
          'autocred-consulta',
          body: {
            'action': 'gerar_pdf',
            'idPesquisa': idPesquisa,
          },
        );
        
        if (resPdf.data is Map<String, dynamic> && !resPdf.data.containsKey('error')) {
          final xmlPdf = resPdf.data['xmlData'] as String;
          final veiculoPdf = AutoCredXmlParser.parse(xmlPdf);
          urlPdf = veiculoPdf.arquivoPesquisaUrl;
        }
      } catch (e) {
        print('Erro ao gerar PDF: $e');
        // Falhar no PDF não impede que a consulta continue
      }

      // Atualiza consulta no banco de dados
      try {
        await repository.atualizarConsulta(
          idPesquisaAutocred: idPesquisa,
          status: 'concluida',
          retornoBruto: xmlResultado,
          dadosTratados: {
            'placa': veiculo.placa,
            'chassi': veiculo.chassi,
            'motor': veiculo.motor,
            'marca': veiculo.marca,
            'modelo': veiculo.modelo,
            'anoFabricacao': veiculo.anoFabricacao,
            'anoModelo': veiculo.anoModelo,
            'cor': veiculo.cor,
          },
          arquivoPesquisaUrl: urlPdf,
        );
      } catch (e) {
        print('Falha não crítica ao atualizar consulta final: $e');
      }

      return AutoCredVeiculo(
        placa: veiculo.placa,
        chassi: veiculo.chassi,
        motor: veiculo.motor,
        marca: veiculo.marca,
        modelo: veiculo.modelo,
        anoFabricacao: veiculo.anoFabricacao,
        anoModelo: veiculo.anoModelo,
        cor: veiculo.cor,
        renavam: veiculo.renavam,
        municipio: veiculo.municipio,
        uf: veiculo.uf,
        restricoes: veiculo.restricoes,
        arquivoPesquisaUrl: urlPdf ?? veiculo.arquivoPesquisaUrl,
        dadosExtras: veiculo.dadosExtras,
      );
    } catch (e) {
      try {
        if (idPesquisa.isNotEmpty) {
          await repository.atualizarConsulta(
            idPesquisaAutocred: idPesquisa,
            status: 'erro',
            retornoBruto: e.toString(),
          );
        } else {
          await repository.salvarConsulta(
            vistoriaId: vistoriaId,
            placa: tipoConsulta == 'placa' ? valorConsulta : '',
            chassi: tipoConsulta == 'chassi' ? valorConsulta : '',
            motor: tipoConsulta == 'motor' ? valorConsulta : '',
            codigoConsulta: codigoConsulta,
            idPesquisaAutocred: '',
            status: 'erro',
            retornoBruto: e.toString(),
            dadosTratados: {},
          );
        }
      } catch (dbError) {
        print('Falha ao salvar erro no banco: $dbError');
      }
      
      String mensagemErro = e.toString();
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map) {
          if (details.containsKey('error')) {
            mensagemErro = details['error'].toString();
          } else if (details.containsKey('message')) {
            mensagemErro = details['message'].toString();
          }
          final rawDetails = details['details']?.toString() ?? '';
          if (rawDetails.contains('Timeout expired') || mensagemErro.contains('Timeout expired')) {
            mensagemErro = 'Servidor da AutoCredCar indisponível (Timeout). Tente novamente mais tarde.';
          }
        }
      }

      // Ajusta a mensagem de erro para o usuário
      if (mensagemErro.contains('Verifique credenciais')) {
        throw Exception('Usuário ou senha inválidos');
      } else if (mensagemErro.toLowerCase().contains('saldo')) {
        throw Exception('Saldo insuficiente');
      } else if (mensagemErro.contains('Timeout') || e.toString().contains('Timeout expired')) {
        throw Exception('Servidor da AutoCredCar indisponível (Timeout). Tente novamente mais tarde.');
      } else if (mensagemErro.contains('Invalid JWT') || mensagemErro.contains('UNAUTHORIZED')) {
        throw Exception('Sessão inválida. Por favor, faça login novamente.');
      }
      
      // Limpa os prefixos indesejados caso ainda existam
      mensagemErro = mensagemErro.replaceAll('Exception: ', '').replaceAll('Erro na consulta: ', '');
      throw Exception('Erro na consulta: $mensagemErro');
    }
  }

  Future<List<AutoCredHistorico>> getHistorico() async {
    final data = await repository.buscarHistoricoConsultas();
    return data.map((json) => AutoCredHistorico.fromJson(json)).toList();
  }
}
