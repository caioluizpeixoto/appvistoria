import 'dart:convert';
import 'package:http/http.dart' as http;

class FipeVeiculoInfo {
  final String valor;
  final String marca;
  final String modelo;
  final int anoModelo;
  final String combustivel;
  final String codigoFipe;
  final String mesReferencia;
  final String siglaCombustivel;

  const FipeVeiculoInfo({
    required this.valor,
    required this.marca,
    required this.modelo,
    required this.anoModelo,
    required this.combustivel,
    required this.codigoFipe,
    required this.mesReferencia,
    required this.siglaCombustivel,
  });

  factory FipeVeiculoInfo.fromJson(Map<String, dynamic> json) {
    return FipeVeiculoInfo(
      valor: json['Valor']?.toString() ?? '',
      marca: json['Marca']?.toString() ?? '',
      modelo: json['Modelo']?.toString() ?? '',
      anoModelo: int.tryParse(json['AnoModelo']?.toString() ?? '') ?? 0,
      combustivel: json['Combustivel']?.toString() ?? '',
      codigoFipe: json['CodigoFipe']?.toString() ?? '',
      mesReferencia: json['MesReferencia']?.toString() ?? '',
      siglaCombustivel: json['SiglaCombustivel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valor': valor,
      'marca': marca,
      'modelo': modelo,
      'anoModelo': anoModelo,
      'combustivel': combustivel,
      'codigoFipe': codigoFipe,
      'mesReferencia': mesReferencia,
      'siglaCombustivel': siglaCombustivel,
    };
  }
}

class FipeService {
  static final Map<String, FipeVeiculoInfo> _cache = {};
  static List<dynamic>? _cachedMarcasCarros;
  static List<dynamic>? _cachedMarcasMotos;
  static List<dynamic>? _cachedMarcasCaminhoes;

