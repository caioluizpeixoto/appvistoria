import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://cmcpmppgpbrufrxznost.supabase.co';
  final anonKey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq';

  final response = await http.post(
    Uri.parse('https://cmcpmppgpbrufrxznost.supabase.co/functions/v1/gerar-imagem-veiculo'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq',
      'apikey': 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq',
    },
    body: jsonEncode({
      'brand': 'Volkswagen',
      'model': 'Gol',
      'parts': [
        {'part': 'hood', 'color': 'yellow'}
      ]
    }),
  );

  print('Status: ${response.statusCode}');
  
  try {
    final data = jsonDecode(response.body);
    if (data['base64'] != null) {
      final String b64 = data['base64'];
      print('Sucesso! Recebeu base64 com ${b64.length} caracteres.');
    } else {
      print('Erro: ${response.body}');
    }
  } catch (e) {
    print('Erro parse: ${response.body}');
  }
}
