import 'package:intl/intl.dart';
import '../../../../core/services/empresa_rodape_helper.dart';

class VistoriaRelatorioItemModel {
  final String id;
  final String numeroLaudo;
  final DateTime data;
  final String veiculo;
  final String ano;
  final String placa;
  final String chassi;
  final String cliente;
  final String servico;
  final String perito;
  final String digitador;
  final String unidade;
  final String empresaNome;
  final String status;
  final String statusFinal;
  final String parecerTecnico;
  final double valor;
  final String? pdfUrl;
  final Map<String, dynamic>? dadosCompletos;

  const VistoriaRelatorioItemModel({
    required this.id,
    required this.numeroLaudo,
    required this.data,
    required this.veiculo,
    required this.ano,
    required this.placa,
    required this.chassi,
    required this.cliente,
    required this.servico,
    required this.perito,
    required this.digitador,
    required this.unidade,
    required this.empresaNome,
    required this.status,
    required this.statusFinal,
    required this.parecerTecnico,
    required this.valor,
    this.pdfUrl,
    this.dadosCompletos,
  });

  factory VistoriaRelatorioItemModel.fromSupabase(
    Map<String, dynamic> row,
  ) {
    final dadosCompletos = row['dados_completos'] as Map<String, dynamic>? ?? {};
    final vistoria = dadosCompletos['vistoria'] as Map<String, dynamic>? ?? {};
    final veiculoData = dadosCompletos['veiculo'] as Map<String, dynamic>? ?? {};

    // 1. Data do laudo
    DateTime dataLaudo;
    if (row['created_at'] != null) {
      dataLaudo = DateTime.tryParse(row['created_at'].toString())?.toLocal() ??
          DateTime.now();
    } else if (vistoria['dataHora'] != null) {
      final rawData = vistoria['dataHora'];
      if (rawData is int) {
        dataLaudo = DateTime.fromMillisecondsSinceEpoch(rawData);
      } else {
        dataLaudo = DateTime.tryParse(rawData.toString()) ?? DateTime.now();
      }
    } else {
      dataLaudo = DateTime.now();
    }

    // 2. Veículo e Ano
    final marca = (veiculoData['marca'] as String? ?? '').trim();
    final modelo = (veiculoData['modelo'] as String? ?? '').trim();
    String veiculoFormatado = '';
    if (marca.isNotEmpty && modelo.isNotEmpty) {
      final marcaUpper = marca.toUpperCase();
      final modeloUpper = modelo.toUpperCase();
      final firstWordModelo = modeloUpper.split(RegExp(r'[\s/]+')).first;

      final isDuplicated = modeloUpper.startsWith(marcaUpper) ||
          marcaUpper.startsWith(firstWordModelo) ||
          (marcaUpper.contains('VOLKSWAGEN') && (modeloUpper.startsWith('VW') || modeloUpper.startsWith('I/VW'))) ||
          (marcaUpper.contains('VW') && (modeloUpper.startsWith('VW') || modeloUpper.startsWith('VOLKSWAGEN'))) ||
          (marcaUpper.contains('CHEVROLET') && (modeloUpper.startsWith('GM') || modeloUpper.startsWith('CHEV'))) ||
          (marcaUpper.contains('FIAT') && modeloUpper.startsWith('FIAT'));

      if (isDuplicated) {
        veiculoFormatado = modelo;
      } else {
        veiculoFormatado = '$marca $modelo';
      }
    } else {
      veiculoFormatado = modelo.isNotEmpty ? modelo : (marca.isNotEmpty ? marca : 'NÃO INFORMADO');
    }

    final anoFab = veiculoData['anoFabricacao']?.toString() ?? '';
    final anoMod = veiculoData['anoModelo']?.toString() ?? '';
    String anoFormatado = '';
    if (anoFab.isNotEmpty && anoMod.isNotEmpty) {
      anoFormatado = anoFab == anoMod ? anoFab : '$anoFab/$anoMod';
    } else {
      anoFormatado = anoFab.isNotEmpty ? anoFab : (anoMod.isNotEmpty ? anoMod : '-');
    }

    // 3. Placa e Chassi
    final placaLimpa = (row['placa'] as String? ??
            veiculoData['placa'] as String? ??
            '')
        .toUpperCase()
        .trim();
    final chassiLimpo = (row['chassi'] as String? ??
            veiculoData['chassiVeiculo'] as String? ??
            '')
        .toUpperCase()
        .trim();

    // 4. Cliente, Perito e Unidade
    final clienteNome = (vistoria['clienteNome'] as String? ?? '').trim();
    final peritoNome = (vistoria['vistoriadorNome'] as String? ?? '').trim();
    final unidadeNome = (vistoria['unidade'] as String? ??
            row['empresa_nome'] as String? ??
            '')
        .trim();

    // 5. Digitador (Operador que gravou o laudo)
    final digitadorNome = (vistoria['digitador'] as String? ??
            row['digitador_nome'] as String? ??
            peritoNome)
        .trim();

    // 6. Tipo de serviço
    final tipoServico = (row['tipo_vistoria'] as String? ??
            vistoria['tipoVistoria'] as String? ??
            'Vistoria Cautelar')
        .trim();

    // 7. Resolução de Preço / Valor: APENAS o valor real digitado pelo usuário (sem valores fictícios ou automáticos)
    double precoCalculado = 0.0;
    if (vistoria['valor'] != null) {
      precoCalculado = (vistoria['valor'] as num).toDouble();
    } else if (row['valor'] != null) {
      precoCalculado = (row['valor'] as num).toDouble();
    }

    // 8. Status e PDF
    final statusRaw = (row['status'] as String? ??
            vistoria['status'] as String? ??
            'em_andamento')
        .toLowerCase();
    final statusFinal = (vistoria['statusFinal'] as String? ?? '').trim();
    final parecer = (vistoria['parecerTecnico'] as String? ?? '').trim();
    // 4b. Empresa com resolução inteligente (CNPJ seed, user_id, dados ou nome)
    final rawEmpresa = (row['empresa_nome'] as String? ?? '').trim();
    final cnpjRow = (row['empresa_cnpj'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final userId = (row['user_id'] as String? ?? '').trim();
    final consulta = dadosCompletos['consulta'] as Map<String, dynamic>? ?? {};
    final municipio = (consulta['municipio'] as String? ?? '').toUpperCase().trim();

    String empresaFinal = rawEmpresa;
    if (empresaFinal.isEmpty ||
        empresaFinal.toUpperCase().contains('NÃO CADASTRADA') ||
        empresaFinal.toUpperCase().contains('NÃO INF')) {
      final resolvida = EmpresaRodapeInfo.resolverNomePorCnpj(cnpjRow);
      if (resolvida.isNotEmpty) {
        empresaFinal = resolvida;
      } else if (userId == '6e86d0c0-3336-49f7-957a-8d7d4515efd0' ||
          municipio.contains('SALTO') ||
          peritoNome.toUpperCase().contains('ERICK')) {
        empresaFinal = 'ULTRA VISÃO SALTO';
      } else if (userId == '1ca7c0b0-69f6-4baf-989c-4711fa1a0a81' ||
          municipio.contains('SUMAR')) {
        empresaFinal = 'SUMARÉ VISTORIAS';
      } else if (userId == 'be177418-b5cc-4fe7-b726-20811576557e' ||
          municipio.contains('INDAIATUBA')) {
        empresaFinal = 'ULTRA VISÃO INDAIATUBA';
      } else if (municipio.contains('MONTE MOR')) {
        empresaFinal = 'ULTRA VISÃO MONTE MOR';
      } else if (municipio.contains('COSMOPOLIS')) {
        empresaFinal = 'AUTO PROVE VISTORIAS';
      }
    }
    if (empresaFinal.isEmpty ||
        empresaFinal.toUpperCase().contains('NÃO CADASTRADA')) {
      empresaFinal = unidadeNome.isNotEmpty ? unidadeNome : 'Empresa não inf.';
    }

    final pdf = (vistoria['pdfUrl'] as String?) ?? (row['pdf_url'] as String?);

    return VistoriaRelatorioItemModel(
      id: row['id']?.toString() ?? '',
      numeroLaudo: row['numero_laudo']?.toString() ??
          vistoria['numeroLaudo']?.toString() ??
          '-',
      data: dataLaudo,
      veiculo: veiculoFormatado.toUpperCase(),
      ano: anoFormatado,
      placa: placaLimpa,
      chassi: chassiLimpo,
      cliente: clienteNome.isNotEmpty ? clienteNome.toUpperCase() : 'PARTICULAR',
      servico: tipoServico,
      perito: peritoNome.isNotEmpty ? peritoNome.toUpperCase() : 'NÃO ATRIBUÍDO',
      digitador: digitadorNome.isNotEmpty ? digitadorNome.toUpperCase() : 'SISTEMA',
      unidade: unidadeNome.isNotEmpty ? unidadeNome.toUpperCase() : 'MATRIZ',
      empresaNome: empresaFinal.toUpperCase(),
      status: statusRaw,
      statusFinal: statusFinal,
      parecerTecnico: parecer,
      valor: precoCalculado,
      pdfUrl: pdf,
      dadosCompletos: dadosCompletos,
    );
  }


  String get dataFormatada => DateFormat('dd/MM/yyyy HH:mm').format(data);
  String get dataApenasFormatada => DateFormat('dd/MM/yyyy').format(data);
  String get valorFormatado =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);

  bool get isConcluido =>
      status.contains('concluid') ||
      status.contains('aprovad') ||
      statusFinal.isNotEmpty;

  bool get isPendente =>
      status.contains('andamento') ||
      status.contains('pendente') ||
      (!isConcluido);
}