  static const String _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  static String _sanitize(String text) {
    var s = text.toLowerCase().trim();
    // Remover prefixos comuns de importação
    s = s.replaceAll(RegExp(r'^(i|imp|ip|importado)\s*[\/\- ]\s*'), '');
    s = s.replaceAll(RegExp(r'[áàãâä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòõôö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    // Preservar pontos em cilindradas/motores (ex: 1.0, 1.6, 2.0)
    s = s.replaceAllMapped(RegExp(r'(\d)\.(\d)'), (m) => '${m[1]}dot${m[2]}');
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    s = s.replaceAllMapped(RegExp(r'(\d)dot(\d)'), (m) => '${m[1]}.${m[2]}');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Future<FipeVeiculoInfo?> consultarFipe({
    required String marca,
    required String modelo,
    required int ano,
    String tipoVeiculo = 'carros',
  }) async {
    final cleanMarca = _sanitize(marca);
    final cleanModelo = _sanitize(modelo);
    final cacheKey = '$cleanMarca|$cleanModelo|$ano|$tipoVeiculo';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      String tipo = 'carros';
      final cleanTipo = _sanitize(tipoVeiculo);
      if (cleanTipo.contains('moto')) {
        tipo = 'motos';
      } else if (cleanTipo.contains('caminh') || cleanTipo.contains('trator')) {
        tipo = 'caminhoes';
      }

      // 1. Obter lista de marcas
      List<dynamic> marcas;
      if (tipo == 'carros') {
        _cachedMarcasCarros ??= await _fetchList('$_baseUrl/carros/marcas');
        marcas = _cachedMarcasCarros ?? [];
      } else if (tipo == 'motos') {
        _cachedMarcasMotos ??= await _fetchList('$_baseUrl/motos/marcas');
        marcas = _cachedMarcasMotos ?? [];
      } else {
        _cachedMarcasCaminhoes ??= await _fetchList('$_baseUrl/caminhoes/marcas');
        marcas = _cachedMarcasCaminhoes ?? [];
      }

      if (marcas.isEmpty) return null;

      // Localizar marca mais próxima
      dynamic marcaEncontrada;

      for (final m in marcas) {
        final nomeM = _sanitize(m['nome']?.toString() ?? '');
        if (nomeM == cleanMarca) {
          marcaEncontrada = m;
          break;
        }

        // Aliases comuns
        if ((cleanMarca.contains('chevrolet') || cleanMarca.contains('gm')) &&
            nomeM.contains('chevrolet')) {
          marcaEncontrada = m;
          break;
        }
        if ((cleanMarca.contains('volkswagen') || cleanMarca == 'vw' || cleanMarca.startsWith('vw ')) &&
            nomeM.contains('volkswagen')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('mercedes') && nomeM.contains('mercedes')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('citroen') && nomeM.contains('citroen')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('fiat') && nomeM.contains('fiat')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('ford') && nomeM.contains('ford')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('renault') && nomeM.contains('renault')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('hyundai') && nomeM.contains('hyundai')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('toyota') && nomeM.contains('toyota')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('honda') && nomeM.contains('honda')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('jeep') && nomeM.contains('jeep')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('nissan') && nomeM.contains('nissan')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('peugeot') && nomeM.contains('peugeot')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('audi') && nomeM.contains('audi')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('bmw') && nomeM.contains('bmw')) {
          marcaEncontrada = m;
          break;
        }
        if ((cleanMarca.contains('chery') || cleanMarca.contains('caoa')) && nomeM.contains('chery')) {
          marcaEncontrada = m;
          break;
        }
        if (cleanMarca.contains('byd') && nomeM.contains('byd')) {
          marcaEncontrada = m;
          break;
        }

        if (nomeM.contains(cleanMarca) || cleanMarca.contains(nomeM)) {
          marcaEncontrada = m;
          break;
        }
      }

      if (marcaEncontrada == null) return null;
      final codigoMarca = marcaEncontrada['codigo']?.toString();
      if (codigoMarca == null) return null;

      // 2. Obter modelos da marca
      final resModelos = await http
          .get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos'))
          .timeout(const Duration(seconds: 8));

      if (resModelos.statusCode != 200) return null;
      final modelosData = jsonDecode(resModelos.body);
      final List modelos = modelosData['modelos'] ?? [];
      if (modelos.isEmpty) return null;

      // 3. Encontrar e pontuar todos os modelos compatíveis
      final searchTokens = cleanModelo
          .replaceAll('etech', 'tech')
          .replaceAll('e-tech', 'tech')
          .split(' ')
          .where((t) => (t.length > 1 || RegExp(r'\d').hasMatch(t)) && !['de', 'do', 'da', 'e', 'o', 'a', 'com', 'sem', 'vw', 'volkswagen'].contains(t))
          .toList();

      final isQueryEtech = cleanModelo.contains('tech') || cleanModelo.contains('etech');
      final isQueryZe = cleanModelo.contains('ze') || cleanModelo.contains('z e');
      final isQueryElectric = cleanModelo.contains('eletric') || cleanModelo.contains('electric') || isQueryEtech || isQueryZe;
      final isQueryFlex = cleanModelo.contains('flex');
      final isQueryDiesel = cleanModelo.contains('diesel');
      final isQueryHybrid = cleanModelo.contains('hybrid') || cleanModelo.contains('hibrid');

      final List<Map<String, dynamic>> scoredModelos = [];

      for (final mod in modelos) {
        final nomeMod = _sanitize(mod['nome']?.toString() ?? '');
        final modTokens = nomeMod
            .replaceAll('etech', 'tech')
            .replaceAll('e-tech', 'tech')
            .split(' ');

        double score = 0.0;
        int matches = 0;

        for (final token in searchTokens) {
          if (modTokens.contains(token)) {
            matches += 2;
            score += 15.0;
          } else if (modTokens.any((mt) => mt.contains(token) || token.contains(mt))) {
            matches += 1;
            score += 5.0;
          }
        }

        if (matches == 0) continue;

        final isModElectric = nomeMod.contains('eletrico') ||
            nomeMod.contains('electric') ||
            nomeMod.contains('tech') ||
            nomeMod.contains('etech') ||
            nomeMod.contains('ze') ||
            nomeMod.contains('z e');
        final isModHybrid = nomeMod.contains('hybrid') || nomeMod.contains('hibrid');

        if (!isQueryElectric && isModElectric) score -= 40.0;
        if (isQueryElectric && isModElectric) score += 30.0;
        if (!isQueryHybrid && isModHybrid) score -= 25.0;
        if (isQueryHybrid && isModHybrid) score += 25.0;

        // Combustível / Versão
        if (isQueryFlex && nomeMod.contains('flex')) score += 10.0;
        if (isQueryDiesel && nomeMod.contains('diesel')) score += 10.0;

        // Penalidade por diferença de tamanho de tokens
        score -= (modTokens.length - searchTokens.length).abs() * 0.5;

        if (score > 0) {
          scoredModelos.add({'modelo': mod, 'score': score});
        }
      }

      if (scoredModelos.isEmpty) return null;

      // Ordenar modelos do mais pontuado para o menos pontuado
      scoredModelos.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // 4. Testar os melhores candidatos até encontrar um que tenha o ano desejado
      dynamic melhorModeloEncontrado;
      dynamic anoEncontrado;

      // Primeiro passe: tentar match exato do ano nos top 8 modelos candidatos
      for (final candidate in scoredModelos.take(8)) {
        final mod = candidate['modelo'];
        final codigoModelo = mod['codigo']?.toString();
        if (codigoModelo == null) continue;

        try {
          final resAnos = await http
              .get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codigoModelo/anos'))
              .timeout(const Duration(seconds: 8));

          if (resAnos.statusCode != 200) continue;
          final List anosList = jsonDecode(resAnos.body) ?? [];
          if (anosList.isEmpty) continue;

          // Buscar match exato do ano
          for (final a in anosList) {
            if (a['codigo']?.toString().startsWith('$ano-') == true ||
                a['nome']?.toString().contains('$ano') == true) {
              melhorModeloEncontrado = mod;
              anoEncontrado = a;
              break;
            }
          }

          if (anoEncontrado != null) break;
        } catch (_) {
          continue;
        }
      }

      // Segundo passe: se nenhum dos top candidatos tiver o ano exato, pegar o melhor modelo geral e o ano mais próximo
      if (anoEncontrado == null) {
        final topMod = scoredModelos.first['modelo'];
        final codigoModelo = topMod['codigo']?.toString();
        if (codigoModelo != null) {
          try {
            final resAnos = await http
                .get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codigoModelo/anos'))
                .timeout(const Duration(seconds: 8));

            if (resAnos.statusCode == 200) {
              final List anosList = jsonDecode(resAnos.body) ?? [];
              if (anosList.isNotEmpty) {
                melhorModeloEncontrado = topMod;
                final anosValidos = anosList.where((a) {
                  final code = a['codigo']?.toString().split('-').first ?? '';
                  final numYear = int.tryParse(code) ?? 0;
                  return numYear > 1900 && numYear < 3000;
                }).toList();

                if (anosValidos.isNotEmpty) {
                  anosValidos.sort((a, b) {
                    final ya = int.tryParse(a['codigo']!.toString().split('-').first) ?? 0;
                    final yb = int.tryParse(b['codigo']!.toString().split('-').first) ?? 0;
                    return (ya - ano).abs().compareTo((yb - ano).abs());
                  });
                  anoEncontrado = anosValidos.first;
                } else {
                  anoEncontrado = anosList.first;
                }
              }
            }
          } catch (_) {}
        }
      }

      if (melhorModeloEncontrado == null || anoEncontrado == null) return null;

      final codigoModelo = melhorModeloEncontrado['codigo']?.toString();
      final codigoAno = anoEncontrado['codigo']?.toString();
      if (codigoModelo == null || codigoAno == null) return null;

      // 5. Obter Preço Final Oficial FIPE
      final resPreco = await http
          .get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codigoModelo/anos/$codigoAno'))
          .timeout(const Duration(seconds: 8));

      if (resPreco.statusCode == 200) {
        final fipeData = jsonDecode(resPreco.body);
        final info = FipeVeiculoInfo.fromJson(fipeData);
        _cache[cacheKey] = info;
        return info;
      }
    } catch (_) {}

    return null;
  }

  static Future<List<dynamic>?> _fetchList(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List;
      }
    } catch (_) {}
    return null;
  }
}
