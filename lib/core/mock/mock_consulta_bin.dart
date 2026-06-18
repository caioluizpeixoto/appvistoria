import 'dart:math';

import '../../features/consulta_bin/domain/entities/consulta_bin_entity.dart';

/// Mock de consulta BIN — simula resposta de API com dados realistas.
/// 30% dos casos têm divergência de motor.
/// 10% dos casos têm restrição ativa.
class MockConsultaBinDatasource {
  static final _random = Random();

  Future<ConsultaBinEntity> consultar(String placa) async {
    // Simula delay de rede (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    final temDivergenciaMotor = _random.nextDouble() < 0.30;
    final temRestricao = _random.nextDouble() < 0.10;

    final chassi =
        '9BWDB45U5ET${_random.nextInt(999999).toString().padLeft(6, '0')}';
    const motorFabrica = 'CCRC09875';
    final motorEstadual = temDivergenciaMotor ? 'CCRC09876' : motorFabrica;

    return ConsultaBinEntity(
      id: placa,
      placa: placa.toUpperCase(),
      chassi: chassi,
      restricoes: temRestricao,
      debitos: false,
      leilao: false,
      sinistro: false,
      situacao: temRestricao ? 'RESTRIÇÃO ATIVA' : 'CIRCULAÇÃO',
      proprietarioAtual: 'JOÃO DA SILVA',
      historicoProprietarios: const [
        ProprietarioEntity(nome: 'MARIA SOUZA', ano: 2018, uf: 'SP'),
        ProprietarioEntity(nome: 'PEDRO ALVES', ano: 2020, uf: 'SP'),
        ProprietarioEntity(nome: 'JOÃO DA SILVA', ano: 2022, uf: 'SP'),
      ],
      marca: 'VOLKSWAGEN',
      modelo: 'VOYAGE 1.6',
      anoFabricacao: 2014,
      anoModelo: 2014,
      cor: 'BRANCA',
      combustivel: 'ÁLCOOL/GASOLINA',
      motorFabrica: motorFabrica,
      motorEstadual: motorEstadual,
      consultadoEm: DateTime.now(),
    );
  }
}
