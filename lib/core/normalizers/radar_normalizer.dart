import 'dart:convert';
import 'radar_normalized_data.dart';

class RadarNormalizer {
  static const Map<String, List<String>> TITLE_ALIASES = {
    'ssp': ['SSP Online', 'SSP - Cortesia'],
    'ipva': ['IPVA (SEFAZ)', 'IPVA - Secretaria de Fazenda'],
    'dividasAtivas': ['Dividas Ativas', 'Dívidas Ativas'],
    'baseEstadual': ['Base Estadual **', 'Base Estadual'],
    'rouboFurto': ['Histórico Roubo e Furto *', 'Histórico Roubo e Furto'],
    'decodificador': ['Decodificador de Chassi'],
    'recall': ['Recall'],
    'comunicadoVenda': ['Comunicado de Venda - Online'],
    'sinistro': [
      'Base Histórica de Indício de Sinistro',
      'Sinistro - Base On-line'
    ],
    'leilao': [
      'Ofertas de Leilão',
      'Ofertas de Leilão *',
      'Leilão Corporativo - Remarketing Automotivo / Venda Direta (Cortesia)'
    ],
    'bin': ['Bin **', 'Bin'],
  };

  static String _normalizeTitle(String title) {
    return title.trim().toLowerCase();
  }

