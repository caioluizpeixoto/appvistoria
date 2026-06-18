import 'package:equatable/equatable.dart';

class ConsultaBinEntity extends Equatable {
  final String id;
  final String placa;
  final String? chassi;
  final bool restricoes;
  final bool debitos;
  final bool leilao;
  final bool sinistro;
  final String? situacao;
  final String? proprietarioAtual;
  final List<ProprietarioEntity> historicoProprietarios;
  final String? marca;
  final String? modelo;
  final int? anoFabricacao;
  final int? anoModelo;
  final String? cor;
  final String? combustivel;
  final String? motorFabrica;
  final String? motorEstadual;
  final DateTime consultadoEm;

  bool get motorDivergente =>
      motorFabrica != null &&
      motorEstadual != null &&
      motorFabrica != motorEstadual;

  const ConsultaBinEntity({
    required this.id,
    required this.placa,
    this.chassi,
    required this.restricoes,
    required this.debitos,
    required this.leilao,
    required this.sinistro,
    this.situacao,
    this.proprietarioAtual,
    this.historicoProprietarios = const [],
    this.marca,
    this.modelo,
    this.anoFabricacao,
    this.anoModelo,
    this.cor,
    this.combustivel,
    this.motorFabrica,
    this.motorEstadual,
    required this.consultadoEm,
  });

  @override
  List<Object?> get props => [id, placa];
}

class ProprietarioEntity extends Equatable {
  final String nome;
  final int? ano;
  final String? uf;

  const ProprietarioEntity({
    required this.nome,
    this.ano,
    this.uf,
  });

  @override
  List<Object?> get props => [nome, ano, uf];
}
