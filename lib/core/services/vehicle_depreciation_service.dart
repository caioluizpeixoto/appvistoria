import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/vistoria/domain/entities/apontamento_avaria.dart';

/// Representa um item/apontamento de avaria orçado.
///
/// Cada apontamento possui um identificador único ([apontamentoId]) que garante
/// a idempotência do cálculo, evitando que reanálises ou regenerações dupliquem o custo.
class DepreciacaoItem {
  final String apontamentoId;
  final String nomePeca;
  final String descricaoProblema;
  final double valorPeca;
  final double valorMaoDeObra;
  final String? justificativa;

  const DepreciacaoItem({
    required this.apontamentoId,
    required this.nomePeca,
    required this.descricaoProblema,
    required this.valorPeca,
    required this.valorMaoDeObra,
    this.justificativa,
  });

  /// Custo total associado a este apontamento específico (peça + mão de obra).
  double get custoTotal => valorPeca + valorMaoDeObra;

  Map<String, dynamic> toMap() {
    return {
      'apontamentoId': apontamentoId,
      'nomePeca': nomePeca,
      'descricaoProblema': descricaoProblema,
      'valorPeca': valorPeca,
      'valorMaoDeObra': valorMaoDeObra,
      'justificativa': justificativa,
      'custoTotal': custoTotal,
    };
  }

  factory DepreciacaoItem.fromMap(Map<String, dynamic> map) {
    return DepreciacaoItem(
      apontamentoId: map['apontamentoId']?.toString() ?? '',
      nomePeca: (map['nomePeca'] ?? map['peca_ou_problema'] ?? '').toString(),
      descricaoProblema: (map['descricaoProblema'] ?? map['observacao_indicada'] ?? '').toString(),
      valorPeca: VehicleDepreciationService.normalizarValor(
        map['valorPeca'] ?? map['valor_peca_estimado'] ?? map['valorEstimadoPeca'],
      ),
      valorMaoDeObra: VehicleDepreciationService.normalizarValor(
        map['valorMaoDeObra'] ?? map['valor_mao_de_obra_estimado'] ?? map['valorEstimadoMaoDeObra'],
      ),
      justificativa: map['justificativa'] as String?,
    );
  }
}

/// Resultado consolidado da avaliação financeira e depreciação.
class ResultadoDepreciacao {
  final double? valorFipe;
  final double depreciacaoTotal;
  final double? valorFinal;
  final List<DepreciacaoItem> itens;
  final bool fipeDisponivel;

  const ResultadoDepreciacao({
    this.valorFipe,
    required this.depreciacaoTotal,
    this.valorFinal,
    required this.itens,
    required this.fipeDisponivel,
  });

  bool get temApontamentos => itens.isNotEmpty;
}

