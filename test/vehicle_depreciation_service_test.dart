import 'package:flutter_test/flutter_test.dart';
import 'package:app_vistoria/core/services/vehicle_depreciation_service.dart';

void main() {
  group('VehicleDepreciationService - Cenários Obrigatórios', () {
    // CENÁRIO 1: FIPE R$ 100.000, nenhum apontamento
    test('Cenário 1: Sem apontamentos deve resultar em Depreciação R\$ 0 e Valor Final = FIPE', () {
      final resultado = VehicleDepreciationService.processar(
        valorFipe: 100000.0,
        itens: [],
      );

      expect(resultado.fipeDisponivel, isTrue);
      expect(resultado.valorFipe, equals(100000.0));
      expect(resultado.depreciacaoTotal, equals(0.0));
      expect(resultado.valorFinal, equals(100000.0));
      expect(resultado.temApontamentos, isFalse);
    });

    // CENÁRIO 2: FIPE R$ 100.000, 1 apontamento (Peça R$ 2.000, Mão de obra R$ 500)
    test('Cenário 2: 1 apontamento (2000 + 500) -> Depreciação R\$ 2.500 e Valor Final R\$ 97.500', () {
      final itens = [
        const DepreciacaoItem(
          apontamentoId: 'apt_1',
          nomePeca: 'Para-choque dianteiro',
          descricaoProblema: 'Danificado',
          valorPeca: 2000.0,
          valorMaoDeObra: 500.0,
        ),
      ];

      final resultado = VehicleDepreciationService.processar(
        valorFipe: 100000.0,
        itens: itens,
      );

      expect(resultado.depreciacaoTotal, equals(2500.0));
      expect(resultado.valorFinal, equals(97500.0));
      expect(resultado.temApontamentos, isTrue);
    });

    // CENÁRIO 3: FIPE R$ 100.000, Apontamento A (2.000 + 500), Apontamento B (1.000 + 300)
    test('Cenário 3: Múltiplos apontamentos (2.500 + 1.300 = 3.800) -> Valor Final R\$ 96.200', () {
      final itens = [
        const DepreciacaoItem(
          apontamentoId: 'apt_A',
          nomePeca: 'Para-choque',
          descricaoProblema: 'Quebrado',
          valorPeca: 2000.0,
          valorMaoDeObra: 500.0,
        ),
        const DepreciacaoItem(
          apontamentoId: 'apt_B',
          nomePeca: 'Farol',
          descricaoProblema: 'Trincado',
          valorPeca: 1000.0,
          valorMaoDeObra: 300.0,
        ),
      ];

      final resultado = VehicleDepreciationService.processar(
        valorFipe: 100000.0,
        itens: itens,
      );

      expect(resultado.depreciacaoTotal, equals(3800.0));
      expect(resultado.valorFinal, equals(96200.0));
    });

    // CENÁRIO 4: Adicionar apontamento de R$ 2.500 e depois removê-lo
    test('Cenário 4: Adicionar apontamento e depois removê-lo recalcula para R\$ 0 e Valor Final = FIPE', () {
      final itens = <DepreciacaoItem>[
        const DepreciacaoItem(
          apontamentoId: 'apt_removivel',
          nomePeca: 'Porta',
          descricaoProblema: 'Amassada',
          valorPeca: 2000.0,
          valorMaoDeObra: 500.0,
        ),
      ];

      // Estado 1: com apontamento
      final resComItem = VehicleDepreciationService.processar(
        valorFipe: 100000.0,
        itens: itens,
      );
      expect(resComItem.depreciacaoTotal, equals(2500.0));
      expect(resComItem.valorFinal, equals(97500.0));

      // Estado 2: removeu o apontamento
      itens.removeWhere((i) => i.apontamentoId == 'apt_removivel');
      final resSemItem = VehicleDepreciationService.processar(
        valorFipe: 100000.0,
        itens: itens,
      );
      expect(resSemItem.depreciacaoTotal, equals(0.0));
      expect(resSemItem.valorFinal, equals(100000.0));
    });

    // CENÁRIO 5: Idempotência (gerar 1 ou 10 vezes produz rigorosamente o mesmo valor)
    test('Cenário 5: Idempotência - chamadas repetidas produzem exatamente o mesmo valor sem acumular', () {
      final itens = [
        const DepreciacaoItem(
          apontamentoId: 'apt_1',
          nomePeca: 'Capô',
          descricaoProblema: 'Risco profundo',
          valorPeca: 800.0,
          valorMaoDeObra: 400.0,
        ),
      ];

      double? primeiroValorFinal;
      double? primeiraDepreciacao;

      for (int i = 0; i < 10; i++) {
        final res = VehicleDepreciationService.processar(
          valorFipe: 80000.0,
          itens: itens,
        );

        if (i == 0) {
          primeiroValorFinal = res.valorFinal;
          primeiraDepreciacao = res.depreciacaoTotal;
        } else {
          expect(res.valorFinal, equals(primeiroValorFinal));
          expect(res.depreciacaoTotal, equals(primeiraDepreciacao));
        }
      }

      expect(primeiraDepreciacao, equals(1200.0));
      expect(primeiroValorFinal, equals(78800.0));
    });

    // CENÁRIO 6: Substituição por ID - não duplicar custo se o mesmo apontamento for reavaliado
    test('Cenário 6: Reanálise com mesmo apontamentoId substitui o valor anterior sem duplicar', () {
      final listaComDuplicatas = [
        const DepreciacaoItem(
          apontamentoId: 'apt_parachoque',
          nomePeca: 'Para-choque',
          descricaoProblema: 'Danificado',
          valorPeca: 1000.0,
          valorMaoDeObra: 500.0, // Total 1.500
        ),
        const DepreciacaoItem(
          apontamentoId: 'apt_parachoque',
          nomePeca: 'Para-choque',
          descricaoProblema: 'Danificado - Reavaliação',
          valorPeca: 800.0,
          valorMaoDeObra: 400.0, // Novo Total 1.200
        ),
      ];

      final resultado = VehicleDepreciationService.processar(
        valorFipe: 80000.0,
        itens: listaComDuplicatas,
      );

      // Deve substituir e valer 1.200, NUNCA somar 1.500 + 1.200 = 2.700
      expect(resultado.depreciacaoTotal, equals(1200.0));
      expect(resultado.valorFinal, equals(78800.0));
      expect(resultado.itens.length, equals(1));
    });

    // CENÁRIO 7: API FIPE indisponível (null)
    test('Cenário 7: FIPE indisponível -> fipeDisponivel = false, sem substituição por IA', () {
      final itens = [
        const DepreciacaoItem(
          apontamentoId: 'apt_1',
          nomePeca: 'Lanterna',
          descricaoProblema: 'Quebrada',
          valorPeca: 500.0,
          valorMaoDeObra: 150.0,
        ),
      ];

      final resultado = VehicleDepreciationService.processar(
        valorFipe: null,
        itens: itens,
      );

      expect(resultado.fipeDisponivel, isFalse);
      expect(resultado.valorFipe, isNull);
      expect(resultado.valorFinal, isNull);
      expect(resultado.depreciacaoTotal, equals(650.0));
    });

    // CENÁRIO 8: Piso de segurança >= 0 (valor final nunca pode ser negativo)
    test('Cenário 8: Depreciação superior à FIPE respeita o piso de 0', () {
      final itens = [
        const DepreciacaoItem(
          apontamentoId: 'apt_pt',
          nomePeca: 'Veículo sinistrado',
          descricaoProblema: 'Dano estrutural grave',
          valorPeca: 70000.0,
          valorMaoDeObra: 40000.0, // Total 110.000
        ),
      ];

      final resultado = VehicleDepreciationService.processar(
        valorFipe: 80000.0,
        itens: itens,
      );

      expect(resultado.depreciacaoTotal, equals(110000.0));
      expect(resultado.valorFinal, equals(0.0)); // max(0, 80000 - 110000)
    });

    // CENÁRIO 9: Sanitização de dados da IA
    test('Cenário 9: parseRespostaIa ignora campos proibidos e normaliza valores corrompidos', () {
      final jsonIa = [
        {
          'apontamentoId': '123',
          'nomePeca': 'Para-choque dianteiro',
          'descricaoProblema': 'Para-choque dianteiro danificado',
          'valorEstimadoPeca': 1200.0,
          'valorEstimadoMaoDeObra': 400.0,
          // Campos proibidos que devem ser solenemente ignorados:
          'valorVeiculo': 80000.0,
          'valorMercado': 85000.0,
          'valorFipe': 80000.0,
          'depreciacao': 5000.0,
          'percentualDepreciacao': 6.25,
          'valorVeiculoDepreciado': 75000.0,
          'valorFinal': 75000.0,
        },
        {
          'apontamentoId': '124',
          'nomePeca': 'Farol',
          'descricaoProblema': 'Farol com lente riscada',
          'valorEstimadoPeca': 'R\$ 350,50',
          'valorEstimadoMaoDeObra': -100.0, // Negativo deve normalizar para 0.0
        }
      ];

      final itens = VehicleDepreciationService.parseRespostaIa(jsonIa);
      expect(itens.length, equals(2));

      expect(itens[0].apontamentoId, equals('123'));
      expect(itens[0].valorPeca, equals(1200.0));
      expect(itens[0].valorMaoDeObra, equals(400.0));
      expect(itens[0].custoTotal, equals(1600.0));

      expect(itens[1].apontamentoId, equals('124'));
      expect(itens[1].valorPeca, equals(350.50));
      expect(itens[1].valorMaoDeObra, equals(0.0)); // Normalizado
      expect(itens[1].custoTotal, equals(350.50));
    });
  });
}
