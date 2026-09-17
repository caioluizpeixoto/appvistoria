import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../data/models/relatorio_dashboard_model.dart';
import '../data/models/relatorio_filtros_model.dart';
import 'relatorio_pdf_service.dart';

class RelatorioCsvService {
  /// Gera conteúdo CSV formatado para Excel (com BOM UTF-8 e separador ;)
  static Uint8List gerarCsv({
    required RelatorioDashboardModel dashboard,
    required RelatorioFiltrosModel filtros,
    required TipoRelatorioExportacao tipo,
  }) {
    List<List<dynamic>> rows = [];

    // Cabeçalho institucional
    rows.add(['RELATÓRIO ULTRA PRIME SOLUÇÕES VEICULARES']);
    rows.add(['Empresa:', dashboard.empresaNome]);
    rows.add(['Tipo:', tipo.titulo]);
    rows.add([
      'Período:',
      '${DateFormat('dd/MM/yyyy').format(filtros.dataInicio)} a ${DateFormat('dd/MM/yyyy').format(filtros.dataFim)}'
    ]);
    rows.add([
      'Data de Emissão:',
      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
    ]);
    rows.add([]); // Linha em branco

    switch (tipo) {
      case TipoRelatorioExportacao.completo:
      case TipoRelatorioExportacao.resumido:
        _montarTabelaCompleta(rows, dashboard);
        break;
      case TipoRelatorioExportacao.financeiro:
        _montarTabelaFinanceira(rows, dashboard);
        break;
      case TipoRelatorioExportacao.porCliente:
        _montarTabelaClientes(rows, dashboard);
        break;
      case TipoRelatorioExportacao.porServico:
        _montarTabelaServicos(rows, dashboard);
        break;
      case TipoRelatorioExportacao.porPerito:
        _montarTabelaPeritos(rows, dashboard);
        break;
    }

    // Csv.excel() configura automaticamente delimitador ';' e BOM UTF-8
    final csvString = Csv.excel().encode(rows);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  static void _montarTabelaCompleta(
      List<List<dynamic>> rows, RelatorioDashboardModel d) {
    rows.add([
      'Nº Laudo',
      'Data/Hora',
      'Veículo',
      'Ano',
      'Placa',
      'Chassi',
      'Cliente',
      'Serviço',
      'Perito',
      'Digitador',
      'Status',
      'Parecer Técnico',
      'Valor (R\$)',
    ]);

    for (final it in d.itensVistoria) {
      rows.add([
        it.numeroLaudo,
        it.dataFormatada,
        it.veiculo,
        it.ano,
        it.placa,
        it.chassi,
        it.cliente,
        it.servico,
        it.perito,
        it.digitador,
        it.statusFinal.isNotEmpty ? it.statusFinal : it.status.toUpperCase(),
        it.parecerTecnico,
        it.valor.toStringAsFixed(2).replaceAll('.', ','),
      ]);
    }

    rows.add([]);
    rows.add([
      'TOTAL GERAL',
      '${d.totalVistorias} vistorias',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'FATURAMENTO TOTAL',
      d.faturamentoTotal.toStringAsFixed(2).replaceAll('.', ','),
    ]);
  }

  static void _montarTabelaFinanceira(
      List<List<dynamic>> rows, RelatorioDashboardModel d) {
    rows.add([
      'Data',
      'Vistorias Realizadas',
      'Faturamento do Dia (R\$)',
      'Ticket Médio (R\$)',
    ]);

    final dias = d.faturamentoPorDia.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final dia in dias) {
      final fat = d.faturamentoPorDia[dia] ?? 0.0;
      final qtd = d.vistoriasPorDia[dia] ?? 0;
      final tkt = qtd > 0 ? (fat / qtd) : 0.0;
      rows.add([
        DateFormat('dd/MM/yyyy').format(dia),
        qtd,
        fat.toStringAsFixed(2).replaceAll('.', ','),
        tkt.toStringAsFixed(2).replaceAll('.', ','),
      ]);
    }

    rows.add([]);
    rows.add([
      'TOTAL',
      d.totalVistorias,
      d.faturamentoTotal.toStringAsFixed(2).replaceAll('.', ','),
      d.ticketMedio.toStringAsFixed(2).replaceAll('.', ','),
    ]);
  }

  static void _montarTabelaClientes(
      List<List<dynamic>> rows, RelatorioDashboardModel d) {
    rows.add([
      'Cliente / Razão Social',
      'Quantidade de Vistorias',
      'Faturamento Total (R\$)',
      'Ticket Médio (R\$)',
      '% do Faturamento',
    ]);

    for (final c in d.fechamentoClientes) {
      rows.add([
        c.clienteNome,
        c.quantidadeServicos,
        c.faturamentoTotal.toStringAsFixed(2).replaceAll('.', ','),
        c.ticketMedio.toStringAsFixed(2).replaceAll('.', ','),
        c.percentualFormatado,
      ]);
    }

    rows.add([]);
    rows.add([
      'TOTAL',
      d.totalVistorias,
      d.faturamentoTotal.toStringAsFixed(2).replaceAll('.', ','),
      d.ticketMedio.toStringAsFixed(2).replaceAll('.', ','),
      '100%',
    ]);
  }

  static void _montarTabelaServicos(
      List<List<dynamic>> rows, RelatorioDashboardModel d) {
    rows.add([
      'Modalidade de Vistoria',
      'Quantidade Realizada',
      '% de Participação',
    ]);

    for (final e in d.servicosMaisRealizados.entries) {
      final perc = d.totalVistorias > 0
          ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
          : '0.0';
      rows.add([e.key, e.value, '$perc%']);
    }

    rows.add([]);
    rows.add(['TOTAL', d.totalVistorias, '100%']);
  }

  static void _montarTabelaPeritos(
      List<List<dynamic>> rows, RelatorioDashboardModel d) {
    rows.add([
      'Perito / Vistoriador',
      'Laudos Concluídos',
      '% da Produção',
    ]);

    for (final e in d.producaoPorPerito.entries) {
      final perc = d.totalVistorias > 0
          ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
          : '0.0';
      rows.add([e.key, e.value, '$perc%']);
    }

    rows.add([]);
    rows.add(['TOTAL', d.totalVistorias, '100%']);
  }
}
