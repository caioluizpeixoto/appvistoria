import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://cmcpmppgpbrufrxznost.supabase.co', 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq');
  final res = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_pericia_hrf', 'param': 'placa', 'value': 'GFO-5385', 'aguardarRetorno': false});
  print('Chamada repetida:');
  print(res.data);
}
