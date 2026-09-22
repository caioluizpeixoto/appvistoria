import 'dart:convert';

/// Representa um apontamento/avaria dinâmico registrado durante a vistoria.
/// Utilizado como entrada exclusiva para cálculo e orçamento de peças/serviços por IA.
class ApontamentoAvaria {
  final String id;
  String categoria;
  String peca;
  String motivoAvaria;
  String observacao;
  List<String> fotosLocais;
  List<String> fotosUrls;

  /// Orçamento gerado pela Inteligência Artificial
  double? valorPeca;
  double? valorMaoDeObra;
  String? justificativaIa;

  ApontamentoAvaria({
    required this.id,
    required this.categoria,
    required this.peca,
    required this.motivoAvaria,
    this.observacao = '',
    this.valorPeca,
    this.valorMaoDeObra,
    this.justificativaIa,
    List<String>? fotosLocais,
    List<String>? fotosUrls,
  })  : fotosLocais = fotosLocais ?? [],
        fotosUrls = fotosUrls ?? [];

  /// Custo total associado a este apontamento específico (peça + mão de obra).
  double get custoTotal => (valorPeca ?? 0.0) + (valorMaoDeObra ?? 0.0);

  /// Indica se a IA já orçou este apontamento.
  bool get orcadoPelaIa => valorPeca != null || valorMaoDeObra != null;

  /// Serializa para salvar no campo `observacao` do SQLite (ItensVistoria) sem quebrar o banco.
  String serializarParaObservacaoBanco() {
    if (valorPeca == null && valorMaoDeObra == null && (justificativaIa == null || justificativaIa!.isEmpty)) {
      return observacao;
    }
    final meta = jsonEncode({
      if (valorPeca != null) 'p': valorPeca,
      if (valorMaoDeObra != null) 'm': valorMaoDeObra,
      if (justificativaIa != null && justificativaIa!.isNotEmpty) 'j': justificativaIa,
    });
    return '$observacao|||VALORES_IA:$meta';
  }

  /// Extrai texto limpo de observação e metadados orçados pela IA.
  static ({String obsLimpa, double? valorPeca, double? valorMaoDeObra, String? justificativaIa}) extrairMetadadosIa(String rawObs) {
    if (!rawObs.contains('|||VALORES_IA:')) {
      return (obsLimpa: rawObs, valorPeca: null, valorMaoDeObra: null, justificativaIa: null);
    }
    final parts = rawObs.split('|||VALORES_IA:');
    final obsLimpa = parts[0];
    try {
      final jsonStr = parts.sublist(1).join('|||VALORES_IA:');
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final p = map['p'] != null ? (map['p'] as num).toDouble() : null;
      final m = map['m'] != null ? (map['m'] as num).toDouble() : null;
      final j = map['j'] as String?;
      return (obsLimpa: obsLimpa, valorPeca: p, valorMaoDeObra: m, justificativaIa: j);
    } catch (_) {
      return (obsLimpa: obsLimpa, valorPeca: null, valorMaoDeObra: null, justificativaIa: null);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'peca': peca,
      'motivoAvaria': motivoAvaria,
      'observacao': observacao,
      'valorPeca': valorPeca,
      'valorMaoDeObra': valorMaoDeObra,
      'justificativaIa': justificativaIa,
      'fotosLocais': fotosLocais,
      'fotosUrls': fotosUrls,
    };
  }

  factory ApontamentoAvaria.fromMap(Map<String, dynamic> map) {
    return ApontamentoAvaria(
      id: map['id'] ?? '',
      categoria: map['categoria'] ?? 'Outro',
      peca: map['peca'] ?? '',
      motivoAvaria: map['motivoAvaria'] ?? '',
      observacao: map['observacao'] ?? '',
      valorPeca: map['valorPeca'] != null ? (map['valorPeca'] as num).toDouble() : null,
      valorMaoDeObra: map['valorMaoDeObra'] != null ? (map['valorMaoDeObra'] as num).toDouble() : null,
      justificativaIa: map['justificativaIa'] as String?,
      fotosLocais: List<String>.from(map['fotosLocais'] ?? []),
      fotosUrls: List<String>.from(map['fotosUrls'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ApontamentoAvaria.fromJson(String source) =>
      ApontamentoAvaria.fromMap(jsonDecode(source));

  ApontamentoAvaria copyWith({
    String? id,
    String? categoria,
    String? peca,
    String? motivoAvaria,
    String? observacao,
    double? valorPeca,
    double? valorMaoDeObra,
    String? justificativaIa,
    List<String>? fotosLocais,
    List<String>? fotosUrls,
  }) {
    return ApontamentoAvaria(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      peca: peca ?? this.peca,
      motivoAvaria: motivoAvaria ?? this.motivoAvaria,
      observacao: observacao ?? this.observacao,
      valorPeca: valorPeca ?? this.valorPeca,
      valorMaoDeObra: valorMaoDeObra ?? this.valorMaoDeObra,
      justificativaIa: justificativaIa ?? this.justificativaIa,
      fotosLocais: fotosLocais ?? List<String>.from(this.fotosLocais),
      fotosUrls: fotosUrls ?? List<String>.from(this.fotosUrls),
    );
  }
}