/// Serviço central e fonte única da verdade para a avaliação financeira veicular.
///
/// REGRAS ABSOLUTAS:
/// 1. O valor base vem EXCLUSIVAMENTE da API FIPE oficial. A IA nunca interfere no valor base.
/// 2. Sem apontamentos = SEM depreciação (depreciação total = 0.0, valor final = valorFipe).
/// 3. Se houver apontamentos, a IA atua apenas orçando peças e mão de obra de cada item.
/// 4. O Flutter realiza 100% dos cálculos matemáticos de forma determinística e idempotente.
/// 5. O valor final nunca é menor que 0: max(0, valorFipe - depreciacaoTotal).
class VehicleDepreciationService {
  /// Normaliza valores numéricos de forma estrita e segura.
  /// Valores null, strings inválidas, NaN, infinitos ou negativos retornam 0.0.
  static double normalizarValor(dynamic valor) {
    if (valor == null) return 0.0;

    if (valor is num) {
      if (valor.isNaN || valor.isInfinite || valor < 0) return 0.0;
      return valor.toDouble();
    }

    final str = valor.toString().trim();
    if (str.isEmpty) return 0.0;

    // Tratar formatação brasileira (ex: "R$ 1.200,50" ou "1200.50")
    var clean = str.replaceAll(RegExp(r'[R$\s]'), '');
    if (clean.contains(',') && clean.contains('.')) {
      // Ex: 1.200,50 -> 1200.50
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else if (clean.contains(',')) {
      // Ex: 1200,50 -> 1200.50
      clean = clean.replaceAll(',', '.');
    }

    final numero = double.tryParse(clean);
    if (numero == null || numero.isNaN || numero.isInfinite || numero < 0) {
      return 0.0;
    }

    return numero;
  }

  /// Converte a string de valor FIPE (ex: "R$ 80.000,00" ou "80000") em double.
  /// Retorna null caso o valor seja inválido, nulo ou vazio (FIPE indisponível).
  static double? converterFipeParaDouble(String? fipeTexto) {
    if (fipeTexto == null || fipeTexto.trim().isEmpty) return null;

    final norm = normalizarValor(fipeTexto);
    if (norm <= 0) return null;
    return norm;
  }

  /// Calcula a depreciação total somando os custos de todos os apontamentos únicos.
  /// Se um `apontamentoId` aparecer mais de uma vez, apenas a versão mais recente é mantida.
  static double calcularDepreciacaoTotal(List<DepreciacaoItem> itens) {
    if (itens.isEmpty) return 0.0;

    // Deduplicação idempotente por apontamentoId
    final itensUnicos = <String, DepreciacaoItem>{};
    for (int i = 0; i < itens.length; i++) {
      final item = itens[i];
      final key = item.apontamentoId.isNotEmpty ? item.apontamentoId : 'idx_$i';
      itensUnicos[key] = item;
    }

    return itensUnicos.values.fold(
      0.0,
      (total, item) => total + item.custoTotal,
    );
  }

  /// Calcula o valor final com piso de segurança: max(0, valorFipe - depreciacaoTotal).
  static double calcularValorFinal({
    required double valorFipe,
    required List<DepreciacaoItem> itens,
  }) {
    final depreciacao = calcularDepreciacaoTotal(itens);
    return max(0.0, valorFipe - depreciacao);
  }

  /// Processa a avaliação financeira completa de forma puramente determinística.
  ///
  /// - Se [valorFipe] for nulo, indica FIPE indisponível (a IA NÃO serve de substituta).
  /// - Se [itens] estiver vazio, depreciação é estritamente 0.0 e valor final = valorFipe.
  static ResultadoDepreciacao processar({
    double? valorFipe,
    List<DepreciacaoItem> itens = const [],
  }) {
    // Sanitizar e deduplicar itens
    final Map<String, DepreciacaoItem> deduplicados = {};
    for (int i = 0; i < itens.length; i++) {
      final item = itens[i];
      final key = item.apontamentoId.isNotEmpty ? item.apontamentoId : 'idx_$i';
      deduplicados[key] = item;
    }

    final listaItens = deduplicados.values.toList();
    final depreciacaoTotal = listaItens.fold<double>(
      0.0,
      (total, item) => total + item.custoTotal,
    );

    if (valorFipe == null || valorFipe <= 0) {
      return ResultadoDepreciacao(
        valorFipe: null,
        depreciacaoTotal: depreciacaoTotal,
        valorFinal: null,
        itens: listaItens,
        fipeDisponivel: false,
      );
    }

    final valorFinal = max(0.0, valorFipe - depreciacaoTotal);

    return ResultadoDepreciacao(
      valorFipe: valorFipe,
      depreciacaoTotal: depreciacaoTotal,
      valorFinal: valorFinal,
      itens: listaItens,
      fipeDisponivel: true,
    );
  }

  /// Extrai e sanitiza a resposta de orçamentos de apontamentos fornecida pela IA.
  ///
  /// Ignora COMPLETAMENTE campos proibidos como:
  /// - `valorVeiculo`, `valorMercado`, `valorFipe`, `depreciacao`,
  /// - `percentualDepreciacao`, `valorVeiculoDepreciado`, `valorFinal`.
  static List<DepreciacaoItem> parseRespostaIa(dynamic rawApontamentos) {
    if (rawApontamentos == null || rawApontamentos is! List) {
      return const [];
    }

    final List<DepreciacaoItem> resultado = [];
    final Set<String> idsProcessados = {};

    for (int i = 0; i < rawApontamentos.length; i++) {
      final item = rawApontamentos[i];
      if (item is! Map) continue;

      final id = (item['apontamentoId'] ?? item['id'] ?? 'apontamento_$i').toString();
      final nome = (item['nomePeca'] ?? item['peca_ou_problema'] ?? item['peca'] ?? '').toString();
      final desc = (item['descricaoProblema'] ?? item['observacao_indicada'] ?? item['observacao'] ?? '').toString();

      final valorPeca = normalizarValor(
        item['valorEstimadoPeca'] ?? item['valor_peca_estimado'] ?? item['valorPeca'],
      );
      final valorMaoDeObra = normalizarValor(
        item['valorEstimadoMaoDeObra'] ?? item['valor_mao_de_obra_estimado'] ?? item['valorMaoDeObra'],
      );

      final justificativa = (item['justificativa'] ?? item['motivo'] ?? item['justificativaIa'] ?? '').toString();

      // Substituição se já existir para manter unicidade e idempotência
      if (idsProcessados.contains(id)) {
        final existingIndex = resultado.indexWhere((it) => it.apontamentoId == id);
        if (existingIndex >= 0) {
          resultado[existingIndex] = DepreciacaoItem(
            apontamentoId: id,
            nomePeca: nome,
            descricaoProblema: desc,
            valorPeca: valorPeca,
            valorMaoDeObra: valorMaoDeObra,
            justificativa: justificativa.isNotEmpty ? justificativa : null,
          );
        }
      } else {
        idsProcessados.add(id);
        resultado.add(DepreciacaoItem(
          apontamentoId: id,
          nomePeca: nome,
          descricaoProblema: desc,
          valorPeca: valorPeca,
          valorMaoDeObra: valorMaoDeObra,
          justificativa: justificativa.isNotEmpty ? justificativa : null,
        ));
      }
    }

    return resultado;
  }

  /// Faz a requisição à Edge Function 'gerar-ficha-veiculo' em modo rápido exclusivamente para orçar apontamentos.
  /// Retorna a lista de [DepreciacaoItem] com o valor da peça e mão de obra calculados por IA.
  static Future<List<DepreciacaoItem>> orcarApontamentosComIa({
    required List<ApontamentoAvaria> apontamentos,
    String? brand,
    String? model,
    int? year,
    String? version,
    String? fuel,
    String? engine,
    String? uf,
  }) async {
    if (apontamentos.isEmpty) return const [];

    final payload = {
      'apenasAvarias': true,
      'modo': 'orcamento_avarias',
      'brand': (brand != null && brand.trim().isNotEmpty) ? brand.trim() : 'NÃO INFORMADA',
      'model': (model != null && model.trim().isNotEmpty) ? model.trim() : 'NÃO INFORMADO',
      'year': year ?? DateTime.now().year,
      'version': version ?? '',
      'fuel': fuel ?? '',
      'engine': engine ?? '',
      'uf': uf ?? '',
      'apontamentos': apontamentos.map((a) => {
        'id': a.id,
        'apontamentoId': a.id,
        'categoria': a.categoria,
        'peca': a.peca,
        'nomePeca': a.peca,
        'motivoAvaria': a.motivoAvaria,
        'descricaoProblema': '${a.motivoAvaria}${a.observacao.isNotEmpty ? " - ${a.observacao}" : ""}',
        'observacao': a.observacao,
        if (a.valorPeca != null) 'valor_peca_estimado': a.valorPeca,
        if (a.valorMaoDeObra != null) 'valor_mao_de_obra_estimado': a.valorMaoDeObra,
      }).toList(),
    };

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'gerar-ficha-veiculo',
        body: payload,
      ).timeout(const Duration(seconds: 35));

      if (res.status == 200 && res.data != null) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final innerData = data is Map ? (data['data'] ?? data) : null;
        if (innerData != null && innerData['apontamentos_veiculo'] != null) {
          return parseRespostaIa(innerData['apontamentos_veiculo']);
        }
      } else {
        print('[VehicleDepreciationService] Erro Edge Function (Status ${res.status}): ${res.data}');
      }
    } catch (e) {
      print('[VehicleDepreciationService] Falha ao orçar apontamentos com IA: $e');
    }

    return const [];
  }

  /// Formata um double para moeda brasileira (ex: R$ 80.000,00).
  /// Se o valor for nulo, retorna "Indisponível".
  static String formatarMoeda(double? valor) {
    if (valor == null) return 'Indisponível';
    final isNegative = valor < 0;
    final absVal = valor.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    final formattedInt = buffer.toString().split('').reversed.join('');
    final prefix = isNegative ? '-R\$ ' : 'R\$ ';
    return '$prefix$formattedInt,$decPart';
  }
}
