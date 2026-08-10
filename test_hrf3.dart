import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://cmcpmppgpbrufrxznost.supabase.co', 'sb_publishable_C2JRdVkSfBaVeNE904dfTg_KTg6oksq');
  
  // Como já há uma em andamento para GFO-5385, vamos pegar uma placa diferente para testar o polling
  final res = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_pericia_hrf', 'param': 'placa', 'value': 'FHT-9430', 'aguardarRetorno': false});
  print('Primeira Chamada:');
  print(res.data);
  var token = res.data['tokenConsulta'];
  while (token != null) {
    print('Aguardando 10 segundos...');
    await Future.delayed(Duration(seconds: 10));
    final res2 = await client.functions.invoke('radar-consultar', body: {'produto': 'auto_pericia_hrf', 'param': 'placa', 'value': 'FHT-9430', 'tokenConsulta': token});
    print('Polling Chamada:');
    print(res2.data);
    if (res2.data['emProcessamento'] == true) {
      token = res2.data['tokenConsulta'];
    } else {
      break;
    }
  }
}
