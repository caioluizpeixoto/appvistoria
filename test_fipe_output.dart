import 'package:app_vistoria/core/services/fipe_service.dart';

void main() async {
  final fipeInfo = await FipeService.consultarFipe(
    marca: 'VW - VolksWagen',
    modelo: 'Gol 1.0',
    ano: 2021,
    tipoVeiculo: 'carros',
  );
  if (fipeInfo != null) {
    print('SUCESSO: ' + fipeInfo.valor.toString() + ' | ' + fipeInfo.modelo.toString() + ' | ' + fipeInfo.codigoFipe.toString());
  } else {
    print('FALHA: Retornou null');
  }
}
