import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyCOEPpW6qbQlOXtENrQN74L7mqaKg30nUc';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-fast-generate-001:predict?key=\$apiKey';
  
  final body = jsonEncode({
    "instances": [
      {
        "prompt": "A realistic 3D isometric render of a VW Gol."
      }
    ],
    "parameters": {
      "sampleCount": 1
    }
  });

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  
  print('Status: ');
  print(response.statusCode);
  
  if (response.statusCode == 200) {
    print('Sucesso!');
    final data = jsonDecode(response.body);
    print(data.keys);
    final preds = data['predictions'] as List;
    if (preds.isNotEmpty) {
       print(preds.first.keys);
    }
  } else {
    print('Erro: ');
    print(response.body);
  }
}
