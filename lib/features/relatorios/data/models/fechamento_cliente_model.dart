import 'package:intl/intl.dart';

class FechamentoClienteModel {
  final String clienteNome;
  final int quantidadeServicos;
  final double faturamentoTotal;
  final double ticketMedio;
  final double percentualFaturamento;
  final Map<String, int> servicosRealizados;

  const FechamentoClienteModel({
    required this.clienteNome,
    required this.quantidadeServicos,
    required this.faturamentoTotal,
    required this.ticketMedio,
    required this.percentualFaturamento,
    required this.servicosRealizados,
  });

  String get faturamentoFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(faturamentoTotal);

  String get ticketMedioFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(ticketMedio);

  String get percentualFormatado =>
      '${percentualFaturamento.toStringAsFixed(1)}%';
}
