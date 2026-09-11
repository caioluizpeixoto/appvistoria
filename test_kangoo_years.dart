import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/core/services/fipe_service.dart';

void main() async {
  final anos = [2010, 2012, 2014, 2015, 2016, 2018, 2020, 2022, 2024];
  for (final a in anos) {
    final res = await FipeService.consultarFipe(
      marca: 'RENAULT',
      modelo: 'KANGOO',
      ano: a,
    );
    print('Ano $a -> Modelo FIPE: ${res?.modelo} | Valor: ${res?.valor}');
  }
}
