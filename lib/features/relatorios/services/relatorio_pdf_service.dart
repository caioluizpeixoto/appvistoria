import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/relatorio_dashboard_model.dart';
import '../data/models/relatorio_filtros_model.dart';
import '../../../../core/services/empresa_rodape_helper.dart';
import '../../../../core/services/time_service.dart';
import '../../../../injection_container.dart';

enum TipoRelatorioExportacao {
  resumido,
  completo,
  financeiro,
  porCliente,
  porServico,
  porPerito,
}

extension TipoRelatorioExportacaoExt on TipoRelatorioExportacao {
  String get titulo {
    switch (this) {
      case TipoRelatorioExportacao.resumido:
        return 'Relatório Resumido Executivo';
      case TipoRelatorioExportacao.completo:
        return 'Relatório Operacional Completo';
      case TipoRelatorioExportacao.financeiro:
        return 'Relatório Financeiro e Faturamento';
      case TipoRelatorioExportacao.porCliente:
        return 'Relatório de Produção por Cliente';
      case TipoRelatorioExportacao.porServico:
        return 'Relatório de Produção por Serviço';
      case TipoRelatorioExportacao.porPerito:
        return 'Relatório de Produtividade por Perito';
    }
  }

  String get descricao {
    switch (this) {
      case TipoRelatorioExportacao.resumido:
        return 'Visão geral com indicadores, ticket médio e resumo de serviços';
      case TipoRelatorioExportacao.completo:
        return 'Listagem detalhada de todas as vistorias com todas as colunas';
      case TipoRelatorioExportacao.financeiro:
        return 'Valores cobrados, evolução diária e fechamento financeiro';
      case TipoRelatorioExportacao.porCliente:
        return 'Agrupamento detalhado por cliente com quantidades e totais';
      case TipoRelatorioExportacao.porServico:
        return 'Agrupamento consolidado por modalidade de vistoria realizada';
      case TipoRelatorioExportacao.porPerito:
        return 'Agrupamento de produção por vistoriador e perito técnico';
    }
  }
}

class RelatorioPdfService {
  static const PdfColor corPrimaria = PdfColor.fromInt(0xFF234B32); // Verde Musgo Ultra Prime
  static const PdfColor corPrimariaClara = PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor corCinzaEscuro = PdfColor.fromInt(0xFF212121);
  static const PdfColor corCinzaMedio = PdfColor.fromInt(0xFF757575);
  static const PdfColor corCinzaClaro = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor corBorda = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor corVerdeSucesso = PdfColor.fromInt(0xFF2E7D32);

