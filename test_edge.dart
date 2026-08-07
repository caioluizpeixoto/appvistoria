import 'package:supabase/supabase.dart';
import 'dart:convert';

void main() async {
  final supabaseUrl = 'https://cmcpmppgpbrufrxznost.supabase.co';
  final anonKey = 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq';

  final client = SupabaseClient(supabaseUrl, anonKey);

  print('Chamando Edge Function gerar-ficha-veiculo...');
  try {
    final res = await client.functions.invoke(
      'gerar-ficha-veiculo',
      body: {
        'brand': 'FIAT',
        'model': 'PUNTO',
        'year': 2012,
        'version': 'ATTRACTIVE 1.4',
        'fuel': 'FLEX',
        'engine': '1.4',
        'uf': 'SP',
      },
    );
    print('Status: ${res.status}');
    print('Data: ${res.data}');
  } catch (e) {
    print('Erro: $e');
  }
}
