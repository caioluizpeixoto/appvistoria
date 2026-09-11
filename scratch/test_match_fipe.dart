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
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() async {
  final marcasRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas'));
  final marcas = jsonDecode(marcasRes.body) as List;
  final vw = marcas.firstWhere((m) => m['nome'].toString().toLowerCase().contains('volkswagen'));
  
  final modelosRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos'));
  final modelos = (jsonDecode(modelosRes.body)['modelos'] as List);

  final testCases = ['VW/GOL 1.0', 'GOL 1.0', 'GOL', 'VOLKSWAGEN GOL 1.0 FLEX'];

  for (final test in testCases) {
    final cleanModelo = _sanitize(test);
    final searchTokens = cleanModelo
        .split(' ')
        .where((t) => t.length > 1 && !['de', 'do', 'da', 'com', 'vw', 'volkswagen'].contains(t))
        .toList();

    dynamic bestModelo;
    int bestScore = -1;

    for (final mod in modelos) {
      final nomeMod = _sanitize(mod['nome']?.toString() ?? '');
      int score = 0;

      for (final tok in searchTokens) {
        if (nomeMod.contains(tok)) {
          score += 10;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestModelo = mod;
      }
    }

    print('Input: "$test" -> Best: "${bestModelo?['nome']}" (Score: $bestScore, ID: ${bestModelo?['codigo']})');
    
    // Anos
    final anosRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos/${bestModelo['codigo']}/anos'));
    final anos = jsonDecode(anosRes.body) as List;
    final ano2021 = anos.firstWhere((a) => a['nome'].toString().contains('2021'), orElse: () => null);
    if (ano2021 != null) {
      final pRes = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${vw['codigo']}/modelos/${bestModelo['codigo']}/anos/${ano2021['codigo']}'));
      final pData = jsonDecode(pRes.body);
      print('  -> Preco 2021: ${pData['Valor']} | Cod: ${pData['CodigoFipe']} | Mes: ${pData['MesReferencia']}');
    } else {
      print('  -> 2021 não disponível para este modelo.');
    }
  }
}
