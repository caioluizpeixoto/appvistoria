import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/empresa_rodape_helper.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../models/relatorio_filtros_model.dart';
import '../models/vistoria_relatorio_item_model.dart';
import '../models/fechamento_cliente_model.dart';
import '../models/relatorio_dashboard_model.dart';

class RelatoriosRepository {
  final SupabaseClient supabase;

  RelatoriosRepository({required this.supabase});

  /// Busca os preços de serviços configurados no Supabase
  Future<Map<String, double>> obterTabelaPrecos() async {
    try {
      final res = await supabase
          .from('service_prices')
          .select('service_code, name, price')
          .eq('active', true);

      final Map<String, double> mapaPrecos = {};
      for (final item in res) {
        final code = (item['service_code'] as String? ?? '').toLowerCase();
        final name = (item['name'] as String? ?? '').toLowerCase();
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        if (code.isNotEmpty) mapaPrecos[code] = price;
        if (name.isNotEmpty) mapaPrecos[name] = price;
      }
      return mapaPrecos;
    } catch (e) {
      // Falha silenciosa no service_prices, utiliza os preços padrão
      return {};
    }
  }

  /// Carrega todos os dados do dashboard respeitando os filtros e o isolamento por empresa
  Future<RelatorioDashboardModel> carregarDashboard(
      RelatorioFiltrosModel filtros) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final isMaster = user.isMaster;

    // 1. Consulta de Vistorias no Supabase
    var queryAtual = supabase.from('vistorias_cloud').select();
    var queryAnterior = supabase.from('vistorias_cloud').select();

    if (!isMaster) {
      // ── REGRA DE ISOLAMENTO TOTAL PARA EMPRESA COMUM ──
      // Empresa comum NUNCA pode ver outras lojas / filiais / empresas.
      queryAtual = queryAtual.eq('user_id', user.id);
      queryAnterior = queryAnterior.eq('user_id', user.id);
    } else {
      // ── MASTER: PODE VER TODAS OU FILTRAR POR EMPRESA ──
      final filtro = filtros.empresaId?.trim();
      if (filtro != null && filtro.isNotEmpty && filtro != 'todas') {
        final digits = filtro.replaceAll(RegExp(r'\D'), '');
        final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(filtro);
        final upper = filtro.toUpperCase();

        if (isUuid) {
          queryAtual = queryAtual.eq('user_id', filtro);
          queryAnterior = queryAnterior.eq('user_id', filtro);
        } else if (upper.contains('SUMAR') || digits == '11977969000133') {
          queryAtual = queryAtual.or('empresa_nome.ilike.%Sumar%,empresa_cnpj.ilike.%11977969000133%');
          queryAnterior = queryAnterior.or('empresa_nome.ilike.%Sumar%,empresa_cnpj.ilike.%11977969000133%');
        } else if (upper.contains('INDAIATUBA') || digits == '08420171000181') {
          queryAtual = queryAtual.or('empresa_nome.ilike.%Indaiatuba%,empresa_cnpj.ilike.%08420171000181%,empresa_nome.eq.ULTRA VISAO,empresa_nome.eq.Ultra Visao');
          queryAnterior = queryAnterior.or('empresa_nome.ilike.%Indaiatuba%,empresa_cnpj.ilike.%08420171000181%,empresa_nome.eq.ULTRA VISAO,empresa_nome.eq.Ultra Visao');
        } else if (upper.contains('SALTO') || digits == '08420171000424') {
          queryAtual = queryAtual.or('empresa_nome.ilike.%Salto%,empresa_cnpj.ilike.%08420171000424%');
          queryAnterior = queryAnterior.or('empresa_nome.ilike.%Salto%,empresa_cnpj.ilike.%08420171000424%');
        } else if (upper.contains('MONTE MOR') || digits == '22931906000162') {
          queryAtual = queryAtual.or('empresa_nome.ilike.%Monte Mor%,empresa_cnpj.ilike.%22931906000162%');
          queryAnterior = queryAnterior.or('empresa_nome.ilike.%Monte Mor%,empresa_cnpj.ilike.%22931906000162%');
        } else if (upper.contains('AUTO PROVE') || digits == '24868718000162') {
          queryAtual = queryAtual.or('empresa_nome.ilike.%Auto Prove%,empresa_cnpj.ilike.%24868718000162%');
          queryAnterior = queryAnterior.or('empresa_nome.ilike.%Auto Prove%,empresa_cnpj.ilike.%24868718000162%');
        } else if (digits.length >= 11) {
          queryAtual = queryAtual.or('empresa_cnpj.ilike.%$digits%,empresa_nome.ilike.%$filtro%');
          queryAnterior = queryAnterior.or('empresa_cnpj.ilike.%$digits%,empresa_nome.ilike.%$filtro%');
        } else {
          queryAtual = queryAtual.ilike('empresa_nome', '%$filtro%');
          queryAnterior = queryAnterior.ilike('empresa_nome', '%$filtro%');
        }
      }
      // Se for 'todas' ou null, Master visualiza o consolidado global de todas as empresas
    }

