import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/empresa_rodape_helper.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../data/models/relatorio_filtros_model.dart';
import '../../data/repositories/relatorios_repository.dart';
import '../../services/relatorio_pdf_service.dart';
import '../../services/relatorio_csv_service.dart';
import 'relatorios_state.dart';

class RelatoriosCubit extends Cubit<RelatoriosState> {
  final RelatoriosRepository repository;
  final SupabaseClient supabase;

  RelatoriosCubit({
    required this.repository,
    required this.supabase,
  }) : super(RelatoriosInitial());

  /// Inicializa o carregamento com o período padrão ("Este mês")
  Future<void> inicializar() async {
    emit(RelatoriosLoading());
    try {
      final user = supabase.auth.currentUser;
      final isMaster = user?.isMaster ?? false;
      List<Map<String, dynamic>> empresas = [];

      if (isMaster) {
        final Map<String, Map<String, dynamic>> empresasMap = {};

        // 1. Sementes conhecidas no sistema
        EmpresaRodapeInfo.empresasConhecidas.forEach((cnpj, info) {
          final nomeCanonico = info.razaoSocial.toUpperCase().trim();
          empresasMap[nomeCanonico] = {
            'id': nomeCanonico,
            'razao_social': nomeCanonico,
            'cnpj': cnpj,
          };
        });

        // 2. Empresas cadastradas na tabela oficial do Supabase
        try {
          final res = await supabase
              .from('empresas')
              .select('id, razao_social, cnpj')
              .order('razao_social', ascending: true);
          for (final row in res) {
            final cnpj = (row['cnpj'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
            final rawNome = (row['razao_social'] as String? ?? '').trim();
            final nomeCanonico = _canonicalizarEmpresa(rawNome, cnpj);
            if (nomeCanonico.isNotEmpty) {
              empresasMap[nomeCanonico] = {
                'id': nomeCanonico,
                'razao_social': nomeCanonico,
                'cnpj': cnpj.isNotEmpty ? cnpj : (empresasMap[nomeCanonico]?['cnpj'] ?? ''),
              };
            }
          }
        } catch (_) {}

        // 3. Empresas distintas que já realizaram vistorias na nuvem
        try {
          final resVist = await supabase
              .from('vistorias_cloud')
              .select('empresa_nome, empresa_cnpj, user_id');
          for (final row in resVist) {
            final rawNome = (row['empresa_nome'] as String? ?? '').trim();
            final cnpj = (row['empresa_cnpj'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
            if (rawNome.isEmpty || rawNome.toUpperCase().contains('NÃO CADASTRADA')) continue;
            final nomeCanonico = _canonicalizarEmpresa(rawNome, cnpj);
            if (nomeCanonico.isNotEmpty) {
              empresasMap.putIfAbsent(nomeCanonico, () => {
                'id': nomeCanonico,
                'razao_social': nomeCanonico,
                'cnpj': cnpj,
              });
            }
          }
        } catch (_) {}

        empresas = empresasMap.values.toList()
          ..sort((a, b) => (a['razao_social'] as String).compareTo(b['razao_social'] as String));
      }

      final filtrosIniciais = RelatorioFiltrosModel.padrao();
      final dashboard = await repository.carregarDashboard(filtrosIniciais);

      emit(RelatoriosLoaded(
        dashboard: dashboard,
        filtros: filtrosIniciais,
        empresasMaster: empresas,
      ));
    } catch (e) {
      emit(RelatoriosError('Erro ao carregar relatório: $e'));
    }
  }

  /// Alterna período rápido (Hoje, 7 dias, este mês, mês anterior ou personalizado)
  Future<void> alterarPeriodo(
    TipoPeriodoFiltro periodo, {
    DateTimeRange? customRange,
  }) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(RelatoriosLoading());
    try {
      final novosFiltros = RelatorioFiltrosModel.paraPeriodo(
        periodo,
        customRange: customRange,
        cliente: currentState.filtros.cliente,
        tipoServico: currentState.filtros.tipoServico,
        perito: currentState.filtros.perito,
        digitador: currentState.filtros.digitador,
        unidade: currentState.filtros.unidade,
        status: currentState.filtros.status,
        queryBusca: currentState.filtros.queryBusca,
        empresaId: currentState.filtros.empresaId,
      );

      final dashboard = await repository.carregarDashboard(novosFiltros);
      emit(currentState.copyWith(
        dashboard: dashboard,
        filtros: novosFiltros,
        paginaAtual: 1,
      ));
    } catch (e) {
      emit(RelatoriosError('Erro ao alterar período: $e'));
    }
  }

  /// Atualiza filtros secundários (Cliente, Serviço, Perito, Digitador, Unidade, Status)
  Future<void> aplicarFiltrosSecundarios({
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
  }) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(RelatoriosLoading());
    try {
      final novosFiltros = currentState.filtros.copyWith(
        cliente: cliente,
        clearCliente: clearCliente,
        tipoServico: tipoServico,
        clearTipoServico: clearTipoServico,
        perito: perito,
        clearPerito: clearPerito,
        digitador: digitador,
        clearDigitador: clearDigitador,
        unidade: unidade,
        clearUnidade: clearUnidade,
        status: status,
        clearStatus: clearStatus,
      );

      final dashboard = await repository.carregarDashboard(novosFiltros);
      emit(currentState.copyWith(
        dashboard: dashboard,
        filtros: novosFiltros,
        paginaAtual: 1,
      ));
    } catch (e) {
      emit(RelatoriosError('Erro ao filtrar dados: $e'));
    }
  }

  /// Filtra em tempo real pelo campo de busca (placa, chassi, cliente, laudo)
  Future<void> buscar(String query) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    try {
      final novosFiltros = currentState.filtros.copyWith(queryBusca: query);
      final dashboard = await repository.carregarDashboard(novosFiltros);
      emit(currentState.copyWith(
        dashboard: dashboard,
        filtros: novosFiltros,
        paginaAtual: 1,
      ));
    } catch (_) {}
  }

  /// Altera empresa selecionada (Exclusivo para Master)
  Future<void> selecionarEmpresaMaster(String? empresaId) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(RelatoriosLoading());
    try {
      final novosFiltros = currentState.filtros.copyWith(
        empresaId: empresaId,
        clearEmpresaId: empresaId == null || empresaId == 'todas',
      );
      final dashboard = await repository.carregarDashboard(novosFiltros);
      emit(currentState.copyWith(
        dashboard: dashboard,
        filtros: novosFiltros,
        paginaAtual: 1,
      ));
    } catch (e) {
      emit(RelatoriosError('Erro ao trocar empresa: $e'));
    }
  }

