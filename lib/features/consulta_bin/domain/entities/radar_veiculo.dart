class RadarVeiculo {
  final String placa;
  final String renavam;
  final String chassi;
  final String anoFabricacao;
  final String anoModelo;
  final String marcaModelo;
  final String cor;
  final String combustivel;
  final String tipoVeiculo;
  final String especie;
  final String categoria;
  final String motor;
  final String situacao;
  final String municipio;
  final String estado;
  final String proprietario;
  final String documentoProprietario;
  final String restricoes1;
  final String restricoes2;
  final String restricoes3;
  final String restricoes4;
  final String informacoesRelevantes;
  final Map<String, dynamic> resultadoCompleto;

  RadarVeiculo({
    required this.placa,
    required this.renavam,
    required this.chassi,
    required this.anoFabricacao,
    required this.anoModelo,
    required this.marcaModelo,
    required this.cor,
    required this.combustivel,
    required this.tipoVeiculo,
    required this.especie,
    required this.categoria,
    required this.motor,
    required this.situacao,
    required this.municipio,
    required this.estado,
    required this.proprietario,
    required this.documentoProprietario,
    required this.restricoes1,
    required this.restricoes2,
    required this.restricoes3,
    required this.restricoes4,
    required this.informacoesRelevantes,
    required this.resultadoCompleto,
  });

  factory RadarVeiculo.fromJson(Map<String, dynamic> json) {
    return RadarVeiculo(
      placa: json['placa']?.toString() ?? '',
      renavam: json['renavam']?.toString() ?? '',
      chassi: json['chassi']?.toString() ?? '',
      anoFabricacao: json['anoFabricacao']?.toString() ?? '',
      anoModelo: json['anoModelo']?.toString() ?? '',
      marcaModelo: json['marcaModelo']?.toString() ?? '',
      cor: json['cor']?.toString() ?? '',
      combustivel: json['combustivel']?.toString() ?? '',
      tipoVeiculo: json['tipoVeiculo']?.toString() ?? '',
      especie: json['especie']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      motor: json['motor']?.toString() ?? '',
      situacao: json['situacao']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      proprietario: json['proprietario']?.toString() ?? '',
      documentoProprietario: json['documentoProprietario']?.toString() ?? '',
      restricoes1: json['restricoes1']?.toString() ?? '',
      restricoes2: json['restricoes2']?.toString() ?? '',
      restricoes3: json['restricoes3']?.toString() ?? '',
      restricoes4: json['restricoes4']?.toString() ?? '',
      informacoesRelevantes: json['informacoesRelevantes']?.toString() ?? '',
      resultadoCompleto: json['resultadoCompleto'] != null 
          ? Map<String, dynamic>.from(json['resultadoCompleto'])
          : {},
    );
  }
}
