import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/radar_veiculo.dart';
import '../../domain/entities/radar_historico.dart';
import '../../domain/radar_produtos.dart';
import '../repositories/radar_repository.dart';
import '../../../wallet/data/repositories/wallet_repository.dart';

class RadarService {
  final SupabaseClient supabase;
  final RadarRepository repository;

  static const String _radarUser = '20401';
  static const String _radarPassword = '*Ultra541';
  static const String _radarApiToken =
      '216A3AD5C8689671782240712MY1KQ6IY9693950QYFCEMEDUO';
  static const String _radarConsultarUrl =
      'https://www.radarconsultas.com.br/rdrv2/api/consultar';
  static const String _radarDetalhesUrl =
      'https://www.radarconsultas.com.br/rdrv2/api/consultas/detalhes';
  static const String _radarListUrl =
      'https://www.radarconsultas.com.br/rdrv2/api/consultas/list';
  static const String _radarSaldoUrl =
      'https://www.radarconsultas.com.br/rdrv2/api/saldo';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  RadarService({required this.supabase, required this.repository});

  WalletRepository? _getWalletRepository() {
    try {
      return GetIt.I<WalletRepository>();
    } catch (_) {
      return null;
    }
  }

  bool _deveConsultarDireto(String produto) {
    return true; // Sempre consulta diretamente a API da Radar via Dio com credenciais configuradas
  }

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
          .timeout(const Duration(seconds: 15));

