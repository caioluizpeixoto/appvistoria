import 'dart:convert';
import 'package:http/http.dart' as http;

class FipeTester {
  static const String _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  static String _sanitize(String text) {
    var s = text.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[áàãâä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòõôö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Future<Map<String, dynamic>?> consultarFipe({
    required String marca,
    required String modelo,
    required int ano,
    String tipoVeiculo = 'carros',
  }) async {
    final cleanMarca = _sanitize(marca);
    final cleanModelo = _sanitize(modelo);

    String tipo = 'carros';
    final cleanTipo = _sanitize(tipoVeiculo);
    if (cleanTipo.contains('moto')) {
      tipo = 'motos';
    } else if (cleanTipo.contains('caminh') || cleanTipo.contains('trator')) {
      tipo = 'caminhoes';
    }

    // 1. Marcas
    final resMarcas = await http.get(Uri.parse('$_baseUrl/$tipo/marcas'));
    final List marcas = jsonDecode(resMarcas.body);
    dynamic marcaEncontrada;
    for (final m in marcas) {
      final nomeM = _sanitize(m['nome']?.toString() ?? '');
      if (nomeM == cleanMarca) {
        marcaEncontrada = m;
        break;
      }
      if (cleanMarca.contains('renault') && nomeM.contains('renault')) {
        marcaEncontrada = m;
        break;
      }
      if (cleanMarca.contains('audi') && nomeM.contains('audi')) {
        marcaEncontrada = m;
        break;
      }
      if (nomeM.contains(cleanMarca) || cleanMarca.contains(nomeM)) {
        marcaEncontrada = m;
        break;
      }
    }
    if (marcaEncontrada == null) return null;
    final codigoMarca = marcaEncontrada['codigo'];

    // 2. Modelos
    final resModelos = await http.get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos'));
    final List modelos = jsonDecode(resModelos.body)['modelos'] ?? [];

    // 3. Classificar modelos
    final searchTokens = cleanModelo
        .replaceAll('etech', 'tech')
        .replaceAll('e-tech', 'tech')
        .split(' ')
        .where((t) => t.length > 1 && !['de', 'do', 'da', 'e', 'o', 'a', 'com', 'sem'].contains(t))
        .toList();

    final isQueryEtech = cleanModelo.contains('tech') || cleanModelo.contains('etech');
    final isQueryZe = cleanModelo.contains('ze') || cleanModelo.contains('z e');
    final isQueryElectric = cleanModelo.contains('eletric') || cleanModelo.contains('electric') || isQueryEtech || isQueryZe;
    final isQueryFlex = cleanModelo.contains('flex');
    final isQueryDiesel = cleanModelo.contains('diesel');
    final isQueryHybrid = cleanModelo.contains('hybrid') || cleanModelo.contains('hibrid');

    List<Map<String, dynamic>> scoredModelos = [];

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
          score += 10.0;
        } else if (modTokens.any((mt) => mt.contains(token) || token.contains(mt))) {
          matches += 1;
          score += 4.0;
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

      // Se a consulta NÃO pede elétrico, penaliza pesadamente modelos elétricos
      if (!isQueryElectric && isModElectric) {
        score -= 50.0;
      }
      if (isQueryElectric && isModElectric) {
        score += 30.0;
      }
      if (!isQueryHybrid && isModHybrid) {
        score -= 30.0;
      }
      if (isQueryHybrid && isModHybrid) {
        score += 30.0;
      }

      if (isQueryFlex && nomeMod.contains('flex')) score += 10.0;
      if (isQueryDiesel && nomeMod.contains('diesel')) score += 10.0;

      // Penalidade leve pelo tamanho de tokens extras
      score -= (modTokens.length - searchTokens.length).abs() * 0.5;

      scoredModelos.add({
        'modelo': mod,
        'score': score,
        'nome': mod['nome'],
      });
    }

    scoredModelos.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Testar os melhores candidatos até encontrar um que tenha o ano desejado
    dynamic melhorAno;
    dynamic modeloEscolhido;

    for (final cand in scoredModelos.take(5)) {
      final mod = cand['modelo'];
      final codMod = mod['codigo'];
      final resAnos = await http.get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codMod/anos'));
      if (resAnos.statusCode != 200) continue;
      final List anosList = jsonDecode(resAnos.body) ?? [];
      
      dynamic anoMatch;
      // 1. Exato
      for (final a in anosList) {
        if (a['codigo']?.toString().startsWith('$ano-') == true || a['nome']?.toString().contains('$ano') == true) {
          anoMatch = a;
          break;
        }
      }
      if (anoMatch != null) {
        melhorAno = anoMatch;
        modeloEscolhido = mod;
        break;
      }
    }

    // Se nenhum dos top 5 tiver o ano exato, usa o primeiro colocado com ano mais próximo
    if (modeloEscolhido == null && scoredModelos.isNotEmpty) {
      modeloEscolhido = scoredModelos.first['modelo'];
      final codMod = modeloEscolhido['codigo'];
      final resAnos = await http.get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codMod/anos'));
      final List anosList = jsonDecode(resAnos.body) ?? [];
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
        melhorAno = anosValidos.first;
      } else {
        melhorAno = anosList.firstOrNull;
      }
    }

    if (modeloEscolhido == null || melhorAno == null) return null;

    final codMod = modeloEscolhido['codigo'];
    final codAno = melhorAno['codigo'];
    final resPreco = await http.get(Uri.parse('$_baseUrl/$tipo/marcas/$codigoMarca/modelos/$codMod/anos/$codAno'));
    if (resPreco.statusCode == 200) {
      return jsonDecode(resPreco.body);
    }
    return null;
  }
}

void main() async {
  print('--- Teste Kangoo 2015 ---');
  final r1 = await FipeTester.consultarFipe(marca: 'RENAULT', modelo: 'KANGOO', ano: 2015);
  print('Kangoo 2015: ${r1?['Modelo']} -> ${r1?['Valor']}');

  print('\n--- Teste Kangoo Express 2014 ---');
  final r2 = await FipeTester.consultarFipe(marca: 'RENAULT', modelo: 'KANGOO EXPRESS', ano: 2014);
  print('Kangoo Express 2014: ${r2?['Modelo']} -> ${r2?['Valor']}');

  print('\n--- Teste Audi Q3 2020 ---');
  final r3 = await FipeTester.consultarFipe(marca: 'AUDI', modelo: 'Q3', ano: 2020);
  print('Audi Q3 2020: ${r3?['Modelo']} -> ${r3?['Valor']}');

  print('\n--- Teste Audi Q3 2015 ---');
  final r4 = await FipeTester.consultarFipe(marca: 'AUDI', modelo: 'Q3 1.4', ano: 2015);
  print('Audi Q3 2015: ${r4?['Modelo']} -> ${r4?['Valor']}');
}
