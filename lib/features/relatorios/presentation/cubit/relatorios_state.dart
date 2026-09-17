import 'package:equatable/equatable.dart';
import '../../data/models/relatorio_dashboard_model.dart';
import '../../data/models/relatorio_filtros_model.dart';
import '../../data/models/vistoria_relatorio_item_model.dart';

abstract class RelatoriosState extends Equatable {
  const RelatoriosState();
  @override
  List<Object?> get props => [];
}

class RelatoriosInitial extends RelatoriosState {}

class RelatoriosLoading extends RelatoriosState {}

class RelatoriosLoaded extends RelatoriosState {
  final RelatorioDashboardModel dashboard;
  final RelatorioFiltrosModel filtros;
  final int paginaAtual;
  final int itensPorPagina;
  final List<Map<String, dynamic>> empresasMaster; // Para perfil Master alternar empresas
  final bool isExportando;
  final String? mensagemExportacao;

  const RelatoriosLoaded({
    required this.dashboard,
    required this.filtros,
    this.paginaAtual = 1,
    this.itensPorPagina = 10,
    this.empresasMaster = const [],
    this.isExportando = false,
    this.mensagemExportacao,
  });

  int get totalPaginas {
    final total = dashboard.itensVistoria.length;
    if (total == 0) return 1;
    return (total / itensPorPagina).ceil();
  }

  List<VistoriaRelatorioItemModel> get itensPaginados {
    final inicio = (paginaAtual - 1) * itensPorPagina;
    if (inicio >= dashboard.itensVistoria.length) return [];
    final fim = (inicio + itensPorPagina).clamp(0, dashboard.itensVistoria.length);
    return dashboard.itensVistoria.sublist(inicio, fim);
  }

  RelatoriosLoaded copyWith({
    RelatorioDashboardModel? dashboard,
    RelatorioFiltrosModel? filtros,
    int? paginaAtual,
    int? itensPorPagina,
    List<Map<String, dynamic>>? empresasMaster,
    bool? isExportando,
    String? mensagemExportacao,
    bool clearMensagemExportacao = false,
  }) {
    return RelatoriosLoaded(
      dashboard: dashboard ?? this.dashboard,
      filtros: filtros ?? this.filtros,
      paginaAtual: paginaAtual ?? this.paginaAtual,
      itensPorPagina: itensPorPagina ?? this.itensPorPagina,
      empresasMaster: empresasMaster ?? this.empresasMaster,
      isExportando: isExportando ?? this.isExportando,
      mensagemExportacao: clearMensagemExportacao
          ? null
          : (mensagemExportacao ?? this.mensagemExportacao),
    );
  }

  @override
  List<Object?> get props => [
        dashboard,
        filtros,
        paginaAtual,
        itensPorPagina,
        empresasMaster,
        isExportando,
        mensagemExportacao,
      ];
}

class RelatoriosError extends RelatoriosState {
  final String mensagem;
  const RelatoriosError(this.mensagem);
  @override
  List<Object?> get props => [mensagem];
}
