import 'package:equatable/equatable.dart';

class VistoriaEntity extends Equatable {
  final String id;
  final String numeroLaudo;
  final String status;
  final DateTime dataHora;
  final String vistoriadorId;
  final String? clienteNome;
  final String? observacoesGerais;
  final String? pdfUrl;
  final bool sincronizado;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relacionamentos (opcionais, carregados conforme necessário)
  final VeiculoEntity? veiculo;
  final List<ItemVistoriaEntity> itens;
  final List<FotoEntity> fotos;
  final List<ItemPinturaEntity> pintura;
  final List<ItemEstruturaEntity> estrutura;

  const VistoriaEntity({
    required this.id,
    required this.numeroLaudo,
    required this.status,
    required this.dataHora,
    required this.vistoriadorId,
    this.clienteNome,
    this.observacoesGerais,
    this.pdfUrl,
    required this.sincronizado,
    required this.createdAt,
    required this.updatedAt,
    this.veiculo,
    this.itens = const [],
    this.fotos = const [],
    this.pintura = const [],
    this.estrutura = const [],
  });

  VistoriaEntity copyWith({
    String? status,
    String? clienteNome,
    String? observacoesGerais,
    String? pdfUrl,
    bool? sincronizado,
    DateTime? updatedAt,
    VeiculoEntity? veiculo,
    List<ItemVistoriaEntity>? itens,
    List<FotoEntity>? fotos,
    List<ItemPinturaEntity>? pintura,
    List<ItemEstruturaEntity>? estrutura,
  }) {
    return VistoriaEntity(
      id: id,
      numeroLaudo: numeroLaudo,
      status: status ?? this.status,
      dataHora: dataHora,
      vistoriadorId: vistoriadorId,
      clienteNome: clienteNome ?? this.clienteNome,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      sincronizado: sincronizado ?? this.sincronizado,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      veiculo: veiculo ?? this.veiculo,
      itens: itens ?? this.itens,
      fotos: fotos ?? this.fotos,
      pintura: pintura ?? this.pintura,
      estrutura: estrutura ?? this.estrutura,
    );
  }

  /// Calcula status com base nos itens inspecionados
  String get statusCalculado {
    if (itens.isEmpty) return 'em_andamento';
    final temNaoConforme =
        itens.any((i) => i.status == 'nao_conforme');
    if (temNaoConforme) return 'nao_conforme';
    final temComObs =
        itens.any((i) => i.status == 'conforme_obs');
    if (temComObs) return 'conforme_obs';
    final temPendente = itens.any((i) => i.status == 'pendente');
    if (temPendente) return 'em_andamento';
    return 'conforme';
  }

  int get totalItens => itens.where((i) => i.status != 'nao_aplicavel').length;
  int get itensRespondidos =>
      itens.where((i) => i.status != 'pendente').length;

  @override
  List<Object?> get props => [
        id,
        numeroLaudo,
        status,
        dataHora,
        vistoriadorId,
        sincronizado,
      ];
}

// ── Veículo ──────────────────────────────────────────────────────────────────

class VeiculoEntity extends Equatable {
  final String id;
  final String vistoriaId;
  final String placa;
  final String? chassiVeiculo;
  final String? chassiBin;
  final String? motorVeiculo;
  final String? motorBin;
  final String? cambioVeiculo;
  final String? cambioBin;
  final String? renavam;
  final String? marca;
  final String? modelo;
  final int? anoFabricacao;
  final int? anoModelo;
  final String? cor;
  final String? combustivel;
  final int? km;
  final String tipo;
  final bool motorDivergente;
  final bool chassiDivergente;
  final bool cambioDivergente;

  const VeiculoEntity({
    required this.id,
    required this.vistoriaId,
    required this.placa,
    this.chassiVeiculo,
    this.chassiBin,
    this.motorVeiculo,
    this.motorBin,
    this.cambioVeiculo,
    this.cambioBin,
    this.renavam,
    this.marca,
    this.modelo,
    this.anoFabricacao,
    this.anoModelo,
    this.cor,
    this.combustivel,
    this.km,
    this.tipo = 'automovel',
    this.motorDivergente = false,
    this.chassiDivergente = false,
    this.cambioDivergente = false,
  });

  bool get temDivergencia =>
      motorDivergente || chassiDivergente || cambioDivergente;

  @override
  List<Object?> get props => [id, vistoriaId, placa];
}

// ── Item de Vistoria ─────────────────────────────────────────────────────────

class ItemVistoriaEntity extends Equatable {
  final String id;
  final String vistoriaId;
  final String categoria;
  final String nome;
  final String status;
  final String? observacao;
  final int ordem;

  const ItemVistoriaEntity({
    required this.id,
    required this.vistoriaId,
    required this.categoria,
    required this.nome,
    required this.status,
    this.observacao,
    required this.ordem,
  });

  ItemVistoriaEntity copyWith({String? status, String? observacao}) {
    return ItemVistoriaEntity(
      id: id,
      vistoriaId: vistoriaId,
      categoria: categoria,
      nome: nome,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      ordem: ordem,
    );
  }

  @override
  List<Object?> get props => [id, vistoriaId, categoria, nome, status];
}

// ── Foto ─────────────────────────────────────────────────────────────────────

class FotoEntity extends Equatable {
  final String id;
  final String vistoriaId;
  final String? itemId;
  final String legenda;
  final String? pathLocal;
  final String? urlSupabase;
  final String? storagePath;
  final int ordem;
  final DateTime createdAt;

  const FotoEntity({
    required this.id,
    required this.vistoriaId,
    this.itemId,
    required this.legenda,
    this.pathLocal,
    this.urlSupabase,
    this.storagePath,
    required this.ordem,
    required this.createdAt,
  });

  bool get uploadPendente => urlSupabase == null && pathLocal != null;

  @override
  List<Object?> get props => [id, vistoriaId, legenda];
}

// ── Pintura ──────────────────────────────────────────────────────────────────

class ItemPinturaEntity extends Equatable {
  final String id;
  final String vistoriaId;
  final String peca;
  final String status;
  final int? espessuraMicra;
  final String? observacao;

  const ItemPinturaEntity({
    required this.id,
    required this.vistoriaId,
    required this.peca,
    required this.status,
    this.espessuraMicra,
    this.observacao,
  });

  @override
  List<Object?> get props => [id, vistoriaId, peca, status];
}

// ── Estrutura ─────────────────────────────────────────────────────────────────

class ItemEstruturaEntity extends Equatable {
  final String id;
  final String vistoriaId;
  final String peca;
  final String status;
  final String? observacao;

  const ItemEstruturaEntity({
    required this.id,
    required this.vistoriaId,
    required this.peca,
    required this.status,
    this.observacao,
  });

  @override
  List<Object?> get props => [id, vistoriaId, peca, status];
}

// ── Vistoriador ───────────────────────────────────────────────────────────────

class VistoriadorEntity extends Equatable {
  final String id;
  final String nome;
  final String cpf;
  final String unidadeNome;
  final String? unidadeCnpj;
  final String cargo;

  const VistoriadorEntity({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.unidadeNome,
    this.unidadeCnpj,
    required this.cargo,
  });

  @override
  List<Object?> get props => [id, cpf];
}
