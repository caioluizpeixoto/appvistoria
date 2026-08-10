import 'package:supabase/supabase.dart';
import 'dart:convert';
void main() async {
  final client = SupabaseClient('https://cmcpmppgpbrufrxznost.supabase.co', 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq');
  
  final res = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_bin', 'param': 'placa', 'value': 'FHT-9430', 'aguardarRetorno': true});
  print(jsonEncode(res.data));
}
