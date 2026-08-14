class RadarNormalizedData {
  final Map<String, dynamic> rawJson;
  final VeiculoData veiculo;
  final ProprietarioData proprietario;
  final RadarModule<List<MultaData>> multas;
  final RadarModule<List<IpvaData>> ipva;
  final RadarModule<List<LicenciamentoData>> licenciamentos;
  final RadarModule<List<VistoriaData>> vistorias;
  final RadarModule<List<RestricaoData>> restricoes;
  final RadarModule<RouboFurtoData> rouboFurto;
  final RadarModule<Map<String, dynamic>> comunicacaoVenda;
  final RadarModule<Map<String, dynamic>> recall;
  final RadarModule<List<Map<String, dynamic>>> sinistros;
  final RadarModule<List<Map<String, dynamic>>> leiloes;
  final RadarModule<List<Map<String, dynamic>>> dividasAtivas;
  final List<RadarError> erros;

  RadarNormalizedData({
    required this.rawJson,
    required this.veiculo,
    required this.proprietario,
    required this.multas,
    required this.ipva,
    required this.licenciamentos,
    required this.vistorias,
    required this.restricoes,
    required this.rouboFurto,
    required this.comunicacaoVenda,
    required this.recall,
    required this.sinistros,
    required this.leiloes,
    required this.dividasAtivas,
    required this.erros,
  });
}

enum RadarModuleStatus {
  preenchido,
  nada_consta,
  sem_informacao,
  erro,
  indisponivel,
  nao_consultado,
}

class RadarModule<T> {
  final String modulo;
  final RadarModuleStatus status;
  final String? mensagem;
  final T? dados;
  final String? fonte;

  RadarModule({
    required this.modulo,
    required this.status,
    this.mensagem,
    this.dados,
    this.fonte,
  });

  bool get hasData => status == RadarModuleStatus.preenchido && dados != null;
}

class RadarError {
  final String modulo;
  final String mensagem;
  final String fonte;

  RadarError({
    required this.modulo,
    required this.mensagem,
    required this.fonte,
  });
}

class VeiculoData {
  final String placa;
  final String renavam;
  final String chassi;
  final String marcaModelo;
  final String cor;
  final String anoFabricacao;
  final String anoModelo;
  final String tipo;
  final String combustivel;
  final String especie;
  final String categoria;
  final String motor;
  final String capacidadePassageiros;
  final String capacidadeCarga;
  final String potencia;
  final String carroceria;
  final String eixos;
  final String situacao;
  final String municipio;
  final String uf;
  final String cilindradas;
  final String dataEmissaoCrlv;

  VeiculoData({
    this.placa = '',
    this.renavam = '',
    this.chassi = '',
    this.marcaModelo = '',
    this.cor = '',
    this.anoFabricacao = '',
    this.anoModelo = '',
    this.tipo = '',
    this.combustivel = '',
    this.especie = '',
    this.categoria = '',
    this.motor = '',
    this.capacidadePassageiros = '',
    this.capacidadeCarga = '',
    this.potencia = '',
    this.carroceria = '',
    this.eixos = '',
    this.situacao = '',
    this.municipio = '',
    this.uf = '',
    this.cilindradas = '',
    this.dataEmissaoCrlv = '',
  });
}

class ProprietarioData {
  final String nome;
  final String documento;
  final String municipio;
  final String uf;

  ProprietarioData({
    this.nome = '',
    this.documento = '',
    this.municipio = '',
    this.uf = '',
  });
}

class MultaData {
  final String orgao;
  final String valor;
  final String dataInfracao;
  final String descricao;
  final String situacao;
  final String autoInfracao;
  final String local;

  MultaData({
    this.orgao = '',
    this.valor = '',
    this.dataInfracao = '',
    this.descricao = '',
    this.situacao = '',
    this.autoInfracao = '',
    this.local = '',
  });
}

class IpvaData {
  final String parcela;
  final String valor;
  final String vencimento;
  final String situacao;
  final String exercicio;

  IpvaData({
    this.parcela = '',
    this.valor = '',
    this.vencimento = '',
    this.situacao = '',
    this.exercicio = '',
  });
}

class LicenciamentoData {
  final String exercicio;
  final String valor;
  final String situacao;
  final String dataPagamento;

  LicenciamentoData({
    this.exercicio = '',
    this.valor = '',
    this.situacao = '',
    this.dataPagamento = '',
  });
}

class VistoriaData {
  final String data;
  final String resultado;
  final String empresa;
  final String observacao;

  VistoriaData({
    this.data = '',
    this.resultado = '',
    this.empresa = '',
    this.observacao = '',
  });
}

class RestricaoData {
  final String tipo;
  final String descricao;
  final bool possuiRestricao;

  RestricaoData({
    required this.tipo,
    required this.descricao,
    required this.possuiRestricao,
  });
}

class RouboFurtoData {
  final bool possuiOcorrencia;
  final List<Map<String, dynamic>> historico;
  final String mensagem;

  RouboFurtoData({
    this.possuiOcorrencia = false,
    this.historico = const [],
    this.mensagem = '',
  });
}
