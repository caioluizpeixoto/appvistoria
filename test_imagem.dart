import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://cmcpmppgpbrufrxznost.supabase.co';
  final anonKey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq';

  final response = await http.post(
    Uri.parse(
        'https://cmcpmppgpbrufrxznost.supabase.co/functions/v1/gerar-imagem-veiculo'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq',
      'apikey': 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq',
    },
    body: jsonEncode({
      'brand': 'Jeep',
      'model': 'Compass',
      'year': '2022',
      'version': 'Limited T270',
      'type': 'SUV',
      'parts': [
        {'part': 'rear right (passenger side) door', 'color': 'red'}
      ],
      'customInstruction':
          'Ensure ONLY the rear right door on the passenger side is red. The left driver side doors MUST be neutral gray.'
    }),
  );

  print('Status: ${response.statusCode}');

  try {
    final data = jsonDecode(response.body);
    if (data['base64'] != null) {
      final String b64 = data['base64'];
      print('Sucesso! Fonte: ${data['source']} | Base64: ${b64.length} chars.');
      final bytes = base64Decode(b64);
      final file = File('test_carro.png');
      await file.writeAsBytes(bytes);
      print('Imagem salva em test_carro.png!');
    } else {
      print('Erro: ${response.body}');
    }
  } catch (e) {
    print('Erro parse: ${response.body}');
  }
}