  /// Paginação da tabela
  void mudarPagina(int novaPagina) {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;
    if (novaPagina < 1 || novaPagina > currentState.totalPaginas) return;
    emit(currentState.copyWith(paginaAtual: novaPagina));
  }

  void alterarItensPorPagina(int itens) {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;
    emit(currentState.copyWith(itensPorPagina: itens, paginaAtual: 1));
  }

  /// Limpa todos os filtros adicionais e busca
  Future<void> limparFiltros() async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(RelatoriosLoading());
    try {
      final filtrosLimpos = RelatorioFiltrosModel.paraPeriodo(
        currentState.filtros.tipoPeriodo,
        empresaId: currentState.filtros.empresaId,
      );
      final dashboard = await repository.carregarDashboard(filtrosLimpos);
      emit(currentState.copyWith(
        dashboard: dashboard,
        filtros: filtrosLimpos,
        paginaAtual: 1,
      ));
    } catch (e) {
      emit(RelatoriosError('Erro ao redefinir filtros: $e'));
    }
  }

  /// Gera e abre o visualizador de PDF oficial para impressão
  Future<void> exportarPdf({
    required TipoRelatorioExportacao tipo,
    required BuildContext context,
  }) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(currentState.copyWith(
      isExportando: true,
      mensagemExportacao: 'Gerando PDF diagramado em alta resolução...',
    ));

    try {
      final bytes = await RelatorioPdfService.gerarPdf(
        dashboard: currentState.dashboard,
        filtros: currentState.filtros,
        tipo: tipo,
      );

      emit(currentState.copyWith(isExportando: false, clearMensagemExportacao: true));

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: '${tipo.titulo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      emit(currentState.copyWith(
        isExportando: false,
        mensagemExportacao: 'Erro ao gerar PDF: $e',
      ));
    }
  }

  /// Gera e compartilha arquivo CSV formatado para Excel
  Future<void> exportarCsv({
    required TipoRelatorioExportacao tipo,
  }) async {
    final currentState = state;
    if (currentState is! RelatoriosLoaded) return;

    emit(currentState.copyWith(
      isExportando: true,
      mensagemExportacao: 'Gerando planilha Excel/CSV...',
    ));

    try {
      final bytes = RelatorioCsvService.gerarCsv(
        dashboard: currentState.dashboard,
        filtros: currentState.filtros,
        tipo: tipo,
      );

      emit(currentState.copyWith(isExportando: false, clearMensagemExportacao: true));

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${tipo.titulo.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    } catch (e) {
      emit(currentState.copyWith(
        isExportando: false,
        mensagemExportacao: 'Erro ao exportar CSV: $e',
      ));
    }
  }

  /// Padroniza nomes de empresas e CNPJs para eliminar duplicidades (ex: acentos, caixa, variações)
  String _canonicalizarEmpresa(String rawNome, String? cnpj) {
    final c = (cnpj ?? '').replaceAll(RegExp(r'\D'), '');
    final n = rawNome
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ç', 'C')
        .trim();

    if (c == '11977969000133' || n.contains('SUMARE')) {
      return 'SUMARÉ VISTORIAS';
    }
    if (c == '08420171000181' || n.contains('INDAIATUBA')) {
      return 'ULTRA VISÃO INDAIATUBA';
    }
    if (c == '08420171000424' || n.contains('SALTO')) {
      return 'ULTRA VISÃO SALTO';
    }
    if (c == '22931906000162' || n.contains('MONTE MOR')) {
      return 'ULTRA VISÃO MONTE MOR';
    }
    if (c == '24868718000162' || n.contains('AUTO PROVE') || n.contains('COSMOPOLIS')) {
      return 'AUTO PROVE VISTORIAS';
    }

    // Se for apenas "ULTRA VISAO" genérico (registro legado sem filial), unifica com a matriz
    if (n == 'ULTRA VISAO' || n == 'ULTRA VISAO VISTORIAS') {
      return 'ULTRA VISÃO INDAIATUBA';
    }

    return rawNome.trim().toUpperCase();
  }
}
