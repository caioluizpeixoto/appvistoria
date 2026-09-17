import 'package:flutter_test/flutter_test.dart';
import 'package:app_vistoria/features/relatorios/data/models/relatorio_filtros_model.dart';
import 'package:app_vistoria/features/relatorios/data/models/vistoria_relatorio_item_model.dart';
import 'package:app_vistoria/features/relatorios/data/models/fechamento_cliente_model.dart';
import 'package:app_vistoria/features/relatorios/data/models/relatorio_dashboard_model.dart';
import 'package:app_vistoria/features/relatorios/services/relatorio_csv_service.dart';
import 'package:app_vistoria/features/relatorios/services/relatorio_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RelatorioFiltrosModel Tests', () {
    test('paraPeriodo hoje should produce correct start and end dates', () {
      final filtros = RelatorioFiltrosModel.paraPeriodo(TipoPeriodoFiltro.hoje);
      expect(filtros.tipoPeriodo, TipoPeriodoFiltro.hoje);
      expect(filtros.dataInicio.hour, 0);
      expect(filtros.dataInicio.minute, 0);
      expect(filtros.dataFim.hour, 23);
      expect(filtros.dataFim.minute, 59);
      expect(filtros.dataFim.isAfter(filtros.dataInicio), isTrue);
      expect(filtros.dataInicio.isAfter(filtros.dataInicioAnterior), isTrue);
    });

    test('paraPeriodo ultimos7Dias should span 7 days', () {
      final filtros =
          RelatorioFiltrosModel.paraPeriodo(TipoPeriodoFiltro.ultimos7Dias);
      final diff = filtros.dataFim.difference(filtros.dataInicio).inDays;
      expect(diff, 6); // start to end is 6 full days (inclusive 7 days)
    });

    test('copyWith preserves and clears filters correctly', () {
      final filtros = RelatorioFiltrosModel.padrao();
      final comCliente = filtros.copyWith(cliente: 'Cliente Teste');
      expect(comCliente.cliente, 'Cliente Teste');

      final limpo = comCliente.copyWith(clearCliente: true);
      expect(limpo.cliente, isNull);
    });
  });

  group('VistoriaRelatorioItemModel Parsing Tests', () {
    test('parses real Supabase row structure into clean model', () {
      final mockRow = {
        'id': 'vst-123',
        'numero_laudo': 'VST-96230309',
        'created_at': '2026-09-09T18:36:27.981258+00:00',
        'placa': 'BXZ2I08',
        'chassi': '99ABJ68U2H4001624',
        'status': 'concluido',
        'tipo_vistoria': 'Vistoria Cautelar Croqui + Avarias',
        'empresa_nome': 'Sumaré Vistorias',
        'dados_completos': {
          'vistoria': {
            'clienteNome': 'Particular',
            'vistoriadorNome': 'Ubiratan Soares',
            'unidade': 'Sumaré Matriz',
            'statusFinal': 'Conforme',
            'parecerTecnico': 'Veículo aprovado',
            'pdfUrl': 'https://supabase.co/laudos/laudo.pdf',
          },
          'veiculo': {
            'marca': 'AUDI',
            'modelo': 'Q3 1.4TFSI',
            'anoFabricacao': 2016,
            'anoModelo': 2017,
          }
        }
      };

      final item = VistoriaRelatorioItemModel.fromSupabase(mockRow);

      expect(item.id, 'vst-123');
      expect(item.numeroLaudo, 'VST-96230309');
      expect(item.placa, 'BXZ2I08');
      expect(item.chassi, '99ABJ68U2H4001624');
      expect(item.cliente, 'PARTICULAR');
      expect(item.perito, 'UBIRATAN SOARES');
      expect(item.unidade, 'SUMARÉ MATRIZ');
      expect(item.statusFinal, 'Conforme');
      expect(item.isConcluido, isTrue);
      expect(item.ano, '2016/2017');
      expect(item.valor, 180.00); // Preço padrão para Croqui + Avarias
    });
  });

  group('RelatorioDashboardModel Calculations Tests', () {
    test('computes percentage variations correctly', () {
      final item1 = VistoriaRelatorioItemModel(
        id: '1',
        numeroLaudo: 'VST-1',
        data: DateTime(2026, 9, 10),
        veiculo: 'VW GOL',
        ano: '2020',
        placa: 'ABC1234',
        chassi: '123456',
        cliente: 'CLIENTE A',
        servico: 'Vistoria Cautelar Carro',
        perito: 'PERITO 1',
        digitador: 'DIGITADOR 1',
        unidade: 'MATRIZ',
        status: 'concluido',
        statusFinal: 'Conforme',
        parecerTecnico: 'OK',
        valor: 150.00,
      );

      final item2 = VistoriaRelatorioItemModel(
        id: '2',
        numeroLaudo: 'VST-2',
        data: DateTime(2026, 9, 11),
        veiculo: 'FIAT PALIO',
        ano: '2019',
        placa: 'DEF5678',
        chassi: '789012',
        cliente: 'CLIENTE A',
        servico: 'Vistoria Cautelar Carro',
        perito: 'PERITO 1',
        digitador: 'DIGITADOR 1',
        unidade: 'MATRIZ',
        status: 'concluido',
        statusFinal: 'Conforme',
        parecerTecnico: 'OK',
        valor: 150.00,
      );

      final model = RelatorioDashboardModel(
        totalVistorias: 2,
        faturamentoTotal: 300.00,
        ticketMedio: 150.00,
        quantidadeClientes: 1,
        quantidadeConcluidos: 2,
        quantidadePendentes: 0,
        totalVistoriasAnterior: 1,
        faturamentoTotalAnterior: 150.00,
        ticketMedioAnterior: 150.00,
        quantidadeClientesAnterior: 1,
        quantidadeConcluidosAnterior: 1,
        quantidadePendentesAnterior: 0,
        vistoriasPorDia: {DateTime(2026, 9, 10): 1, DateTime(2026, 9, 11): 1},
        faturamentoPorDia: {
          DateTime(2026, 9, 10): 150.00,
          DateTime(2026, 9, 11): 150.00
        },
        servicosMaisRealizados: {'Vistoria Cautelar Carro': 2},
        producaoPorCliente: {'CLIENTE A': 2},
        producaoPorPerito: {'PERITO 1': 2},
        itensVistoria: [item1, item2],
        fechamentoClientes: [
          const FechamentoClienteModel(
            clienteNome: 'CLIENTE A',
            quantidadeServicos: 2,
            faturamentoTotal: 300.00,
            ticketMedio: 150.00,
            percentualFaturamento: 100.0,
            servicosRealizados: {'Vistoria Cautelar Carro': 2},
          )
        ],
        clientesDisponiveis: ['CLIENTE A'],
        servicosDisponiveis: ['Vistoria Cautelar Carro'],
        peritosDisponiveis: ['PERITO 1'],
        digitadoresDisponiveis: ['DIGITADOR 1'],
        unidadesDisponiveis: ['MATRIZ'],
        statusDisponiveis: ['concluido'],
        empresaNome: 'ULTRA PRIME INDAIATUBA',
        empresaCnpj: '08420171000181',
      );

      expect(model.variacaoVistorias, 100.0);
      expect(model.variacaoVistoriasFormatada, '+100.0%');
      expect(model.variacaoFaturamento, 100.0);
      expect(model.variacaoFaturamentoFormatada, '+100.0%');
      expect(model.ticketMedioFormatado, 'R\$ 150,00');
    });
  });

  group('RelatorioCsvService Tests', () {
    test('generates valid Excel-compatible CSV with UTF-8 BOM and semicolon', () {
      final model = RelatorioDashboardModel(
        totalVistorias: 1,
        faturamentoTotal: 180.00,
        ticketMedio: 180.00,
        quantidadeClientes: 1,
        quantidadeConcluidos: 1,
        quantidadePendentes: 0,
        totalVistoriasAnterior: 0,
        faturamentoTotalAnterior: 0,
        ticketMedioAnterior: 0,
        quantidadeClientesAnterior: 0,
        quantidadeConcluidosAnterior: 0,
        quantidadePendentesAnterior: 0,
        vistoriasPorDia: {DateTime(2026, 9, 10): 1},
        faturamentoPorDia: {DateTime(2026, 9, 10): 180.00},
        servicosMaisRealizados: {'Vistoria Cautelar': 1},
        producaoPorCliente: {'CLIENTE X': 1},
        producaoPorPerito: {'PERITO Y': 1},
        itensVistoria: [
          VistoriaRelatorioItemModel(
            id: '1',
            numeroLaudo: 'VST-1234',
            data: DateTime(2026, 9, 10, 14, 30),
            veiculo: 'TOYOTA COROLLA',
            ano: '2022/2023',
            placa: 'BRA2E19',
            chassi: '9BRBL42EX',
            cliente: 'CLIENTE X',
            servico: 'Vistoria Cautelar',
            perito: 'PERITO Y',
            digitador: 'OPERADOR Z',
            unidade: 'MATRIZ',
            status: 'concluido',
            statusFinal: 'Conforme',
            parecerTecnico: 'Aprovado',
            valor: 180.00,
          )
        ],
        fechamentoClientes: [],
        clientesDisponiveis: [],
        servicosDisponiveis: [],
        peritosDisponiveis: [],
        digitadoresDisponiveis: [],
        unidadesDisponiveis: [],
        statusDisponiveis: [],
        empresaNome: 'ULTRA PRIME',
        empresaCnpj: '08420171000181',
      );

      final filtros = RelatorioFiltrosModel.padrao();
      final csvBytes = RelatorioCsvService.gerarCsv(
        dashboard: model,
        filtros: filtros,
        tipo: TipoRelatorioExportacao.completo,
      );

      // Deve começar com UTF-8 BOM: 0xEF, 0xBB, 0xBF
      expect(csvBytes.length, greaterThan(3));
      expect(csvBytes[0], 0xEF);
      expect(csvBytes[1], 0xBB);
      expect(csvBytes[2], 0xBF);

      final content = String.fromCharCodes(csvBytes.sublist(3));
      expect(content, contains('ULTRA PRIME'));
      expect(content, contains('VST-1234'));
      expect(content, contains('BRA2E19'));
      expect(content, contains('TOYOTA COROLLA'));
    });
  });

  group('RelatorioPdfService Tests', () {
    test('generates valid PDF bytes without throwing', () async {
      final model = RelatorioDashboardModel(
        totalVistorias: 1,
        faturamentoTotal: 180.00,
        ticketMedio: 180.00,
        quantidadeClientes: 1,
        quantidadeConcluidos: 1,
        quantidadePendentes: 0,
        totalVistoriasAnterior: 0,
        faturamentoTotalAnterior: 0,
        ticketMedioAnterior: 0,
        quantidadeClientesAnterior: 0,
        quantidadeConcluidosAnterior: 0,
        quantidadePendentesAnterior: 0,
        vistoriasPorDia: {DateTime(2026, 9, 10): 1},
        faturamentoPorDia: {DateTime(2026, 9, 10): 180.00},
        servicosMaisRealizados: {'Vistoria Cautelar': 1},
        producaoPorCliente: {'CLIENTE X': 1},
        producaoPorPerito: {'PERITO Y': 1},
        itensVistoria: [
          VistoriaRelatorioItemModel(
            id: '1',
            numeroLaudo: 'VST-1234',
            data: DateTime(2026, 9, 10, 14, 30),
            veiculo: 'TOYOTA COROLLA',
            ano: '2022/2023',
            placa: 'BRA2E19',
            chassi: '9BRBL42EX',
            cliente: 'CLIENTE X',
            servico: 'Vistoria Cautelar',
            perito: 'PERITO Y',
            digitador: 'OPERADOR Z',
            unidade: 'MATRIZ',
            status: 'concluido',
            statusFinal: 'Conforme',
            parecerTecnico: 'Aprovado',
            valor: 180.00,
          )
        ],
        fechamentoClientes: [
          const FechamentoClienteModel(
            clienteNome: 'CLIENTE X',
            quantidadeServicos: 1,
            faturamentoTotal: 180.00,
            ticketMedio: 180.00,
            percentualFaturamento: 100.0,
            servicosRealizados: {'Vistoria Cautelar': 1},
          )
        ],
        clientesDisponiveis: ['CLIENTE X'],
        servicosDisponiveis: ['Vistoria Cautelar'],
        peritosDisponiveis: ['PERITO Y'],
        digitadoresDisponiveis: ['OPERADOR Z'],
        unidadesDisponiveis: ['MATRIZ'],
        statusDisponiveis: ['concluido'],
        empresaNome: 'ULTRA PRIME TESTE',
        empresaCnpj: '08420171000181',
      );

      final filtros = RelatorioFiltrosModel.padrao();

      // Testar geração dos tipos principais
      final pdfResumido = await RelatorioPdfService.gerarPdf(
        dashboard: model,
        filtros: filtros,
        tipo: TipoRelatorioExportacao.resumido,
      );
      expect(pdfResumido, isNotEmpty);
      expect(pdfResumido.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // "%PDF" header

      final pdfCompleto = await RelatorioPdfService.gerarPdf(
        dashboard: model,
        filtros: filtros,
        tipo: TipoRelatorioExportacao.completo,
      );
      expect(pdfCompleto, isNotEmpty);
      expect(pdfCompleto.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // "%PDF" header
    });
  });
}
