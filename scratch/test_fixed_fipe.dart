import 'dart:convert';
import 'package:http/http.dart' as http;

String _sanitize(String s) {
  s = s.toLowerCase();
  s = s.replaceAll(RegExp(r'[áàãâä]'), 'a');
  s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
  s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
  s = s.replaceAll(RegExp(r'[óòõôö]'), 'o');
  s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
  s = s.replaceAll(RegExp(r'[ç]'), 'c');
  // Substituir pontos entre numeros por ponto mesmo (ex: 1.0 continua 1.0)
  s = s.replaceAllMapped(RegExp(r'(\d)\.(\d)'), (m) => '${m[1]}dot${m[2]}');
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  s = s.replaceAllMapped(RegExp(r'(\d)dot(\d)'), (m) => '${m[1]}.${m[2]}');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() async {
  final marcasRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas'));
  final marcas = jsonDecode(marcasRes.body) as List;
  final vw = marcas.firstWhere((m) => m['nome'].toString().toLowerCase().contains('volkswagen'));
  
  final modelosRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos'));
  final modelos = (jsonDecode(modelosRes.body)['modelos'] as List);

  final testCases = ['VW/GOL 1.0', 'GOL 1.0', 'VOLKSWAGEN GOL 1.0 FLEX'];
  final ano = 2021;

  for (final test in testCases) {
    final cleanModelo = _sanitize(test);
    final searchTokens = cleanModelo
        .split(' ')
        .where((t) => (t.length > 1 || RegExp(r'\d').hasMatch(t)) && !['de', 'do', 'da', 'com', 'vw', 'volkswagen'].contains(t))
        .toList();

    print('Sanitized "$test" -> Tokens: $searchTokens');

    List<Map<String, dynamic>> scoredModelos = [];

    for (final mod in modelos) {
      final nomeMod = _sanitize(mod['nome']?.toString() ?? '');
      final modTokens = nomeMod.split(' ');
      double score = 0.0;

      for (final tok in searchTokens) {
        if (modTokens.contains(tok)) {
          score += 15.0;
        } else if (nomeMod.contains(tok)) {
          score += 6.0;
        }
      }

      // Penalidade por diferença de tamanho de tokens
      score -= (modTokens.length - searchTokens.length).abs() * 0.5;

      if (score > 0) {
        scoredModelos.add({'modelo': mod, 'score': score, 'nome': nomeMod});
      }
    }

    scoredModelos.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    print('Query: "$test" (Top 3):');
    for (var i = 0; i < scoredModelos.take(5).length; i++) {
      final sm = scoredModelos[i];
      final mod = sm['modelo'];
      final codigoModelo = mod['codigo'];
      final anosRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos/$codigoModelo/anos'));
      final List anosList = jsonDecode(anosRes.body) ?? [];
      final hasExactYear = anosList.any((a) => a['codigo']?.toString().startsWith('$ano-') == true || a['nome']?.toString().contains('$ano') == true);
      print('  #$i: ${mod['nome']} (Score: ${sm['score']}) -> Tem ano $ano? $hasExactYear');

      if (hasExactYear) {
        final anoItem = anosList.firstWhere((a) => a['codigo']?.toString().startsWith('$ano-') == true || a['nome']?.toString().contains('$ano') == true);
        final pRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos/$codigoModelo/anos/${anoItem['codigo']}'));
        final pData = jsonDecode(pRes.body);
        print('  >>> SUCESSO! Valor FIPE: ${pData['Valor']} | Modelo: ${pData['Modelo']} | Cod: ${pData['CodigoFipe']}');
        break;
      }
    }
  }
}
