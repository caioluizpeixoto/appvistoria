class RadarHistorico {
  final String id;
  final String? vistoriaId;
  final String? placa;
  final String? chassi;
  final String? motor;
  final int codigoConsulta;
  final String idPesquisaRadar;
  final String status;
  final String? retornoBruto;
  final Map<String, dynamic> dadosTratados;
  final String? arquivoPesquisaUrl;
  final DateTime createdAt;

  RadarHistorico({
    required this.id,
    this.vistoriaId,
    this.placa,
    this.chassi,
    this.motor,
    required this.codigoConsulta,
    required this.idPesquisaRadar,
    required this.status,
    this.retornoBruto,
    required this.dadosTratados,
    this.arquivoPesquisaUrl,
    required this.createdAt,
  });

  factory RadarHistorico.fromJson(Map<String, dynamic> json) {
    return RadarHistorico(
      id: json['id'] ?? '',
      vistoriaId: json['vistoria_id'],
      placa: json['placa'],
      chassi: json['chassi'],
      motor: json['motor'],
      codigoConsulta: json['codigo_consulta'] ?? 0,
      idPesquisaRadar: json['id_pesquisa_radar'] ?? '',
      status: json['status'] ?? 'pendente',
      retornoBruto: json['retorno_bruto'],
      dadosTratados: json['dados_tratados'] ?? {},
      arquivoPesquisaUrl: json['arquivo_pesquisa_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(
              json['created_at'].toString().endsWith('Z') || json['created_at'].toString().contains('+') || json['created_at'].toString().contains('-')
                  ? json['created_at'].toString()
                  : '${json['created_at']}Z'
            ).toLocal()
          : DateTime.now(),
    );
  }

  bool get permiteRetificacao => true;

  String get tokenRadarOficial {
    if (dadosTratados['tokenConsulta'] != null &&
        dadosTratados['tokenConsulta'].toString().isNotEmpty) {
      return dadosTratados['tokenConsulta'].toString();
    }
    if (dadosTratados['token'] != null &&
        dadosTratados['token'].toString().isNotEmpty) {
      return dadosTratados['token'].toString();
    }
    if (arquivoPesquisaUrl != null && arquivoPesquisaUrl!.isNotEmpty) {
      final uri = Uri.tryParse(arquivoPesquisaUrl!);
      if (uri != null) {
        final segments = uri.pathSegments;
        final resIdx = segments.indexOf('resultado');
        if (resIdx != -1 && segments.length > resIdx + 1) {
          final t = segments[resIdx + 1];
          if (t.length >= 30) return t;
        }
      }
    }
    return idPesquisaRadar;
  }
}