    final queryAtualExec = queryAtual
        .gte('created_at', filtros.dataInicio.toUtc().toIso8601String())
        .lte('created_at', filtros.dataFim.toUtc().toIso8601String())
        .order('created_at', ascending: false);

    final queryAnteriorExec = queryAnterior
        .gte('created_at', filtros.dataInicioAnterior.toUtc().toIso8601String())
        .lte('created_at', filtros.dataFimAnterior.toUtc().toIso8601String());

    final resultados = await Future.wait([
      queryAtualExec,
      queryAnteriorExec,
    ]);

    final List<Map<String, dynamic>> rowsAtual =
        List<Map<String, dynamic>>.from(resultados[0]);
    final List<Map<String, dynamic>> rowsAnterior =
        List<Map<String, dynamic>>.from(resultados[1]);

    // 3. Converter período anterior para calcular totais comparativos
    final itensAnterior = rowsAnterior
        .map((r) => VistoriaRelatorioItemModel.fromSupabase(r))
        .toList();

    int totalVistoriasAnt = itensAnterior.length;
    double faturamentoTotalAnt = 0.0;
    int concluidosAnt = 0;
    int pendentesAnt = 0;
    final Set<String> clientesAnt = {};

    for (final it in itensAnterior) {
      if (it.isConcluido) {
        faturamentoTotalAnt += it.valor;
        concluidosAnt++;
      } else {
        pendentesAnt++;
      }
      if (it.cliente.isNotEmpty) clientesAnt.add(it.cliente);
    }
    double ticketMedioAnt = concluidosAnt > 0
        ? (faturamentoTotalAnt / concluidosAnt)
        : 0.0;

    // 4. Converter período atual
    final todosItensAtual = rowsAtual
        .map((r) => VistoriaRelatorioItemModel.fromSupabase(r))
        .toList();

    // 6. Extrair listas únicas para preencher os filtros da UI
    final Set<String> setClientes = {};
    final Set<String> setServicos = {};
    final Set<String> setPeritos = {};
    final Set<String> setDigitadores = {};
    final Set<String> setUnidades = {};
    final Set<String> setStatus = {};

    for (final it in todosItensAtual) {
      if (it.cliente.isNotEmpty) setClientes.add(it.cliente);
      if (it.servico.isNotEmpty) setServicos.add(it.servico);
      if (it.perito.isNotEmpty) setPeritos.add(it.perito);
      if (it.digitador.isNotEmpty) setDigitadores.add(it.digitador);
      if (it.unidade.isNotEmpty) setUnidades.add(it.unidade);
      if (it.status.isNotEmpty) setStatus.add(it.status);
    }

    // Inclui também clientes e peritos cadastrados na nuvem para a empresa
    try {
      var queryCli = supabase.from('clientes_cloud').select('nome');
      if (!isMaster) {
        queryCli = queryCli.eq('user_id', user.id);
      }
      final resCli = await queryCli;
      for (final r in resCli) {
        final n = (r['nome'] as String? ?? '').trim();
        if (n.isNotEmpty) setClientes.add(n);
      }
    } catch (_) {}

    try {
      var queryVist = supabase.from('vistoriadores_cloud').select('nome');
      if (!isMaster) {
        queryVist = queryVist.eq('user_id', user.id);
      }
      final resVist = await queryVist;
      for (final r in resVist) {
        final n = (r['nome'] as String? ?? '').trim();
        if (n.isNotEmpty) setPeritos.add(n);
      }
    } catch (_) {}

