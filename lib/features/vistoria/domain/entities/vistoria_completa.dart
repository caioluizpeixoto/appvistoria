import 'package:equatable/equatable.dart';

class VistoriaCompleta extends Equatable {
  final String? id;
  final String? placa;
  final String? chassi;
  final String? motor;
  final String? marca;
  final String? modelo;
  final String? anoFabricacao;
  final String? anoModelo;
  final String? cor;
  
  // OCR Status
  final String? chassiOcr;
  final String? chassiStatus;
  final String? motorOcr;
  final String? motorStatus;
  
  // Passos intermediários como JSON Flexível
  final Map<String, dynamic> dadosInspecao;
  
  final String? observacoesGerais;
  final String? parecerTecnico;
  final String? statusFinal;
  
  final bool isDraft;

  const VistoriaCompleta({
    this.id,
    this.placa,
    this.chassi,
    this.motor,
    this.marca,
    this.modelo,
    this.anoFabricacao,
    this.anoModelo,
    this.cor,
    this.chassiOcr,
    this.chassiStatus,
    this.motorOcr,
    this.motorStatus,
    this.dadosInspecao = const {},
    this.observacoesGerais,
    this.parecerTecnico,
    this.statusFinal,
    this.isDraft = true,
  });

  VistoriaCompleta copyWith({
    String? id,
    String? placa,
    String? chassi,
    String? motor,
    String? marca,
    String? modelo,
    String? anoFabricacao,
    String? anoModelo,
    String? cor,
    String? chassiOcr,
    String? chassiStatus,
    String? motorOcr,
    String? motorStatus,
    Map<String, dynamic>? dadosInspecao,
    String? observacoesGerais,
    String? parecerTecnico,
    String? statusFinal,
    bool? isDraft,
  }) {
    return VistoriaCompleta(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      chassi: chassi ?? this.chassi,
      motor: motor ?? this.motor,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anoFabricacao: anoFabricacao ?? this.anoFabricacao,
      anoModelo: anoModelo ?? this.anoModelo,
      cor: cor ?? this.cor,
      chassiOcr: chassiOcr ?? this.chassiOcr,
      chassiStatus: chassiStatus ?? this.chassiStatus,
      motorOcr: motorOcr ?? this.motorOcr,
      motorStatus: motorStatus ?? this.motorStatus,
      dadosInspecao: dadosInspecao ?? this.dadosInspecao,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      parecerTecnico: parecerTecnico ?? this.parecerTecnico,
      statusFinal: statusFinal ?? this.statusFinal,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  @override
  List<Object?> get props => [
        id, placa, chassi, motor, marca, modelo, anoFabricacao, anoModelo, cor,
        chassiOcr, chassiStatus, motorOcr, motorStatus, dadosInspecao,
        observacoesGerais, parecerTecnico, statusFinal, isDraft
      ];
}
