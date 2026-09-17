import 'package:intl/intl.dart';
import 'vistoria_relatorio_item_model.dart';
import 'fechamento_cliente_model.dart';

class RelatorioDashboardModel {
  // ── Indicadores Atuais ──────────────────────────────────────────────────────
  final int totalVistorias;
  final double faturamentoTotal;
  final double ticketMedio;
  final int quantidadeClientes;
  final int quantidadeConcluidos;
  final int quantidadePendentes;

  // ── Indicadores Período Anterior (para comparativo) ─────────────────────────
  final int totalVistoriasAnterior;
  final double faturamentoTotalAnterior;
  final double ticketMedioAnterior;
  final int quantidadeClientesAnterior;
  final int quantidadeConcluidosAnterior;
  final int quantidadePendentesAnterior;

  // ── Dados para os Gráficos ─────────────────────────────────────────────────
  final Map<DateTime, int> vistoriasPorDia;
  final Map<DateTime, double> faturamentoPorDia;
  final Map<String, int> servicosMaisRealizados;
  final Map<String, int> producaoPorCliente;
  final Map<String, int> producaoPorPerito;

  // ── Tabela e Fechamento ────────────────────────────────────────────────────
  final List<VistoriaRelatorioItemModel> itensVistoria;
  final List<FechamentoClienteModel> fechamentoClientes;

  // ── Filtros Disponíveis Extraídos ──────────────────────────────────────────
  final List<String> clientesDisponiveis;
  final List<String> servicosDisponiveis;
  final List<String> peritosDisponiveis;
  final List<String> digitadoresDisponiveis;
  final List<String> unidadesDisponiveis;
  final List<String> statusDisponiveis;

  // ── Identificação da Empresa ───────────────────────────────────────────────
  final String empresaNome;
  final String empresaCnpj;

  const RelatorioDashboardModel({
    required this.totalVistorias,
    required this.faturamentoTotal,
    required this.ticketMedio,
    required this.quantidadeClientes,
    required this.quantidadeConcluidos,
    required this.quantidadePendentes,
    required this.totalVistoriasAnterior,
    required this.faturamentoTotalAnterior,
    required this.ticketMedioAnterior,
    required this.quantidadeClientesAnterior,
    required this.quantidadeConcluidosAnterior,
    required this.quantidadePendentesAnterior,
    required this.vistoriasPorDia,
    required this.faturamentoPorDia,
    required this.servicosMaisRealizados,
    required this.producaoPorCliente,
    required this.producaoPorPerito,
    required this.itensVistoria,
    required this.fechamentoClientes,
    required this.clientesDisponiveis,
    required this.servicosDisponiveis,
    required this.peritosDisponiveis,
    required this.digitadoresDisponiveis,
    required this.unidadesDisponiveis,
    required this.statusDisponiveis,
    required this.empresaNome,
    required this.empresaCnpj,
  });

  // ── Variações Percentuais ──────────────────────────────────────────────────
  double get variacaoVistorias {
    if (totalVistoriasAnterior == 0) {
      return totalVistorias > 0 ? 100.0 : 0.0;
    }
    return ((totalVistorias - totalVistoriasAnterior) /
            totalVistoriasAnterior) *
        100.0;
  }

  double get variacaoFaturamento {
    if (faturamentoTotalAnterior == 0.0) {
      return faturamentoTotal > 0.0 ? 100.0 : 0.0;
    }
    return ((faturamentoTotal - faturamentoTotalAnterior) /
            faturamentoTotalAnterior) *
        100.0;
  }

  // ── Formatadores Monetários ────────────────────────────────────────────────
  String get faturamentoTotalFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(faturamentoTotal);

  String get ticketMedioFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(ticketMedio);

  String get variacaoVistoriasFormatada {
    final v = variacaoVistorias;
    final prefix = v > 0 ? '+' : '';
    return '$prefix${v.toStringAsFixed(1)}%';
  }

  String get variacaoFaturamentoFormatada {
    final v = variacaoFaturamento;
    final prefix = v > 0 ? '+' : '';
    return '$prefix${v.toStringAsFixed(1)}%';
  }
}
