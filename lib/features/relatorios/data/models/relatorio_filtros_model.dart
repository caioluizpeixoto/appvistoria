import 'package:flutter/material.dart';

enum TipoPeriodoFiltro {
  hoje,
  ultimos7Dias,
  esteMes,
  mesAnterior,
  personalizado,
}

extension TipoPeriodoFiltroExt on TipoPeriodoFiltro {
  String get label {
    switch (this) {
      case TipoPeriodoFiltro.hoje:
        return 'Hoje';
      case TipoPeriodoFiltro.ultimos7Dias:
        return 'Últimos 7 dias';
      case TipoPeriodoFiltro.esteMes:
        return 'Este mês';
      case TipoPeriodoFiltro.mesAnterior:
        return 'Mês anterior';
      case TipoPeriodoFiltro.personalizado:
        return 'Personalizado';
    }
  }
}

class RelatorioFiltrosModel {
  final TipoPeriodoFiltro tipoPeriodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final DateTime dataInicioAnterior;
  final DateTime dataFimAnterior;

  final String? cliente;
  final String? tipoServico;
  final String? perito;
  final String? digitador;
  final String? unidade;
  final String? status;
  final String queryBusca;
  final String? empresaId; // Utilizado quando Master seleciona uma empresa específica

  const RelatorioFiltrosModel({
    required this.tipoPeriodo,
    required this.dataInicio,
    required this.dataFim,
    required this.dataInicioAnterior,
    required this.dataFimAnterior,
    this.cliente,
    this.tipoServico,
    this.perito,
    this.digitador,
    this.unidade,
    this.status,
    this.queryBusca = '',
    this.empresaId,
  });

  /// Construtor padrão com período inicial "Este mês"
  factory RelatorioFiltrosModel.padrao({String? empresaId}) {
    return RelatorioFiltrosModel.paraPeriodo(
      TipoPeriodoFiltro.esteMes,
      empresaId: empresaId,
    );
  }

  /// Gera os intervalos corrente e anterior baseados no tipo selecionado
  factory RelatorioFiltrosModel.paraPeriodo(
    TipoPeriodoFiltro periodo, {
    DateTimeRange? customRange,
    String? cliente,
    String? tipoServico,
    String? perito,
    String? digitador,
    String? unidade,
    String? status,
    String queryBusca = '',
    String? empresaId,
  }) {
    final now = DateTime.now();
    DateTime inicio;
    DateTime fim;
    DateTime inicioAnt;
    DateTime fimAnt;

    switch (periodo) {
      case TipoPeriodoFiltro.hoje:
        inicio = DateTime(now.year, now.month, now.day, 0, 0, 0);
        fim = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final ontem = now.subtract(const Duration(days: 1));
        inicioAnt = DateTime(ontem.year, ontem.month, ontem.day, 0, 0, 0);
        fimAnt = DateTime(ontem.year, ontem.month, ontem.day, 23, 59, 59, 999);
        break;

      case TipoPeriodoFiltro.ultimos7Dias:
        fim = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        inicio = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        final diff = fim.difference(inicio);
        fimAnt = inicio.subtract(const Duration(milliseconds: 1));
        inicioAnt = fimAnt.subtract(diff);
        break;

      case TipoPeriodoFiltro.esteMes:
        inicio = DateTime(now.year, now.month, 1, 0, 0, 0);
        fim = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        // Mês anterior completo para base justa de comparação
        inicioAnt = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        fimAnt = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        break;

      case TipoPeriodoFiltro.mesAnterior:
        inicio = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
        fim = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        // Dois meses atrás
        inicioAnt = DateTime(now.year, now.month - 2, 1, 0, 0, 0);
        fimAnt = DateTime(now.year, now.month - 1, 0, 23, 59, 59, 999);
        break;

      case TipoPeriodoFiltro.personalizado:
        if (customRange != null) {
          inicio = DateTime(customRange.start.year, customRange.start.month,
              customRange.start.day, 0, 0, 0);
          fim = DateTime(customRange.end.year, customRange.end.month,
              customRange.end.day, 23, 59, 59, 999);
        } else {
          inicio = DateTime(now.year, now.month, 1, 0, 0, 0);
          fim = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        }
        final duracao = fim.difference(inicio);
        fimAnt = inicio.subtract(const Duration(milliseconds: 1));
        inicioAnt = fimAnt.subtract(duracao);
        break;
    }

    return RelatorioFiltrosModel(
      tipoPeriodo: periodo,
      dataInicio: inicio,
      dataFim: fim,
      dataInicioAnterior: inicioAnt,
      dataFimAnterior: fimAnt,
      cliente: cliente,
      tipoServico: tipoServico,
      perito: perito,
      digitador: digitador,
      unidade: unidade,
      status: status,
      queryBusca: queryBusca,
      empresaId: empresaId,
    );
  }

  RelatorioFiltrosModel copyWith({
    TipoPeriodoFiltro? tipoPeriodo,
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataInicioAnterior,
    DateTime? dataFimAnterior,
    String? cliente,
    bool clearCliente = false,
    String? tipoServico,
    bool clearTipoServico = false,
    String? perito,
    bool clearPerito = false,
    String? digitador,
    bool clearDigitador = false,
    String? unidade,
    bool clearUnidade = false,
    String? status,
    bool clearStatus = false,
    String? queryBusca,
    String? empresaId,
    bool clearEmpresaId = false,
  }) {
    return RelatorioFiltrosModel(
      tipoPeriodo: tipoPeriodo ?? this.tipoPeriodo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      dataInicioAnterior: dataInicioAnterior ?? this.dataInicioAnterior,
      dataFimAnterior: dataFimAnterior ?? this.dataFimAnterior,
      cliente: clearCliente ? null : (cliente ?? this.cliente),
      tipoServico:
          clearTipoServico ? null : (tipoServico ?? this.tipoServico),
      perito: clearPerito ? null : (perito ?? this.perito),
      digitador: clearDigitador ? null : (digitador ?? this.digitador),
      unidade: clearUnidade ? null : (unidade ?? this.unidade),
      status: clearStatus ? null : (status ?? this.status),
      queryBusca: queryBusca ?? this.queryBusca,
      empresaId: clearEmpresaId ? null : (empresaId ?? this.empresaId),
    );
  }
}
