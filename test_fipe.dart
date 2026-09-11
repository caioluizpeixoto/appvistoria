import 'lib/core/services/fipe_service.dart';

void main() async {
  print('--- Testando Fipe AUDI Q3 ---');
  final fipeAudi = await FipeService.consultarFipe(
    marca: 'AUDI',
    modelo: 'Q3',
    ano: 2020,
    tipoVeiculo: 'carros',
  );
  print('Audi Q3: valor=${fipeAudi?.valor}, marca=${fipeAudi?.marca}, modelo=${fipeAudi?.modelo}, codigo=${fipeAudi?.codigoFipe}');

  print('\n--- Testando Fipe AUDI Q3 1.4 TFSI ---');
  final fipeAudi2 = await FipeService.consultarFipe(
    marca: 'AUDI',
    modelo: 'Q3 1.4 TFSI',
    ano: 2020,
    tipoVeiculo: 'carros',
  );
  print('Audi Q3 1.4: valor=${fipeAudi2?.valor}, marca=${fipeAudi2?.marca}, modelo=${fipeAudi2?.modelo}, codigo=${fipeAudi2?.codigoFipe}');

  print('\n--- Testando Fipe RENAULT KANGOO ---');
  final fipeKangoo = await FipeService.consultarFipe(
    marca: 'RENAULT',
    modelo: 'KANGOO',
    ano: 2015,
    tipoVeiculo: 'carros',
  );
  print('Kangoo: valor=${fipeKangoo?.valor}, marca=${fipeKangoo?.marca}, modelo=${fipeKangoo?.modelo}, codigo=${fipeKangoo?.codigoFipe}');
}
