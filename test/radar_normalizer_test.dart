import 'package:flutter_test/flutter_test.dart';
import 'package:app_vistoria/core/normalizers/radar_normalizer.dart';
import 'package:app_vistoria/core/normalizers/radar_normalized_data.dart';

void main() {
  group('RadarNormalizer Tests', () {
    test('Should parse JSON 01 correctly (SSP Online and IPVA (SEFAZ))', () {
      final json01 = '''
      {
        "consulta": {
          "resultados": [
            {
              "title": "SSP Online",
              "retorno": {
                "placa": "ABC1234",
                "renavam": "123456789",
                "marca": "VW/GOL",
                "multas": {
                  "lista": [
                    {
                      "valor": "130.16",
                      "descricao": "Excesso de velocidade"
                    }
                  ]
                }
              }
            },
            {
              "title": "IPVA (SEFAZ)",
              "retorno": {
                "ipva": [
                  {
                    "parcela": "Cota Única",
                    "valor": "1500.00",
                    "vencimento": "10/01/2026"
                  }
                ]
              }
            }
          ]
        }
      }
      ''';

      final result = RadarNormalizer.parse(json01);

      expect(result.veiculo.placa, 'ABC1234');
      expect(result.veiculo.renavam, '123456789');
      expect(result.veiculo.marcaModelo, 'VW/GOL');

      expect(result.multas.hasData, true);
      expect(result.multas.dados!.length, 1);
      expect(result.multas.dados![0].valor, '130.16');
      expect(result.multas.dados![0].descricao, 'Excesso de velocidade');

      expect(result.ipva.hasData, true);
      expect(result.ipva.dados!.length, 1);
      expect(result.ipva.dados![0].parcela, 'Cota Única');
      expect(result.ipva.dados![0].valor, '1500.00');
    });

    test('Should parse JSON 02 correctly (SSP Cortesia and IPVA as error string)', () {
      final json02 = '''
      {
        "consulta": {
          "resultados": [
            {
              "title": "SSP - Cortesia",
              "retorno": {
                "Dados Veículo": {
                  "data": {
                    "Placa": "XYZ9876",
                    "Renavam": "987654321",
                    "Marca / Modelo": "FIAT/UNO"
                  }
                },
                "Multas": {
                  "data": [
                    {
                      "Valor a Pagar": "195.23",
                      "Descrição da Infração": "Avançar sinal vermelho"
                    }
                  ]
                }
              }
            },
            {
              "title": "IPVA - Secretaria de Fazenda",
              "retorno": "Classe de serialize não encontrada"
            },
            {
              "title": "Dividas Ativas",
              "retorno": "DOCUMENTO NÃO POSSUÍ DÍVIDA ATIVA"
            }
          ]
        }
      }
      ''';

      final result = RadarNormalizer.parse(json02);

      expect(result.veiculo.placa, 'XYZ9876');
      expect(result.veiculo.renavam, '987654321');
      expect(result.veiculo.marcaModelo, 'FIAT/UNO');

      expect(result.multas.hasData, true);
      expect(result.multas.dados!.length, 1);
      expect(result.multas.dados![0].valor, '195.23');
      expect(result.multas.dados![0].descricao, 'Avançar sinal vermelho');

      expect(result.ipva.status, RadarModuleStatus.erro);
      expect(result.ipva.mensagem, 'Classe de serialize não encontrada');
      expect(result.ipva.hasData, false);
      expect(result.erros.length, 1);
      expect(result.erros[0].modulo, 'ipva');

      expect(result.dividasAtivas.status, RadarModuleStatus.nada_consta);
      expect(result.dividasAtivas.hasData, false);
    });
  });
}