  static Future<Uint8List> gerarPdf({
    required RelatorioDashboardModel dashboard,
    required RelatorioFiltrosModel filtros,
    required TipoRelatorioExportacao tipo,
  }) async {
    final pdf = pw.Document();

    // Carregar logotipo se disponível
    pw.ImageProvider? logoImage;
    try {
      final bytes = await rootBundle.load('assets/logos/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      try {
        final bytes = await rootBundle.load('assets/images/app_icon.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}
    }

    final empresaInfo = EmpresaRodapeInfo.obterAtual();
    final nomeEmpresa = dashboard.empresaNome.isNotEmpty
        ? dashboard.empresaNome
        : empresaInfo.razaoSocial;
    final enderecoEmpresa = empresaInfo.linhaEndereco;
    final contatoEmpresa = empresaInfo.linhaContato;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm');
    final periodoFormatado =
        '${dateFormat.format(filtros.dataInicio)} a ${dateFormat.format(filtros.dataFim)}';
    final dataEmissaoFormatada = timeFormat.format(sl<TimeService>().nowBrasilia());

    // Orientação: Paisagem para tabelas extensas, Retrato para Resumido
    final pageFormat = tipo == TipoRelatorioExportacao.resumido
        ? PdfPageFormat.a4
        : PdfPageFormat.a4.landscape;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (context) => _buildHeader(
          context: context,
          logo: logoImage,
          nomeEmpresa: nomeEmpresa,
          enderecoEmpresa: enderecoEmpresa,
          contatoEmpresa: contatoEmpresa,
          titulo: tipo.titulo,
          periodo: periodoFormatado,
          dataEmissao: dataEmissaoFormatada,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => _buildConteudo(
          context: context,
          tipo: tipo,
          dashboard: dashboard,
          filtros: filtros,
        ),
      ),
    );

    return pdf.save();
  }

  // ── Cabeçalho Corporativo ──────────────────────────────────────────────────
  static pw.Widget _buildHeader({
    required pw.Context context,
    required pw.ImageProvider? logo,
    required String nomeEmpresa,
    required String enderecoEmpresa,
    required String contatoEmpresa,
    required String titulo,
    required String periodo,
    required String dataEmissao,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: corPrimaria, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logotipo
          if (logo != null) ...[
            pw.Container(
              width: 70,
              height: 45,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 12),
          ],

          // Dados da Empresa
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  nomeEmpresa.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: corPrimaria,
                  ),
                ),
                if (enderecoEmpresa.isNotEmpty &&
                    !enderecoEmpresa.contains('NÃO CADASTRADO'))
                  pw.Text(
                    enderecoEmpresa,
                    style: const pw.TextStyle(fontSize: 7.5, color: corCinzaMedio),
                    maxLines: 1,
                  ),
                if (contatoEmpresa.isNotEmpty &&
                    !contatoEmpresa.contains('NÃO CADASTRADO'))
                  pw.Text(
                    contatoEmpresa,
                    style: const pw.TextStyle(fontSize: 7.5, color: corCinzaMedio),
                  ),
              ],
            ),
          ),

          // Título e Período do Relatório
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: corPrimariaClara,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: corPrimaria, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  titulo.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: corPrimaria,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Período: $periodo',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: corCinzaEscuro,
                  ),
                ),
                pw.Text(
                  'Emissão: $dataEmissao',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: corCinzaMedio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rodapé com Paginação "Página X de Y" ────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: corBorda, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Ultra Prime Soluções Veiculares - Gestão e Inteligência Pericial',
            style: const pw.TextStyle(fontSize: 7.5, color: corCinzaMedio),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: corCinzaEscuro,
            ),
          ),
        ],
      ),
    );
  }

  // ── Conteúdo Conforme o Tipo de Relatório ───────────────────────────────────
  static List<pw.Widget> _buildConteudo({
    required pw.Context context,
    required TipoRelatorioExportacao tipo,
    required RelatorioDashboardModel dashboard,
    required RelatorioFiltrosModel filtros,
  }) {
    switch (tipo) {
      case TipoRelatorioExportacao.resumido:
        return _buildConteudoResumido(dashboard, filtros);
      case TipoRelatorioExportacao.completo:
        return _buildConteudoCompleto(dashboard);
      case TipoRelatorioExportacao.financeiro:
        return _buildConteudoFinanceiro(dashboard);
      case TipoRelatorioExportacao.porCliente:
        return _buildConteudoPorCliente(dashboard);
      case TipoRelatorioExportacao.porServico:
        return _buildConteudoPorServico(dashboard);
      case TipoRelatorioExportacao.porPerito:
        return _buildConteudoPorPerito(dashboard);
    }
  }

  // ── 1. Resumido Executivo ──────────────────────────────────────────────────
  static List<pw.Widget> _buildConteudoResumido(
    RelatorioDashboardModel d,
    RelatorioFiltrosModel f,
  ) {
    return [
      _buildIndicadoresCards(d),
      pw.SizedBox(height: 14),

      // Tabela de Serviços
      _buildSecaoTitulo('Serviços Mais Realizados no Período'),
      pw.SizedBox(height: 4),
      _buildTabelaSimples(
        cabecalhos: ['Tipo de Serviço', 'Quantidade', '% do Total'],
        linhas: d.servicosMaisRealizados.entries.map((e) {
          final perc = d.totalVistorias > 0
              ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
              : '0.0';
          return [e.key, e.value.toString(), '$perc%'];
        }).toList(),
      ),

      pw.SizedBox(height: 14),

      // Tabela de Peritos
      _buildSecaoTitulo('Produtividade por Perito / Vistoriador'),
      pw.SizedBox(height: 4),
      _buildTabelaSimples(
        cabecalhos: ['Perito / Vistoriador', 'Vistorias Concluídas', '% Produção'],
        linhas: d.producaoPorPerito.entries.map((e) {
          final perc = d.totalVistorias > 0
              ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
              : '0.0';
          return [e.key, e.value.toString(), '$perc%'];
        }).toList(),
      ),

      pw.SizedBox(height: 14),

      // Top Clientes
      _buildSecaoTitulo('Top Clientes Atendidos'),
      pw.SizedBox(height: 4),
      _buildTabelaSimples(
        cabecalhos: ['Cliente', 'Serviços', 'Total Faturado', 'Ticket Médio'],
        linhas: d.fechamentoClientes.take(10).map((c) {
          return [
            c.clienteNome,
            c.quantidadeServicos.toString(),
            c.faturamentoFormatado,
            c.ticketMedioFormatado,
          ];
        }).toList(),
      ),
    ];
  }

  // ── 2. Operacional Completo (Tabela Extensa A4 Paisagem) ───────────────────
  static List<pw.Widget> _buildConteudoCompleto(RelatorioDashboardModel d) {
    return [
      _buildBarraResumo(d),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: corBorda, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: corPrimaria),
        headerHeight: 20,
        cellHeight: 18,
        cellStyle: const pw.TextStyle(fontSize: 7),
        cellAlignment: pw.Alignment.centerLeft,
        oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
        columnWidths: const {
          0: pw.FixedColumnWidth(65),  // Nº Laudo
          1: pw.FixedColumnWidth(60),  // Data
          2: pw.FlexColumnWidth(2.2),  // Veículo
          3: pw.FixedColumnWidth(40),  // Ano
          4: pw.FixedColumnWidth(48),  // Placa
          5: pw.FlexColumnWidth(2.2),  // Cliente
          6: pw.FlexColumnWidth(2.5),  // Serviço
          7: pw.FlexColumnWidth(2.0),  // Perito
          8: pw.FixedColumnWidth(55),  // Status
          9: pw.FixedColumnWidth(50),  // Valor
        },
        headers: [
          'Nº Laudo',
          'Data',
          'Veículo',
          'Ano',
          'Placa',
          'Cliente',
          'Serviço',
          'Perito',
          'Status',
          'Valor',
        ],
        data: d.itensVistoria.map((it) {
          return [
            it.numeroLaudo,
            it.dataFormatada,
            it.veiculo,
            it.ano,
            it.placa,
            it.cliente,
            it.servico,
            it.perito,
            it.statusFinal.isNotEmpty ? it.statusFinal : it.status.toUpperCase(),
            it.valorFormatado,
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      _buildTotalGeralRodape(d),
    ];
  }

  // ── 3. Financeiro e Faturamento ────────────────────────────────────────────
  static List<pw.Widget> _buildConteudoFinanceiro(RelatorioDashboardModel d) {
    return [
      _buildIndicadoresCards(d),
      pw.SizedBox(height: 10),
      _buildSecaoTitulo('Evolução do Faturamento Diário'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: corBorda, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: corPrimaria),
        headerHeight: 20,
        cellHeight: 18,
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
        headers: ['Data', 'Vistorias Realizadas', 'Faturamento do Dia', 'Ticket Médio'],
        data: (d.faturamentoPorDia.keys.toList()..sort((a, b) => b.compareTo(a)))
            .map((dia) {
          final fat = d.faturamentoPorDia[dia] ?? 0.0;
          final qtd = d.vistoriasPorDia[dia] ?? 0;
          final tkt = qtd > 0 ? (fat / qtd) : 0.0;
          return [
            DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR').format(dia),
            qtd.toString(),
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(fat),
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(tkt),
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      _buildTotalGeralRodape(d),
    ];
  }

  // ── 4. Fechamento por Cliente ──────────────────────────────────────────────
  static List<pw.Widget> _buildConteudoPorCliente(RelatorioDashboardModel d) {
    return [
      _buildBarraResumo(d),
      pw.SizedBox(height: 8),
      _buildSecaoTitulo('Extrato de Fechamento por Cliente'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: corBorda, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: corPrimaria),
        headerHeight: 20,
        cellHeight: 18,
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.5),
          1: pw.FixedColumnWidth(70),
          2: pw.FixedColumnWidth(90),
          3: pw.FixedColumnWidth(80),
          4: pw.FixedColumnWidth(70),
        },
        headers: [
          'Cliente / Razão Social',
          'Qtd. Vistorias',
          'Total Faturado',
          'Ticket Médio',
          '% Faturamento',
        ],
        data: d.fechamentoClientes.map((c) {
          return [
            c.clienteNome,
            c.quantidadeServicos.toString(),
            c.faturamentoFormatado,
            c.ticketMedioFormatado,
            c.percentualFormatado,
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      _buildTotalGeralRodape(d),
    ];
  }

  // ── 5. Produção por Serviço ────────────────────────────────────────────────
  static List<pw.Widget> _buildConteudoPorServico(RelatorioDashboardModel d) {
    return [
      _buildBarraResumo(d),
      pw.SizedBox(height: 8),
      _buildSecaoTitulo('Consolidação por Modalidade de Vistoria'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: corBorda, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: corPrimaria),
        headerHeight: 20,
        cellHeight: 18,
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
        headers: ['Modalidade de Vistoria', 'Quantidade', '% do Volume'],
        data: d.servicosMaisRealizados.entries.map((e) {
          final perc = d.totalVistorias > 0
              ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
              : '0.0';
          return [e.key, e.value.toString(), '$perc%'];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      _buildTotalGeralRodape(d),
    ];
  }

  // ── 6. Produtividade por Perito ────────────────────────────────────────────
  static List<pw.Widget> _buildConteudoPorPerito(RelatorioDashboardModel d) {
    return [
      _buildBarraResumo(d),
      pw.SizedBox(height: 8),
      _buildSecaoTitulo('Produtividade por Vistoriador / Perito Técnico'),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: corBorda, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: corPrimaria),
        headerHeight: 20,
        cellHeight: 18,
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
        headers: ['Vistoriador / Perito', 'Laudos Concluídos', '% de Participação'],
        data: d.producaoPorPerito.entries.map((e) {
          final perc = d.totalVistorias > 0
              ? (e.value / d.totalVistorias * 100).toStringAsFixed(1)
              : '0.0';
          return [e.key, e.value.toString(), '$perc%'];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      _buildTotalGeralRodape(d),
    ];
  }

  // ── Componentes Auxiliares de Diagramação ──────────────────────────────────
  static pw.Widget _buildIndicadoresCards(RelatorioDashboardModel d) {
    return pw.Row(
      children: [
        _buildCardItem('TOTAL VISTORIAS', d.totalVistorias.toString(), d.variacaoVistoriasFormatada),
        pw.SizedBox(width: 8),
        _buildCardItem('FATURAMENTO', d.faturamentoTotalFormatado, d.variacaoFaturamentoFormatada),
        pw.SizedBox(width: 8),
        _buildCardItem('TICKET MÉDIO', d.ticketMedioFormatado, null),
        pw.SizedBox(width: 8),
        _buildCardItem('CLIENTES', d.quantidadeClientes.toString(), null),
        pw.SizedBox(width: 8),
        _buildCardItem('CONCLUÍDOS', d.quantidadeConcluidos.toString(), null),
        pw.SizedBox(width: 8),
        _buildCardItem('PENDENTES', d.quantidadePendentes.toString(), null),
      ],
    );
  }

  static pw.Widget _buildCardItem(String titulo, String valor, String? variacao) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: pw.BoxDecoration(
          color: corCinzaClaro,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: corBorda, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: const pw.TextStyle(fontSize: 6.5, color: corCinzaMedio),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: corPrimaria,
              ),
              maxLines: 1,
            ),
            if (variacao != null) ...[
              pw.SizedBox(height: 1),
              pw.Text(
                'Var: $variacao',
                style: pw.TextStyle(
                  fontSize: 6,
                  color: variacao.startsWith('+') ? corVerdeSucesso : PdfColors.red800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBarraResumo(RelatorioDashboardModel d) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: corPrimariaClara,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: corPrimaria, width: 0.6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total de Registros: ${d.totalVistorias}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
          pw.Text('Faturamento Total: ${d.faturamentoTotalFormatado}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
          pw.Text('Ticket Médio: ${d.ticketMedioFormatado}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
          pw.Text('Clientes Atendidos: ${d.quantidadeClientes}',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: corPrimaria)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalGeralRodape(RelatorioDashboardModel d) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: corPrimaria,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOTAL GERAL (${d.totalVistorias} VISTORIAS)',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'FATURAMENTO TOTAL: ${d.faturamentoTotalFormatado}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSecaoTitulo(String titulo) {
    return pw.Text(
      titulo.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: corPrimaria,
      ),
    );
  }

  static pw.Widget _buildTabelaSimples({
    required List<String> cabecalhos,
    required List<List<String>> linhas,
  }) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: corBorda, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: corPrimaria),
      headerHeight: 18,
      cellHeight: 16,
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      oddRowDecoration: const pw.BoxDecoration(color: corCinzaClaro),
      headers: cabecalhos,
      data: linhas,
    );
  }
}
