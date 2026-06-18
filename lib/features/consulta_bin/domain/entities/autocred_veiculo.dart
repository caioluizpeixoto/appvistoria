import 'package:equatable/equatable.dart';

class AutoCredVeiculo extends Equatable {
  final String placa;
  final String? chassi;
  final String? motor;
  final String? marca;
  final String? modelo;
  final String? anoFabricacao;
  final String? anoModelo;
  final String? cor;
  final String? renavam;
  final String? municipio;
  final String? uf;
  final String? restricoes;
  final String? arquivoPesquisaUrl;
  
  // Dados brutos caso queiramos extrair mais informações depois
  final Map<String, dynamic> dadosExtras;

  const AutoCredVeiculo({
    required this.placa,
    this.chassi,
    this.motor,
    this.marca,
    this.modelo,
    this.anoFabricacao,
    this.anoModelo,
    this.cor,
    this.renavam,
    this.municipio,
    this.uf,
    this.restricoes,
    this.arquivoPesquisaUrl,
    this.dadosExtras = const {},
  });

  @override
  List<Object?> get props => [
        placa,
        chassi,
        motor,
        marca,
        modelo,
        anoFabricacao,
        anoModelo,
        cor,
        renavam,
        municipio,
        uf,
        restricoes,
        arquivoPesquisaUrl,
        dadosExtras,
      ];
}
