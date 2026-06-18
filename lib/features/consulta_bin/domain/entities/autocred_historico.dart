import 'package:equatable/equatable.dart';

class AutoCredHistorico extends Equatable {
  final String id;
  final String? placa;
  final String? chassi;
  final int codigoConsulta;
  final DateTime createdAt;
  final Map<String, dynamic> dadosTratados;
  final String? arquivoPesquisaUrl;

  const AutoCredHistorico({
    required this.id,
    this.placa,
    this.chassi,
    required this.codigoConsulta,
    required this.createdAt,
    required this.dadosTratados,
    this.arquivoPesquisaUrl,
  });

  bool get permiteRetificacao {
    final diff = DateTime.now().difference(createdAt);
    return diff.inHours <= 72;
  }

  @override
  List<Object?> get props => [id, placa, chassi, codigoConsulta, createdAt, dadosTratados, arquivoPesquisaUrl];

  factory AutoCredHistorico.fromJson(Map<String, dynamic> json) {
    return AutoCredHistorico(
      id: json['id'] as String,
      placa: json['placa'] as String?,
      chassi: json['chassi'] as String?,
      codigoConsulta: json['codigo_consulta'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      dadosTratados: json['dados_tratados'] as Map<String, dynamic>? ?? {},
      arquivoPesquisaUrl: json['arquivo_pesquisa_url'] as String?,
    );
  }
}
