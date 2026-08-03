import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url =
      'https://generativelanguage.googleapis.com/v1beta/models?key=AIzaSyCOEPpW6qbQlOXtENrQN74L7mqaKg30nUc';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final models = data['models'] as List;
    for (final m in models) {
      final name = m['name'];
      if (name.contains('imagen') || name.contains('image')) {
        print('Encontrado: ');
        print(name);
        print('Supported Methods: ');
        print(m['supportedGenerationMethods']);
      }
    }
    print('Fim da busca.');
  } else {
    print('Erro: ');
    print(response.body);
  }
}
