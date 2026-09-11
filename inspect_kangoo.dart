import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final resMarcas = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas'));
  final List marcas = jsonDecode(resMarcas.body);
  final renault = marcas.firstWhere((m) => m['nome'].toString().toUpperCase().contains('RENAULT'));
  print('Renault marca: $renault');

  final resModelos = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${renault['codigo']}/modelos'));
  final data = jsonDecode(resModelos.body);
  final List modelos = data['modelos'];
  
  print('--- Modelos Kangoo encontrados ---');
  for (final m in modelos) {
    if (m['nome'].toString().toUpperCase().contains('KANGOO')) {
      print('Codigo: ${m['codigo']} | Nome: ${m['nome']}');
    }
  }

  // Agora vamos testar o algoritmo de score de fipe_service para "KANGOO" e "KANGOO EXPRESS"
  print('\n--- Testando Audi Marca e Modelos ---');
  final audi = marcas.firstWhere((m) => m['nome'].toString().toUpperCase() == 'AUDI');
  print('Audi marca: $audi');
  final resAudiModelos = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/${audi['codigo']}/modelos'));
  final audiData = jsonDecode(resAudiModelos.body);
  final List audiModelos = audiData['modelos'];
  for (final m in audiModelos) {
    if (m['nome'].toString().toUpperCase().contains('Q3')) {
      print('Audi Q3 modelo: ${m['codigo']} | ${m['nome']}');
    }
  }
}
