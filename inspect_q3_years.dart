import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Audi marca = 6
  final resModelos = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/6/modelos'));
  final data = jsonDecode(resModelos.body);
  final List modelos = data['modelos'];
  final q3List = modelos.where((m) => m['nome'].toString().toUpperCase().contains('Q3')).toList();
  
  for (final m in q3List) {
    final cod = m['codigo'];
    final resAnos = await http.get(Uri.parse('https://parallelum.com.br/fipe/api/v1/carros/marcas/6/modelos/$cod/anos'));
    final List anos = jsonDecode(resAnos.body) ?? [];
    final anosNomes = anos.map((a) => a['nome']).toList();
    print('Modelo: ${m['nome']} (Cod: $cod) -> Anos: $anosNomes');
  }
}