  static String? _findAlias(String originalTitle) {
    final normTitle = _normalizeTitle(originalTitle);
    for (final entry in TITLE_ALIASES.entries) {
      for (final alias in entry.value) {
        if (_normalizeTitle(alias) == normTitle) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static dynamic _firstValid(List<dynamic> values) {
    for (var v in values) {
      if (v != null && v != '' && v != 'Não informado' && v != 'Não Informado') {
        return v;
      }
    }
    return null;
  }

  static RadarModuleStatus _classifyValue(dynamic value) {
    if (value == null || value == '') {
      return RadarModuleStatus.sem_informacao;
    }
    if (value is List && value.isEmpty) {
      return RadarModuleStatus.nada_consta;
    }
    if (value is String) {
      final t = value.toLowerCase();
      if (t.contains('houve um erro') ||
          t.contains('serialize não encontrada') ||
          t.contains('indisponível')) {
        return RadarModuleStatus.erro;
      }
      if (t.contains('nada consta') ||
          t.contains('não possui') ||
          t.contains('não possuí')) {
        return RadarModuleStatus.nada_consta;
      }
    }
    return RadarModuleStatus.preenchido;
  }

  static bool _isPlainObject(dynamic value) {
    return value != null && value is Map && value is! List;
  }

  static RadarNormalizedData parse(String jsonString) {
    Map<String, dynamic> raw;
    try {
      raw = jsonDecode(jsonString);
    } catch (e) {
      // JSON Inválido
      return _buildEmptyData(
        erros: [RadarError(modulo: 'Geral', mensagem: 'JSON inválido', fonte: 'API')],
        rawJson: {},
      );
    }

    final resultados = _extractResultados(raw);
    
    final Map<String, dynamic> modulos = {};
    for (var r in resultados) {
      if (r is! Map) continue;
      final title = r['title']?.toString() ?? '';
      final alias = _findAlias(title) ?? title;
      modulos[alias] = r;
    }

    final veiculo = _extractVeiculo(modulos);
    final proprietario = _extractProprietario(modulos);
    final ipva = _extractIpva(modulos);
    final multas = _extractMultas(modulos);
    final restricoes = _extractRestricoes(modulos);
    final rouboFurto = _extractRouboFurto(modulos);
    final licenciamentos = _extractLicenciamentos(modulos);
    final vistorias = _extractVistorias(modulos);

    final recall = _extractGenericModule(modulos, 'recall');
    final comunicacaoVenda = _extractGenericModule(modulos, 'comunicadoVenda');
    final sinistros = _extractGenericList(modulos, 'sinistro');
    final leiloes = _extractGenericList(modulos, 'leilao');
    final dividasAtivas = _extractGenericList(modulos, 'dividasAtivas');

    final List<RadarError> erros = [];
    for (var entry in modulos.entries) {
      final r = entry.value;
      if (r['retorno'] is String) {
        final status = _classifyValue(r['retorno']);
        if (status == RadarModuleStatus.erro) {
          erros.add(RadarError(
            modulo: entry.key, 
            mensagem: r['retorno'], 
            fonte: r['title'] ?? '',
          ));
        }
      }
    }

    return RadarNormalizedData(
      rawJson: raw,
      veiculo: veiculo,
      proprietario: proprietario,
      multas: multas,
      ipva: ipva,
      licenciamentos: licenciamentos,
      vistorias: vistorias,
      restricoes: restricoes,
      rouboFurto: rouboFurto,
      comunicacaoVenda: comunicacaoVenda,
      recall: recall,
      sinistros: sinistros,
      leiloes: leiloes,
      dividasAtivas: dividasAtivas,
      erros: erros,
    );
  }

  static List<dynamic> _extractResultados(Map<String, dynamic> raw) {
    if (raw['consulta'] != null && raw['consulta']['resultados'] is List) {
      return raw['consulta']['resultados'];
    }
    if (raw['resultados_completos'] is List) {
      return raw['resultados_completos'];
    }
    if (raw['resultadoCompleto'] != null && raw['resultadoCompleto']['resultados_completos'] is List) {
      return raw['resultadoCompleto']['resultados_completos'];
    }
    return [];
  }

  // --- Extrações de Módulos Específicos ---

  static VeiculoData _extractVeiculo(Map<String, dynamic> modulos) {
    final sources = [
      _getRetorno(modulos['bin']),
      _getRetorno(modulos['baseEstadual']),
      _getRetorno(modulos['decodificador']),
      _getRetorno(modulos['ssp']),
    ];

    String placa = '';
    String chassi = '';
    String renavam = '';
    String marcaModelo = '';
    String cor = '';
    String anoFabricacao = '';
    String anoModelo = '';
    String municipio = '';
    String uf = '';
    String motor = '';
    String tipo = '';
    String combustivel = '';
    String especie = '';
    String categoria = '';
    String capacidadePassageiros = '';
    String potencia = '';
    String cilindradas = '';
    String situacao = '';
    String dataEmissaoCrlv = '';

    for (var s in sources) {
      if (s == null) continue;
      
      placa = _firstValid([
        placa,
        s['placa'],
        s['Placa'],
        s['data']?['placa'],
        s['data']?['Placa'],
        s['dadosVeiculo']?['placa'],
        s['dadosVeiculo']?['Placa'],
        s['Dados Veículo']?['data']?['placa'],
        s['Dados Veículo']?['data']?['Placa']
      ])?.toString() ?? placa;

      renavam = _firstValid([
        renavam,
        s['renavam'],
        s['Renavam'],
        s['codigoRenavam'],
        s['data']?['renavam'],
        s['data']?['codigoRenavam'],
        s['Dados Veículo']?['data']?['Renavam']
      ])?.toString() ?? renavam;

      chassi = _firstValid([
        chassi,
        s['chassi'],
        s['Chassi'],
        s['data']?['chassi'],
        s['data']?['Chassi'],
        s['dadosVeiculo']?['chassi'],
        s['Dados Veículo']?['data']?['Chassi']
      ])?.toString() ?? chassi;

      marcaModelo = _firstValid([
        marcaModelo,
        s['marcaModelo'],
        s['marcamodelo'],
        s['marca'],
        s['modelo'],
        s['data']?['marcaModelo']?['descricao'],
        s['data']?['marcamodelo'],
        s['dadosVeiculo']?['veiculo'],
        s['dadosVeiculo']?['marca'],
        s['Dados Veículo']?['data']?['Marca / Modelo']
      ])?.toString() ?? marcaModelo;
      
      cor = _firstValid([
        cor, s['cor'], s['Cor'], s['data']?['cor'], s['Dados Veículo']?['data']?['Cor']
      ])?.toString() ?? cor;

      anoFabricacao = _firstValid([
        anoFabricacao, s['anoFabricacao'], s['anofabricacao'], s['anofabricacaoveiculo'], s['Dados Veículo']?['data']?['Ano Fabricação']
      ])?.toString() ?? anoFabricacao;

      anoModelo = _firstValid([
        anoModelo, s['anoModelo'], s['anomodelo'], s['anomodeloveiculo'], s['Dados Veículo']?['data']?['Ano Modelo']
      ])?.toString() ?? anoModelo;
      
      municipio = _firstValid([
        municipio, s['municipio'], s['municipioEmplacamento'], s['Dados Veículo']?['data']?['Município']
      ])?.toString() ?? municipio;
      
      uf = _firstValid([
        uf, s['uf'], s['estado'], s['ufJurisdicao'], s['Dados Veículo']?['data']?['UF']
      ])?.toString() ?? uf;
      
      motor = _firstValid([
        motor, s['motor'], s['numerodomotor'], s['Dados Veículo']?['data']?['Motor']
      ])?.toString() ?? motor;

      tipo = _firstValid([
        tipo, s['tipoVeiculo'], s['tipoveiculo'], s['Dados Veículo']?['data']?['Tipo Veículo']
      ])?.toString() ?? tipo;

      combustivel = _firstValid([
        combustivel, s['combustivel'], s['tipocombustivel'], s['Dados Veículo']?['data']?['Combustível']
      ])?.toString() ?? combustivel;

      especie = _firstValid([
        especie, s['especie'], s['Dados Veículo']?['data']?['Espécie']
      ])?.toString() ?? especie;

      categoria = _firstValid([
        categoria, s['categoria'], s['Dados Veículo']?['data']?['Categoria']
      ])?.toString() ?? categoria;
      
      situacao = _firstValid([
        situacao, s['situacao'], s['Dados Veículo']?['data']?['Situação']
      ])?.toString() ?? situacao;
      
      potencia = _firstValid([
        potencia, s['potencia'], s['Dados Veículo']?['data']?['Potência']
      ])?.toString() ?? potencia;

      cilindradas = _firstValid([
        cilindradas, s['cilindradas'], s['Dados Veículo']?['data']?['Cilindradas']
      ])?.toString() ?? cilindradas;
      
      capacidadePassageiros = _firstValid([
        capacidadePassageiros, s['lotacao'], s['capacidadePassageiros'], s['Dados Veículo']?['data']?['Capacidade de passageiros']
      ])?.toString() ?? capacidadePassageiros;
      
      dataEmissaoCrlv = _firstValid([
        dataEmissaoCrlv, s['dataEmissaoCrlv'], s['dataEmissaoCrvl'], s['Dados Veículo']?['data']?['Data de Emissão do CRLV'], s['emissaoCrlv']
      ])?.toString() ?? dataEmissaoCrlv;
    }

    return VeiculoData(
      placa: placa,
      chassi: chassi,
      renavam: renavam,
      marcaModelo: marcaModelo,
      cor: cor,
      anoFabricacao: anoFabricacao,
      anoModelo: anoModelo,
      municipio: municipio,
      uf: uf,
      motor: motor,
      tipo: tipo,
      combustivel: combustivel,
      especie: especie,
      categoria: categoria,
      situacao: situacao,
      potencia: potencia,
      cilindradas: cilindradas,
      capacidadePassageiros: capacidadePassageiros,
      dataEmissaoCrlv: dataEmissaoCrlv,
    );
  }

  static ProprietarioData _extractProprietario(Map<String, dynamic> modulos) {
    final s = _getRetorno(modulos['bin']) ?? _getRetorno(modulos['baseEstadual']);
    if (s == null) return ProprietarioData();
    return ProprietarioData(
      nome: _firstValid([s['nomeProprietario'], s['nomeproprietario'], s['proprietario']])?.toString() ?? '',
      documento: _firstValid([s['documentoProprietario'], s['numeroIdentificacaoProprietario']])?.toString() ?? '',
      municipio: _firstValid([s['municipio']])?.toString() ?? '',
      uf: _firstValid([s['uf'], s['estado']])?.toString() ?? '',
    );
  }

  static RadarModule<List<IpvaData>> _extractIpva(Map<String, dynamic> modulos) {
    final mod = modulos['ipva'] ?? modulos['ssp'];
    if (mod == null) return _emptyModule('ipva');

    final r = _getRetorno(mod);
    if (r == null) {
      if (mod['retorno'] is String) {
        final status = _classifyValue(mod['retorno']);
        return RadarModule(modulo: 'ipva', status: status, mensagem: mod['retorno'], fonte: mod['title']);
      }
      return _emptyModule('ipva');
    }

    List<dynamic> ipvaRaw = [];
    if (r['ipva'] is List) {
      ipvaRaw = r['ipva'];
    } else if (r['IPVA']?['data'] is List) {
      ipvaRaw = r['IPVA']['data'];
    } else if (mod['title']?.toString().toLowerCase().contains('ipva') == true) {
      // It might be a direct object if it's not a list, but user says array
    }

    if (ipvaRaw.isEmpty) {
      return RadarModule(modulo: 'ipva', status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);
    }

    final List<IpvaData> result = [];
    for (var item in ipvaRaw) {
      if (item is Map) {
         result.add(IpvaData(
           parcela: _firstValid([item['parcela'], item['tributo'], item['Parcela / Tributo']])?.toString() ?? '',
           valor: _firstValid([item['valor'], item['valorTotal'], item['Valor Total']])?.toString() ?? '',
           vencimento: _firstValid([item['vencimento'], item['Vencimento']])?.toString() ?? '',
           situacao: _firstValid([item['situacao'], item['Situação']])?.toString() ?? '',
           exercicio: _firstValid([item['exercicio']])?.toString() ?? '',
         ));
      }
    }

    return RadarModule(
      modulo: 'ipva',
      status: RadarModuleStatus.preenchido,
      dados: result,
      fonte: mod['title'],
    );
  }

  static RadarModule<List<MultaData>> _extractMultas(Map<String, dynamic> modulos) {
    final mod = modulos['ssp'] ?? modulos['baseEstadual'];
    if (mod == null) return _emptyModule('multas');
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule('multas');

    List<dynamic> multasRaw = [];
    if (r['multas']?['lista'] is List) {
      multasRaw = r['multas']['lista'];
    } else if (r['multas'] is List) {
      multasRaw = r['multas'];
    } else if (r['Multas']?['data'] is List) {
      multasRaw = r['Multas']['data'];
    }

    if (multasRaw.isEmpty) return RadarModule(modulo: 'multas', status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);

    final List<MultaData> result = [];
    for (var item in multasRaw) {
      if (item is Map) {
        result.add(MultaData(
          orgao: _firstValid([item['orgao'], item['Órgão Autuador']])?.toString() ?? '',
          valor: _firstValid([item['valor'], item['Valor a Pagar']])?.toString() ?? '',
          dataInfracao: _firstValid([item['data'], item['dataInfracao'], item['Data e Hora']])?.toString() ?? '',
          descricao: _firstValid([item['descricao'], item['Descrição da Infração']])?.toString() ?? '',
          situacao: _firstValid([item['situacao'], item['Status']])?.toString() ?? '',
          autoInfracao: _firstValid([item['autoInfracao'], item['Número do Auto']])?.toString() ?? '',
          local: _firstValid([item['local'], item['Local da Infração']])?.toString() ?? '',
        ));
      }
    }

    return RadarModule(modulo: 'multas', status: RadarModuleStatus.preenchido, dados: result, fonte: mod['title']);
  }

  static RadarModule<List<LicenciamentoData>> _extractLicenciamentos(Map<String, dynamic> modulos) {
    final mod = modulos['ssp'] ?? modulos['baseEstadual'];
    if (mod == null) return _emptyModule('licenciamentos');
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule('licenciamentos');

    List<dynamic> raw = [];
    if (r['licenciamentos'] is List) {
      raw = r['licenciamentos'];
    } else if (r['Licenciamento']?['data'] is List) {
      raw = r['Licenciamento']['data'];
    }

    if (raw.isEmpty) return RadarModule(modulo: 'licenciamentos', status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);

    final List<LicenciamentoData> result = [];
    for (var item in raw) {
      if (item is Map) {
        result.add(LicenciamentoData(
          exercicio: _firstValid([item['exercicio'], item['Exercício']])?.toString() ?? '',
          valor: _firstValid([item['valor'], item['Valor']])?.toString() ?? '',
          situacao: _firstValid([item['situacao'], item['Situação']])?.toString() ?? '',
          dataPagamento: _firstValid([item['dataPagamento'], item['Data de Pagamento']])?.toString() ?? '',
        ));
      }
    }
    return RadarModule(modulo: 'licenciamentos', status: RadarModuleStatus.preenchido, dados: result, fonte: mod['title']);
  }

  static RadarModule<List<VistoriaData>> _extractVistorias(Map<String, dynamic> modulos) {
    final mod = modulos['ssp'];
    if (mod == null) return _emptyModule('vistorias');
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule('vistorias');

    List<dynamic> raw = [];
    if (r['vistorias'] is List) {
      raw = r['vistorias'];
    } else if (r['Vistorias']?['data'] is List) {
      raw = r['Vistorias']['data'];
    }

    if (raw.isEmpty) return RadarModule(modulo: 'vistorias', status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);

    final List<VistoriaData> result = [];
    for (var item in raw) {
      if (item is Map) {
        result.add(VistoriaData(
          data: _firstValid([item['data'], item['Data da Vistoria']])?.toString() ?? '',
          resultado: _firstValid([item['resultado'], item['Resultado']])?.toString() ?? '',
          empresa: _firstValid([item['empresa'], item['Empresa']])?.toString() ?? '',
          observacao: _firstValid([item['observacao'], item['Observações']])?.toString() ?? '',
        ));
      }
    }
    return RadarModule(modulo: 'vistorias', status: RadarModuleStatus.preenchido, dados: result, fonte: mod['title']);
  }

  static RadarModule<List<RestricaoData>> _extractRestricoes(Map<String, dynamic> modulos) {
    final mod = modulos['ssp'] ?? modulos['bin'];
    if (mod == null) return _emptyModule('restricoes');
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule('restricoes');

    final List<RestricaoData> result = [];
    
    // Structure 2: retorno["Restrições"].data
    if (r['Restrições']?['data'] is Map) {
      final rest = r['Restrições']['data'] as Map;
      for (var entry in rest.entries) {
        final val = entry.value?.toString() ?? '';
        final status = _classifyValue(val);
        result.add(RestricaoData(
          tipo: entry.key.toString(),
          descricao: val,
          possuiRestricao: status == RadarModuleStatus.preenchido,
        ));
      }
    } else if (r['informacoesRelevantes'] is Map) {
      // Structure 1: bin.informacoesRelevantes
      final rest = r['informacoesRelevantes'] as Map;
      for (var key in ['restricaoAdministrativa', 'restricaoJudicial', 'restricaoTributaria', 'restricaoRenajud', 'restricaoAmbiental']) {
        final val = rest[key]?.toString() ?? '';
        final status = _classifyValue(val);
        if (status != RadarModuleStatus.sem_informacao) {
          result.add(RestricaoData(
            tipo: key,
            descricao: val,
            possuiRestricao: status == RadarModuleStatus.preenchido,
          ));
        }
      }
    }

    if (result.isEmpty) return RadarModule(modulo: 'restricoes', status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);
    return RadarModule(modulo: 'restricoes', status: RadarModuleStatus.preenchido, dados: result, fonte: mod['title']);
  }

  static RadarModule<RouboFurtoData> _extractRouboFurto(Map<String, dynamic> modulos) {
    final mod = modulos['rouboFurto'] ?? modulos['bin'];
    if (mod == null) return _emptyModule('rouboFurto');
    
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule('rouboFurto');

    List<Map<String, dynamic>> historico = [];
    bool possui = false;

    if (r['rf'] is List) {
       for (var item in r['rf']) {
         if (item is Map) {
           historico.add(Map<String, dynamic>.from(item));
           possui = true;
         }
       }
    }

    return RadarModule(
      modulo: 'rouboFurto',
      status: possui ? RadarModuleStatus.preenchido : RadarModuleStatus.nada_consta,
      dados: RouboFurtoData(
        possuiOcorrencia: possui,
        historico: historico,
      ),
      fonte: mod['title'],
    );
  }

  static RadarModule<Map<String, dynamic>> _extractGenericModule(Map<String, dynamic> modulos, String alias) {
    final mod = modulos[alias];
    if (mod == null) return _emptyModule(alias);
    final r = _getRetorno(mod);
    if (r == null) return _emptyModule(alias);
    return RadarModule(modulo: alias, status: RadarModuleStatus.preenchido, dados: r, fonte: mod['title']);
  }

  static RadarModule<List<Map<String, dynamic>>> _extractGenericList(Map<String, dynamic> modulos, String alias) {
    final mod = modulos[alias];
    if (mod == null) return _emptyModule(alias);
    final r = _getRetorno(mod);
    if (r == null) {
      if (mod['retorno'] is String) {
        return RadarModule(modulo: alias, status: _classifyValue(mod['retorno']), mensagem: mod['retorno'], fonte: mod['title']);
      }
      return _emptyModule(alias);
    }
    
    List<Map<String, dynamic>> list = [];
    if (r is Map && r['data'] is List) {
      list = List<Map<String, dynamic>>.from(r['data'].whereType<Map>());
    } else if (mod['retorno'] is List) {
      list = List<Map<String, dynamic>>.from(mod['retorno'].whereType<Map>());
    }

    if (list.isEmpty) return RadarModule(modulo: alias, status: RadarModuleStatus.nada_consta, dados: [], fonte: mod['title']);
    return RadarModule(modulo: alias, status: RadarModuleStatus.preenchido, dados: list, fonte: mod['title']);
  }

  static Map<String, dynamic>? _getRetorno(Map<String, dynamic>? modulo) {
    if (modulo == null) return null;
    if (_isPlainObject(modulo['retorno'])) {
      return modulo['retorno'];
    }
    return null;
  }

  static RadarModule<T> _emptyModule<T>(String name) {
    return RadarModule<T>(modulo: name, status: RadarModuleStatus.nao_consultado);
  }

  static RadarNormalizedData _buildEmptyData({required List<RadarError> erros, required Map<String, dynamic> rawJson}) {
    return RadarNormalizedData(
      rawJson: rawJson,
      veiculo: VeiculoData(),
      proprietario: ProprietarioData(),
      multas: _emptyModule('multas'),
      ipva: _emptyModule('ipva'),
      licenciamentos: _emptyModule('licenciamentos'),
      vistorias: _emptyModule('vistorias'),
      restricoes: _emptyModule('restricoes'),
      rouboFurto: _emptyModule('rouboFurto'),
      comunicacaoVenda: _emptyModule('comunicacaoVenda'),
      recall: _emptyModule('recall'),
      sinistros: _emptyModule('sinistros'),
      leiloes: _emptyModule('leiloes'),
      dividasAtivas: _emptyModule('dividasAtivas'),
      erros: erros,
    );
  }
}