      final data = response.data;
      if (data != null &&
          data is Map<String, dynamic> &&
          data['sucesso'] == true) {
        return data['consultas'] as List<dynamic>;
      }
    } catch (e) {
      print('Aviso: falha na edge function radar-listar-consultas: $e');
    }

    // Fallback direto para a API Radar
    try {
      final basicAuth =
          base64Encode(utf8.encode('$_radarUser:$_radarPassword'));
      final postData = <String, dynamic>{
        'page': '1',
        'forpage': '50',
      };
      if (param != null && value != null) {
        postData['param'] = param.toLowerCase();
        postData['value'] =
            value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      }

      final res = await _dio.post(
        _radarListUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'api-token': _radarApiToken,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.json,
        ),
        data: postData,
      );

      dynamic data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is Map && data['consultas'] is List) {
        final list = data['consultas'] as List;
        if (param != null && value != null) {
          final normVal =
              value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
          return list.where((c) {
            final cVal = (c['parametro_valor'] ?? '')
                .toString()
                .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                .toUpperCase();
            return cVal == normVal;
          }).toList();
        }
        return list;
      }
      return [];
    } catch (e) {
      print('Erro ao listar consultas direto da Radar: $e');
      return [];
    }
  }

  Future<List<dynamic>> listarConsultasAutocredNuvem() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await supabase
          .from('autocred_consultas')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      if (response == null || response is! List) return [];

      return response.map((row) {
        final Map<String, dynamic> c = row as Map<String, dynamic>;

        // Emular formato da Radar API para o ModalAtrelarPesquisa
        final status = c['status'] == 'concluida' ? '1' : '2';

        // O token original da Radar fica dentro do retorno_bruto
        String token = '';
        try {
          if (c['retorno_bruto'] != null && c['retorno_bruto'].toString().isNotEmpty) {
            final raw = jsonDecode(c['retorno_bruto']);
            if (raw is Map) {
              if (raw['consulta'] is Map && raw['consulta']['token'] != null) {
                token = raw['consulta']['token'].toString();
              } else if (raw['token-consulta'] != null) {
                token = raw['token-consulta'].toString();
              }
            }
          }
        } catch (_) {}

        String parametro = 'placa';
        String parametroValor = c['placa'] ?? '';
        if (parametroValor.isEmpty && c['chassi'] != null && c['chassi'].toString().isNotEmpty) {
          parametro = 'chassi';
          parametroValor = c['chassi'];
        } else if (parametroValor.isEmpty && c['motor'] != null && c['motor'].toString().isNotEmpty) {
          parametro = 'motor';
          parametroValor = c['motor'];
        }

        return {
          'status': status,
          'token': token,
          'parametro': parametro,
          'parametro_valor': parametroValor,
          'titulo': 'Pesquisa Autocred',
          'data_hora': c['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Erro ao buscar historico nuvem: $e');
      return [];
    }
  }

  static final Map<String, Future<RadarVeiculo>> _ongoingConsultas = {};

  Future<RadarVeiculo> consultarVeiculo({
    required String produto, // ex: "auto_bin", "bin_por_motor"
    required String param, // ex: "placa", "chassi", "motor"
    required String value, // ex: "ABC1234", "F1CE3481C7268924"
    String vistoriaId = '',
    int codigoConsulta = 0,
    bool forcarNova = false,
    String? tokenConsulta,
  }) async {
    final cacheKey = '${produto}_${param}_${value.toUpperCase()}';

    if (_ongoingConsultas.containsKey(cacheKey)) {
      print('>>> [TRAVA INTELIGENTE] Consulta já em andamento para $cacheKey. Prevenindo duplicidade!');
      return await _ongoingConsultas[cacheKey]!;
    }

    final future = _internalConsultarVeiculo(
      produto: produto,
      param: param,
      value: value,
      vistoriaId: vistoriaId,
      codigoConsulta: codigoConsulta,
      forcarNova: forcarNova,
      tokenConsulta: tokenConsulta,
    );
    _ongoingConsultas[cacheKey] = future;

    try {
      return await future;
    } finally {
      _ongoingConsultas.remove(cacheKey);
    }
  }

  Future<RadarVeiculo> _internalConsultarVeiculo({
    required String produto,
    required String param,
    required String value,
    String vistoriaId = '',
    int codigoConsulta = 0,
    bool forcarNova = false,
    String? tokenConsulta,
  }) async {
    final idPesquisa = const Uuid().v4();
    bool isReusingSearch = tokenConsulta != null;

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

      // Chama a Edge Function que agora é blindada por idempotência no backend
      int pollingAttempts = 0;
      bool isReusedBackend = false;

      while (true) {
        try {
          // Passamos a empresaId para a Edge Function poder compor a idempotency_key de forma segura
          final userResp = await supabase.auth.getUser();
          final userId = userResp.user?.id;
          String? empresaId;
          
          if (userId != null) {
            try {
               final profile = await supabase.from('profiles').select('empresa_id').eq('id', userId).maybeSingle();
               if (profile != null) {
                 empresaId = profile['empresa_id'];
               }
            } catch (_) {}
          }

          final bool isValidUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(vistoriaId);
          
          final response = await supabase.functions.invoke(
            'radar-consultar',
            body: {
              'vistoriaId': isValidUuid ? vistoriaId : null,
              'empresaId': empresaId?.isEmpty == true ? null : empresaId,
              'produto': produto,
              'param': param,
              'value': value,
              'forcarNova': isForcarNova,
              'tokenConsulta': currentToken,
              'aguardarRetorno': false,
              'idPesquisaClient': idPesquisa,
            },
          );

          isForcarNova = false;
          final data = response.data;
          
          if (data is Map<String, dynamic>) {
            if (data['sucesso'] == false) {
              final erroMsg = data['error']?.toString() ?? 'Erro desconhecido na Radar Consultas';
              throw Exception(erroMsg);
            }

            if (data['reused'] == true) {
               isReusedBackend = true;
               isReusingSearch = true;
            }

            if (data['emProcessamento'] == true) {
              currentToken = data['tokenConsulta'];
              
              // SALVAR O TOKEN IMEDIATAMENTE (Fail-safe contra crashes)
              if (currentToken != null) {
                await repository.atualizarConsulta(
                  idPesquisaRadar: idPesquisa,
                  status: 'pendente',
                  retornoBruto: jsonEncode({'consulta': {'token': currentToken}}),
                  dadosTratados: {},
                );
              }

              pollingAttempts++;
              if (pollingAttempts >= 12) {
                throw TimeoutException('A pesquisa está em andamento (token: ${currentToken ?? ""}). Ela continuará no Histórico.');
              }
              print('>>> STATUS RADAR: Processando... Aguardando 5s (tentativa $pollingAttempts)');
              await Future.delayed(const Duration(seconds: 5));
              continue; // Faz o polling usando o token
            }

            finalData = data;
            break;
          } else {
            throw Exception('Resposta inválida da API Radar (Backend).');
          }
        } catch (innerError) {
          String errStr = innerError.toString();
          if (innerError is FunctionException) {
            final details = innerError.details;
            if (details is Map && details.containsKey('error')) {
              errStr = details['error'].toString();
            }
          }

          bool isNetworkError = errStr.contains('SocketException') ||
              errStr.contains('Failed host lookup') ||
              innerError is TimeoutException ||
              errStr.toLowerCase().contains('timeout') ||
              errStr.contains('502') || errStr.contains('503') || errStr.contains('504');

          if (!isNetworkError) {
            rethrow;
          }

          if (currentToken == null) {
            throw Exception('Falha de conexão ao iniciar a pesquisa. Verifique sua internet.');
          } else {
             // Se já temos token, a internet caiu DURANTE o polling. Vamos abortar e deixar no histórico.
             throw TimeoutException('Conexão instável. A pesquisa continuará no Histórico.');
          }
        }
      }
      final parsed = finalData!['parsed'] as Map<String, dynamic>;
      final raw = finalData['raw'];

      final veiculo = RadarVeiculo.fromJson(parsed);

      final hasVehicleData = veiculo.placa.isNotEmpty ||
          veiculo.chassi.isNotEmpty ||
          veiculo.marcaModelo.isNotEmpty;

      final rawConsulta = raw is Map ? raw['consulta'] : null;
      final rawStatus = rawConsulta is Map ? rawConsulta['status'] : null;

      final bool isPendente = !hasVehicleData && rawStatus != 1;
      final String statusFinal = isPendente ? 'pendente' : 'concluida';

      await repository.atualizarConsulta(
        idPesquisaRadar: idPesquisa,
        status: statusFinal,
        retornoBruto: jsonEncode(raw),
        dadosTratados: parsed,
        arquivoPesquisaUrl: parsed['radar_pdf_url'],
      );

      // DÉBITO DA CARTEIRA REMOVIDO DO FRONTEND.
      // O débito agora é feito exclusivamente pela Edge Function de forma idempotente,
      // prevenindo race conditions ou falhas caso o app feche inesperadamente.
      print('>>> STATUS FINAL DA PESQUISA: $statusFinal');
      
      if (isReusedBackend) {
        print('>>> PESQUISA REAPROVEITADA. Removendo linha duplicada localmente para não sujar o histórico.');
        try {
          await repository.supabase
              .from('autocred_consultas')
              .delete()
              .eq('id_pesquisa_radar', idPesquisa);
        } catch (e) {}
      }

      if (isPendente) {
        throw TimeoutException(
          'A pesquisa foi aberta na Radar e está em análise técnica pelo Detran.\n\n⚠️ Atenção: NÃO realize uma nova pesquisa para evitar cobrança duplicada!\n\nVocê pode acompanhar pelo Histórico de Pesquisas assim que for liberada.',
        );
      }

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
          mensagemErro.contains('já está em andamento') ||
          mensagemErro.contains('análise técnica');

      if (isReusingSearch) {
        try {
          await repository.supabase
              .from('autocred_consultas')
              .delete()
              .eq('id_pesquisa_radar', idPesquisa);
        } catch (_) {}
      } else {
        await repository.atualizarConsulta(
          idPesquisaRadar: idPesquisa,
          status: isTimeout ? 'pendente' : 'erro',
          retornoBruto: e.toString(),
        );
      }

      if (isTimeout) {
        if (mensagemErro.contains('análise técnica')) {
          mensagemErro =
              'A pesquisa de motor foi aberta na Radar e está em análise técnica pelo Detran. Você pode acompanhar pelo histórico de pesquisas para carregar os dados assim que for concluída.';
        } else {
          mensagemErro =
              'A consulta está demorando muito para responder. Clique no relógio amarelo para puxar os dados.';
        }
        throw TimeoutException(mensagemErro);
      } else if (mensagemErro
              .contains('ClientSoftware caused connection abort') ||
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

  Future<Map<String, dynamic>> _consultarDiretoRadar({
    required String produto,
    required String param,
    required String value,
    bool forcarNova = false,
    String? tokenConsulta,
  }) async {
    final tokenProduto = RadarProdutos.catalogo[produto]?.token ??
        (produto.length >= 40 ? produto : null);

    if (tokenProduto == null && tokenConsulta == null) {
      throw Exception('Produto não encontrado no catálogo Radar: $produto');
    }

    final basicAuth = base64Encode(utf8.encode('$_radarUser:$_radarPassword'));
    final headers = {
      'Authorization': 'Basic $basicAuth',
      'api-token': _radarApiToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final normalizedParam = param.toLowerCase();
    final normalizedValue =
        value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

    String? currentToken = tokenConsulta;
    Map<String, dynamic>? finalData;
    bool isForcarNova = forcarNova;
    int retryCount = 0;
    int pollingAttempts = 0;

    while (true) {
      try {
        Response response;
        if (currentToken != null) {
          response = await _dio.post(
            _radarDetalhesUrl,
            options: Options(
              headers: headers,
              contentType: 'application/x-www-form-urlencoded',
              responseType: ResponseType.json,
            ),
            data: {
              'consulta': currentToken,
            },
          );
        } else {
          response = await _dio.post(
            _radarConsultarUrl,
            options: Options(
              headers: headers,
              contentType: 'application/x-www-form-urlencoded',
              responseType: ResponseType.json,
            ),
            data: {
              'produto': tokenProduto,
              'param': normalizedParam,
              'value': normalizedValue,
              'aguardar-retorno': 'true',
              if (isForcarNova) 'forcar-nova': 'true',
            },
          );
        }

        isForcarNova = false;
        retryCount = 0;

        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        if (data is! Map<String, dynamic>) {
          throw Exception('Resposta inválida da API Radar.');
        }

        if (data['erro'] != null) {
          final erroMsg = data['erro'].toString();
          if (erroMsg.contains('já está em andamento')) {
            await Future.delayed(const Duration(seconds: 10));
            continue;
          }
          throw Exception(erroMsg);
        }

        if (data['result'] == 0 && data['message'] != null) {
          final erroMsg = data['message'].toString();
          if (erroMsg.contains('já está em andamento')) {
            await Future.delayed(const Duration(seconds: 10));
            continue;
          }
          throw Exception(erroMsg);
        }

        // Checagem se ainda está em processamento (status 1 = concluído, status 2 = em análise técnica)
        final isPolling = currentToken != null;
        bool emProcessamento = false;

        final consulta = data['consulta'];
        final statusConsulta = consulta is Map ? consulta['status'] : null;
        final resultados = consulta is Map ? consulta['resultados'] : null;
        final bool hasResultadosProntos = resultados is List &&
            resultados.isNotEmpty &&
            resultados[0] is Map &&
            resultados[0]['view'] is Map &&
            resultados[0]['view']['full'] != null;

        if (isPolling) {
          // Se já tem resultados do módulo prontos (mesmo que o lote geral esteja status: 2), NÃO está em processamento!
          if (consulta == null) {
            emProcessamento = true;
          } else if (statusConsulta != 1 && !hasResultadosProntos) {
            emProcessamento = true;
          }
        } else {
          if (data['token-consulta'] != null) {
            emProcessamento = true;
            currentToken = data['token-consulta']?.toString();
          } else if (consulta is Map &&
              consulta['token'] != null &&
              statusConsulta != 1 &&
              !hasResultadosProntos) {
            emProcessamento = true;
            currentToken = consulta['token']?.toString();
          }
        }

        if (emProcessamento) {
          pollingAttempts++;
          final maxTentativas = isPolling ? 2 : 12;
          if (pollingAttempts > maxTentativas) {
            throw TimeoutException(
              'A pesquisa foi aberta na Radar e está em análise técnica pelo Detran. Você pode acompanhar pelo histórico de pesquisas assim que for concluída.',
            );
          }
          await Future.delayed(Duration(seconds: isPolling ? 2 : 5));
          continue;
        }

        finalData = data;
        break;
      } catch (innerError) {
        String errStr = innerError.toString();
        bool isNetworkError = errStr.contains('SocketException') ||
            errStr.contains('Failed host lookup') ||
            innerError is TimeoutException ||
            errStr.toLowerCase().contains('timeout') ||
            (innerError is DioException &&
                (innerError.type == DioExceptionType.connectionTimeout ||
                    innerError.type == DioExceptionType.receiveTimeout ||
                    innerError.type == DioExceptionType.connectionError));

        if (!isNetworkError) {
          rethrow;
        }

        retryCount++;
        if (retryCount > 5) {
          throw Exception(
              'Falha de conexão ao carregar a pesquisa. Tente novamente mais tarde.');
        }
        await Future.delayed(const Duration(seconds: 10));
      }
    }

    return await _extrairDadosRadar(finalData, param, value);
  }

  Future<Map<String, dynamic>> _extrairDadosRadar(
    Map<String, dynamic> data,
    String param,
    String value,
  ) async {
    Map<String, dynamic> resultData = {};
    List<dynamic> ipvaData = [];
    List<dynamic> multasData = [];
    List<dynamic> renajudData = [];

    final consulta = data['consulta'];
    final resultados = consulta is Map ? consulta['resultados'] : null;

    String avisoRetorno = '';

    if (resultados is List) {
      for (final item in resultados) {
        if (item is Map) {
          final retorno = item['retorno'];
          dynamic rData;
          if (retorno is Map) {
            rData = retorno['data'] is Map ? retorno['data'] : retorno;
          } else if (retorno is String && retorno.isNotEmpty && retorno != '1') {
            if (avisoRetorno.isEmpty) {
              avisoRetorno = retorno;
            }
          }

          if (rData is Map) {
            final rMap = Map<String, dynamic>.from(rData);
            if (rMap['placa'] != null && resultData['placa'] == null) {
              resultData = {...resultData, ...rMap};
            } else {
              resultData = {...rMap, ...resultData};
            }
            if (rMap['ipva'] is List) {
              ipvaData = rMap['ipva'];
            }
            if (rMap['multas'] is List) {
              multasData = rMap['multas'];
            }
            if (rMap['renajud'] is List) {
              renajudData = rMap['renajud'];
            }
          }
        }
      }
    } else {
      resultData = Map<String, dynamic>.from(data);
    }

    if (ipvaData.isNotEmpty) resultData['ipva'] = ipvaData;
    if (multasData.isNotEmpty) resultData['multas'] = multasData;
    if (renajudData.isNotEmpty) resultData['renajud'] = renajudData;
    resultData['resultados_completos'] = resultados;

    // URL do relatório em PDF da Radar:
    // Para pesquisa de motor (bin_por_motor), o módulo 0 é o relatório específico do motor
    // Para TODAS as pesquisas de veículos por placa/chassi (Auto Perícia HRF, Auto BIN, etc.),
    // a URL oficial completa é consulta['view']['full'], contendo todos os módulos!
    String radarPdfUrl = '';
    final bool isMotor = param.toLowerCase() == 'motor';

    if (isMotor &&
        resultados is List &&
        resultados.isNotEmpty &&
        resultados[0] is Map &&
        resultados[0]['view'] is Map &&
        resultados[0]['view']['full'] != null) {
      radarPdfUrl = resultados[0]['view']['full'].toString();
    } else if (consulta is Map &&
        consulta['view'] is Map &&
        consulta['view']['full'] != null) {
      radarPdfUrl = consulta['view']['full'].toString();
    } else if (resultados is List &&
        resultados.isNotEmpty &&
        resultados[0] is Map &&
        resultados[0]['view'] is Map &&
        resultados[0]['view']['full'] != null) {
      radarPdfUrl = resultados[0]['view']['full'].toString();
    }

    // Se o JSON não veio estruturado mas a página HTML do módulo já possui a tabela de dados, extrai direto do HTML
    if ((resultData['placa'] == null ||
            resultData['placa'].toString().trim().isEmpty) &&
        radarPdfUrl.isNotEmpty &&
        radarPdfUrl.startsWith('http')) {
      try {
        final res = await _dio.get<String>(
          radarPdfUrl,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
        final html = res.data ?? '';
        final matches = RegExp(
          r'<strong[^>]*>(.*?)<\/strong>\s*<\/td>\s*<td[^>]*>(.*?)<\/td>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(html);

        for (final m in matches) {
          final k = m
                  .group(1)
                  ?.replaceAll(RegExp(r'<[^<]+?>'), '')
                  .trim()
                  .toLowerCase() ??
              '';
          final v =
              m.group(2)?.replaceAll(RegExp(r'<[^<]+?>'), '').trim() ?? '';
          if (v.isEmpty || v.toLowerCase().contains('não informado')) continue;

          if (k.contains('placa') &&
              (resultData['placa'] == null ||
                  resultData['placa'].toString().isEmpty)) {
            resultData['placa'] = v;
          } else if (k.contains('chassi') &&
              (resultData['chassi'] == null ||
                  resultData['chassi'].toString().isEmpty)) {
            resultData['chassi'] = v;
          } else if (k.contains('marca') || k.contains('modelo')) {
            resultData['marcamodelo'] ??= v;
          } else if (k.contains('ano fabrica')) {
            resultData['anofabricacaoveiculo'] ??= v;
          } else if (k.contains('ano modelo')) {
            resultData['anomodeloveiculo'] ??= v;
          } else if (k.contains('cor')) {
            resultData['cor'] ??= v;
          } else if (k.contains('combust')) {
            resultData['combustivel'] ??= v;
          } else if (k.contains('munic')) {
            resultData['municipio'] ??= v;
          } else if (k == 'uf') {
            resultData['estado'] ??= v;
          } else if (k.contains('motor')) {
            resultData['numerodomotor'] ??= v;
          } else if (k.contains('espécie') || k.contains('especie')) {
            resultData['especie'] ??= v;
          } else if (k.contains('tipo')) {
            resultData['tipoveiculo'] ??= v;
          }
        }
      } catch (e) {
        print('Aviso ao extrair dados da tabela HTML da Radar: $e');
      }
    }

    final motorVal = resultData['numerodomotor']?.toString() ??
        resultData['motor']?.toString() ??
        (param.toLowerCase() == 'motor' ? value : '');

    final informacoesRelevantes =
        resultData['informacoesRelevantes']?.toString() ??
            resultData['informacoesrelevantes']?.toString() ??
            avisoRetorno;

    final parsed = {
      'placa': resultData['placa']?.toString() ??
          (param.toLowerCase() == 'placa' ? value : ''),
      'renavam': resultData['renavam']?.toString() ?? '',
      'chassi': resultData['chassi']?.toString() ??
          (param.toLowerCase() == 'chassi' ? value : ''),
      'anoFabricacao': resultData['anofabricacaoveiculo']?.toString() ??
          resultData['anofabricacao']?.toString() ??
          '',
      'anoModelo': resultData['anomodeloveiculo']?.toString() ??
          resultData['anomodelo']?.toString() ??
          '',
      'marcaModelo': resultData['marcamodelo']?.toString() ?? '',
      'cor': resultData['cor']?.toString() ?? '',
      'combustivel': resultData['combustivel']?.toString() ??
          resultData['tipocombustivel']?.toString() ??
          '',
      'tipoVeiculo': resultData['tipoveiculo']?.toString() ?? '',
      'especie': resultData['especie']?.toString() ?? '',
      'categoria': resultData['categoria']?.toString() ?? '',
      'motor': motorVal,
      'situacao': resultData['situacao']?.toString() ?? '',
      'municipio': resultData['municipio']?.toString() ?? '',
      'estado': resultData['estado']?.toString() ??
          resultData['uf']?.toString() ??
          '',
      'proprietario': resultData['nomeproprietario']?.toString() ??
          resultData['proprietario']?.toString() ??
          '',
      'documentoProprietario':
          resultData['documentoproprietario']?.toString() ?? '',
      'restricoes1': resultData['restricoes1']?.toString() ?? '',
      'restricoes2': resultData['restricoes2']?.toString() ?? '',
      'restricoes3': resultData['restricoes3']?.toString() ?? '',
      'restricoes4': resultData['restricoes4']?.toString() ?? '',
      'informacoesRelevantes': informacoesRelevantes,
      'ipva': ipvaData,
      'multas': multasData,
      'renajud': renajudData,
      'radar_pdf_url': radarPdfUrl,
      'resultadoCompleto': resultData,
    };

    return {
      'raw': data,
      'parsed': parsed,
    };
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
    } catch (_) {}

    try {
      final basicAuth =
          base64Encode(utf8.encode('$_radarUser:$_radarPassword'));
      final res = await _dio.post(
        _radarSaldoUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'api-token': _radarApiToken,
          },
          responseType: ResponseType.json,
        ),
      );
      if (res.data is Map && res.data['saldo'] != null) {
        return res.data['saldo'].toString();
      }
    } catch (_) {}

    return 'Indisponível';
  }
}
