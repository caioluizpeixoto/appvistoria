import 'package:app_vistoria/core/services/fipe_service.dart';

void main() async {
  print('--- Teste Gol 1.0 2021 ---');
  final gol2021 = await FipeService.consultarFipe(
    marca: 'VOLKSWAGEN',
    modelo: 'VW/GOL 1.0',
    ano: 2021,
  );
  print('Gol 2021: ${gol2021?.modelo} -> ${gol2021?.valor} (Cod: ${gol2021?.codigoFipe})');

  print('\n--- Teste Gol 1.6 2021 ---');
  final gol16_2021 = await FipeService.consultarFipe(
    marca: 'VW',
    modelo: 'GOL 1.6 MSI',
    ano: 2021,
  );
  print('Gol 1.6 2021: ${gol16_2021?.modelo} -> ${gol16_2021?.valor} (Cod: ${gol16_2021?.codigoFipe})');

  print('\n--- Teste Kangoo 2015 ---');
  final kangoo = await FipeService.consultarFipe(
    marca: 'RENAULT',
    modelo: 'KANGOO 1.0',
    ano: 2015,
  );
  print('Kangoo 2015: ${kangoo?.modelo} -> ${kangoo?.valor}');

  print('\n--- Teste Audi Q3 2020 ---');
  final audi = await FipeService.consultarFipe(
    marca: 'AUDI',
    modelo: 'Q3',
    ano: 2020,
  );
  print('Audi Q3 2020: ${audi?.modelo} -> ${audi?.valor}');
}
