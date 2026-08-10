import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://cmcpmppgpbrufrxznost.supabase.co', 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq');
  final res = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_pericia_hrf', 'param': 'placa', 'value': 'GFO-5385', 'aguardarRetorno': false});
  print('Primeira Chamada:');
  print(res.data);
  final token = res.data['tokenConsulta'];
  if (token != null) {
    print('Aguardando 5 segundos...');
    await Future.delayed(Duration(seconds: 5));
    final res2 = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_pericia_hrf', 'param': 'placa', 'value': 'GFO-5385', 'tokenConsulta': token});
    print('Segunda Chamada (Detalhes):');
    print(res2.data);
  }
}