    final clientesDisponiveis = setClientes.toList()..sort();
    final servicosDisponiveis = setServicos.toList()..sort();
    final peritosDisponiveis = setPeritos.toList()..sort();
    final digitadoresDisponiveis = setDigitadores.toList()..sort();
    final unidadesDisponiveis = setUnidades.toList()..sort();
    final statusDisponiveis = setStatus.toList()..sort();

    // 7. Aplicar filtros secundários (Cliente, Serviço, Perito, Digitador, Unidade, Status, Busca)
    final List<VistoriaRelatorioItemModel> itensFiltrados = todosItensAtual.where((item) {
      if (filtros.cliente != null &&
          filtros.cliente!.isNotEmpty &&
          filtros.cliente != 'todos' &&
          item.cliente.toUpperCase() != filtros.cliente!.toUpperCase()) {
        return false;
      }
      if (filtros.tipoServico != null &&
          filtros.tipoServico!.isNotEmpty &&
          filtros.tipoServico != 'todos' &&
          item.servico.toUpperCase() != filtros.tipoServico!.toUpperCase()) {
        return false;
      }
      if (filtros.perito != null &&
          filtros.perito!.isNotEmpty &&
          filtros.perito != 'todos' &&
          item.perito.toUpperCase() != filtros.perito!.toUpperCase()) {
        return false;
      }
      if (filtros.digitador != null &&
          filtros.digitador!.isNotEmpty &&
          filtros.digitador != 'todos' &&
          item.digitador.toUpperCase() != filtros.digitador!.toUpperCase()) {
        return false;
      }
      if (filtros.unidade != null &&
          filtros.unidade!.isNotEmpty &&
          filtros.unidade != 'todos' &&
          item.unidade.toUpperCase() != filtros.unidade!.toUpperCase()) {
        return false;
      }
      if (filtros.status != null &&
          filtros.status!.isNotEmpty &&
          filtros.status != 'todos' &&
          item.status.toLowerCase() != filtros.status!.toLowerCase()) {
        return false;
      }
      if (filtros.queryBusca.trim().isNotEmpty) {
        final query = filtros.queryBusca.trim().toUpperCase();
        final placaMatch = item.placa.contains(query);
        final chassiMatch = item.chassi.contains(query);
        final clienteMatch = item.cliente.contains(query);
        final laudoMatch = item.numeroLaudo.toUpperCase().contains(query);
        final veiculoMatch = item.veiculo.contains(query);
        if (!placaMatch && !chassiMatch && !clienteMatch && !laudoMatch && !veiculoMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    // 8. Calcular indicadores atuais com os dados filtrados
    int totalVistorias = itensFiltrados.length;
    double faturamentoTotal = 0.0;
    int concluidos = 0;
    int pendentes = 0;
    final Set<String> clientesAtendidos = {};

    // Mapas para os gráficos
    final Map<DateTime, int> vistoriasPorDia = {};
    final Map<DateTime, double> faturamentoPorDia = {};
    final Map<String, int> servicosMaisRealizados = {};
    final Map<String, int> producaoPorCliente = {};
    final Map<String, int> producaoPorPerito = {};

    // Agrupamento para Fechamento por Cliente
    final Map<String, _ClienteAcumulador> acumuladorClientes = {};

    for (final it in itensFiltrados) {
      final diaTruncado = DateTime(it.data.year, it.data.month, it.data.day);
      vistoriasPorDia[diaTruncado] = (vistoriasPorDia[diaTruncado] ?? 0) + 1;

      if (it.isConcluido) {
        concluidos++;
        faturamentoTotal += it.valor;
        faturamentoPorDia[diaTruncado] =
            (faturamentoPorDia[diaTruncado] ?? 0.0) + it.valor;
      } else {
        pendentes++;
      }
      if (it.cliente.isNotEmpty) clientesAtendidos.add(it.cliente);

      // Gráfico Serviços
      servicosMaisRealizados[it.servico] = (servicosMaisRealizados[it.servico] ?? 0) + 1;

      // Gráfico Clientes
      producaoPorCliente[it.cliente] = (producaoPorCliente[it.cliente] ?? 0) + 1;

      // Gráfico Perito
      producaoPorPerito[it.perito] = (producaoPorPerito[it.perito] ?? 0) + 1;

      // Fechamento Clientes
      final acc = acumuladorClientes.putIfAbsent(it.cliente, () => _ClienteAcumulador(it.cliente));
      acc.totalVistorias++;
      if (it.isConcluido) {
        acc.concluidos++;
        acc.faturamento += it.valor;
      }
      acc.servicos[it.servico] = (acc.servicos[it.servico] ?? 0) + 1;
    }

    double ticketMedio =
        concluidos > 0 ? (faturamentoTotal / concluidos) : 0.0;

    // 9. Montar lista de Fechamento por Cliente ordenada por maior faturamento
    final List<FechamentoClienteModel> fechamentoClientes = acumuladorClientes.values.map((acc) {
      final perc = faturamentoTotal > 0 ? ((acc.faturamento / faturamentoTotal) * 100.0) : 0.0;
      final tkt = acc.concluidos > 0
          ? (acc.faturamento / acc.concluidos)
          : (acc.totalVistorias > 0 ? (acc.faturamento / acc.totalVistorias) : 0.0);
      return FechamentoClienteModel(
        clienteNome: acc.clienteNome,
        quantidadeServicos: acc.totalVistorias,
        faturamentoTotal: acc.faturamento,
        ticketMedio: tkt,
        percentualFaturamento: perc,
        servicosRealizados: acc.servicos,
      );
    }).toList()
      ..sort((a, b) => b.faturamentoTotal.compareTo(a.faturamentoTotal));

    // 10. Identificação da Empresa para Cabeçalho de Relatório
    String nomeEmpresa = '';
    String cnpjEmpresa = '';

    if (isMaster) {
      if (filtros.empresaId != null && filtros.empresaId != 'todas' && filtros.empresaId!.isNotEmpty) {
        final filtro = filtros.empresaId!.trim();
        final digits = filtro.replaceAll(RegExp(r'\D'), '');
        final resolvida = EmpresaRodapeInfo.resolverNomePorCnpj(digits);
        nomeEmpresa = resolvida.isNotEmpty ? resolvida : filtro.toUpperCase();
        cnpjEmpresa = digits;
      } else {
        nomeEmpresa = 'TODAS AS EMPRESAS (CONSOLIDADO MASTER)';
        cnpjEmpresa = '';
      }
    } else {
      final empresaAtual = EmpresaRodapeInfo.obterAtual();
      nomeEmpresa = empresaAtual.razaoSocial.isNotEmpty &&
              !empresaAtual.razaoSocial.contains('NÃO CADASTRADA')
          ? empresaAtual.razaoSocial
          : (user.userMetadata?['name'] as String? ?? 'ULTRA PRIME SOLUÇÕES VEICULARES');
      cnpjEmpresa = user.userMetadata?['cnpj'] as String? ?? '';
    }

    return RelatorioDashboardModel(
      totalVistorias: totalVistorias,
      faturamentoTotal: faturamentoTotal,
      ticketMedio: ticketMedio,
      quantidadeClientes: clientesAtendidos.length,
      quantidadeConcluidos: concluidos,
      quantidadePendentes: pendentes,
      totalVistoriasAnterior: totalVistoriasAnt,
      faturamentoTotalAnterior: faturamentoTotalAnt,
      ticketMedioAnterior: ticketMedioAnt,
      quantidadeClientesAnterior: clientesAnt.length,
      quantidadeConcluidosAnterior: concluidosAnt,
      quantidadePendentesAnterior: pendentesAnt,
      vistoriasPorDia: vistoriasPorDia,
      faturamentoPorDia: faturamentoPorDia,
      servicosMaisRealizados: servicosMaisRealizados,
      producaoPorCliente: producaoPorCliente,
      producaoPorPerito: producaoPorPerito,
      itensVistoria: itensFiltrados,
      fechamentoClientes: fechamentoClientes,
      clientesDisponiveis: clientesDisponiveis,
      servicosDisponiveis: servicosDisponiveis,
      peritosDisponiveis: peritosDisponiveis,
      digitadoresDisponiveis: digitadoresDisponiveis,
      unidadesDisponiveis: unidadesDisponiveis,
      statusDisponiveis: statusDisponiveis,
      empresaNome: nomeEmpresa,
      empresaCnpj: cnpjEmpresa,
    );
  }
}

class _ClienteAcumulador {
  final String clienteNome;
  int totalVistorias = 0;
  int concluidos = 0;
  double faturamento = 0.0;
  final Map<String, int> servicos = {};

  _ClienteAcumulador(this.clienteNome);
}
