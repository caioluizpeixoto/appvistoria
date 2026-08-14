import 'package:flutter_test/flutter_test.dart';
import 'package:app_vistoria/core/utils/veiculo_parser.dart';

void main() {
  group('VeiculoParser Tests', () {
    test('Should parse I/JEEP I/JEEP GCHEROKEE LTD3.6L correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/JEEP I/JEEP GCHEROKEE LTD3.6L');
      expect(res.marca, 'JEEP');
      expect(res.modelo, 'GCHEROKEE LTD3.6L');
    });

    test('Should parse I/JEEP CHEROKEE correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/JEEP CHEROKEE');
      expect(res.marca, 'JEEP');
      expect(res.modelo, 'CHEROKEE');
    });

    test('Should parse VW/GOL 1.0 correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('VW/GOL 1.0');
      expect(res.marca, 'VW');
      expect(res.modelo, 'GOL 1.0');
    });

    test('Should parse FIAT/PALIO ATTRACTIV 1.0 correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('FIAT/PALIO ATTRACTIV 1.0');
      expect(res.marca, 'FIAT');
      expect(res.modelo, 'PALIO ATTRACTIV 1.0');
    });

    test('Should parse I/BMW 320I correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/BMW 320I');
      expect(res.marca, 'BMW');
      expect(res.modelo, '320I');
    });

    test('Should parse I/M.BENZ C180 correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/M.BENZ C180');
      expect(res.marca, 'M.BENZ');
      expect(res.modelo, 'C180');
    });

    test('Should parse I/LAND ROVER EVOQUE DYNAMIC 5D correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/LAND ROVER EVOQUE DYNAMIC 5D');
      expect(res.marca, 'LAND ROVER');
      expect(res.modelo, 'EVOQUE DYNAMIC 5D');
    });

    test('Should parse I/FORD I/FORD RANGER XLS correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/FORD I/FORD RANGER XLS');
      expect(res.marca, 'FORD');
      expect(res.modelo, 'RANGER XLS');
    });

    test('Should parse CHEVROLET/ONIX PLUS 1.0T correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('CHEVROLET/ONIX PLUS 1.0T');
      expect(res.marca, 'CHEVROLET');
      expect(res.modelo, 'ONIX PLUS 1.0T');
    });

    test('Should parse I/TOYOTA HILUX CD4X4 correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('I/TOYOTA HILUX CD4X4');
      expect(res.marca, 'TOYOTA');
      expect(res.modelo, 'HILUX CD4X4');
    });

    test('Should parse single brand correctly', () {
      final res = VeiculoParser.extrairMarcaModelo('JEEP');
      expect(res.marca, 'JEEP');
      expect(res.modelo, 'JEEP');
    });

    test('Should handle empty and null strings gracefully', () {
      final res1 = VeiculoParser.extrairMarcaModelo('');
      expect(res1.marca, '');
      expect(res1.modelo, '');

      final res2 = VeiculoParser.extrairMarcaModelo(null);
      expect(res2.marca, '');
      expect(res2.modelo, '');
    });
  });
}
