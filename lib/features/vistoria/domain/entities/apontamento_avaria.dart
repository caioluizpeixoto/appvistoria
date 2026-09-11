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

  ApontamentoAvaria({
    required this.id,
    required this.categoria,
    required this.peca,
    required this.motivoAvaria,
    this.observacao = '',
    List<String>? fotosLocais,
    List<String>? fotosUrls,
  })  : fotosLocais = fotosLocais ?? [],
        fotosUrls = fotosUrls ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoria': categoria,
      'peca': peca,
      'motivoAvaria': motivoAvaria,
      'observacao': observacao,
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
    List<String>? fotosLocais,
    List<String>? fotosUrls,
  }) {
    return ApontamentoAvaria(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      peca: peca ?? this.peca,
      motivoAvaria: motivoAvaria ?? this.motivoAvaria,
      observacao: observacao ?? this.observacao,
      fotosLocais: fotosLocais ?? List<String>.from(this.fotosLocais),
      fotosUrls: fotosUrls ?? List<String>.from(this.fotosUrls),
    );
  }
}
