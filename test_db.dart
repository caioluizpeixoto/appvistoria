import 'package:supabase/supabase.dart';
import 'dart:io';
void main() async {
  final client = SupabaseClient('https://cmcpmppgpbrufrxznost.supabase.co', 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq');
  final res = await client.from('autocred_consultas').select('retorno_bruto').limit(2);
  for (final row in res) {
    print(row['retorno_bruto']);
    print('---');
  }
  exit(0);
}
