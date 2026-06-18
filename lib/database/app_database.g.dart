// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VistoriadoresTable extends Vistoriadores
    with TableInfo<$VistoriadoresTable, Vistoriadore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VistoriadoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  @override
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
      'cpf', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unidadeNomeMeta =
      const VerificationMeta('unidadeNome');
  @override
  late final GeneratedColumn<String> unidadeNome = GeneratedColumn<String>(
      'unidade_nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unidadeCnpjMeta =
      const VerificationMeta('unidadeCnpj');
  @override
  late final GeneratedColumn<String> unidadeCnpj = GeneratedColumn<String>(
      'unidade_cnpj', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cargoMeta = const VerificationMeta('cargo');
  @override
  late final GeneratedColumn<String> cargo = GeneratedColumn<String>(
      'cargo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('vistoriador'));
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, nome, cpf, unidadeNome, unidadeCnpj, cargo, ativo, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vistoriadores';
  @override
  VerificationContext validateIntegrity(Insertable<Vistoriadore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cpf')) {
      context.handle(
          _cpfMeta, cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta));
    } else if (isInserting) {
      context.missing(_cpfMeta);
    }
    if (data.containsKey('unidade_nome')) {
      context.handle(
          _unidadeNomeMeta,
          unidadeNome.isAcceptableOrUnknown(
              data['unidade_nome']!, _unidadeNomeMeta));
    } else if (isInserting) {
      context.missing(_unidadeNomeMeta);
    }
    if (data.containsKey('unidade_cnpj')) {
      context.handle(
          _unidadeCnpjMeta,
          unidadeCnpj.isAcceptableOrUnknown(
              data['unidade_cnpj']!, _unidadeCnpjMeta));
    }
    if (data.containsKey('cargo')) {
      context.handle(
          _cargoMeta, cargo.isAcceptableOrUnknown(data['cargo']!, _cargoMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vistoriadore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vistoriadore(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      cpf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cpf'])!,
      unidadeNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unidade_nome'])!,
      unidadeCnpj: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unidade_cnpj']),
      cargo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cargo'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VistoriadoresTable createAlias(String alias) {
    return $VistoriadoresTable(attachedDatabase, alias);
  }
}

class Vistoriadore extends DataClass implements Insertable<Vistoriadore> {
  final String id;
  final String nome;
  final String cpf;
  final String unidadeNome;
  final String? unidadeCnpj;
  final String cargo;
  final bool ativo;
  final DateTime createdAt;
  const Vistoriadore(
      {required this.id,
      required this.nome,
      required this.cpf,
      required this.unidadeNome,
      this.unidadeCnpj,
      required this.cargo,
      required this.ativo,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['cpf'] = Variable<String>(cpf);
    map['unidade_nome'] = Variable<String>(unidadeNome);
    if (!nullToAbsent || unidadeCnpj != null) {
      map['unidade_cnpj'] = Variable<String>(unidadeCnpj);
    }
    map['cargo'] = Variable<String>(cargo);
    map['ativo'] = Variable<bool>(ativo);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VistoriadoresCompanion toCompanion(bool nullToAbsent) {
    return VistoriadoresCompanion(
      id: Value(id),
      nome: Value(nome),
      cpf: Value(cpf),
      unidadeNome: Value(unidadeNome),
      unidadeCnpj: unidadeCnpj == null && nullToAbsent
          ? const Value.absent()
          : Value(unidadeCnpj),
      cargo: Value(cargo),
      ativo: Value(ativo),
      createdAt: Value(createdAt),
    );
  }

  factory Vistoriadore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vistoriadore(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      cpf: serializer.fromJson<String>(json['cpf']),
      unidadeNome: serializer.fromJson<String>(json['unidadeNome']),
      unidadeCnpj: serializer.fromJson<String?>(json['unidadeCnpj']),
      cargo: serializer.fromJson<String>(json['cargo']),
      ativo: serializer.fromJson<bool>(json['ativo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'cpf': serializer.toJson<String>(cpf),
      'unidadeNome': serializer.toJson<String>(unidadeNome),
      'unidadeCnpj': serializer.toJson<String?>(unidadeCnpj),
      'cargo': serializer.toJson<String>(cargo),
      'ativo': serializer.toJson<bool>(ativo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Vistoriadore copyWith(
          {String? id,
          String? nome,
          String? cpf,
          String? unidadeNome,
          Value<String?> unidadeCnpj = const Value.absent(),
          String? cargo,
          bool? ativo,
          DateTime? createdAt}) =>
      Vistoriadore(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        cpf: cpf ?? this.cpf,
        unidadeNome: unidadeNome ?? this.unidadeNome,
        unidadeCnpj: unidadeCnpj.present ? unidadeCnpj.value : this.unidadeCnpj,
        cargo: cargo ?? this.cargo,
        ativo: ativo ?? this.ativo,
        createdAt: createdAt ?? this.createdAt,
      );
  Vistoriadore copyWithCompanion(VistoriadoresCompanion data) {
    return Vistoriadore(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      unidadeNome:
          data.unidadeNome.present ? data.unidadeNome.value : this.unidadeNome,
      unidadeCnpj:
          data.unidadeCnpj.present ? data.unidadeCnpj.value : this.unidadeCnpj,
      cargo: data.cargo.present ? data.cargo.value : this.cargo,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vistoriadore(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('unidadeNome: $unidadeNome, ')
          ..write('unidadeCnpj: $unidadeCnpj, ')
          ..write('cargo: $cargo, ')
          ..write('ativo: $ativo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, nome, cpf, unidadeNome, unidadeCnpj, cargo, ativo, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vistoriadore &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.cpf == this.cpf &&
          other.unidadeNome == this.unidadeNome &&
          other.unidadeCnpj == this.unidadeCnpj &&
          other.cargo == this.cargo &&
          other.ativo == this.ativo &&
          other.createdAt == this.createdAt);
}

class VistoriadoresCompanion extends UpdateCompanion<Vistoriadore> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> cpf;
  final Value<String> unidadeNome;
  final Value<String?> unidadeCnpj;
  final Value<String> cargo;
  final Value<bool> ativo;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VistoriadoresCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.cpf = const Value.absent(),
    this.unidadeNome = const Value.absent(),
    this.unidadeCnpj = const Value.absent(),
    this.cargo = const Value.absent(),
    this.ativo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VistoriadoresCompanion.insert({
    required String id,
    required String nome,
    required String cpf,
    required String unidadeNome,
    this.unidadeCnpj = const Value.absent(),
    this.cargo = const Value.absent(),
    this.ativo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        nome = Value(nome),
        cpf = Value(cpf),
        unidadeNome = Value(unidadeNome);
  static Insertable<Vistoriadore> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? cpf,
    Expression<String>? unidadeNome,
    Expression<String>? unidadeCnpj,
    Expression<String>? cargo,
    Expression<bool>? ativo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (cpf != null) 'cpf': cpf,
      if (unidadeNome != null) 'unidade_nome': unidadeNome,
      if (unidadeCnpj != null) 'unidade_cnpj': unidadeCnpj,
      if (cargo != null) 'cargo': cargo,
      if (ativo != null) 'ativo': ativo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VistoriadoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? nome,
      Value<String>? cpf,
      Value<String>? unidadeNome,
      Value<String?>? unidadeCnpj,
      Value<String>? cargo,
      Value<bool>? ativo,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return VistoriadoresCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      unidadeNome: unidadeNome ?? this.unidadeNome,
      unidadeCnpj: unidadeCnpj ?? this.unidadeCnpj,
      cargo: cargo ?? this.cargo,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    if (unidadeNome.present) {
      map['unidade_nome'] = Variable<String>(unidadeNome.value);
    }
    if (unidadeCnpj.present) {
      map['unidade_cnpj'] = Variable<String>(unidadeCnpj.value);
    }
    if (cargo.present) {
      map['cargo'] = Variable<String>(cargo.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VistoriadoresCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('unidadeNome: $unidadeNome, ')
          ..write('unidadeCnpj: $unidadeCnpj, ')
          ..write('cargo: $cargo, ')
          ..write('ativo: $ativo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VistoriasTable extends Vistorias
    with TableInfo<$VistoriasTable, Vistoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VistoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numeroLaudoMeta =
      const VerificationMeta('numeroLaudo');
  @override
  late final GeneratedColumn<String> numeroLaudo = GeneratedColumn<String>(
      'numero_laudo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('em_andamento'));
  static const VerificationMeta _tipoVistoriaMeta =
      const VerificationMeta('tipoVistoria');
  @override
  late final GeneratedColumn<String> tipoVistoria = GeneratedColumn<String>(
      'tipo_vistoria', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cautelar_carro'));
  static const VerificationMeta _clienteNomeMeta =
      const VerificationMeta('clienteNome');
  @override
  late final GeneratedColumn<String> clienteNome = GeneratedColumn<String>(
      'cliente_nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unidadeMeta =
      const VerificationMeta('unidade');
  @override
  late final GeneratedColumn<String> unidade = GeneratedColumn<String>(
      'unidade', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _parecerTecnicoMeta =
      const VerificationMeta('parecerTecnico');
  @override
  late final GeneratedColumn<String> parecerTecnico = GeneratedColumn<String>(
      'parecer_tecnico', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusFinalMeta =
      const VerificationMeta('statusFinal');
  @override
  late final GeneratedColumn<String> statusFinal = GeneratedColumn<String>(
      'status_final', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _assinaturaPathMeta =
      const VerificationMeta('assinaturaPath');
  @override
  late final GeneratedColumn<String> assinaturaPath = GeneratedColumn<String>(
      'assinatura_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dataHoraMeta =
      const VerificationMeta('dataHora');
  @override
  late final GeneratedColumn<DateTime> dataHora = GeneratedColumn<DateTime>(
      'data_hora', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _vistoriadorIdMeta =
      const VerificationMeta('vistoriadorId');
  @override
  late final GeneratedColumn<String> vistoriadorId = GeneratedColumn<String>(
      'vistoriador_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriadorNomeMeta =
      const VerificationMeta('vistoriadorNome');
  @override
  late final GeneratedColumn<String> vistoriadorNome = GeneratedColumn<String>(
      'vistoriador_nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vistoriadorCpfMeta =
      const VerificationMeta('vistoriadorCpf');
  @override
  late final GeneratedColumn<String> vistoriadorCpf = GeneratedColumn<String>(
      'vistoriador_cpf', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacoesGeraisMeta =
      const VerificationMeta('observacoesGerais');
  @override
  late final GeneratedColumn<String> observacoesGerais =
      GeneratedColumn<String>('observacoes_gerais', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pdfUrlMeta = const VerificationMeta('pdfUrl');
  @override
  late final GeneratedColumn<String> pdfUrl = GeneratedColumn<String>(
      'pdf_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _etapaAtualMeta =
      const VerificationMeta('etapaAtual');
  @override
  late final GeneratedColumn<int> etapaAtual = GeneratedColumn<int>(
      'etapa_atual', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sincronizado" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        numeroLaudo,
        status,
        tipoVistoria,
        clienteNome,
        unidade,
        parecerTecnico,
        statusFinal,
        assinaturaPath,
        dataHora,
        vistoriadorId,
        vistoriadorNome,
        vistoriadorCpf,
        observacoesGerais,
        pdfUrl,
        etapaAtual,
        sincronizado,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vistorias';
  @override
  VerificationContext validateIntegrity(Insertable<Vistoria> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('numero_laudo')) {
      context.handle(
          _numeroLaudoMeta,
          numeroLaudo.isAcceptableOrUnknown(
              data['numero_laudo']!, _numeroLaudoMeta));
    } else if (isInserting) {
      context.missing(_numeroLaudoMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('tipo_vistoria')) {
      context.handle(
          _tipoVistoriaMeta,
          tipoVistoria.isAcceptableOrUnknown(
              data['tipo_vistoria']!, _tipoVistoriaMeta));
    }
    if (data.containsKey('cliente_nome')) {
      context.handle(
          _clienteNomeMeta,
          clienteNome.isAcceptableOrUnknown(
              data['cliente_nome']!, _clienteNomeMeta));
    }
    if (data.containsKey('unidade')) {
      context.handle(_unidadeMeta,
          unidade.isAcceptableOrUnknown(data['unidade']!, _unidadeMeta));
    }
    if (data.containsKey('parecer_tecnico')) {
      context.handle(
          _parecerTecnicoMeta,
          parecerTecnico.isAcceptableOrUnknown(
              data['parecer_tecnico']!, _parecerTecnicoMeta));
    }
    if (data.containsKey('status_final')) {
      context.handle(
          _statusFinalMeta,
          statusFinal.isAcceptableOrUnknown(
              data['status_final']!, _statusFinalMeta));
    }
    if (data.containsKey('assinatura_path')) {
      context.handle(
          _assinaturaPathMeta,
          assinaturaPath.isAcceptableOrUnknown(
              data['assinatura_path']!, _assinaturaPathMeta));
    }
    if (data.containsKey('data_hora')) {
      context.handle(_dataHoraMeta,
          dataHora.isAcceptableOrUnknown(data['data_hora']!, _dataHoraMeta));
    }
    if (data.containsKey('vistoriador_id')) {
      context.handle(
          _vistoriadorIdMeta,
          vistoriadorId.isAcceptableOrUnknown(
              data['vistoriador_id']!, _vistoriadorIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriadorIdMeta);
    }
    if (data.containsKey('vistoriador_nome')) {
      context.handle(
          _vistoriadorNomeMeta,
          vistoriadorNome.isAcceptableOrUnknown(
              data['vistoriador_nome']!, _vistoriadorNomeMeta));
    }
    if (data.containsKey('vistoriador_cpf')) {
      context.handle(
          _vistoriadorCpfMeta,
          vistoriadorCpf.isAcceptableOrUnknown(
              data['vistoriador_cpf']!, _vistoriadorCpfMeta));
    }
    if (data.containsKey('observacoes_gerais')) {
      context.handle(
          _observacoesGeraisMeta,
          observacoesGerais.isAcceptableOrUnknown(
              data['observacoes_gerais']!, _observacoesGeraisMeta));
    }
    if (data.containsKey('pdf_url')) {
      context.handle(_pdfUrlMeta,
          pdfUrl.isAcceptableOrUnknown(data['pdf_url']!, _pdfUrlMeta));
    }
    if (data.containsKey('etapa_atual')) {
      context.handle(
          _etapaAtualMeta,
          etapaAtual.isAcceptableOrUnknown(
              data['etapa_atual']!, _etapaAtualMeta));
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vistoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vistoria(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      numeroLaudo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}numero_laudo'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      tipoVistoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo_vistoria'])!,
      clienteNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cliente_nome']),
      unidade: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unidade']),
      parecerTecnico: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parecer_tecnico']),
      statusFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status_final']),
      assinaturaPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assinatura_path']),
      dataHora: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data_hora'])!,
      vistoriadorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoriador_id'])!,
      vistoriadorNome: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}vistoriador_nome']),
      vistoriadorCpf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoriador_cpf']),
      observacoesGerais: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}observacoes_gerais']),
      pdfUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pdf_url']),
      etapaAtual: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}etapa_atual'])!,
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sincronizado'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VistoriasTable createAlias(String alias) {
    return $VistoriasTable(attachedDatabase, alias);
  }
}

class Vistoria extends DataClass implements Insertable<Vistoria> {
  final String id;
  final String numeroLaudo;
  final String status;
  final String tipoVistoria;
  final String? clienteNome;
  final String? unidade;
  final String? parecerTecnico;
  final String? statusFinal;
  final String? assinaturaPath;
  final DateTime dataHora;
  final String vistoriadorId;
  final String? vistoriadorNome;
  final String? vistoriadorCpf;
  final String? observacoesGerais;
  final String? pdfUrl;
  final int etapaAtual;
  final bool sincronizado;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Vistoria(
      {required this.id,
      required this.numeroLaudo,
      required this.status,
      required this.tipoVistoria,
      this.clienteNome,
      this.unidade,
      this.parecerTecnico,
      this.statusFinal,
      this.assinaturaPath,
      required this.dataHora,
      required this.vistoriadorId,
      this.vistoriadorNome,
      this.vistoriadorCpf,
      this.observacoesGerais,
      this.pdfUrl,
      required this.etapaAtual,
      required this.sincronizado,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['numero_laudo'] = Variable<String>(numeroLaudo);
    map['status'] = Variable<String>(status);
    map['tipo_vistoria'] = Variable<String>(tipoVistoria);
    if (!nullToAbsent || clienteNome != null) {
      map['cliente_nome'] = Variable<String>(clienteNome);
    }
    if (!nullToAbsent || unidade != null) {
      map['unidade'] = Variable<String>(unidade);
    }
    if (!nullToAbsent || parecerTecnico != null) {
      map['parecer_tecnico'] = Variable<String>(parecerTecnico);
    }
    if (!nullToAbsent || statusFinal != null) {
      map['status_final'] = Variable<String>(statusFinal);
    }
    if (!nullToAbsent || assinaturaPath != null) {
      map['assinatura_path'] = Variable<String>(assinaturaPath);
    }
    map['data_hora'] = Variable<DateTime>(dataHora);
    map['vistoriador_id'] = Variable<String>(vistoriadorId);
    if (!nullToAbsent || vistoriadorNome != null) {
      map['vistoriador_nome'] = Variable<String>(vistoriadorNome);
    }
    if (!nullToAbsent || vistoriadorCpf != null) {
      map['vistoriador_cpf'] = Variable<String>(vistoriadorCpf);
    }
    if (!nullToAbsent || observacoesGerais != null) {
      map['observacoes_gerais'] = Variable<String>(observacoesGerais);
    }
    if (!nullToAbsent || pdfUrl != null) {
      map['pdf_url'] = Variable<String>(pdfUrl);
    }
    map['etapa_atual'] = Variable<int>(etapaAtual);
    map['sincronizado'] = Variable<bool>(sincronizado);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VistoriasCompanion toCompanion(bool nullToAbsent) {
    return VistoriasCompanion(
      id: Value(id),
      numeroLaudo: Value(numeroLaudo),
      status: Value(status),
      tipoVistoria: Value(tipoVistoria),
      clienteNome: clienteNome == null && nullToAbsent
          ? const Value.absent()
          : Value(clienteNome),
      unidade: unidade == null && nullToAbsent
          ? const Value.absent()
          : Value(unidade),
      parecerTecnico: parecerTecnico == null && nullToAbsent
          ? const Value.absent()
          : Value(parecerTecnico),
      statusFinal: statusFinal == null && nullToAbsent
          ? const Value.absent()
          : Value(statusFinal),
      assinaturaPath: assinaturaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(assinaturaPath),
      dataHora: Value(dataHora),
      vistoriadorId: Value(vistoriadorId),
      vistoriadorNome: vistoriadorNome == null && nullToAbsent
          ? const Value.absent()
          : Value(vistoriadorNome),
      vistoriadorCpf: vistoriadorCpf == null && nullToAbsent
          ? const Value.absent()
          : Value(vistoriadorCpf),
      observacoesGerais: observacoesGerais == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoesGerais),
      pdfUrl:
          pdfUrl == null && nullToAbsent ? const Value.absent() : Value(pdfUrl),
      etapaAtual: Value(etapaAtual),
      sincronizado: Value(sincronizado),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Vistoria.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vistoria(
      id: serializer.fromJson<String>(json['id']),
      numeroLaudo: serializer.fromJson<String>(json['numeroLaudo']),
      status: serializer.fromJson<String>(json['status']),
      tipoVistoria: serializer.fromJson<String>(json['tipoVistoria']),
      clienteNome: serializer.fromJson<String?>(json['clienteNome']),
      unidade: serializer.fromJson<String?>(json['unidade']),
      parecerTecnico: serializer.fromJson<String?>(json['parecerTecnico']),
      statusFinal: serializer.fromJson<String?>(json['statusFinal']),
      assinaturaPath: serializer.fromJson<String?>(json['assinaturaPath']),
      dataHora: serializer.fromJson<DateTime>(json['dataHora']),
      vistoriadorId: serializer.fromJson<String>(json['vistoriadorId']),
      vistoriadorNome: serializer.fromJson<String?>(json['vistoriadorNome']),
      vistoriadorCpf: serializer.fromJson<String?>(json['vistoriadorCpf']),
      observacoesGerais:
          serializer.fromJson<String?>(json['observacoesGerais']),
      pdfUrl: serializer.fromJson<String?>(json['pdfUrl']),
      etapaAtual: serializer.fromJson<int>(json['etapaAtual']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'numeroLaudo': serializer.toJson<String>(numeroLaudo),
      'status': serializer.toJson<String>(status),
      'tipoVistoria': serializer.toJson<String>(tipoVistoria),
      'clienteNome': serializer.toJson<String?>(clienteNome),
      'unidade': serializer.toJson<String?>(unidade),
      'parecerTecnico': serializer.toJson<String?>(parecerTecnico),
      'statusFinal': serializer.toJson<String?>(statusFinal),
      'assinaturaPath': serializer.toJson<String?>(assinaturaPath),
      'dataHora': serializer.toJson<DateTime>(dataHora),
      'vistoriadorId': serializer.toJson<String>(vistoriadorId),
      'vistoriadorNome': serializer.toJson<String?>(vistoriadorNome),
      'vistoriadorCpf': serializer.toJson<String?>(vistoriadorCpf),
      'observacoesGerais': serializer.toJson<String?>(observacoesGerais),
      'pdfUrl': serializer.toJson<String?>(pdfUrl),
      'etapaAtual': serializer.toJson<int>(etapaAtual),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Vistoria copyWith(
          {String? id,
          String? numeroLaudo,
          String? status,
          String? tipoVistoria,
          Value<String?> clienteNome = const Value.absent(),
          Value<String?> unidade = const Value.absent(),
          Value<String?> parecerTecnico = const Value.absent(),
          Value<String?> statusFinal = const Value.absent(),
          Value<String?> assinaturaPath = const Value.absent(),
          DateTime? dataHora,
          String? vistoriadorId,
          Value<String?> vistoriadorNome = const Value.absent(),
          Value<String?> vistoriadorCpf = const Value.absent(),
          Value<String?> observacoesGerais = const Value.absent(),
          Value<String?> pdfUrl = const Value.absent(),
          int? etapaAtual,
          bool? sincronizado,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Vistoria(
        id: id ?? this.id,
        numeroLaudo: numeroLaudo ?? this.numeroLaudo,
        status: status ?? this.status,
        tipoVistoria: tipoVistoria ?? this.tipoVistoria,
        clienteNome: clienteNome.present ? clienteNome.value : this.clienteNome,
        unidade: unidade.present ? unidade.value : this.unidade,
        parecerTecnico:
            parecerTecnico.present ? parecerTecnico.value : this.parecerTecnico,
        statusFinal: statusFinal.present ? statusFinal.value : this.statusFinal,
        assinaturaPath:
            assinaturaPath.present ? assinaturaPath.value : this.assinaturaPath,
        dataHora: dataHora ?? this.dataHora,
        vistoriadorId: vistoriadorId ?? this.vistoriadorId,
        vistoriadorNome: vistoriadorNome.present
            ? vistoriadorNome.value
            : this.vistoriadorNome,
        vistoriadorCpf:
            vistoriadorCpf.present ? vistoriadorCpf.value : this.vistoriadorCpf,
        observacoesGerais: observacoesGerais.present
            ? observacoesGerais.value
            : this.observacoesGerais,
        pdfUrl: pdfUrl.present ? pdfUrl.value : this.pdfUrl,
        etapaAtual: etapaAtual ?? this.etapaAtual,
        sincronizado: sincronizado ?? this.sincronizado,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Vistoria copyWithCompanion(VistoriasCompanion data) {
    return Vistoria(
      id: data.id.present ? data.id.value : this.id,
      numeroLaudo:
          data.numeroLaudo.present ? data.numeroLaudo.value : this.numeroLaudo,
      status: data.status.present ? data.status.value : this.status,
      tipoVistoria: data.tipoVistoria.present
          ? data.tipoVistoria.value
          : this.tipoVistoria,
      clienteNome:
          data.clienteNome.present ? data.clienteNome.value : this.clienteNome,
      unidade: data.unidade.present ? data.unidade.value : this.unidade,
      parecerTecnico: data.parecerTecnico.present
          ? data.parecerTecnico.value
          : this.parecerTecnico,
      statusFinal:
          data.statusFinal.present ? data.statusFinal.value : this.statusFinal,
      assinaturaPath: data.assinaturaPath.present
          ? data.assinaturaPath.value
          : this.assinaturaPath,
      dataHora: data.dataHora.present ? data.dataHora.value : this.dataHora,
      vistoriadorId: data.vistoriadorId.present
          ? data.vistoriadorId.value
          : this.vistoriadorId,
      vistoriadorNome: data.vistoriadorNome.present
          ? data.vistoriadorNome.value
          : this.vistoriadorNome,
      vistoriadorCpf: data.vistoriadorCpf.present
          ? data.vistoriadorCpf.value
          : this.vistoriadorCpf,
      observacoesGerais: data.observacoesGerais.present
          ? data.observacoesGerais.value
          : this.observacoesGerais,
      pdfUrl: data.pdfUrl.present ? data.pdfUrl.value : this.pdfUrl,
      etapaAtual:
          data.etapaAtual.present ? data.etapaAtual.value : this.etapaAtual,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vistoria(')
          ..write('id: $id, ')
          ..write('numeroLaudo: $numeroLaudo, ')
          ..write('status: $status, ')
          ..write('tipoVistoria: $tipoVistoria, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('unidade: $unidade, ')
          ..write('parecerTecnico: $parecerTecnico, ')
          ..write('statusFinal: $statusFinal, ')
          ..write('assinaturaPath: $assinaturaPath, ')
          ..write('dataHora: $dataHora, ')
          ..write('vistoriadorId: $vistoriadorId, ')
          ..write('vistoriadorNome: $vistoriadorNome, ')
          ..write('vistoriadorCpf: $vistoriadorCpf, ')
          ..write('observacoesGerais: $observacoesGerais, ')
          ..write('pdfUrl: $pdfUrl, ')
          ..write('etapaAtual: $etapaAtual, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      numeroLaudo,
      status,
      tipoVistoria,
      clienteNome,
      unidade,
      parecerTecnico,
      statusFinal,
      assinaturaPath,
      dataHora,
      vistoriadorId,
      vistoriadorNome,
      vistoriadorCpf,
      observacoesGerais,
      pdfUrl,
      etapaAtual,
      sincronizado,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vistoria &&
          other.id == this.id &&
          other.numeroLaudo == this.numeroLaudo &&
          other.status == this.status &&
          other.tipoVistoria == this.tipoVistoria &&
          other.clienteNome == this.clienteNome &&
          other.unidade == this.unidade &&
          other.parecerTecnico == this.parecerTecnico &&
          other.statusFinal == this.statusFinal &&
          other.assinaturaPath == this.assinaturaPath &&
          other.dataHora == this.dataHora &&
          other.vistoriadorId == this.vistoriadorId &&
          other.vistoriadorNome == this.vistoriadorNome &&
          other.vistoriadorCpf == this.vistoriadorCpf &&
          other.observacoesGerais == this.observacoesGerais &&
          other.pdfUrl == this.pdfUrl &&
          other.etapaAtual == this.etapaAtual &&
          other.sincronizado == this.sincronizado &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VistoriasCompanion extends UpdateCompanion<Vistoria> {
  final Value<String> id;
  final Value<String> numeroLaudo;
  final Value<String> status;
  final Value<String> tipoVistoria;
  final Value<String?> clienteNome;
  final Value<String?> unidade;
  final Value<String?> parecerTecnico;
  final Value<String?> statusFinal;
  final Value<String?> assinaturaPath;
  final Value<DateTime> dataHora;
  final Value<String> vistoriadorId;
  final Value<String?> vistoriadorNome;
  final Value<String?> vistoriadorCpf;
  final Value<String?> observacoesGerais;
  final Value<String?> pdfUrl;
  final Value<int> etapaAtual;
  final Value<bool> sincronizado;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VistoriasCompanion({
    this.id = const Value.absent(),
    this.numeroLaudo = const Value.absent(),
    this.status = const Value.absent(),
    this.tipoVistoria = const Value.absent(),
    this.clienteNome = const Value.absent(),
    this.unidade = const Value.absent(),
    this.parecerTecnico = const Value.absent(),
    this.statusFinal = const Value.absent(),
    this.assinaturaPath = const Value.absent(),
    this.dataHora = const Value.absent(),
    this.vistoriadorId = const Value.absent(),
    this.vistoriadorNome = const Value.absent(),
    this.vistoriadorCpf = const Value.absent(),
    this.observacoesGerais = const Value.absent(),
    this.pdfUrl = const Value.absent(),
    this.etapaAtual = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VistoriasCompanion.insert({
    required String id,
    required String numeroLaudo,
    this.status = const Value.absent(),
    this.tipoVistoria = const Value.absent(),
    this.clienteNome = const Value.absent(),
    this.unidade = const Value.absent(),
    this.parecerTecnico = const Value.absent(),
    this.statusFinal = const Value.absent(),
    this.assinaturaPath = const Value.absent(),
    this.dataHora = const Value.absent(),
    required String vistoriadorId,
    this.vistoriadorNome = const Value.absent(),
    this.vistoriadorCpf = const Value.absent(),
    this.observacoesGerais = const Value.absent(),
    this.pdfUrl = const Value.absent(),
    this.etapaAtual = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        numeroLaudo = Value(numeroLaudo),
        vistoriadorId = Value(vistoriadorId);
  static Insertable<Vistoria> custom({
    Expression<String>? id,
    Expression<String>? numeroLaudo,
    Expression<String>? status,
    Expression<String>? tipoVistoria,
    Expression<String>? clienteNome,
    Expression<String>? unidade,
    Expression<String>? parecerTecnico,
    Expression<String>? statusFinal,
    Expression<String>? assinaturaPath,
    Expression<DateTime>? dataHora,
    Expression<String>? vistoriadorId,
    Expression<String>? vistoriadorNome,
    Expression<String>? vistoriadorCpf,
    Expression<String>? observacoesGerais,
    Expression<String>? pdfUrl,
    Expression<int>? etapaAtual,
    Expression<bool>? sincronizado,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numeroLaudo != null) 'numero_laudo': numeroLaudo,
      if (status != null) 'status': status,
      if (tipoVistoria != null) 'tipo_vistoria': tipoVistoria,
      if (clienteNome != null) 'cliente_nome': clienteNome,
      if (unidade != null) 'unidade': unidade,
      if (parecerTecnico != null) 'parecer_tecnico': parecerTecnico,
      if (statusFinal != null) 'status_final': statusFinal,
      if (assinaturaPath != null) 'assinatura_path': assinaturaPath,
      if (dataHora != null) 'data_hora': dataHora,
      if (vistoriadorId != null) 'vistoriador_id': vistoriadorId,
      if (vistoriadorNome != null) 'vistoriador_nome': vistoriadorNome,
      if (vistoriadorCpf != null) 'vistoriador_cpf': vistoriadorCpf,
      if (observacoesGerais != null) 'observacoes_gerais': observacoesGerais,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (etapaAtual != null) 'etapa_atual': etapaAtual,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VistoriasCompanion copyWith(
      {Value<String>? id,
      Value<String>? numeroLaudo,
      Value<String>? status,
      Value<String>? tipoVistoria,
      Value<String?>? clienteNome,
      Value<String?>? unidade,
      Value<String?>? parecerTecnico,
      Value<String?>? statusFinal,
      Value<String?>? assinaturaPath,
      Value<DateTime>? dataHora,
      Value<String>? vistoriadorId,
      Value<String?>? vistoriadorNome,
      Value<String?>? vistoriadorCpf,
      Value<String?>? observacoesGerais,
      Value<String?>? pdfUrl,
      Value<int>? etapaAtual,
      Value<bool>? sincronizado,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VistoriasCompanion(
      id: id ?? this.id,
      numeroLaudo: numeroLaudo ?? this.numeroLaudo,
      status: status ?? this.status,
      tipoVistoria: tipoVistoria ?? this.tipoVistoria,
      clienteNome: clienteNome ?? this.clienteNome,
      unidade: unidade ?? this.unidade,
      parecerTecnico: parecerTecnico ?? this.parecerTecnico,
      statusFinal: statusFinal ?? this.statusFinal,
      assinaturaPath: assinaturaPath ?? this.assinaturaPath,
      dataHora: dataHora ?? this.dataHora,
      vistoriadorId: vistoriadorId ?? this.vistoriadorId,
      vistoriadorNome: vistoriadorNome ?? this.vistoriadorNome,
      vistoriadorCpf: vistoriadorCpf ?? this.vistoriadorCpf,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      etapaAtual: etapaAtual ?? this.etapaAtual,
      sincronizado: sincronizado ?? this.sincronizado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (numeroLaudo.present) {
      map['numero_laudo'] = Variable<String>(numeroLaudo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (tipoVistoria.present) {
      map['tipo_vistoria'] = Variable<String>(tipoVistoria.value);
    }
    if (clienteNome.present) {
      map['cliente_nome'] = Variable<String>(clienteNome.value);
    }
    if (unidade.present) {
      map['unidade'] = Variable<String>(unidade.value);
    }
    if (parecerTecnico.present) {
      map['parecer_tecnico'] = Variable<String>(parecerTecnico.value);
    }
    if (statusFinal.present) {
      map['status_final'] = Variable<String>(statusFinal.value);
    }
    if (assinaturaPath.present) {
      map['assinatura_path'] = Variable<String>(assinaturaPath.value);
    }
    if (dataHora.present) {
      map['data_hora'] = Variable<DateTime>(dataHora.value);
    }
    if (vistoriadorId.present) {
      map['vistoriador_id'] = Variable<String>(vistoriadorId.value);
    }
    if (vistoriadorNome.present) {
      map['vistoriador_nome'] = Variable<String>(vistoriadorNome.value);
    }
    if (vistoriadorCpf.present) {
      map['vistoriador_cpf'] = Variable<String>(vistoriadorCpf.value);
    }
    if (observacoesGerais.present) {
      map['observacoes_gerais'] = Variable<String>(observacoesGerais.value);
    }
    if (pdfUrl.present) {
      map['pdf_url'] = Variable<String>(pdfUrl.value);
    }
    if (etapaAtual.present) {
      map['etapa_atual'] = Variable<int>(etapaAtual.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VistoriasCompanion(')
          ..write('id: $id, ')
          ..write('numeroLaudo: $numeroLaudo, ')
          ..write('status: $status, ')
          ..write('tipoVistoria: $tipoVistoria, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('unidade: $unidade, ')
          ..write('parecerTecnico: $parecerTecnico, ')
          ..write('statusFinal: $statusFinal, ')
          ..write('assinaturaPath: $assinaturaPath, ')
          ..write('dataHora: $dataHora, ')
          ..write('vistoriadorId: $vistoriadorId, ')
          ..write('vistoriadorNome: $vistoriadorNome, ')
          ..write('vistoriadorCpf: $vistoriadorCpf, ')
          ..write('observacoesGerais: $observacoesGerais, ')
          ..write('pdfUrl: $pdfUrl, ')
          ..write('etapaAtual: $etapaAtual, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VeiculosTable extends Veiculos with TableInfo<$VeiculosTable, Veiculo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VeiculosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _placaMeta = const VerificationMeta('placa');
  @override
  late final GeneratedColumn<String> placa = GeneratedColumn<String>(
      'placa', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chassiVeiculoMeta =
      const VerificationMeta('chassiVeiculo');
  @override
  late final GeneratedColumn<String> chassiVeiculo = GeneratedColumn<String>(
      'chassi_veiculo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chassiBinMeta =
      const VerificationMeta('chassiBin');
  @override
  late final GeneratedColumn<String> chassiBin = GeneratedColumn<String>(
      'chassi_bin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motorVeiculoMeta =
      const VerificationMeta('motorVeiculo');
  @override
  late final GeneratedColumn<String> motorVeiculo = GeneratedColumn<String>(
      'motor_veiculo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motorBinMeta =
      const VerificationMeta('motorBin');
  @override
  late final GeneratedColumn<String> motorBin = GeneratedColumn<String>(
      'motor_bin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cambioVeiculoMeta =
      const VerificationMeta('cambioVeiculo');
  @override
  late final GeneratedColumn<String> cambioVeiculo = GeneratedColumn<String>(
      'cambio_veiculo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cambioBinMeta =
      const VerificationMeta('cambioBin');
  @override
  late final GeneratedColumn<String> cambioBin = GeneratedColumn<String>(
      'cambio_bin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _renavamMeta =
      const VerificationMeta('renavam');
  @override
  late final GeneratedColumn<String> renavam = GeneratedColumn<String>(
      'renavam', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
      'marca', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
      'modelo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _anoFabricacaoMeta =
      const VerificationMeta('anoFabricacao');
  @override
  late final GeneratedColumn<int> anoFabricacao = GeneratedColumn<int>(
      'ano_fabricacao', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _anoModeloMeta =
      const VerificationMeta('anoModelo');
  @override
  late final GeneratedColumn<int> anoModelo = GeneratedColumn<int>(
      'ano_modelo', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _corMeta = const VerificationMeta('cor');
  @override
  late final GeneratedColumn<String> cor = GeneratedColumn<String>(
      'cor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _combustivelMeta =
      const VerificationMeta('combustivel');
  @override
  late final GeneratedColumn<String> combustivel = GeneratedColumn<String>(
      'combustivel', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<int> km = GeneratedColumn<int>(
      'km', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _municipioMeta =
      const VerificationMeta('municipio');
  @override
  late final GeneratedColumn<String> municipio = GeneratedColumn<String>(
      'municipio', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ufMeta = const VerificationMeta('uf');
  @override
  late final GeneratedColumn<String> uf = GeneratedColumn<String>(
      'uf', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _numeroGrvMeta =
      const VerificationMeta('numeroGrv');
  @override
  late final GeneratedColumn<String> numeroGrv = GeneratedColumn<String>(
      'numero_grv', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('automovel'));
  static const VerificationMeta _motorDivergenteMeta =
      const VerificationMeta('motorDivergente');
  @override
  late final GeneratedColumn<bool> motorDivergente = GeneratedColumn<bool>(
      'motor_divergente', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("motor_divergente" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _chassiDivergenteMeta =
      const VerificationMeta('chassiDivergente');
  @override
  late final GeneratedColumn<bool> chassiDivergente = GeneratedColumn<bool>(
      'chassi_divergente', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("chassi_divergente" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _cambioDivergenteMeta =
      const VerificationMeta('cambioDivergente');
  @override
  late final GeneratedColumn<bool> cambioDivergente = GeneratedColumn<bool>(
      'cambio_divergente', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("cambio_divergente" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vistoriaId,
        placa,
        chassiVeiculo,
        chassiBin,
        motorVeiculo,
        motorBin,
        cambioVeiculo,
        cambioBin,
        renavam,
        marca,
        modelo,
        anoFabricacao,
        anoModelo,
        cor,
        combustivel,
        km,
        municipio,
        uf,
        numeroGrv,
        tipo,
        motorDivergente,
        chassiDivergente,
        cambioDivergente
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'veiculos';
  @override
  VerificationContext validateIntegrity(Insertable<Veiculo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('placa')) {
      context.handle(
          _placaMeta, placa.isAcceptableOrUnknown(data['placa']!, _placaMeta));
    } else if (isInserting) {
      context.missing(_placaMeta);
    }
    if (data.containsKey('chassi_veiculo')) {
      context.handle(
          _chassiVeiculoMeta,
          chassiVeiculo.isAcceptableOrUnknown(
              data['chassi_veiculo']!, _chassiVeiculoMeta));
    }
    if (data.containsKey('chassi_bin')) {
      context.handle(_chassiBinMeta,
          chassiBin.isAcceptableOrUnknown(data['chassi_bin']!, _chassiBinMeta));
    }
    if (data.containsKey('motor_veiculo')) {
      context.handle(
          _motorVeiculoMeta,
          motorVeiculo.isAcceptableOrUnknown(
              data['motor_veiculo']!, _motorVeiculoMeta));
    }
    if (data.containsKey('motor_bin')) {
      context.handle(_motorBinMeta,
          motorBin.isAcceptableOrUnknown(data['motor_bin']!, _motorBinMeta));
    }
    if (data.containsKey('cambio_veiculo')) {
      context.handle(
          _cambioVeiculoMeta,
          cambioVeiculo.isAcceptableOrUnknown(
              data['cambio_veiculo']!, _cambioVeiculoMeta));
    }
    if (data.containsKey('cambio_bin')) {
      context.handle(_cambioBinMeta,
          cambioBin.isAcceptableOrUnknown(data['cambio_bin']!, _cambioBinMeta));
    }
    if (data.containsKey('renavam')) {
      context.handle(_renavamMeta,
          renavam.isAcceptableOrUnknown(data['renavam']!, _renavamMeta));
    }
    if (data.containsKey('marca')) {
      context.handle(
          _marcaMeta, marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta));
    }
    if (data.containsKey('modelo')) {
      context.handle(_modeloMeta,
          modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta));
    }
    if (data.containsKey('ano_fabricacao')) {
      context.handle(
          _anoFabricacaoMeta,
          anoFabricacao.isAcceptableOrUnknown(
              data['ano_fabricacao']!, _anoFabricacaoMeta));
    }
    if (data.containsKey('ano_modelo')) {
      context.handle(_anoModeloMeta,
          anoModelo.isAcceptableOrUnknown(data['ano_modelo']!, _anoModeloMeta));
    }
    if (data.containsKey('cor')) {
      context.handle(
          _corMeta, cor.isAcceptableOrUnknown(data['cor']!, _corMeta));
    }
    if (data.containsKey('combustivel')) {
      context.handle(
          _combustivelMeta,
          combustivel.isAcceptableOrUnknown(
              data['combustivel']!, _combustivelMeta));
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    }
    if (data.containsKey('municipio')) {
      context.handle(_municipioMeta,
          municipio.isAcceptableOrUnknown(data['municipio']!, _municipioMeta));
    }
    if (data.containsKey('uf')) {
      context.handle(_ufMeta, uf.isAcceptableOrUnknown(data['uf']!, _ufMeta));
    }
    if (data.containsKey('numero_grv')) {
      context.handle(_numeroGrvMeta,
          numeroGrv.isAcceptableOrUnknown(data['numero_grv']!, _numeroGrvMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    }
    if (data.containsKey('motor_divergente')) {
      context.handle(
          _motorDivergenteMeta,
          motorDivergente.isAcceptableOrUnknown(
              data['motor_divergente']!, _motorDivergenteMeta));
    }
    if (data.containsKey('chassi_divergente')) {
      context.handle(
          _chassiDivergenteMeta,
          chassiDivergente.isAcceptableOrUnknown(
              data['chassi_divergente']!, _chassiDivergenteMeta));
    }
    if (data.containsKey('cambio_divergente')) {
      context.handle(
          _cambioDivergenteMeta,
          cambioDivergente.isAcceptableOrUnknown(
              data['cambio_divergente']!, _cambioDivergenteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Veiculo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Veiculo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      placa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}placa'])!,
      chassiVeiculo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chassi_veiculo']),
      chassiBin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chassi_bin']),
      motorVeiculo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motor_veiculo']),
      motorBin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motor_bin']),
      cambioVeiculo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cambio_veiculo']),
      cambioBin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cambio_bin']),
      renavam: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}renavam']),
      marca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marca']),
      modelo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modelo']),
      anoFabricacao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ano_fabricacao']),
      anoModelo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ano_modelo']),
      cor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cor']),
      combustivel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}combustivel']),
      km: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}km']),
      municipio: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}municipio']),
      uf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uf']),
      numeroGrv: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}numero_grv']),
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      motorDivergente: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}motor_divergente'])!,
      chassiDivergente: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}chassi_divergente'])!,
      cambioDivergente: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}cambio_divergente'])!,
    );
  }

  @override
  $VeiculosTable createAlias(String alias) {
    return $VeiculosTable(attachedDatabase, alias);
  }
}

class Veiculo extends DataClass implements Insertable<Veiculo> {
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
  final String? municipio;
  final String? uf;
  final String? numeroGrv;
  final String tipo;
  final bool motorDivergente;
  final bool chassiDivergente;
  final bool cambioDivergente;
  const Veiculo(
      {required this.id,
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
      this.municipio,
      this.uf,
      this.numeroGrv,
      required this.tipo,
      required this.motorDivergente,
      required this.chassiDivergente,
      required this.cambioDivergente});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    map['placa'] = Variable<String>(placa);
    if (!nullToAbsent || chassiVeiculo != null) {
      map['chassi_veiculo'] = Variable<String>(chassiVeiculo);
    }
    if (!nullToAbsent || chassiBin != null) {
      map['chassi_bin'] = Variable<String>(chassiBin);
    }
    if (!nullToAbsent || motorVeiculo != null) {
      map['motor_veiculo'] = Variable<String>(motorVeiculo);
    }
    if (!nullToAbsent || motorBin != null) {
      map['motor_bin'] = Variable<String>(motorBin);
    }
    if (!nullToAbsent || cambioVeiculo != null) {
      map['cambio_veiculo'] = Variable<String>(cambioVeiculo);
    }
    if (!nullToAbsent || cambioBin != null) {
      map['cambio_bin'] = Variable<String>(cambioBin);
    }
    if (!nullToAbsent || renavam != null) {
      map['renavam'] = Variable<String>(renavam);
    }
    if (!nullToAbsent || marca != null) {
      map['marca'] = Variable<String>(marca);
    }
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    if (!nullToAbsent || anoFabricacao != null) {
      map['ano_fabricacao'] = Variable<int>(anoFabricacao);
    }
    if (!nullToAbsent || anoModelo != null) {
      map['ano_modelo'] = Variable<int>(anoModelo);
    }
    if (!nullToAbsent || cor != null) {
      map['cor'] = Variable<String>(cor);
    }
    if (!nullToAbsent || combustivel != null) {
      map['combustivel'] = Variable<String>(combustivel);
    }
    if (!nullToAbsent || km != null) {
      map['km'] = Variable<int>(km);
    }
    if (!nullToAbsent || municipio != null) {
      map['municipio'] = Variable<String>(municipio);
    }
    if (!nullToAbsent || uf != null) {
      map['uf'] = Variable<String>(uf);
    }
    if (!nullToAbsent || numeroGrv != null) {
      map['numero_grv'] = Variable<String>(numeroGrv);
    }
    map['tipo'] = Variable<String>(tipo);
    map['motor_divergente'] = Variable<bool>(motorDivergente);
    map['chassi_divergente'] = Variable<bool>(chassiDivergente);
    map['cambio_divergente'] = Variable<bool>(cambioDivergente);
    return map;
  }

  VeiculosCompanion toCompanion(bool nullToAbsent) {
    return VeiculosCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      placa: Value(placa),
      chassiVeiculo: chassiVeiculo == null && nullToAbsent
          ? const Value.absent()
          : Value(chassiVeiculo),
      chassiBin: chassiBin == null && nullToAbsent
          ? const Value.absent()
          : Value(chassiBin),
      motorVeiculo: motorVeiculo == null && nullToAbsent
          ? const Value.absent()
          : Value(motorVeiculo),
      motorBin: motorBin == null && nullToAbsent
          ? const Value.absent()
          : Value(motorBin),
      cambioVeiculo: cambioVeiculo == null && nullToAbsent
          ? const Value.absent()
          : Value(cambioVeiculo),
      cambioBin: cambioBin == null && nullToAbsent
          ? const Value.absent()
          : Value(cambioBin),
      renavam: renavam == null && nullToAbsent
          ? const Value.absent()
          : Value(renavam),
      marca:
          marca == null && nullToAbsent ? const Value.absent() : Value(marca),
      modelo:
          modelo == null && nullToAbsent ? const Value.absent() : Value(modelo),
      anoFabricacao: anoFabricacao == null && nullToAbsent
          ? const Value.absent()
          : Value(anoFabricacao),
      anoModelo: anoModelo == null && nullToAbsent
          ? const Value.absent()
          : Value(anoModelo),
      cor: cor == null && nullToAbsent ? const Value.absent() : Value(cor),
      combustivel: combustivel == null && nullToAbsent
          ? const Value.absent()
          : Value(combustivel),
      km: km == null && nullToAbsent ? const Value.absent() : Value(km),
      municipio: municipio == null && nullToAbsent
          ? const Value.absent()
          : Value(municipio),
      uf: uf == null && nullToAbsent ? const Value.absent() : Value(uf),
      numeroGrv: numeroGrv == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroGrv),
      tipo: Value(tipo),
      motorDivergente: Value(motorDivergente),
      chassiDivergente: Value(chassiDivergente),
      cambioDivergente: Value(cambioDivergente),
    );
  }

  factory Veiculo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Veiculo(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      placa: serializer.fromJson<String>(json['placa']),
      chassiVeiculo: serializer.fromJson<String?>(json['chassiVeiculo']),
      chassiBin: serializer.fromJson<String?>(json['chassiBin']),
      motorVeiculo: serializer.fromJson<String?>(json['motorVeiculo']),
      motorBin: serializer.fromJson<String?>(json['motorBin']),
      cambioVeiculo: serializer.fromJson<String?>(json['cambioVeiculo']),
      cambioBin: serializer.fromJson<String?>(json['cambioBin']),
      renavam: serializer.fromJson<String?>(json['renavam']),
      marca: serializer.fromJson<String?>(json['marca']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      anoFabricacao: serializer.fromJson<int?>(json['anoFabricacao']),
      anoModelo: serializer.fromJson<int?>(json['anoModelo']),
      cor: serializer.fromJson<String?>(json['cor']),
      combustivel: serializer.fromJson<String?>(json['combustivel']),
      km: serializer.fromJson<int?>(json['km']),
      municipio: serializer.fromJson<String?>(json['municipio']),
      uf: serializer.fromJson<String?>(json['uf']),
      numeroGrv: serializer.fromJson<String?>(json['numeroGrv']),
      tipo: serializer.fromJson<String>(json['tipo']),
      motorDivergente: serializer.fromJson<bool>(json['motorDivergente']),
      chassiDivergente: serializer.fromJson<bool>(json['chassiDivergente']),
      cambioDivergente: serializer.fromJson<bool>(json['cambioDivergente']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'placa': serializer.toJson<String>(placa),
      'chassiVeiculo': serializer.toJson<String?>(chassiVeiculo),
      'chassiBin': serializer.toJson<String?>(chassiBin),
      'motorVeiculo': serializer.toJson<String?>(motorVeiculo),
      'motorBin': serializer.toJson<String?>(motorBin),
      'cambioVeiculo': serializer.toJson<String?>(cambioVeiculo),
      'cambioBin': serializer.toJson<String?>(cambioBin),
      'renavam': serializer.toJson<String?>(renavam),
      'marca': serializer.toJson<String?>(marca),
      'modelo': serializer.toJson<String?>(modelo),
      'anoFabricacao': serializer.toJson<int?>(anoFabricacao),
      'anoModelo': serializer.toJson<int?>(anoModelo),
      'cor': serializer.toJson<String?>(cor),
      'combustivel': serializer.toJson<String?>(combustivel),
      'km': serializer.toJson<int?>(km),
      'municipio': serializer.toJson<String?>(municipio),
      'uf': serializer.toJson<String?>(uf),
      'numeroGrv': serializer.toJson<String?>(numeroGrv),
      'tipo': serializer.toJson<String>(tipo),
      'motorDivergente': serializer.toJson<bool>(motorDivergente),
      'chassiDivergente': serializer.toJson<bool>(chassiDivergente),
      'cambioDivergente': serializer.toJson<bool>(cambioDivergente),
    };
  }

  Veiculo copyWith(
          {String? id,
          String? vistoriaId,
          String? placa,
          Value<String?> chassiVeiculo = const Value.absent(),
          Value<String?> chassiBin = const Value.absent(),
          Value<String?> motorVeiculo = const Value.absent(),
          Value<String?> motorBin = const Value.absent(),
          Value<String?> cambioVeiculo = const Value.absent(),
          Value<String?> cambioBin = const Value.absent(),
          Value<String?> renavam = const Value.absent(),
          Value<String?> marca = const Value.absent(),
          Value<String?> modelo = const Value.absent(),
          Value<int?> anoFabricacao = const Value.absent(),
          Value<int?> anoModelo = const Value.absent(),
          Value<String?> cor = const Value.absent(),
          Value<String?> combustivel = const Value.absent(),
          Value<int?> km = const Value.absent(),
          Value<String?> municipio = const Value.absent(),
          Value<String?> uf = const Value.absent(),
          Value<String?> numeroGrv = const Value.absent(),
          String? tipo,
          bool? motorDivergente,
          bool? chassiDivergente,
          bool? cambioDivergente}) =>
      Veiculo(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        placa: placa ?? this.placa,
        chassiVeiculo:
            chassiVeiculo.present ? chassiVeiculo.value : this.chassiVeiculo,
        chassiBin: chassiBin.present ? chassiBin.value : this.chassiBin,
        motorVeiculo:
            motorVeiculo.present ? motorVeiculo.value : this.motorVeiculo,
        motorBin: motorBin.present ? motorBin.value : this.motorBin,
        cambioVeiculo:
            cambioVeiculo.present ? cambioVeiculo.value : this.cambioVeiculo,
        cambioBin: cambioBin.present ? cambioBin.value : this.cambioBin,
        renavam: renavam.present ? renavam.value : this.renavam,
        marca: marca.present ? marca.value : this.marca,
        modelo: modelo.present ? modelo.value : this.modelo,
        anoFabricacao:
            anoFabricacao.present ? anoFabricacao.value : this.anoFabricacao,
        anoModelo: anoModelo.present ? anoModelo.value : this.anoModelo,
        cor: cor.present ? cor.value : this.cor,
        combustivel: combustivel.present ? combustivel.value : this.combustivel,
        km: km.present ? km.value : this.km,
        municipio: municipio.present ? municipio.value : this.municipio,
        uf: uf.present ? uf.value : this.uf,
        numeroGrv: numeroGrv.present ? numeroGrv.value : this.numeroGrv,
        tipo: tipo ?? this.tipo,
        motorDivergente: motorDivergente ?? this.motorDivergente,
        chassiDivergente: chassiDivergente ?? this.chassiDivergente,
        cambioDivergente: cambioDivergente ?? this.cambioDivergente,
      );
  Veiculo copyWithCompanion(VeiculosCompanion data) {
    return Veiculo(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      placa: data.placa.present ? data.placa.value : this.placa,
      chassiVeiculo: data.chassiVeiculo.present
          ? data.chassiVeiculo.value
          : this.chassiVeiculo,
      chassiBin: data.chassiBin.present ? data.chassiBin.value : this.chassiBin,
      motorVeiculo: data.motorVeiculo.present
          ? data.motorVeiculo.value
          : this.motorVeiculo,
      motorBin: data.motorBin.present ? data.motorBin.value : this.motorBin,
      cambioVeiculo: data.cambioVeiculo.present
          ? data.cambioVeiculo.value
          : this.cambioVeiculo,
      cambioBin: data.cambioBin.present ? data.cambioBin.value : this.cambioBin,
      renavam: data.renavam.present ? data.renavam.value : this.renavam,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      anoFabricacao: data.anoFabricacao.present
          ? data.anoFabricacao.value
          : this.anoFabricacao,
      anoModelo: data.anoModelo.present ? data.anoModelo.value : this.anoModelo,
      cor: data.cor.present ? data.cor.value : this.cor,
      combustivel:
          data.combustivel.present ? data.combustivel.value : this.combustivel,
      km: data.km.present ? data.km.value : this.km,
      municipio: data.municipio.present ? data.municipio.value : this.municipio,
      uf: data.uf.present ? data.uf.value : this.uf,
      numeroGrv: data.numeroGrv.present ? data.numeroGrv.value : this.numeroGrv,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      motorDivergente: data.motorDivergente.present
          ? data.motorDivergente.value
          : this.motorDivergente,
      chassiDivergente: data.chassiDivergente.present
          ? data.chassiDivergente.value
          : this.chassiDivergente,
      cambioDivergente: data.cambioDivergente.present
          ? data.cambioDivergente.value
          : this.cambioDivergente,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Veiculo(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('placa: $placa, ')
          ..write('chassiVeiculo: $chassiVeiculo, ')
          ..write('chassiBin: $chassiBin, ')
          ..write('motorVeiculo: $motorVeiculo, ')
          ..write('motorBin: $motorBin, ')
          ..write('cambioVeiculo: $cambioVeiculo, ')
          ..write('cambioBin: $cambioBin, ')
          ..write('renavam: $renavam, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anoFabricacao: $anoFabricacao, ')
          ..write('anoModelo: $anoModelo, ')
          ..write('cor: $cor, ')
          ..write('combustivel: $combustivel, ')
          ..write('km: $km, ')
          ..write('municipio: $municipio, ')
          ..write('uf: $uf, ')
          ..write('numeroGrv: $numeroGrv, ')
          ..write('tipo: $tipo, ')
          ..write('motorDivergente: $motorDivergente, ')
          ..write('chassiDivergente: $chassiDivergente, ')
          ..write('cambioDivergente: $cambioDivergente')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        vistoriaId,
        placa,
        chassiVeiculo,
        chassiBin,
        motorVeiculo,
        motorBin,
        cambioVeiculo,
        cambioBin,
        renavam,
        marca,
        modelo,
        anoFabricacao,
        anoModelo,
        cor,
        combustivel,
        km,
        municipio,
        uf,
        numeroGrv,
        tipo,
        motorDivergente,
        chassiDivergente,
        cambioDivergente
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Veiculo &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.placa == this.placa &&
          other.chassiVeiculo == this.chassiVeiculo &&
          other.chassiBin == this.chassiBin &&
          other.motorVeiculo == this.motorVeiculo &&
          other.motorBin == this.motorBin &&
          other.cambioVeiculo == this.cambioVeiculo &&
          other.cambioBin == this.cambioBin &&
          other.renavam == this.renavam &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.anoFabricacao == this.anoFabricacao &&
          other.anoModelo == this.anoModelo &&
          other.cor == this.cor &&
          other.combustivel == this.combustivel &&
          other.km == this.km &&
          other.municipio == this.municipio &&
          other.uf == this.uf &&
          other.numeroGrv == this.numeroGrv &&
          other.tipo == this.tipo &&
          other.motorDivergente == this.motorDivergente &&
          other.chassiDivergente == this.chassiDivergente &&
          other.cambioDivergente == this.cambioDivergente);
}

class VeiculosCompanion extends UpdateCompanion<Veiculo> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String> placa;
  final Value<String?> chassiVeiculo;
  final Value<String?> chassiBin;
  final Value<String?> motorVeiculo;
  final Value<String?> motorBin;
  final Value<String?> cambioVeiculo;
  final Value<String?> cambioBin;
  final Value<String?> renavam;
  final Value<String?> marca;
  final Value<String?> modelo;
  final Value<int?> anoFabricacao;
  final Value<int?> anoModelo;
  final Value<String?> cor;
  final Value<String?> combustivel;
  final Value<int?> km;
  final Value<String?> municipio;
  final Value<String?> uf;
  final Value<String?> numeroGrv;
  final Value<String> tipo;
  final Value<bool> motorDivergente;
  final Value<bool> chassiDivergente;
  final Value<bool> cambioDivergente;
  final Value<int> rowid;
  const VeiculosCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.placa = const Value.absent(),
    this.chassiVeiculo = const Value.absent(),
    this.chassiBin = const Value.absent(),
    this.motorVeiculo = const Value.absent(),
    this.motorBin = const Value.absent(),
    this.cambioVeiculo = const Value.absent(),
    this.cambioBin = const Value.absent(),
    this.renavam = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.anoFabricacao = const Value.absent(),
    this.anoModelo = const Value.absent(),
    this.cor = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.km = const Value.absent(),
    this.municipio = const Value.absent(),
    this.uf = const Value.absent(),
    this.numeroGrv = const Value.absent(),
    this.tipo = const Value.absent(),
    this.motorDivergente = const Value.absent(),
    this.chassiDivergente = const Value.absent(),
    this.cambioDivergente = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VeiculosCompanion.insert({
    required String id,
    required String vistoriaId,
    required String placa,
    this.chassiVeiculo = const Value.absent(),
    this.chassiBin = const Value.absent(),
    this.motorVeiculo = const Value.absent(),
    this.motorBin = const Value.absent(),
    this.cambioVeiculo = const Value.absent(),
    this.cambioBin = const Value.absent(),
    this.renavam = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.anoFabricacao = const Value.absent(),
    this.anoModelo = const Value.absent(),
    this.cor = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.km = const Value.absent(),
    this.municipio = const Value.absent(),
    this.uf = const Value.absent(),
    this.numeroGrv = const Value.absent(),
    this.tipo = const Value.absent(),
    this.motorDivergente = const Value.absent(),
    this.chassiDivergente = const Value.absent(),
    this.cambioDivergente = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        placa = Value(placa);
  static Insertable<Veiculo> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? placa,
    Expression<String>? chassiVeiculo,
    Expression<String>? chassiBin,
    Expression<String>? motorVeiculo,
    Expression<String>? motorBin,
    Expression<String>? cambioVeiculo,
    Expression<String>? cambioBin,
    Expression<String>? renavam,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<int>? anoFabricacao,
    Expression<int>? anoModelo,
    Expression<String>? cor,
    Expression<String>? combustivel,
    Expression<int>? km,
    Expression<String>? municipio,
    Expression<String>? uf,
    Expression<String>? numeroGrv,
    Expression<String>? tipo,
    Expression<bool>? motorDivergente,
    Expression<bool>? chassiDivergente,
    Expression<bool>? cambioDivergente,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (placa != null) 'placa': placa,
      if (chassiVeiculo != null) 'chassi_veiculo': chassiVeiculo,
      if (chassiBin != null) 'chassi_bin': chassiBin,
      if (motorVeiculo != null) 'motor_veiculo': motorVeiculo,
      if (motorBin != null) 'motor_bin': motorBin,
      if (cambioVeiculo != null) 'cambio_veiculo': cambioVeiculo,
      if (cambioBin != null) 'cambio_bin': cambioBin,
      if (renavam != null) 'renavam': renavam,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (anoFabricacao != null) 'ano_fabricacao': anoFabricacao,
      if (anoModelo != null) 'ano_modelo': anoModelo,
      if (cor != null) 'cor': cor,
      if (combustivel != null) 'combustivel': combustivel,
      if (km != null) 'km': km,
      if (municipio != null) 'municipio': municipio,
      if (uf != null) 'uf': uf,
      if (numeroGrv != null) 'numero_grv': numeroGrv,
      if (tipo != null) 'tipo': tipo,
      if (motorDivergente != null) 'motor_divergente': motorDivergente,
      if (chassiDivergente != null) 'chassi_divergente': chassiDivergente,
      if (cambioDivergente != null) 'cambio_divergente': cambioDivergente,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VeiculosCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String>? placa,
      Value<String?>? chassiVeiculo,
      Value<String?>? chassiBin,
      Value<String?>? motorVeiculo,
      Value<String?>? motorBin,
      Value<String?>? cambioVeiculo,
      Value<String?>? cambioBin,
      Value<String?>? renavam,
      Value<String?>? marca,
      Value<String?>? modelo,
      Value<int?>? anoFabricacao,
      Value<int?>? anoModelo,
      Value<String?>? cor,
      Value<String?>? combustivel,
      Value<int?>? km,
      Value<String?>? municipio,
      Value<String?>? uf,
      Value<String?>? numeroGrv,
      Value<String>? tipo,
      Value<bool>? motorDivergente,
      Value<bool>? chassiDivergente,
      Value<bool>? cambioDivergente,
      Value<int>? rowid}) {
    return VeiculosCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      placa: placa ?? this.placa,
      chassiVeiculo: chassiVeiculo ?? this.chassiVeiculo,
      chassiBin: chassiBin ?? this.chassiBin,
      motorVeiculo: motorVeiculo ?? this.motorVeiculo,
      motorBin: motorBin ?? this.motorBin,
      cambioVeiculo: cambioVeiculo ?? this.cambioVeiculo,
      cambioBin: cambioBin ?? this.cambioBin,
      renavam: renavam ?? this.renavam,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anoFabricacao: anoFabricacao ?? this.anoFabricacao,
      anoModelo: anoModelo ?? this.anoModelo,
      cor: cor ?? this.cor,
      combustivel: combustivel ?? this.combustivel,
      km: km ?? this.km,
      municipio: municipio ?? this.municipio,
      uf: uf ?? this.uf,
      numeroGrv: numeroGrv ?? this.numeroGrv,
      tipo: tipo ?? this.tipo,
      motorDivergente: motorDivergente ?? this.motorDivergente,
      chassiDivergente: chassiDivergente ?? this.chassiDivergente,
      cambioDivergente: cambioDivergente ?? this.cambioDivergente,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (placa.present) {
      map['placa'] = Variable<String>(placa.value);
    }
    if (chassiVeiculo.present) {
      map['chassi_veiculo'] = Variable<String>(chassiVeiculo.value);
    }
    if (chassiBin.present) {
      map['chassi_bin'] = Variable<String>(chassiBin.value);
    }
    if (motorVeiculo.present) {
      map['motor_veiculo'] = Variable<String>(motorVeiculo.value);
    }
    if (motorBin.present) {
      map['motor_bin'] = Variable<String>(motorBin.value);
    }
    if (cambioVeiculo.present) {
      map['cambio_veiculo'] = Variable<String>(cambioVeiculo.value);
    }
    if (cambioBin.present) {
      map['cambio_bin'] = Variable<String>(cambioBin.value);
    }
    if (renavam.present) {
      map['renavam'] = Variable<String>(renavam.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (anoFabricacao.present) {
      map['ano_fabricacao'] = Variable<int>(anoFabricacao.value);
    }
    if (anoModelo.present) {
      map['ano_modelo'] = Variable<int>(anoModelo.value);
    }
    if (cor.present) {
      map['cor'] = Variable<String>(cor.value);
    }
    if (combustivel.present) {
      map['combustivel'] = Variable<String>(combustivel.value);
    }
    if (km.present) {
      map['km'] = Variable<int>(km.value);
    }
    if (municipio.present) {
      map['municipio'] = Variable<String>(municipio.value);
    }
    if (uf.present) {
      map['uf'] = Variable<String>(uf.value);
    }
    if (numeroGrv.present) {
      map['numero_grv'] = Variable<String>(numeroGrv.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (motorDivergente.present) {
      map['motor_divergente'] = Variable<bool>(motorDivergente.value);
    }
    if (chassiDivergente.present) {
      map['chassi_divergente'] = Variable<bool>(chassiDivergente.value);
    }
    if (cambioDivergente.present) {
      map['cambio_divergente'] = Variable<bool>(cambioDivergente.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VeiculosCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('placa: $placa, ')
          ..write('chassiVeiculo: $chassiVeiculo, ')
          ..write('chassiBin: $chassiBin, ')
          ..write('motorVeiculo: $motorVeiculo, ')
          ..write('motorBin: $motorBin, ')
          ..write('cambioVeiculo: $cambioVeiculo, ')
          ..write('cambioBin: $cambioBin, ')
          ..write('renavam: $renavam, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anoFabricacao: $anoFabricacao, ')
          ..write('anoModelo: $anoModelo, ')
          ..write('cor: $cor, ')
          ..write('combustivel: $combustivel, ')
          ..write('km: $km, ')
          ..write('municipio: $municipio, ')
          ..write('uf: $uf, ')
          ..write('numeroGrv: $numeroGrv, ')
          ..write('tipo: $tipo, ')
          ..write('motorDivergente: $motorDivergente, ')
          ..write('chassiDivergente: $chassiDivergente, ')
          ..write('cambioDivergente: $cambioDivergente, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItensVistoriaTable extends ItensVistoria
    with TableInfo<$ItensVistoriaTable, ItensVistoriaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensVistoriaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _categoriaMeta =
      const VerificationMeta('categoria');
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
      'categoria', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendente'));
  static const VerificationMeta _observacaoMeta =
      const VerificationMeta('observacao');
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
      'observacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _etapaMeta = const VerificationMeta('etapa');
  @override
  late final GeneratedColumn<String> etapa = GeneratedColumn<String>(
      'etapa', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
      'ordem', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, vistoriaId, categoria, nome, status, observacao, etapa, ordem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_vistoria';
  @override
  VerificationContext validateIntegrity(Insertable<ItensVistoriaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(_categoriaMeta,
          categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta));
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('observacao')) {
      context.handle(
          _observacaoMeta,
          observacao.isAcceptableOrUnknown(
              data['observacao']!, _observacaoMeta));
    }
    if (data.containsKey('etapa')) {
      context.handle(
          _etapaMeta, etapa.isAcceptableOrUnknown(data['etapa']!, _etapaMeta));
    }
    if (data.containsKey('ordem')) {
      context.handle(
          _ordemMeta, ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensVistoriaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensVistoriaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      categoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoria'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      observacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacao']),
      etapa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etapa']),
      ordem: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordem'])!,
    );
  }

  @override
  $ItensVistoriaTable createAlias(String alias) {
    return $ItensVistoriaTable(attachedDatabase, alias);
  }
}

class ItensVistoriaData extends DataClass
    implements Insertable<ItensVistoriaData> {
  final String id;
  final String vistoriaId;
  final String categoria;
  final String nome;
  final String status;
  final String? observacao;
  final String? etapa;
  final int ordem;
  const ItensVistoriaData(
      {required this.id,
      required this.vistoriaId,
      required this.categoria,
      required this.nome,
      required this.status,
      this.observacao,
      this.etapa,
      required this.ordem});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    map['categoria'] = Variable<String>(categoria);
    map['nome'] = Variable<String>(nome);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    if (!nullToAbsent || etapa != null) {
      map['etapa'] = Variable<String>(etapa);
    }
    map['ordem'] = Variable<int>(ordem);
    return map;
  }

  ItensVistoriaCompanion toCompanion(bool nullToAbsent) {
    return ItensVistoriaCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      categoria: Value(categoria),
      nome: Value(nome),
      status: Value(status),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      etapa:
          etapa == null && nullToAbsent ? const Value.absent() : Value(etapa),
      ordem: Value(ordem),
    );
  }

  factory ItensVistoriaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensVistoriaData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      categoria: serializer.fromJson<String>(json['categoria']),
      nome: serializer.fromJson<String>(json['nome']),
      status: serializer.fromJson<String>(json['status']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      etapa: serializer.fromJson<String?>(json['etapa']),
      ordem: serializer.fromJson<int>(json['ordem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'categoria': serializer.toJson<String>(categoria),
      'nome': serializer.toJson<String>(nome),
      'status': serializer.toJson<String>(status),
      'observacao': serializer.toJson<String?>(observacao),
      'etapa': serializer.toJson<String?>(etapa),
      'ordem': serializer.toJson<int>(ordem),
    };
  }

  ItensVistoriaData copyWith(
          {String? id,
          String? vistoriaId,
          String? categoria,
          String? nome,
          String? status,
          Value<String?> observacao = const Value.absent(),
          Value<String?> etapa = const Value.absent(),
          int? ordem}) =>
      ItensVistoriaData(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        categoria: categoria ?? this.categoria,
        nome: nome ?? this.nome,
        status: status ?? this.status,
        observacao: observacao.present ? observacao.value : this.observacao,
        etapa: etapa.present ? etapa.value : this.etapa,
        ordem: ordem ?? this.ordem,
      );
  ItensVistoriaData copyWithCompanion(ItensVistoriaCompanion data) {
    return ItensVistoriaData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      nome: data.nome.present ? data.nome.value : this.nome,
      status: data.status.present ? data.status.value : this.status,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
      etapa: data.etapa.present ? data.etapa.value : this.etapa,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensVistoriaData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('categoria: $categoria, ')
          ..write('nome: $nome, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('etapa: $etapa, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, vistoriaId, categoria, nome, status, observacao, etapa, ordem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensVistoriaData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.categoria == this.categoria &&
          other.nome == this.nome &&
          other.status == this.status &&
          other.observacao == this.observacao &&
          other.etapa == this.etapa &&
          other.ordem == this.ordem);
}

class ItensVistoriaCompanion extends UpdateCompanion<ItensVistoriaData> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String> categoria;
  final Value<String> nome;
  final Value<String> status;
  final Value<String?> observacao;
  final Value<String?> etapa;
  final Value<int> ordem;
  final Value<int> rowid;
  const ItensVistoriaCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.categoria = const Value.absent(),
    this.nome = const Value.absent(),
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.etapa = const Value.absent(),
    this.ordem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItensVistoriaCompanion.insert({
    required String id,
    required String vistoriaId,
    required String categoria,
    required String nome,
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.etapa = const Value.absent(),
    this.ordem = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        categoria = Value(categoria),
        nome = Value(nome);
  static Insertable<ItensVistoriaData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? categoria,
    Expression<String>? nome,
    Expression<String>? status,
    Expression<String>? observacao,
    Expression<String>? etapa,
    Expression<int>? ordem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (categoria != null) 'categoria': categoria,
      if (nome != null) 'nome': nome,
      if (status != null) 'status': status,
      if (observacao != null) 'observacao': observacao,
      if (etapa != null) 'etapa': etapa,
      if (ordem != null) 'ordem': ordem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItensVistoriaCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String>? categoria,
      Value<String>? nome,
      Value<String>? status,
      Value<String?>? observacao,
      Value<String?>? etapa,
      Value<int>? ordem,
      Value<int>? rowid}) {
    return ItensVistoriaCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      categoria: categoria ?? this.categoria,
      nome: nome ?? this.nome,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      etapa: etapa ?? this.etapa,
      ordem: ordem ?? this.ordem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (etapa.present) {
      map['etapa'] = Variable<String>(etapa.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensVistoriaCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('categoria: $categoria, ')
          ..write('nome: $nome, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('etapa: $etapa, ')
          ..write('ordem: $ordem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FotosVistoriaTable extends FotosVistoria
    with TableInfo<$FotosVistoriaTable, FotosVistoriaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FotosVistoriaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _legendaMeta =
      const VerificationMeta('legenda');
  @override
  late final GeneratedColumn<String> legenda = GeneratedColumn<String>(
      'legenda', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _etapaMeta = const VerificationMeta('etapa');
  @override
  late final GeneratedColumn<String> etapa = GeneratedColumn<String>(
      'etapa', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusFotoMeta =
      const VerificationMeta('statusFoto');
  @override
  late final GeneratedColumn<String> statusFoto = GeneratedColumn<String>(
      'status_foto', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacaoMeta =
      const VerificationMeta('observacao');
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
      'observacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _obrigatoriaMeta =
      const VerificationMeta('obrigatoria');
  @override
  late final GeneratedColumn<bool> obrigatoria = GeneratedColumn<bool>(
      'obrigatoria', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("obrigatoria" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pathLocalMeta =
      const VerificationMeta('pathLocal');
  @override
  late final GeneratedColumn<String> pathLocal = GeneratedColumn<String>(
      'path_local', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlSupabaseMeta =
      const VerificationMeta('urlSupabase');
  @override
  late final GeneratedColumn<String> urlSupabase = GeneratedColumn<String>(
      'url_supabase', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
      'ordem', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vistoriaId,
        itemId,
        legenda,
        etapa,
        statusFoto,
        observacao,
        obrigatoria,
        pathLocal,
        urlSupabase,
        storagePath,
        ordem,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fotos_vistoria';
  @override
  VerificationContext validateIntegrity(Insertable<FotosVistoriaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    }
    if (data.containsKey('legenda')) {
      context.handle(_legendaMeta,
          legenda.isAcceptableOrUnknown(data['legenda']!, _legendaMeta));
    } else if (isInserting) {
      context.missing(_legendaMeta);
    }
    if (data.containsKey('etapa')) {
      context.handle(
          _etapaMeta, etapa.isAcceptableOrUnknown(data['etapa']!, _etapaMeta));
    }
    if (data.containsKey('status_foto')) {
      context.handle(
          _statusFotoMeta,
          statusFoto.isAcceptableOrUnknown(
              data['status_foto']!, _statusFotoMeta));
    }
    if (data.containsKey('observacao')) {
      context.handle(
          _observacaoMeta,
          observacao.isAcceptableOrUnknown(
              data['observacao']!, _observacaoMeta));
    }
    if (data.containsKey('obrigatoria')) {
      context.handle(
          _obrigatoriaMeta,
          obrigatoria.isAcceptableOrUnknown(
              data['obrigatoria']!, _obrigatoriaMeta));
    }
    if (data.containsKey('path_local')) {
      context.handle(_pathLocalMeta,
          pathLocal.isAcceptableOrUnknown(data['path_local']!, _pathLocalMeta));
    }
    if (data.containsKey('url_supabase')) {
      context.handle(
          _urlSupabaseMeta,
          urlSupabase.isAcceptableOrUnknown(
              data['url_supabase']!, _urlSupabaseMeta));
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    }
    if (data.containsKey('ordem')) {
      context.handle(
          _ordemMeta, ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FotosVistoriaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FotosVistoriaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id']),
      legenda: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}legenda'])!,
      etapa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}etapa']),
      statusFoto: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status_foto']),
      observacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacao']),
      obrigatoria: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}obrigatoria'])!,
      pathLocal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path_local']),
      urlSupabase: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url_supabase']),
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path']),
      ordem: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordem'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FotosVistoriaTable createAlias(String alias) {
    return $FotosVistoriaTable(attachedDatabase, alias);
  }
}

class FotosVistoriaData extends DataClass
    implements Insertable<FotosVistoriaData> {
  final String id;
  final String vistoriaId;
  final String? itemId;
  final String legenda;
  final String? etapa;
  final String? statusFoto;
  final String? observacao;
  final bool obrigatoria;
  final String? pathLocal;
  final String? urlSupabase;
  final String? storagePath;
  final int ordem;
  final DateTime createdAt;
  const FotosVistoriaData(
      {required this.id,
      required this.vistoriaId,
      this.itemId,
      required this.legenda,
      this.etapa,
      this.statusFoto,
      this.observacao,
      required this.obrigatoria,
      this.pathLocal,
      this.urlSupabase,
      this.storagePath,
      required this.ordem,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['legenda'] = Variable<String>(legenda);
    if (!nullToAbsent || etapa != null) {
      map['etapa'] = Variable<String>(etapa);
    }
    if (!nullToAbsent || statusFoto != null) {
      map['status_foto'] = Variable<String>(statusFoto);
    }
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    map['obrigatoria'] = Variable<bool>(obrigatoria);
    if (!nullToAbsent || pathLocal != null) {
      map['path_local'] = Variable<String>(pathLocal);
    }
    if (!nullToAbsent || urlSupabase != null) {
      map['url_supabase'] = Variable<String>(urlSupabase);
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    map['ordem'] = Variable<int>(ordem);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FotosVistoriaCompanion toCompanion(bool nullToAbsent) {
    return FotosVistoriaCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      itemId:
          itemId == null && nullToAbsent ? const Value.absent() : Value(itemId),
      legenda: Value(legenda),
      etapa:
          etapa == null && nullToAbsent ? const Value.absent() : Value(etapa),
      statusFoto: statusFoto == null && nullToAbsent
          ? const Value.absent()
          : Value(statusFoto),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      obrigatoria: Value(obrigatoria),
      pathLocal: pathLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(pathLocal),
      urlSupabase: urlSupabase == null && nullToAbsent
          ? const Value.absent()
          : Value(urlSupabase),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
      ordem: Value(ordem),
      createdAt: Value(createdAt),
    );
  }

  factory FotosVistoriaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FotosVistoriaData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      legenda: serializer.fromJson<String>(json['legenda']),
      etapa: serializer.fromJson<String?>(json['etapa']),
      statusFoto: serializer.fromJson<String?>(json['statusFoto']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      obrigatoria: serializer.fromJson<bool>(json['obrigatoria']),
      pathLocal: serializer.fromJson<String?>(json['pathLocal']),
      urlSupabase: serializer.fromJson<String?>(json['urlSupabase']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      ordem: serializer.fromJson<int>(json['ordem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'itemId': serializer.toJson<String?>(itemId),
      'legenda': serializer.toJson<String>(legenda),
      'etapa': serializer.toJson<String?>(etapa),
      'statusFoto': serializer.toJson<String?>(statusFoto),
      'observacao': serializer.toJson<String?>(observacao),
      'obrigatoria': serializer.toJson<bool>(obrigatoria),
      'pathLocal': serializer.toJson<String?>(pathLocal),
      'urlSupabase': serializer.toJson<String?>(urlSupabase),
      'storagePath': serializer.toJson<String?>(storagePath),
      'ordem': serializer.toJson<int>(ordem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FotosVistoriaData copyWith(
          {String? id,
          String? vistoriaId,
          Value<String?> itemId = const Value.absent(),
          String? legenda,
          Value<String?> etapa = const Value.absent(),
          Value<String?> statusFoto = const Value.absent(),
          Value<String?> observacao = const Value.absent(),
          bool? obrigatoria,
          Value<String?> pathLocal = const Value.absent(),
          Value<String?> urlSupabase = const Value.absent(),
          Value<String?> storagePath = const Value.absent(),
          int? ordem,
          DateTime? createdAt}) =>
      FotosVistoriaData(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        itemId: itemId.present ? itemId.value : this.itemId,
        legenda: legenda ?? this.legenda,
        etapa: etapa.present ? etapa.value : this.etapa,
        statusFoto: statusFoto.present ? statusFoto.value : this.statusFoto,
        observacao: observacao.present ? observacao.value : this.observacao,
        obrigatoria: obrigatoria ?? this.obrigatoria,
        pathLocal: pathLocal.present ? pathLocal.value : this.pathLocal,
        urlSupabase: urlSupabase.present ? urlSupabase.value : this.urlSupabase,
        storagePath: storagePath.present ? storagePath.value : this.storagePath,
        ordem: ordem ?? this.ordem,
        createdAt: createdAt ?? this.createdAt,
      );
  FotosVistoriaData copyWithCompanion(FotosVistoriaCompanion data) {
    return FotosVistoriaData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      legenda: data.legenda.present ? data.legenda.value : this.legenda,
      etapa: data.etapa.present ? data.etapa.value : this.etapa,
      statusFoto:
          data.statusFoto.present ? data.statusFoto.value : this.statusFoto,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
      obrigatoria:
          data.obrigatoria.present ? data.obrigatoria.value : this.obrigatoria,
      pathLocal: data.pathLocal.present ? data.pathLocal.value : this.pathLocal,
      urlSupabase:
          data.urlSupabase.present ? data.urlSupabase.value : this.urlSupabase,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FotosVistoriaData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('itemId: $itemId, ')
          ..write('legenda: $legenda, ')
          ..write('etapa: $etapa, ')
          ..write('statusFoto: $statusFoto, ')
          ..write('observacao: $observacao, ')
          ..write('obrigatoria: $obrigatoria, ')
          ..write('pathLocal: $pathLocal, ')
          ..write('urlSupabase: $urlSupabase, ')
          ..write('storagePath: $storagePath, ')
          ..write('ordem: $ordem, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      vistoriaId,
      itemId,
      legenda,
      etapa,
      statusFoto,
      observacao,
      obrigatoria,
      pathLocal,
      urlSupabase,
      storagePath,
      ordem,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FotosVistoriaData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.itemId == this.itemId &&
          other.legenda == this.legenda &&
          other.etapa == this.etapa &&
          other.statusFoto == this.statusFoto &&
          other.observacao == this.observacao &&
          other.obrigatoria == this.obrigatoria &&
          other.pathLocal == this.pathLocal &&
          other.urlSupabase == this.urlSupabase &&
          other.storagePath == this.storagePath &&
          other.ordem == this.ordem &&
          other.createdAt == this.createdAt);
}

class FotosVistoriaCompanion extends UpdateCompanion<FotosVistoriaData> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String?> itemId;
  final Value<String> legenda;
  final Value<String?> etapa;
  final Value<String?> statusFoto;
  final Value<String?> observacao;
  final Value<bool> obrigatoria;
  final Value<String?> pathLocal;
  final Value<String?> urlSupabase;
  final Value<String?> storagePath;
  final Value<int> ordem;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FotosVistoriaCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.legenda = const Value.absent(),
    this.etapa = const Value.absent(),
    this.statusFoto = const Value.absent(),
    this.observacao = const Value.absent(),
    this.obrigatoria = const Value.absent(),
    this.pathLocal = const Value.absent(),
    this.urlSupabase = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.ordem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FotosVistoriaCompanion.insert({
    required String id,
    required String vistoriaId,
    this.itemId = const Value.absent(),
    required String legenda,
    this.etapa = const Value.absent(),
    this.statusFoto = const Value.absent(),
    this.observacao = const Value.absent(),
    this.obrigatoria = const Value.absent(),
    this.pathLocal = const Value.absent(),
    this.urlSupabase = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.ordem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        legenda = Value(legenda);
  static Insertable<FotosVistoriaData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? itemId,
    Expression<String>? legenda,
    Expression<String>? etapa,
    Expression<String>? statusFoto,
    Expression<String>? observacao,
    Expression<bool>? obrigatoria,
    Expression<String>? pathLocal,
    Expression<String>? urlSupabase,
    Expression<String>? storagePath,
    Expression<int>? ordem,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (itemId != null) 'item_id': itemId,
      if (legenda != null) 'legenda': legenda,
      if (etapa != null) 'etapa': etapa,
      if (statusFoto != null) 'status_foto': statusFoto,
      if (observacao != null) 'observacao': observacao,
      if (obrigatoria != null) 'obrigatoria': obrigatoria,
      if (pathLocal != null) 'path_local': pathLocal,
      if (urlSupabase != null) 'url_supabase': urlSupabase,
      if (storagePath != null) 'storage_path': storagePath,
      if (ordem != null) 'ordem': ordem,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FotosVistoriaCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String?>? itemId,
      Value<String>? legenda,
      Value<String?>? etapa,
      Value<String?>? statusFoto,
      Value<String?>? observacao,
      Value<bool>? obrigatoria,
      Value<String?>? pathLocal,
      Value<String?>? urlSupabase,
      Value<String?>? storagePath,
      Value<int>? ordem,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FotosVistoriaCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      itemId: itemId ?? this.itemId,
      legenda: legenda ?? this.legenda,
      etapa: etapa ?? this.etapa,
      statusFoto: statusFoto ?? this.statusFoto,
      observacao: observacao ?? this.observacao,
      obrigatoria: obrigatoria ?? this.obrigatoria,
      pathLocal: pathLocal ?? this.pathLocal,
      urlSupabase: urlSupabase ?? this.urlSupabase,
      storagePath: storagePath ?? this.storagePath,
      ordem: ordem ?? this.ordem,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (legenda.present) {
      map['legenda'] = Variable<String>(legenda.value);
    }
    if (etapa.present) {
      map['etapa'] = Variable<String>(etapa.value);
    }
    if (statusFoto.present) {
      map['status_foto'] = Variable<String>(statusFoto.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (obrigatoria.present) {
      map['obrigatoria'] = Variable<bool>(obrigatoria.value);
    }
    if (pathLocal.present) {
      map['path_local'] = Variable<String>(pathLocal.value);
    }
    if (urlSupabase.present) {
      map['url_supabase'] = Variable<String>(urlSupabase.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FotosVistoriaCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('itemId: $itemId, ')
          ..write('legenda: $legenda, ')
          ..write('etapa: $etapa, ')
          ..write('statusFoto: $statusFoto, ')
          ..write('observacao: $observacao, ')
          ..write('obrigatoria: $obrigatoria, ')
          ..write('pathLocal: $pathLocal, ')
          ..write('urlSupabase: $urlSupabase, ')
          ..write('storagePath: $storagePath, ')
          ..write('ordem: $ordem, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItensPinturaTable extends ItensPintura
    with TableInfo<$ItensPinturaTable, ItensPinturaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensPinturaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _pecaMeta = const VerificationMeta('peca');
  @override
  late final GeneratedColumn<String> peca = GeneratedColumn<String>(
      'peca', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('original'));
  static const VerificationMeta _espessuraMicraMeta =
      const VerificationMeta('espessuraMicra');
  @override
  late final GeneratedColumn<int> espessuraMicra = GeneratedColumn<int>(
      'espessura_micra', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _observacaoMeta =
      const VerificationMeta('observacao');
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
      'observacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fotoUrlMeta =
      const VerificationMeta('fotoUrl');
  @override
  late final GeneratedColumn<String> fotoUrl = GeneratedColumn<String>(
      'foto_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, vistoriaId, peca, status, espessuraMicra, observacao, fotoUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_pintura';
  @override
  VerificationContext validateIntegrity(Insertable<ItensPinturaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('peca')) {
      context.handle(
          _pecaMeta, peca.isAcceptableOrUnknown(data['peca']!, _pecaMeta));
    } else if (isInserting) {
      context.missing(_pecaMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('espessura_micra')) {
      context.handle(
          _espessuraMicraMeta,
          espessuraMicra.isAcceptableOrUnknown(
              data['espessura_micra']!, _espessuraMicraMeta));
    }
    if (data.containsKey('observacao')) {
      context.handle(
          _observacaoMeta,
          observacao.isAcceptableOrUnknown(
              data['observacao']!, _observacaoMeta));
    }
    if (data.containsKey('foto_url')) {
      context.handle(_fotoUrlMeta,
          fotoUrl.isAcceptableOrUnknown(data['foto_url']!, _fotoUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensPinturaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensPinturaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      peca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peca'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      espessuraMicra: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}espessura_micra']),
      observacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacao']),
      fotoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_url']),
    );
  }

  @override
  $ItensPinturaTable createAlias(String alias) {
    return $ItensPinturaTable(attachedDatabase, alias);
  }
}

class ItensPinturaData extends DataClass
    implements Insertable<ItensPinturaData> {
  final String id;
  final String vistoriaId;
  final String peca;
  final String status;
  final int? espessuraMicra;
  final String? observacao;
  final String? fotoUrl;
  const ItensPinturaData(
      {required this.id,
      required this.vistoriaId,
      required this.peca,
      required this.status,
      this.espessuraMicra,
      this.observacao,
      this.fotoUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    map['peca'] = Variable<String>(peca);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || espessuraMicra != null) {
      map['espessura_micra'] = Variable<int>(espessuraMicra);
    }
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    if (!nullToAbsent || fotoUrl != null) {
      map['foto_url'] = Variable<String>(fotoUrl);
    }
    return map;
  }

  ItensPinturaCompanion toCompanion(bool nullToAbsent) {
    return ItensPinturaCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      peca: Value(peca),
      status: Value(status),
      espessuraMicra: espessuraMicra == null && nullToAbsent
          ? const Value.absent()
          : Value(espessuraMicra),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      fotoUrl: fotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoUrl),
    );
  }

  factory ItensPinturaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensPinturaData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      peca: serializer.fromJson<String>(json['peca']),
      status: serializer.fromJson<String>(json['status']),
      espessuraMicra: serializer.fromJson<int?>(json['espessuraMicra']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      fotoUrl: serializer.fromJson<String?>(json['fotoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'peca': serializer.toJson<String>(peca),
      'status': serializer.toJson<String>(status),
      'espessuraMicra': serializer.toJson<int?>(espessuraMicra),
      'observacao': serializer.toJson<String?>(observacao),
      'fotoUrl': serializer.toJson<String?>(fotoUrl),
    };
  }

  ItensPinturaData copyWith(
          {String? id,
          String? vistoriaId,
          String? peca,
          String? status,
          Value<int?> espessuraMicra = const Value.absent(),
          Value<String?> observacao = const Value.absent(),
          Value<String?> fotoUrl = const Value.absent()}) =>
      ItensPinturaData(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        peca: peca ?? this.peca,
        status: status ?? this.status,
        espessuraMicra:
            espessuraMicra.present ? espessuraMicra.value : this.espessuraMicra,
        observacao: observacao.present ? observacao.value : this.observacao,
        fotoUrl: fotoUrl.present ? fotoUrl.value : this.fotoUrl,
      );
  ItensPinturaData copyWithCompanion(ItensPinturaCompanion data) {
    return ItensPinturaData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      peca: data.peca.present ? data.peca.value : this.peca,
      status: data.status.present ? data.status.value : this.status,
      espessuraMicra: data.espessuraMicra.present
          ? data.espessuraMicra.value
          : this.espessuraMicra,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
      fotoUrl: data.fotoUrl.present ? data.fotoUrl.value : this.fotoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensPinturaData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('peca: $peca, ')
          ..write('status: $status, ')
          ..write('espessuraMicra: $espessuraMicra, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, vistoriaId, peca, status, espessuraMicra, observacao, fotoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensPinturaData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.peca == this.peca &&
          other.status == this.status &&
          other.espessuraMicra == this.espessuraMicra &&
          other.observacao == this.observacao &&
          other.fotoUrl == this.fotoUrl);
}

class ItensPinturaCompanion extends UpdateCompanion<ItensPinturaData> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String> peca;
  final Value<String> status;
  final Value<int?> espessuraMicra;
  final Value<String?> observacao;
  final Value<String?> fotoUrl;
  final Value<int> rowid;
  const ItensPinturaCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.peca = const Value.absent(),
    this.status = const Value.absent(),
    this.espessuraMicra = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItensPinturaCompanion.insert({
    required String id,
    required String vistoriaId,
    required String peca,
    this.status = const Value.absent(),
    this.espessuraMicra = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        peca = Value(peca);
  static Insertable<ItensPinturaData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? peca,
    Expression<String>? status,
    Expression<int>? espessuraMicra,
    Expression<String>? observacao,
    Expression<String>? fotoUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (peca != null) 'peca': peca,
      if (status != null) 'status': status,
      if (espessuraMicra != null) 'espessura_micra': espessuraMicra,
      if (observacao != null) 'observacao': observacao,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItensPinturaCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String>? peca,
      Value<String>? status,
      Value<int?>? espessuraMicra,
      Value<String?>? observacao,
      Value<String?>? fotoUrl,
      Value<int>? rowid}) {
    return ItensPinturaCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      peca: peca ?? this.peca,
      status: status ?? this.status,
      espessuraMicra: espessuraMicra ?? this.espessuraMicra,
      observacao: observacao ?? this.observacao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (peca.present) {
      map['peca'] = Variable<String>(peca.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (espessuraMicra.present) {
      map['espessura_micra'] = Variable<int>(espessuraMicra.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (fotoUrl.present) {
      map['foto_url'] = Variable<String>(fotoUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensPinturaCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('peca: $peca, ')
          ..write('status: $status, ')
          ..write('espessuraMicra: $espessuraMicra, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItensEstruturaTable extends ItensEstrutura
    with TableInfo<$ItensEstruturaTable, ItensEstruturaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensEstruturaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _pecaMeta = const VerificationMeta('peca');
  @override
  late final GeneratedColumn<String> peca = GeneratedColumn<String>(
      'peca', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sem_reparo'));
  static const VerificationMeta _observacaoMeta =
      const VerificationMeta('observacao');
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
      'observacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fotoUrlMeta =
      const VerificationMeta('fotoUrl');
  @override
  late final GeneratedColumn<String> fotoUrl = GeneratedColumn<String>(
      'foto_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, vistoriaId, peca, status, observacao, fotoUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_estrutura';
  @override
  VerificationContext validateIntegrity(Insertable<ItensEstruturaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('peca')) {
      context.handle(
          _pecaMeta, peca.isAcceptableOrUnknown(data['peca']!, _pecaMeta));
    } else if (isInserting) {
      context.missing(_pecaMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('observacao')) {
      context.handle(
          _observacaoMeta,
          observacao.isAcceptableOrUnknown(
              data['observacao']!, _observacaoMeta));
    }
    if (data.containsKey('foto_url')) {
      context.handle(_fotoUrlMeta,
          fotoUrl.isAcceptableOrUnknown(data['foto_url']!, _fotoUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensEstruturaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensEstruturaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      peca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peca'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      observacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacao']),
      fotoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_url']),
    );
  }

  @override
  $ItensEstruturaTable createAlias(String alias) {
    return $ItensEstruturaTable(attachedDatabase, alias);
  }
}

class ItensEstruturaData extends DataClass
    implements Insertable<ItensEstruturaData> {
  final String id;
  final String vistoriaId;
  final String peca;
  final String status;
  final String? observacao;
  final String? fotoUrl;
  const ItensEstruturaData(
      {required this.id,
      required this.vistoriaId,
      required this.peca,
      required this.status,
      this.observacao,
      this.fotoUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    map['peca'] = Variable<String>(peca);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    if (!nullToAbsent || fotoUrl != null) {
      map['foto_url'] = Variable<String>(fotoUrl);
    }
    return map;
  }

  ItensEstruturaCompanion toCompanion(bool nullToAbsent) {
    return ItensEstruturaCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      peca: Value(peca),
      status: Value(status),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      fotoUrl: fotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoUrl),
    );
  }

  factory ItensEstruturaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensEstruturaData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      peca: serializer.fromJson<String>(json['peca']),
      status: serializer.fromJson<String>(json['status']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      fotoUrl: serializer.fromJson<String?>(json['fotoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'peca': serializer.toJson<String>(peca),
      'status': serializer.toJson<String>(status),
      'observacao': serializer.toJson<String?>(observacao),
      'fotoUrl': serializer.toJson<String?>(fotoUrl),
    };
  }

  ItensEstruturaData copyWith(
          {String? id,
          String? vistoriaId,
          String? peca,
          String? status,
          Value<String?> observacao = const Value.absent(),
          Value<String?> fotoUrl = const Value.absent()}) =>
      ItensEstruturaData(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        peca: peca ?? this.peca,
        status: status ?? this.status,
        observacao: observacao.present ? observacao.value : this.observacao,
        fotoUrl: fotoUrl.present ? fotoUrl.value : this.fotoUrl,
      );
  ItensEstruturaData copyWithCompanion(ItensEstruturaCompanion data) {
    return ItensEstruturaData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      peca: data.peca.present ? data.peca.value : this.peca,
      status: data.status.present ? data.status.value : this.status,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
      fotoUrl: data.fotoUrl.present ? data.fotoUrl.value : this.fotoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensEstruturaData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('peca: $peca, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vistoriaId, peca, status, observacao, fotoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensEstruturaData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.peca == this.peca &&
          other.status == this.status &&
          other.observacao == this.observacao &&
          other.fotoUrl == this.fotoUrl);
}

class ItensEstruturaCompanion extends UpdateCompanion<ItensEstruturaData> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String> peca;
  final Value<String> status;
  final Value<String?> observacao;
  final Value<String?> fotoUrl;
  final Value<int> rowid;
  const ItensEstruturaCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.peca = const Value.absent(),
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItensEstruturaCompanion.insert({
    required String id,
    required String vistoriaId,
    required String peca,
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        peca = Value(peca);
  static Insertable<ItensEstruturaData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? peca,
    Expression<String>? status,
    Expression<String>? observacao,
    Expression<String>? fotoUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (peca != null) 'peca': peca,
      if (status != null) 'status': status,
      if (observacao != null) 'observacao': observacao,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItensEstruturaCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String>? peca,
      Value<String>? status,
      Value<String?>? observacao,
      Value<String?>? fotoUrl,
      Value<int>? rowid}) {
    return ItensEstruturaCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      peca: peca ?? this.peca,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (peca.present) {
      map['peca'] = Variable<String>(peca.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (fotoUrl.present) {
      map['foto_url'] = Variable<String>(fotoUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensEstruturaCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('peca: $peca, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VidrosVistoriaTable extends VidrosVistoria
    with TableInfo<$VidrosVistoriaTable, VidrosVistoriaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VidrosVistoriaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _posicaoMeta =
      const VerificationMeta('posicao');
  @override
  late final GeneratedColumn<String> posicao = GeneratedColumn<String>(
      'posicao', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codigoEncontradoMeta =
      const VerificationMeta('codigoEncontrado');
  @override
  late final GeneratedColumn<String> codigoEncontrado = GeneratedColumn<String>(
      'codigo_encontrado', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('nao_analisado'));
  static const VerificationMeta _observacaoMeta =
      const VerificationMeta('observacao');
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
      'observacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fotoUrlMeta =
      const VerificationMeta('fotoUrl');
  @override
  late final GeneratedColumn<String> fotoUrl = GeneratedColumn<String>(
      'foto_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, vistoriaId, posicao, codigoEncontrado, status, observacao, fotoUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vidros_vistoria';
  @override
  VerificationContext validateIntegrity(Insertable<VidrosVistoriaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    } else if (isInserting) {
      context.missing(_vistoriaIdMeta);
    }
    if (data.containsKey('posicao')) {
      context.handle(_posicaoMeta,
          posicao.isAcceptableOrUnknown(data['posicao']!, _posicaoMeta));
    } else if (isInserting) {
      context.missing(_posicaoMeta);
    }
    if (data.containsKey('codigo_encontrado')) {
      context.handle(
          _codigoEncontradoMeta,
          codigoEncontrado.isAcceptableOrUnknown(
              data['codigo_encontrado']!, _codigoEncontradoMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('observacao')) {
      context.handle(
          _observacaoMeta,
          observacao.isAcceptableOrUnknown(
              data['observacao']!, _observacaoMeta));
    }
    if (data.containsKey('foto_url')) {
      context.handle(_fotoUrlMeta,
          fotoUrl.isAcceptableOrUnknown(data['foto_url']!, _fotoUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VidrosVistoriaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VidrosVistoriaData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id'])!,
      posicao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}posicao'])!,
      codigoEncontrado: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}codigo_encontrado']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      observacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacao']),
      fotoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_url']),
    );
  }

  @override
  $VidrosVistoriaTable createAlias(String alias) {
    return $VidrosVistoriaTable(attachedDatabase, alias);
  }
}

class VidrosVistoriaData extends DataClass
    implements Insertable<VidrosVistoriaData> {
  final String id;
  final String vistoriaId;
  final String posicao;
  final String? codigoEncontrado;
  final String status;
  final String? observacao;
  final String? fotoUrl;
  const VidrosVistoriaData(
      {required this.id,
      required this.vistoriaId,
      required this.posicao,
      this.codigoEncontrado,
      required this.status,
      this.observacao,
      this.fotoUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vistoria_id'] = Variable<String>(vistoriaId);
    map['posicao'] = Variable<String>(posicao);
    if (!nullToAbsent || codigoEncontrado != null) {
      map['codigo_encontrado'] = Variable<String>(codigoEncontrado);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    if (!nullToAbsent || fotoUrl != null) {
      map['foto_url'] = Variable<String>(fotoUrl);
    }
    return map;
  }

  VidrosVistoriaCompanion toCompanion(bool nullToAbsent) {
    return VidrosVistoriaCompanion(
      id: Value(id),
      vistoriaId: Value(vistoriaId),
      posicao: Value(posicao),
      codigoEncontrado: codigoEncontrado == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoEncontrado),
      status: Value(status),
      observacao: observacao == null && nullToAbsent
          ? const Value.absent()
          : Value(observacao),
      fotoUrl: fotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoUrl),
    );
  }

  factory VidrosVistoriaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VidrosVistoriaData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String>(json['vistoriaId']),
      posicao: serializer.fromJson<String>(json['posicao']),
      codigoEncontrado: serializer.fromJson<String?>(json['codigoEncontrado']),
      status: serializer.fromJson<String>(json['status']),
      observacao: serializer.fromJson<String?>(json['observacao']),
      fotoUrl: serializer.fromJson<String?>(json['fotoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String>(vistoriaId),
      'posicao': serializer.toJson<String>(posicao),
      'codigoEncontrado': serializer.toJson<String?>(codigoEncontrado),
      'status': serializer.toJson<String>(status),
      'observacao': serializer.toJson<String?>(observacao),
      'fotoUrl': serializer.toJson<String?>(fotoUrl),
    };
  }

  VidrosVistoriaData copyWith(
          {String? id,
          String? vistoriaId,
          String? posicao,
          Value<String?> codigoEncontrado = const Value.absent(),
          String? status,
          Value<String?> observacao = const Value.absent(),
          Value<String?> fotoUrl = const Value.absent()}) =>
      VidrosVistoriaData(
        id: id ?? this.id,
        vistoriaId: vistoriaId ?? this.vistoriaId,
        posicao: posicao ?? this.posicao,
        codigoEncontrado: codigoEncontrado.present
            ? codigoEncontrado.value
            : this.codigoEncontrado,
        status: status ?? this.status,
        observacao: observacao.present ? observacao.value : this.observacao,
        fotoUrl: fotoUrl.present ? fotoUrl.value : this.fotoUrl,
      );
  VidrosVistoriaData copyWithCompanion(VidrosVistoriaCompanion data) {
    return VidrosVistoriaData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      posicao: data.posicao.present ? data.posicao.value : this.posicao,
      codigoEncontrado: data.codigoEncontrado.present
          ? data.codigoEncontrado.value
          : this.codigoEncontrado,
      status: data.status.present ? data.status.value : this.status,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
      fotoUrl: data.fotoUrl.present ? data.fotoUrl.value : this.fotoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VidrosVistoriaData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('posicao: $posicao, ')
          ..write('codigoEncontrado: $codigoEncontrado, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, vistoriaId, posicao, codigoEncontrado, status, observacao, fotoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VidrosVistoriaData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.posicao == this.posicao &&
          other.codigoEncontrado == this.codigoEncontrado &&
          other.status == this.status &&
          other.observacao == this.observacao &&
          other.fotoUrl == this.fotoUrl);
}

class VidrosVistoriaCompanion extends UpdateCompanion<VidrosVistoriaData> {
  final Value<String> id;
  final Value<String> vistoriaId;
  final Value<String> posicao;
  final Value<String?> codigoEncontrado;
  final Value<String> status;
  final Value<String?> observacao;
  final Value<String?> fotoUrl;
  final Value<int> rowid;
  const VidrosVistoriaCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.posicao = const Value.absent(),
    this.codigoEncontrado = const Value.absent(),
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VidrosVistoriaCompanion.insert({
    required String id,
    required String vistoriaId,
    required String posicao,
    this.codigoEncontrado = const Value.absent(),
    this.status = const Value.absent(),
    this.observacao = const Value.absent(),
    this.fotoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vistoriaId = Value(vistoriaId),
        posicao = Value(posicao);
  static Insertable<VidrosVistoriaData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? posicao,
    Expression<String>? codigoEncontrado,
    Expression<String>? status,
    Expression<String>? observacao,
    Expression<String>? fotoUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (posicao != null) 'posicao': posicao,
      if (codigoEncontrado != null) 'codigo_encontrado': codigoEncontrado,
      if (status != null) 'status': status,
      if (observacao != null) 'observacao': observacao,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VidrosVistoriaCompanion copyWith(
      {Value<String>? id,
      Value<String>? vistoriaId,
      Value<String>? posicao,
      Value<String?>? codigoEncontrado,
      Value<String>? status,
      Value<String?>? observacao,
      Value<String?>? fotoUrl,
      Value<int>? rowid}) {
    return VidrosVistoriaCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      posicao: posicao ?? this.posicao,
      codigoEncontrado: codigoEncontrado ?? this.codigoEncontrado,
      status: status ?? this.status,
      observacao: observacao ?? this.observacao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (posicao.present) {
      map['posicao'] = Variable<String>(posicao.value);
    }
    if (codigoEncontrado.present) {
      map['codigo_encontrado'] = Variable<String>(codigoEncontrado.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (fotoUrl.present) {
      map['foto_url'] = Variable<String>(fotoUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VidrosVistoriaCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('posicao: $posicao, ')
          ..write('codigoEncontrado: $codigoEncontrado, ')
          ..write('status: $status, ')
          ..write('observacao: $observacao, ')
          ..write('fotoUrl: $fotoUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsultasBinTable extends ConsultasBin
    with TableInfo<$ConsultasBinTable, ConsultasBinData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsultasBinTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _placaMeta = const VerificationMeta('placa');
  @override
  late final GeneratedColumn<String> placa = GeneratedColumn<String>(
      'placa', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _chassiMeta = const VerificationMeta('chassi');
  @override
  late final GeneratedColumn<String> chassi = GeneratedColumn<String>(
      'chassi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dadosJsonMeta =
      const VerificationMeta('dadosJson');
  @override
  late final GeneratedColumn<String> dadosJson = GeneratedColumn<String>(
      'dados_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _restricoesMeta =
      const VerificationMeta('restricoes');
  @override
  late final GeneratedColumn<bool> restricoes = GeneratedColumn<bool>(
      'restricoes', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("restricoes" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _debitosMeta =
      const VerificationMeta('debitos');
  @override
  late final GeneratedColumn<bool> debitos = GeneratedColumn<bool>(
      'debitos', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("debitos" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _leilaoMeta = const VerificationMeta('leilao');
  @override
  late final GeneratedColumn<bool> leilao = GeneratedColumn<bool>(
      'leilao', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("leilao" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sinistroMeta =
      const VerificationMeta('sinistro');
  @override
  late final GeneratedColumn<bool> sinistro = GeneratedColumn<bool>(
      'sinistro', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sinistro" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _situacaoMeta =
      const VerificationMeta('situacao');
  @override
  late final GeneratedColumn<String> situacao = GeneratedColumn<String>(
      'situacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _proprietarioAtualMeta =
      const VerificationMeta('proprietarioAtual');
  @override
  late final GeneratedColumn<String> proprietarioAtual =
      GeneratedColumn<String>('proprietario_atual', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _historicoProprietariosJsonMeta =
      const VerificationMeta('historicoProprietariosJson');
  @override
  late final GeneratedColumn<String> historicoProprietariosJson =
      GeneratedColumn<String>('historico_proprietarios_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
      'marca', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
      'modelo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _anoFabricacaoMeta =
      const VerificationMeta('anoFabricacao');
  @override
  late final GeneratedColumn<int> anoFabricacao = GeneratedColumn<int>(
      'ano_fabricacao', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _anoModeloMeta =
      const VerificationMeta('anoModelo');
  @override
  late final GeneratedColumn<int> anoModelo = GeneratedColumn<int>(
      'ano_modelo', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _corMeta = const VerificationMeta('cor');
  @override
  late final GeneratedColumn<String> cor = GeneratedColumn<String>(
      'cor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _combustivelMeta =
      const VerificationMeta('combustivel');
  @override
  late final GeneratedColumn<String> combustivel = GeneratedColumn<String>(
      'combustivel', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motorFabricaMeta =
      const VerificationMeta('motorFabrica');
  @override
  late final GeneratedColumn<String> motorFabrica = GeneratedColumn<String>(
      'motor_fabrica', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motorEstadualMeta =
      const VerificationMeta('motorEstadual');
  @override
  late final GeneratedColumn<String> motorEstadual = GeneratedColumn<String>(
      'motor_estadual', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _consultadoEmMeta =
      const VerificationMeta('consultadoEm');
  @override
  late final GeneratedColumn<DateTime> consultadoEm = GeneratedColumn<DateTime>(
      'consultado_em', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        placa,
        chassi,
        dadosJson,
        restricoes,
        debitos,
        leilao,
        sinistro,
        situacao,
        proprietarioAtual,
        historicoProprietariosJson,
        marca,
        modelo,
        anoFabricacao,
        anoModelo,
        cor,
        combustivel,
        motorFabrica,
        motorEstadual,
        consultadoEm
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consultas_bin';
  @override
  VerificationContext validateIntegrity(Insertable<ConsultasBinData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('placa')) {
      context.handle(
          _placaMeta, placa.isAcceptableOrUnknown(data['placa']!, _placaMeta));
    } else if (isInserting) {
      context.missing(_placaMeta);
    }
    if (data.containsKey('chassi')) {
      context.handle(_chassiMeta,
          chassi.isAcceptableOrUnknown(data['chassi']!, _chassiMeta));
    }
    if (data.containsKey('dados_json')) {
      context.handle(_dadosJsonMeta,
          dadosJson.isAcceptableOrUnknown(data['dados_json']!, _dadosJsonMeta));
    }
    if (data.containsKey('restricoes')) {
      context.handle(
          _restricoesMeta,
          restricoes.isAcceptableOrUnknown(
              data['restricoes']!, _restricoesMeta));
    }
    if (data.containsKey('debitos')) {
      context.handle(_debitosMeta,
          debitos.isAcceptableOrUnknown(data['debitos']!, _debitosMeta));
    }
    if (data.containsKey('leilao')) {
      context.handle(_leilaoMeta,
          leilao.isAcceptableOrUnknown(data['leilao']!, _leilaoMeta));
    }
    if (data.containsKey('sinistro')) {
      context.handle(_sinistroMeta,
          sinistro.isAcceptableOrUnknown(data['sinistro']!, _sinistroMeta));
    }
    if (data.containsKey('situacao')) {
      context.handle(_situacaoMeta,
          situacao.isAcceptableOrUnknown(data['situacao']!, _situacaoMeta));
    }
    if (data.containsKey('proprietario_atual')) {
      context.handle(
          _proprietarioAtualMeta,
          proprietarioAtual.isAcceptableOrUnknown(
              data['proprietario_atual']!, _proprietarioAtualMeta));
    }
    if (data.containsKey('historico_proprietarios_json')) {
      context.handle(
          _historicoProprietariosJsonMeta,
          historicoProprietariosJson.isAcceptableOrUnknown(
              data['historico_proprietarios_json']!,
              _historicoProprietariosJsonMeta));
    }
    if (data.containsKey('marca')) {
      context.handle(
          _marcaMeta, marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta));
    }
    if (data.containsKey('modelo')) {
      context.handle(_modeloMeta,
          modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta));
    }
    if (data.containsKey('ano_fabricacao')) {
      context.handle(
          _anoFabricacaoMeta,
          anoFabricacao.isAcceptableOrUnknown(
              data['ano_fabricacao']!, _anoFabricacaoMeta));
    }
    if (data.containsKey('ano_modelo')) {
      context.handle(_anoModeloMeta,
          anoModelo.isAcceptableOrUnknown(data['ano_modelo']!, _anoModeloMeta));
    }
    if (data.containsKey('cor')) {
      context.handle(
          _corMeta, cor.isAcceptableOrUnknown(data['cor']!, _corMeta));
    }
    if (data.containsKey('combustivel')) {
      context.handle(
          _combustivelMeta,
          combustivel.isAcceptableOrUnknown(
              data['combustivel']!, _combustivelMeta));
    }
    if (data.containsKey('motor_fabrica')) {
      context.handle(
          _motorFabricaMeta,
          motorFabrica.isAcceptableOrUnknown(
              data['motor_fabrica']!, _motorFabricaMeta));
    }
    if (data.containsKey('motor_estadual')) {
      context.handle(
          _motorEstadualMeta,
          motorEstadual.isAcceptableOrUnknown(
              data['motor_estadual']!, _motorEstadualMeta));
    }
    if (data.containsKey('consultado_em')) {
      context.handle(
          _consultadoEmMeta,
          consultadoEm.isAcceptableOrUnknown(
              data['consultado_em']!, _consultadoEmMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsultasBinData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsultasBinData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      placa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}placa'])!,
      chassi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chassi']),
      dadosJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dados_json']),
      restricoes: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}restricoes'])!,
      debitos: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}debitos'])!,
      leilao: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}leilao'])!,
      sinistro: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sinistro'])!,
      situacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}situacao']),
      proprietarioAtual: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}proprietario_atual']),
      historicoProprietariosJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}historico_proprietarios_json']),
      marca: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}marca']),
      modelo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modelo']),
      anoFabricacao: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ano_fabricacao']),
      anoModelo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ano_modelo']),
      cor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cor']),
      combustivel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}combustivel']),
      motorFabrica: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motor_fabrica']),
      motorEstadual: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motor_estadual']),
      consultadoEm: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}consultado_em'])!,
    );
  }

  @override
  $ConsultasBinTable createAlias(String alias) {
    return $ConsultasBinTable(attachedDatabase, alias);
  }
}

class ConsultasBinData extends DataClass
    implements Insertable<ConsultasBinData> {
  final String id;
  final String placa;
  final String? chassi;
  final String? dadosJson;
  final bool restricoes;
  final bool debitos;
  final bool leilao;
  final bool sinistro;
  final String? situacao;
  final String? proprietarioAtual;
  final String? historicoProprietariosJson;
  final String? marca;
  final String? modelo;
  final int? anoFabricacao;
  final int? anoModelo;
  final String? cor;
  final String? combustivel;
  final String? motorFabrica;
  final String? motorEstadual;
  final DateTime consultadoEm;
  const ConsultasBinData(
      {required this.id,
      required this.placa,
      this.chassi,
      this.dadosJson,
      required this.restricoes,
      required this.debitos,
      required this.leilao,
      required this.sinistro,
      this.situacao,
      this.proprietarioAtual,
      this.historicoProprietariosJson,
      this.marca,
      this.modelo,
      this.anoFabricacao,
      this.anoModelo,
      this.cor,
      this.combustivel,
      this.motorFabrica,
      this.motorEstadual,
      required this.consultadoEm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['placa'] = Variable<String>(placa);
    if (!nullToAbsent || chassi != null) {
      map['chassi'] = Variable<String>(chassi);
    }
    if (!nullToAbsent || dadosJson != null) {
      map['dados_json'] = Variable<String>(dadosJson);
    }
    map['restricoes'] = Variable<bool>(restricoes);
    map['debitos'] = Variable<bool>(debitos);
    map['leilao'] = Variable<bool>(leilao);
    map['sinistro'] = Variable<bool>(sinistro);
    if (!nullToAbsent || situacao != null) {
      map['situacao'] = Variable<String>(situacao);
    }
    if (!nullToAbsent || proprietarioAtual != null) {
      map['proprietario_atual'] = Variable<String>(proprietarioAtual);
    }
    if (!nullToAbsent || historicoProprietariosJson != null) {
      map['historico_proprietarios_json'] =
          Variable<String>(historicoProprietariosJson);
    }
    if (!nullToAbsent || marca != null) {
      map['marca'] = Variable<String>(marca);
    }
    if (!nullToAbsent || modelo != null) {
      map['modelo'] = Variable<String>(modelo);
    }
    if (!nullToAbsent || anoFabricacao != null) {
      map['ano_fabricacao'] = Variable<int>(anoFabricacao);
    }
    if (!nullToAbsent || anoModelo != null) {
      map['ano_modelo'] = Variable<int>(anoModelo);
    }
    if (!nullToAbsent || cor != null) {
      map['cor'] = Variable<String>(cor);
    }
    if (!nullToAbsent || combustivel != null) {
      map['combustivel'] = Variable<String>(combustivel);
    }
    if (!nullToAbsent || motorFabrica != null) {
      map['motor_fabrica'] = Variable<String>(motorFabrica);
    }
    if (!nullToAbsent || motorEstadual != null) {
      map['motor_estadual'] = Variable<String>(motorEstadual);
    }
    map['consultado_em'] = Variable<DateTime>(consultadoEm);
    return map;
  }

  ConsultasBinCompanion toCompanion(bool nullToAbsent) {
    return ConsultasBinCompanion(
      id: Value(id),
      placa: Value(placa),
      chassi:
          chassi == null && nullToAbsent ? const Value.absent() : Value(chassi),
      dadosJson: dadosJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dadosJson),
      restricoes: Value(restricoes),
      debitos: Value(debitos),
      leilao: Value(leilao),
      sinistro: Value(sinistro),
      situacao: situacao == null && nullToAbsent
          ? const Value.absent()
          : Value(situacao),
      proprietarioAtual: proprietarioAtual == null && nullToAbsent
          ? const Value.absent()
          : Value(proprietarioAtual),
      historicoProprietariosJson:
          historicoProprietariosJson == null && nullToAbsent
              ? const Value.absent()
              : Value(historicoProprietariosJson),
      marca:
          marca == null && nullToAbsent ? const Value.absent() : Value(marca),
      modelo:
          modelo == null && nullToAbsent ? const Value.absent() : Value(modelo),
      anoFabricacao: anoFabricacao == null && nullToAbsent
          ? const Value.absent()
          : Value(anoFabricacao),
      anoModelo: anoModelo == null && nullToAbsent
          ? const Value.absent()
          : Value(anoModelo),
      cor: cor == null && nullToAbsent ? const Value.absent() : Value(cor),
      combustivel: combustivel == null && nullToAbsent
          ? const Value.absent()
          : Value(combustivel),
      motorFabrica: motorFabrica == null && nullToAbsent
          ? const Value.absent()
          : Value(motorFabrica),
      motorEstadual: motorEstadual == null && nullToAbsent
          ? const Value.absent()
          : Value(motorEstadual),
      consultadoEm: Value(consultadoEm),
    );
  }

  factory ConsultasBinData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsultasBinData(
      id: serializer.fromJson<String>(json['id']),
      placa: serializer.fromJson<String>(json['placa']),
      chassi: serializer.fromJson<String?>(json['chassi']),
      dadosJson: serializer.fromJson<String?>(json['dadosJson']),
      restricoes: serializer.fromJson<bool>(json['restricoes']),
      debitos: serializer.fromJson<bool>(json['debitos']),
      leilao: serializer.fromJson<bool>(json['leilao']),
      sinistro: serializer.fromJson<bool>(json['sinistro']),
      situacao: serializer.fromJson<String?>(json['situacao']),
      proprietarioAtual:
          serializer.fromJson<String?>(json['proprietarioAtual']),
      historicoProprietariosJson:
          serializer.fromJson<String?>(json['historicoProprietariosJson']),
      marca: serializer.fromJson<String?>(json['marca']),
      modelo: serializer.fromJson<String?>(json['modelo']),
      anoFabricacao: serializer.fromJson<int?>(json['anoFabricacao']),
      anoModelo: serializer.fromJson<int?>(json['anoModelo']),
      cor: serializer.fromJson<String?>(json['cor']),
      combustivel: serializer.fromJson<String?>(json['combustivel']),
      motorFabrica: serializer.fromJson<String?>(json['motorFabrica']),
      motorEstadual: serializer.fromJson<String?>(json['motorEstadual']),
      consultadoEm: serializer.fromJson<DateTime>(json['consultadoEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'placa': serializer.toJson<String>(placa),
      'chassi': serializer.toJson<String?>(chassi),
      'dadosJson': serializer.toJson<String?>(dadosJson),
      'restricoes': serializer.toJson<bool>(restricoes),
      'debitos': serializer.toJson<bool>(debitos),
      'leilao': serializer.toJson<bool>(leilao),
      'sinistro': serializer.toJson<bool>(sinistro),
      'situacao': serializer.toJson<String?>(situacao),
      'proprietarioAtual': serializer.toJson<String?>(proprietarioAtual),
      'historicoProprietariosJson':
          serializer.toJson<String?>(historicoProprietariosJson),
      'marca': serializer.toJson<String?>(marca),
      'modelo': serializer.toJson<String?>(modelo),
      'anoFabricacao': serializer.toJson<int?>(anoFabricacao),
      'anoModelo': serializer.toJson<int?>(anoModelo),
      'cor': serializer.toJson<String?>(cor),
      'combustivel': serializer.toJson<String?>(combustivel),
      'motorFabrica': serializer.toJson<String?>(motorFabrica),
      'motorEstadual': serializer.toJson<String?>(motorEstadual),
      'consultadoEm': serializer.toJson<DateTime>(consultadoEm),
    };
  }

  ConsultasBinData copyWith(
          {String? id,
          String? placa,
          Value<String?> chassi = const Value.absent(),
          Value<String?> dadosJson = const Value.absent(),
          bool? restricoes,
          bool? debitos,
          bool? leilao,
          bool? sinistro,
          Value<String?> situacao = const Value.absent(),
          Value<String?> proprietarioAtual = const Value.absent(),
          Value<String?> historicoProprietariosJson = const Value.absent(),
          Value<String?> marca = const Value.absent(),
          Value<String?> modelo = const Value.absent(),
          Value<int?> anoFabricacao = const Value.absent(),
          Value<int?> anoModelo = const Value.absent(),
          Value<String?> cor = const Value.absent(),
          Value<String?> combustivel = const Value.absent(),
          Value<String?> motorFabrica = const Value.absent(),
          Value<String?> motorEstadual = const Value.absent(),
          DateTime? consultadoEm}) =>
      ConsultasBinData(
        id: id ?? this.id,
        placa: placa ?? this.placa,
        chassi: chassi.present ? chassi.value : this.chassi,
        dadosJson: dadosJson.present ? dadosJson.value : this.dadosJson,
        restricoes: restricoes ?? this.restricoes,
        debitos: debitos ?? this.debitos,
        leilao: leilao ?? this.leilao,
        sinistro: sinistro ?? this.sinistro,
        situacao: situacao.present ? situacao.value : this.situacao,
        proprietarioAtual: proprietarioAtual.present
            ? proprietarioAtual.value
            : this.proprietarioAtual,
        historicoProprietariosJson: historicoProprietariosJson.present
            ? historicoProprietariosJson.value
            : this.historicoProprietariosJson,
        marca: marca.present ? marca.value : this.marca,
        modelo: modelo.present ? modelo.value : this.modelo,
        anoFabricacao:
            anoFabricacao.present ? anoFabricacao.value : this.anoFabricacao,
        anoModelo: anoModelo.present ? anoModelo.value : this.anoModelo,
        cor: cor.present ? cor.value : this.cor,
        combustivel: combustivel.present ? combustivel.value : this.combustivel,
        motorFabrica:
            motorFabrica.present ? motorFabrica.value : this.motorFabrica,
        motorEstadual:
            motorEstadual.present ? motorEstadual.value : this.motorEstadual,
        consultadoEm: consultadoEm ?? this.consultadoEm,
      );
  ConsultasBinData copyWithCompanion(ConsultasBinCompanion data) {
    return ConsultasBinData(
      id: data.id.present ? data.id.value : this.id,
      placa: data.placa.present ? data.placa.value : this.placa,
      chassi: data.chassi.present ? data.chassi.value : this.chassi,
      dadosJson: data.dadosJson.present ? data.dadosJson.value : this.dadosJson,
      restricoes:
          data.restricoes.present ? data.restricoes.value : this.restricoes,
      debitos: data.debitos.present ? data.debitos.value : this.debitos,
      leilao: data.leilao.present ? data.leilao.value : this.leilao,
      sinistro: data.sinistro.present ? data.sinistro.value : this.sinistro,
      situacao: data.situacao.present ? data.situacao.value : this.situacao,
      proprietarioAtual: data.proprietarioAtual.present
          ? data.proprietarioAtual.value
          : this.proprietarioAtual,
      historicoProprietariosJson: data.historicoProprietariosJson.present
          ? data.historicoProprietariosJson.value
          : this.historicoProprietariosJson,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      anoFabricacao: data.anoFabricacao.present
          ? data.anoFabricacao.value
          : this.anoFabricacao,
      anoModelo: data.anoModelo.present ? data.anoModelo.value : this.anoModelo,
      cor: data.cor.present ? data.cor.value : this.cor,
      combustivel:
          data.combustivel.present ? data.combustivel.value : this.combustivel,
      motorFabrica: data.motorFabrica.present
          ? data.motorFabrica.value
          : this.motorFabrica,
      motorEstadual: data.motorEstadual.present
          ? data.motorEstadual.value
          : this.motorEstadual,
      consultadoEm: data.consultadoEm.present
          ? data.consultadoEm.value
          : this.consultadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsultasBinData(')
          ..write('id: $id, ')
          ..write('placa: $placa, ')
          ..write('chassi: $chassi, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('restricoes: $restricoes, ')
          ..write('debitos: $debitos, ')
          ..write('leilao: $leilao, ')
          ..write('sinistro: $sinistro, ')
          ..write('situacao: $situacao, ')
          ..write('proprietarioAtual: $proprietarioAtual, ')
          ..write('historicoProprietariosJson: $historicoProprietariosJson, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anoFabricacao: $anoFabricacao, ')
          ..write('anoModelo: $anoModelo, ')
          ..write('cor: $cor, ')
          ..write('combustivel: $combustivel, ')
          ..write('motorFabrica: $motorFabrica, ')
          ..write('motorEstadual: $motorEstadual, ')
          ..write('consultadoEm: $consultadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      placa,
      chassi,
      dadosJson,
      restricoes,
      debitos,
      leilao,
      sinistro,
      situacao,
      proprietarioAtual,
      historicoProprietariosJson,
      marca,
      modelo,
      anoFabricacao,
      anoModelo,
      cor,
      combustivel,
      motorFabrica,
      motorEstadual,
      consultadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsultasBinData &&
          other.id == this.id &&
          other.placa == this.placa &&
          other.chassi == this.chassi &&
          other.dadosJson == this.dadosJson &&
          other.restricoes == this.restricoes &&
          other.debitos == this.debitos &&
          other.leilao == this.leilao &&
          other.sinistro == this.sinistro &&
          other.situacao == this.situacao &&
          other.proprietarioAtual == this.proprietarioAtual &&
          other.historicoProprietariosJson == this.historicoProprietariosJson &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.anoFabricacao == this.anoFabricacao &&
          other.anoModelo == this.anoModelo &&
          other.cor == this.cor &&
          other.combustivel == this.combustivel &&
          other.motorFabrica == this.motorFabrica &&
          other.motorEstadual == this.motorEstadual &&
          other.consultadoEm == this.consultadoEm);
}

class ConsultasBinCompanion extends UpdateCompanion<ConsultasBinData> {
  final Value<String> id;
  final Value<String> placa;
  final Value<String?> chassi;
  final Value<String?> dadosJson;
  final Value<bool> restricoes;
  final Value<bool> debitos;
  final Value<bool> leilao;
  final Value<bool> sinistro;
  final Value<String?> situacao;
  final Value<String?> proprietarioAtual;
  final Value<String?> historicoProprietariosJson;
  final Value<String?> marca;
  final Value<String?> modelo;
  final Value<int?> anoFabricacao;
  final Value<int?> anoModelo;
  final Value<String?> cor;
  final Value<String?> combustivel;
  final Value<String?> motorFabrica;
  final Value<String?> motorEstadual;
  final Value<DateTime> consultadoEm;
  final Value<int> rowid;
  const ConsultasBinCompanion({
    this.id = const Value.absent(),
    this.placa = const Value.absent(),
    this.chassi = const Value.absent(),
    this.dadosJson = const Value.absent(),
    this.restricoes = const Value.absent(),
    this.debitos = const Value.absent(),
    this.leilao = const Value.absent(),
    this.sinistro = const Value.absent(),
    this.situacao = const Value.absent(),
    this.proprietarioAtual = const Value.absent(),
    this.historicoProprietariosJson = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.anoFabricacao = const Value.absent(),
    this.anoModelo = const Value.absent(),
    this.cor = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.motorFabrica = const Value.absent(),
    this.motorEstadual = const Value.absent(),
    this.consultadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsultasBinCompanion.insert({
    required String id,
    required String placa,
    this.chassi = const Value.absent(),
    this.dadosJson = const Value.absent(),
    this.restricoes = const Value.absent(),
    this.debitos = const Value.absent(),
    this.leilao = const Value.absent(),
    this.sinistro = const Value.absent(),
    this.situacao = const Value.absent(),
    this.proprietarioAtual = const Value.absent(),
    this.historicoProprietariosJson = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.anoFabricacao = const Value.absent(),
    this.anoModelo = const Value.absent(),
    this.cor = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.motorFabrica = const Value.absent(),
    this.motorEstadual = const Value.absent(),
    this.consultadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        placa = Value(placa);
  static Insertable<ConsultasBinData> custom({
    Expression<String>? id,
    Expression<String>? placa,
    Expression<String>? chassi,
    Expression<String>? dadosJson,
    Expression<bool>? restricoes,
    Expression<bool>? debitos,
    Expression<bool>? leilao,
    Expression<bool>? sinistro,
    Expression<String>? situacao,
    Expression<String>? proprietarioAtual,
    Expression<String>? historicoProprietariosJson,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<int>? anoFabricacao,
    Expression<int>? anoModelo,
    Expression<String>? cor,
    Expression<String>? combustivel,
    Expression<String>? motorFabrica,
    Expression<String>? motorEstadual,
    Expression<DateTime>? consultadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placa != null) 'placa': placa,
      if (chassi != null) 'chassi': chassi,
      if (dadosJson != null) 'dados_json': dadosJson,
      if (restricoes != null) 'restricoes': restricoes,
      if (debitos != null) 'debitos': debitos,
      if (leilao != null) 'leilao': leilao,
      if (sinistro != null) 'sinistro': sinistro,
      if (situacao != null) 'situacao': situacao,
      if (proprietarioAtual != null) 'proprietario_atual': proprietarioAtual,
      if (historicoProprietariosJson != null)
        'historico_proprietarios_json': historicoProprietariosJson,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (anoFabricacao != null) 'ano_fabricacao': anoFabricacao,
      if (anoModelo != null) 'ano_modelo': anoModelo,
      if (cor != null) 'cor': cor,
      if (combustivel != null) 'combustivel': combustivel,
      if (motorFabrica != null) 'motor_fabrica': motorFabrica,
      if (motorEstadual != null) 'motor_estadual': motorEstadual,
      if (consultadoEm != null) 'consultado_em': consultadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsultasBinCompanion copyWith(
      {Value<String>? id,
      Value<String>? placa,
      Value<String?>? chassi,
      Value<String?>? dadosJson,
      Value<bool>? restricoes,
      Value<bool>? debitos,
      Value<bool>? leilao,
      Value<bool>? sinistro,
      Value<String?>? situacao,
      Value<String?>? proprietarioAtual,
      Value<String?>? historicoProprietariosJson,
      Value<String?>? marca,
      Value<String?>? modelo,
      Value<int?>? anoFabricacao,
      Value<int?>? anoModelo,
      Value<String?>? cor,
      Value<String?>? combustivel,
      Value<String?>? motorFabrica,
      Value<String?>? motorEstadual,
      Value<DateTime>? consultadoEm,
      Value<int>? rowid}) {
    return ConsultasBinCompanion(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      chassi: chassi ?? this.chassi,
      dadosJson: dadosJson ?? this.dadosJson,
      restricoes: restricoes ?? this.restricoes,
      debitos: debitos ?? this.debitos,
      leilao: leilao ?? this.leilao,
      sinistro: sinistro ?? this.sinistro,
      situacao: situacao ?? this.situacao,
      proprietarioAtual: proprietarioAtual ?? this.proprietarioAtual,
      historicoProprietariosJson:
          historicoProprietariosJson ?? this.historicoProprietariosJson,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anoFabricacao: anoFabricacao ?? this.anoFabricacao,
      anoModelo: anoModelo ?? this.anoModelo,
      cor: cor ?? this.cor,
      combustivel: combustivel ?? this.combustivel,
      motorFabrica: motorFabrica ?? this.motorFabrica,
      motorEstadual: motorEstadual ?? this.motorEstadual,
      consultadoEm: consultadoEm ?? this.consultadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (placa.present) {
      map['placa'] = Variable<String>(placa.value);
    }
    if (chassi.present) {
      map['chassi'] = Variable<String>(chassi.value);
    }
    if (dadosJson.present) {
      map['dados_json'] = Variable<String>(dadosJson.value);
    }
    if (restricoes.present) {
      map['restricoes'] = Variable<bool>(restricoes.value);
    }
    if (debitos.present) {
      map['debitos'] = Variable<bool>(debitos.value);
    }
    if (leilao.present) {
      map['leilao'] = Variable<bool>(leilao.value);
    }
    if (sinistro.present) {
      map['sinistro'] = Variable<bool>(sinistro.value);
    }
    if (situacao.present) {
      map['situacao'] = Variable<String>(situacao.value);
    }
    if (proprietarioAtual.present) {
      map['proprietario_atual'] = Variable<String>(proprietarioAtual.value);
    }
    if (historicoProprietariosJson.present) {
      map['historico_proprietarios_json'] =
          Variable<String>(historicoProprietariosJson.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (anoFabricacao.present) {
      map['ano_fabricacao'] = Variable<int>(anoFabricacao.value);
    }
    if (anoModelo.present) {
      map['ano_modelo'] = Variable<int>(anoModelo.value);
    }
    if (cor.present) {
      map['cor'] = Variable<String>(cor.value);
    }
    if (combustivel.present) {
      map['combustivel'] = Variable<String>(combustivel.value);
    }
    if (motorFabrica.present) {
      map['motor_fabrica'] = Variable<String>(motorFabrica.value);
    }
    if (motorEstadual.present) {
      map['motor_estadual'] = Variable<String>(motorEstadual.value);
    }
    if (consultadoEm.present) {
      map['consultado_em'] = Variable<DateTime>(consultadoEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsultasBinCompanion(')
          ..write('id: $id, ')
          ..write('placa: $placa, ')
          ..write('chassi: $chassi, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('restricoes: $restricoes, ')
          ..write('debitos: $debitos, ')
          ..write('leilao: $leilao, ')
          ..write('sinistro: $sinistro, ')
          ..write('situacao: $situacao, ')
          ..write('proprietarioAtual: $proprietarioAtual, ')
          ..write('historicoProprietariosJson: $historicoProprietariosJson, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('anoFabricacao: $anoFabricacao, ')
          ..write('anoModelo: $anoModelo, ')
          ..write('cor: $cor, ')
          ..write('combustivel: $combustivel, ')
          ..write('motorFabrica: $motorFabrica, ')
          ..write('motorEstadual: $motorEstadual, ')
          ..write('consultadoEm: $consultadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsultasAutocredTable extends ConsultasAutocred
    with TableInfo<$ConsultasAutocredTable, ConsultasAutocredData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsultasAutocredTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vistoriaIdMeta =
      const VerificationMeta('vistoriaId');
  @override
  late final GeneratedColumn<String> vistoriaId = GeneratedColumn<String>(
      'vistoria_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vistorias (id)'));
  static const VerificationMeta _placaMeta = const VerificationMeta('placa');
  @override
  late final GeneratedColumn<String> placa = GeneratedColumn<String>(
      'placa', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chassiMeta = const VerificationMeta('chassi');
  @override
  late final GeneratedColumn<String> chassi = GeneratedColumn<String>(
      'chassi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _motorMeta = const VerificationMeta('motor');
  @override
  late final GeneratedColumn<String> motor = GeneratedColumn<String>(
      'motor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _codigoConsultaMeta =
      const VerificationMeta('codigoConsulta');
  @override
  late final GeneratedColumn<int> codigoConsulta = GeneratedColumn<int>(
      'codigo_consulta', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _idPesquisaAutocredMeta =
      const VerificationMeta('idPesquisaAutocred');
  @override
  late final GeneratedColumn<String> idPesquisaAutocred =
      GeneratedColumn<String>('id_pesquisa_autocred', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendente'));
  static const VerificationMeta _retornoBrutoMeta =
      const VerificationMeta('retornoBruto');
  @override
  late final GeneratedColumn<String> retornoBruto = GeneratedColumn<String>(
      'retorno_bruto', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dadosTratadosJsonMeta =
      const VerificationMeta('dadosTratadosJson');
  @override
  late final GeneratedColumn<String> dadosTratadosJson =
      GeneratedColumn<String>('dados_tratados_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _arquivoPesquisaUrlMeta =
      const VerificationMeta('arquivoPesquisaUrl');
  @override
  late final GeneratedColumn<String> arquivoPesquisaUrl =
      GeneratedColumn<String>('arquivo_pesquisa_url', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vistoriaId,
        placa,
        chassi,
        motor,
        codigoConsulta,
        idPesquisaAutocred,
        status,
        retornoBruto,
        dadosTratadosJson,
        arquivoPesquisaUrl,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consultas_autocred';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConsultasAutocredData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vistoria_id')) {
      context.handle(
          _vistoriaIdMeta,
          vistoriaId.isAcceptableOrUnknown(
              data['vistoria_id']!, _vistoriaIdMeta));
    }
    if (data.containsKey('placa')) {
      context.handle(
          _placaMeta, placa.isAcceptableOrUnknown(data['placa']!, _placaMeta));
    }
    if (data.containsKey('chassi')) {
      context.handle(_chassiMeta,
          chassi.isAcceptableOrUnknown(data['chassi']!, _chassiMeta));
    }
    if (data.containsKey('motor')) {
      context.handle(
          _motorMeta, motor.isAcceptableOrUnknown(data['motor']!, _motorMeta));
    }
    if (data.containsKey('codigo_consulta')) {
      context.handle(
          _codigoConsultaMeta,
          codigoConsulta.isAcceptableOrUnknown(
              data['codigo_consulta']!, _codigoConsultaMeta));
    } else if (isInserting) {
      context.missing(_codigoConsultaMeta);
    }
    if (data.containsKey('id_pesquisa_autocred')) {
      context.handle(
          _idPesquisaAutocredMeta,
          idPesquisaAutocred.isAcceptableOrUnknown(
              data['id_pesquisa_autocred']!, _idPesquisaAutocredMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retorno_bruto')) {
      context.handle(
          _retornoBrutoMeta,
          retornoBruto.isAcceptableOrUnknown(
              data['retorno_bruto']!, _retornoBrutoMeta));
    }
    if (data.containsKey('dados_tratados_json')) {
      context.handle(
          _dadosTratadosJsonMeta,
          dadosTratadosJson.isAcceptableOrUnknown(
              data['dados_tratados_json']!, _dadosTratadosJsonMeta));
    }
    if (data.containsKey('arquivo_pesquisa_url')) {
      context.handle(
          _arquivoPesquisaUrlMeta,
          arquivoPesquisaUrl.isAcceptableOrUnknown(
              data['arquivo_pesquisa_url']!, _arquivoPesquisaUrlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsultasAutocredData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsultasAutocredData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vistoriaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vistoria_id']),
      placa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}placa']),
      chassi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chassi']),
      motor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}motor']),
      codigoConsulta: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}codigo_consulta'])!,
      idPesquisaAutocred: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}id_pesquisa_autocred']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retornoBruto: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}retorno_bruto']),
      dadosTratadosJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dados_tratados_json']),
      arquivoPesquisaUrl: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}arquivo_pesquisa_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ConsultasAutocredTable createAlias(String alias) {
    return $ConsultasAutocredTable(attachedDatabase, alias);
  }
}

class ConsultasAutocredData extends DataClass
    implements Insertable<ConsultasAutocredData> {
  final String id;
  final String? vistoriaId;
  final String? placa;
  final String? chassi;
  final String? motor;
  final int codigoConsulta;
  final String? idPesquisaAutocred;
  final String status;
  final String? retornoBruto;
  final String? dadosTratadosJson;
  final String? arquivoPesquisaUrl;
  final DateTime createdAt;
  const ConsultasAutocredData(
      {required this.id,
      this.vistoriaId,
      this.placa,
      this.chassi,
      this.motor,
      required this.codigoConsulta,
      this.idPesquisaAutocred,
      required this.status,
      this.retornoBruto,
      this.dadosTratadosJson,
      this.arquivoPesquisaUrl,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || vistoriaId != null) {
      map['vistoria_id'] = Variable<String>(vistoriaId);
    }
    if (!nullToAbsent || placa != null) {
      map['placa'] = Variable<String>(placa);
    }
    if (!nullToAbsent || chassi != null) {
      map['chassi'] = Variable<String>(chassi);
    }
    if (!nullToAbsent || motor != null) {
      map['motor'] = Variable<String>(motor);
    }
    map['codigo_consulta'] = Variable<int>(codigoConsulta);
    if (!nullToAbsent || idPesquisaAutocred != null) {
      map['id_pesquisa_autocred'] = Variable<String>(idPesquisaAutocred);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || retornoBruto != null) {
      map['retorno_bruto'] = Variable<String>(retornoBruto);
    }
    if (!nullToAbsent || dadosTratadosJson != null) {
      map['dados_tratados_json'] = Variable<String>(dadosTratadosJson);
    }
    if (!nullToAbsent || arquivoPesquisaUrl != null) {
      map['arquivo_pesquisa_url'] = Variable<String>(arquivoPesquisaUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConsultasAutocredCompanion toCompanion(bool nullToAbsent) {
    return ConsultasAutocredCompanion(
      id: Value(id),
      vistoriaId: vistoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(vistoriaId),
      placa:
          placa == null && nullToAbsent ? const Value.absent() : Value(placa),
      chassi:
          chassi == null && nullToAbsent ? const Value.absent() : Value(chassi),
      motor:
          motor == null && nullToAbsent ? const Value.absent() : Value(motor),
      codigoConsulta: Value(codigoConsulta),
      idPesquisaAutocred: idPesquisaAutocred == null && nullToAbsent
          ? const Value.absent()
          : Value(idPesquisaAutocred),
      status: Value(status),
      retornoBruto: retornoBruto == null && nullToAbsent
          ? const Value.absent()
          : Value(retornoBruto),
      dadosTratadosJson: dadosTratadosJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dadosTratadosJson),
      arquivoPesquisaUrl: arquivoPesquisaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(arquivoPesquisaUrl),
      createdAt: Value(createdAt),
    );
  }

  factory ConsultasAutocredData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsultasAutocredData(
      id: serializer.fromJson<String>(json['id']),
      vistoriaId: serializer.fromJson<String?>(json['vistoriaId']),
      placa: serializer.fromJson<String?>(json['placa']),
      chassi: serializer.fromJson<String?>(json['chassi']),
      motor: serializer.fromJson<String?>(json['motor']),
      codigoConsulta: serializer.fromJson<int>(json['codigoConsulta']),
      idPesquisaAutocred:
          serializer.fromJson<String?>(json['idPesquisaAutocred']),
      status: serializer.fromJson<String>(json['status']),
      retornoBruto: serializer.fromJson<String?>(json['retornoBruto']),
      dadosTratadosJson:
          serializer.fromJson<String?>(json['dadosTratadosJson']),
      arquivoPesquisaUrl:
          serializer.fromJson<String?>(json['arquivoPesquisaUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vistoriaId': serializer.toJson<String?>(vistoriaId),
      'placa': serializer.toJson<String?>(placa),
      'chassi': serializer.toJson<String?>(chassi),
      'motor': serializer.toJson<String?>(motor),
      'codigoConsulta': serializer.toJson<int>(codigoConsulta),
      'idPesquisaAutocred': serializer.toJson<String?>(idPesquisaAutocred),
      'status': serializer.toJson<String>(status),
      'retornoBruto': serializer.toJson<String?>(retornoBruto),
      'dadosTratadosJson': serializer.toJson<String?>(dadosTratadosJson),
      'arquivoPesquisaUrl': serializer.toJson<String?>(arquivoPesquisaUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConsultasAutocredData copyWith(
          {String? id,
          Value<String?> vistoriaId = const Value.absent(),
          Value<String?> placa = const Value.absent(),
          Value<String?> chassi = const Value.absent(),
          Value<String?> motor = const Value.absent(),
          int? codigoConsulta,
          Value<String?> idPesquisaAutocred = const Value.absent(),
          String? status,
          Value<String?> retornoBruto = const Value.absent(),
          Value<String?> dadosTratadosJson = const Value.absent(),
          Value<String?> arquivoPesquisaUrl = const Value.absent(),
          DateTime? createdAt}) =>
      ConsultasAutocredData(
        id: id ?? this.id,
        vistoriaId: vistoriaId.present ? vistoriaId.value : this.vistoriaId,
        placa: placa.present ? placa.value : this.placa,
        chassi: chassi.present ? chassi.value : this.chassi,
        motor: motor.present ? motor.value : this.motor,
        codigoConsulta: codigoConsulta ?? this.codigoConsulta,
        idPesquisaAutocred: idPesquisaAutocred.present
            ? idPesquisaAutocred.value
            : this.idPesquisaAutocred,
        status: status ?? this.status,
        retornoBruto:
            retornoBruto.present ? retornoBruto.value : this.retornoBruto,
        dadosTratadosJson: dadosTratadosJson.present
            ? dadosTratadosJson.value
            : this.dadosTratadosJson,
        arquivoPesquisaUrl: arquivoPesquisaUrl.present
            ? arquivoPesquisaUrl.value
            : this.arquivoPesquisaUrl,
        createdAt: createdAt ?? this.createdAt,
      );
  ConsultasAutocredData copyWithCompanion(ConsultasAutocredCompanion data) {
    return ConsultasAutocredData(
      id: data.id.present ? data.id.value : this.id,
      vistoriaId:
          data.vistoriaId.present ? data.vistoriaId.value : this.vistoriaId,
      placa: data.placa.present ? data.placa.value : this.placa,
      chassi: data.chassi.present ? data.chassi.value : this.chassi,
      motor: data.motor.present ? data.motor.value : this.motor,
      codigoConsulta: data.codigoConsulta.present
          ? data.codigoConsulta.value
          : this.codigoConsulta,
      idPesquisaAutocred: data.idPesquisaAutocred.present
          ? data.idPesquisaAutocred.value
          : this.idPesquisaAutocred,
      status: data.status.present ? data.status.value : this.status,
      retornoBruto: data.retornoBruto.present
          ? data.retornoBruto.value
          : this.retornoBruto,
      dadosTratadosJson: data.dadosTratadosJson.present
          ? data.dadosTratadosJson.value
          : this.dadosTratadosJson,
      arquivoPesquisaUrl: data.arquivoPesquisaUrl.present
          ? data.arquivoPesquisaUrl.value
          : this.arquivoPesquisaUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsultasAutocredData(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('placa: $placa, ')
          ..write('chassi: $chassi, ')
          ..write('motor: $motor, ')
          ..write('codigoConsulta: $codigoConsulta, ')
          ..write('idPesquisaAutocred: $idPesquisaAutocred, ')
          ..write('status: $status, ')
          ..write('retornoBruto: $retornoBruto, ')
          ..write('dadosTratadosJson: $dadosTratadosJson, ')
          ..write('arquivoPesquisaUrl: $arquivoPesquisaUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      vistoriaId,
      placa,
      chassi,
      motor,
      codigoConsulta,
      idPesquisaAutocred,
      status,
      retornoBruto,
      dadosTratadosJson,
      arquivoPesquisaUrl,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsultasAutocredData &&
          other.id == this.id &&
          other.vistoriaId == this.vistoriaId &&
          other.placa == this.placa &&
          other.chassi == this.chassi &&
          other.motor == this.motor &&
          other.codigoConsulta == this.codigoConsulta &&
          other.idPesquisaAutocred == this.idPesquisaAutocred &&
          other.status == this.status &&
          other.retornoBruto == this.retornoBruto &&
          other.dadosTratadosJson == this.dadosTratadosJson &&
          other.arquivoPesquisaUrl == this.arquivoPesquisaUrl &&
          other.createdAt == this.createdAt);
}

class ConsultasAutocredCompanion
    extends UpdateCompanion<ConsultasAutocredData> {
  final Value<String> id;
  final Value<String?> vistoriaId;
  final Value<String?> placa;
  final Value<String?> chassi;
  final Value<String?> motor;
  final Value<int> codigoConsulta;
  final Value<String?> idPesquisaAutocred;
  final Value<String> status;
  final Value<String?> retornoBruto;
  final Value<String?> dadosTratadosJson;
  final Value<String?> arquivoPesquisaUrl;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConsultasAutocredCompanion({
    this.id = const Value.absent(),
    this.vistoriaId = const Value.absent(),
    this.placa = const Value.absent(),
    this.chassi = const Value.absent(),
    this.motor = const Value.absent(),
    this.codigoConsulta = const Value.absent(),
    this.idPesquisaAutocred = const Value.absent(),
    this.status = const Value.absent(),
    this.retornoBruto = const Value.absent(),
    this.dadosTratadosJson = const Value.absent(),
    this.arquivoPesquisaUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsultasAutocredCompanion.insert({
    required String id,
    this.vistoriaId = const Value.absent(),
    this.placa = const Value.absent(),
    this.chassi = const Value.absent(),
    this.motor = const Value.absent(),
    required int codigoConsulta,
    this.idPesquisaAutocred = const Value.absent(),
    this.status = const Value.absent(),
    this.retornoBruto = const Value.absent(),
    this.dadosTratadosJson = const Value.absent(),
    this.arquivoPesquisaUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        codigoConsulta = Value(codigoConsulta);
  static Insertable<ConsultasAutocredData> custom({
    Expression<String>? id,
    Expression<String>? vistoriaId,
    Expression<String>? placa,
    Expression<String>? chassi,
    Expression<String>? motor,
    Expression<int>? codigoConsulta,
    Expression<String>? idPesquisaAutocred,
    Expression<String>? status,
    Expression<String>? retornoBruto,
    Expression<String>? dadosTratadosJson,
    Expression<String>? arquivoPesquisaUrl,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vistoriaId != null) 'vistoria_id': vistoriaId,
      if (placa != null) 'placa': placa,
      if (chassi != null) 'chassi': chassi,
      if (motor != null) 'motor': motor,
      if (codigoConsulta != null) 'codigo_consulta': codigoConsulta,
      if (idPesquisaAutocred != null)
        'id_pesquisa_autocred': idPesquisaAutocred,
      if (status != null) 'status': status,
      if (retornoBruto != null) 'retorno_bruto': retornoBruto,
      if (dadosTratadosJson != null) 'dados_tratados_json': dadosTratadosJson,
      if (arquivoPesquisaUrl != null)
        'arquivo_pesquisa_url': arquivoPesquisaUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsultasAutocredCompanion copyWith(
      {Value<String>? id,
      Value<String?>? vistoriaId,
      Value<String?>? placa,
      Value<String?>? chassi,
      Value<String?>? motor,
      Value<int>? codigoConsulta,
      Value<String?>? idPesquisaAutocred,
      Value<String>? status,
      Value<String?>? retornoBruto,
      Value<String?>? dadosTratadosJson,
      Value<String?>? arquivoPesquisaUrl,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ConsultasAutocredCompanion(
      id: id ?? this.id,
      vistoriaId: vistoriaId ?? this.vistoriaId,
      placa: placa ?? this.placa,
      chassi: chassi ?? this.chassi,
      motor: motor ?? this.motor,
      codigoConsulta: codigoConsulta ?? this.codigoConsulta,
      idPesquisaAutocred: idPesquisaAutocred ?? this.idPesquisaAutocred,
      status: status ?? this.status,
      retornoBruto: retornoBruto ?? this.retornoBruto,
      dadosTratadosJson: dadosTratadosJson ?? this.dadosTratadosJson,
      arquivoPesquisaUrl: arquivoPesquisaUrl ?? this.arquivoPesquisaUrl,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vistoriaId.present) {
      map['vistoria_id'] = Variable<String>(vistoriaId.value);
    }
    if (placa.present) {
      map['placa'] = Variable<String>(placa.value);
    }
    if (chassi.present) {
      map['chassi'] = Variable<String>(chassi.value);
    }
    if (motor.present) {
      map['motor'] = Variable<String>(motor.value);
    }
    if (codigoConsulta.present) {
      map['codigo_consulta'] = Variable<int>(codigoConsulta.value);
    }
    if (idPesquisaAutocred.present) {
      map['id_pesquisa_autocred'] = Variable<String>(idPesquisaAutocred.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retornoBruto.present) {
      map['retorno_bruto'] = Variable<String>(retornoBruto.value);
    }
    if (dadosTratadosJson.present) {
      map['dados_tratados_json'] = Variable<String>(dadosTratadosJson.value);
    }
    if (arquivoPesquisaUrl.present) {
      map['arquivo_pesquisa_url'] = Variable<String>(arquivoPesquisaUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsultasAutocredCompanion(')
          ..write('id: $id, ')
          ..write('vistoriaId: $vistoriaId, ')
          ..write('placa: $placa, ')
          ..write('chassi: $chassi, ')
          ..write('motor: $motor, ')
          ..write('codigoConsulta: $codigoConsulta, ')
          ..write('idPesquisaAutocred: $idPesquisaAutocred, ')
          ..write('status: $status, ')
          ..write('retornoBruto: $retornoBruto, ')
          ..write('dadosTratadosJson: $dadosTratadosJson, ')
          ..write('arquivoPesquisaUrl: $arquivoPesquisaUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VistoriadoresTable vistoriadores = $VistoriadoresTable(this);
  late final $VistoriasTable vistorias = $VistoriasTable(this);
  late final $VeiculosTable veiculos = $VeiculosTable(this);
  late final $ItensVistoriaTable itensVistoria = $ItensVistoriaTable(this);
  late final $FotosVistoriaTable fotosVistoria = $FotosVistoriaTable(this);
  late final $ItensPinturaTable itensPintura = $ItensPinturaTable(this);
  late final $ItensEstruturaTable itensEstrutura = $ItensEstruturaTable(this);
  late final $VidrosVistoriaTable vidrosVistoria = $VidrosVistoriaTable(this);
  late final $ConsultasBinTable consultasBin = $ConsultasBinTable(this);
  late final $ConsultasAutocredTable consultasAutocred =
      $ConsultasAutocredTable(this);
  late final VistoriaDao vistoriaDao = VistoriaDao(this as AppDatabase);
  late final BinDao binDao = BinDao(this as AppDatabase);
  late final AutocredDao autocredDao = AutocredDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        vistoriadores,
        vistorias,
        veiculos,
        itensVistoria,
        fotosVistoria,
        itensPintura,
        itensEstrutura,
        vidrosVistoria,
        consultasBin,
        consultasAutocred
      ];
}

typedef $$VistoriadoresTableCreateCompanionBuilder = VistoriadoresCompanion
    Function({
  required String id,
  required String nome,
  required String cpf,
  required String unidadeNome,
  Value<String?> unidadeCnpj,
  Value<String> cargo,
  Value<bool> ativo,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$VistoriadoresTableUpdateCompanionBuilder = VistoriadoresCompanion
    Function({
  Value<String> id,
  Value<String> nome,
  Value<String> cpf,
  Value<String> unidadeNome,
  Value<String?> unidadeCnpj,
  Value<String> cargo,
  Value<bool> ativo,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$VistoriadoresTableFilterComposer
    extends Composer<_$AppDatabase, $VistoriadoresTable> {
  $$VistoriadoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cpf => $composableBuilder(
      column: $table.cpf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unidadeNome => $composableBuilder(
      column: $table.unidadeNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unidadeCnpj => $composableBuilder(
      column: $table.unidadeCnpj, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cargo => $composableBuilder(
      column: $table.cargo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$VistoriadoresTableOrderingComposer
    extends Composer<_$AppDatabase, $VistoriadoresTable> {
  $$VistoriadoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cpf => $composableBuilder(
      column: $table.cpf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unidadeNome => $composableBuilder(
      column: $table.unidadeNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unidadeCnpj => $composableBuilder(
      column: $table.unidadeCnpj, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cargo => $composableBuilder(
      column: $table.cargo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$VistoriadoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $VistoriadoresTable> {
  $$VistoriadoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<String> get unidadeNome => $composableBuilder(
      column: $table.unidadeNome, builder: (column) => column);

  GeneratedColumn<String> get unidadeCnpj => $composableBuilder(
      column: $table.unidadeCnpj, builder: (column) => column);

  GeneratedColumn<String> get cargo =>
      $composableBuilder(column: $table.cargo, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VistoriadoresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VistoriadoresTable,
    Vistoriadore,
    $$VistoriadoresTableFilterComposer,
    $$VistoriadoresTableOrderingComposer,
    $$VistoriadoresTableAnnotationComposer,
    $$VistoriadoresTableCreateCompanionBuilder,
    $$VistoriadoresTableUpdateCompanionBuilder,
    (
      Vistoriadore,
      BaseReferences<_$AppDatabase, $VistoriadoresTable, Vistoriadore>
    ),
    Vistoriadore,
    PrefetchHooks Function()> {
  $$VistoriadoresTableTableManager(_$AppDatabase db, $VistoriadoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VistoriadoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VistoriadoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VistoriadoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> cpf = const Value.absent(),
            Value<String> unidadeNome = const Value.absent(),
            Value<String?> unidadeCnpj = const Value.absent(),
            Value<String> cargo = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VistoriadoresCompanion(
            id: id,
            nome: nome,
            cpf: cpf,
            unidadeNome: unidadeNome,
            unidadeCnpj: unidadeCnpj,
            cargo: cargo,
            ativo: ativo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String nome,
            required String cpf,
            required String unidadeNome,
            Value<String?> unidadeCnpj = const Value.absent(),
            Value<String> cargo = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VistoriadoresCompanion.insert(
            id: id,
            nome: nome,
            cpf: cpf,
            unidadeNome: unidadeNome,
            unidadeCnpj: unidadeCnpj,
            cargo: cargo,
            ativo: ativo,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VistoriadoresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VistoriadoresTable,
    Vistoriadore,
    $$VistoriadoresTableFilterComposer,
    $$VistoriadoresTableOrderingComposer,
    $$VistoriadoresTableAnnotationComposer,
    $$VistoriadoresTableCreateCompanionBuilder,
    $$VistoriadoresTableUpdateCompanionBuilder,
    (
      Vistoriadore,
      BaseReferences<_$AppDatabase, $VistoriadoresTable, Vistoriadore>
    ),
    Vistoriadore,
    PrefetchHooks Function()>;
typedef $$VistoriasTableCreateCompanionBuilder = VistoriasCompanion Function({
  required String id,
  required String numeroLaudo,
  Value<String> status,
  Value<String> tipoVistoria,
  Value<String?> clienteNome,
  Value<String?> unidade,
  Value<String?> parecerTecnico,
  Value<String?> statusFinal,
  Value<String?> assinaturaPath,
  Value<DateTime> dataHora,
  required String vistoriadorId,
  Value<String?> vistoriadorNome,
  Value<String?> vistoriadorCpf,
  Value<String?> observacoesGerais,
  Value<String?> pdfUrl,
  Value<int> etapaAtual,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$VistoriasTableUpdateCompanionBuilder = VistoriasCompanion Function({
  Value<String> id,
  Value<String> numeroLaudo,
  Value<String> status,
  Value<String> tipoVistoria,
  Value<String?> clienteNome,
  Value<String?> unidade,
  Value<String?> parecerTecnico,
  Value<String?> statusFinal,
  Value<String?> assinaturaPath,
  Value<DateTime> dataHora,
  Value<String> vistoriadorId,
  Value<String?> vistoriadorNome,
  Value<String?> vistoriadorCpf,
  Value<String?> observacoesGerais,
  Value<String?> pdfUrl,
  Value<int> etapaAtual,
  Value<bool> sincronizado,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$VistoriasTableReferences
    extends BaseReferences<_$AppDatabase, $VistoriasTable, Vistoria> {
  $$VistoriasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VeiculosTable, List<Veiculo>> _veiculosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.veiculos,
          aliasName:
              $_aliasNameGenerator(db.vistorias.id, db.veiculos.vistoriaId));

  $$VeiculosTableProcessedTableManager get veiculosRefs {
    final manager = $$VeiculosTableTableManager($_db, $_db.veiculos)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_veiculosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItensVistoriaTable, List<ItensVistoriaData>>
      _itensVistoriaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.itensVistoria,
              aliasName: $_aliasNameGenerator(
                  db.vistorias.id, db.itensVistoria.vistoriaId));

  $$ItensVistoriaTableProcessedTableManager get itensVistoriaRefs {
    final manager = $$ItensVistoriaTableTableManager($_db, $_db.itensVistoria)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itensVistoriaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FotosVistoriaTable, List<FotosVistoriaData>>
      _fotosVistoriaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.fotosVistoria,
              aliasName: $_aliasNameGenerator(
                  db.vistorias.id, db.fotosVistoria.vistoriaId));

  $$FotosVistoriaTableProcessedTableManager get fotosVistoriaRefs {
    final manager = $$FotosVistoriaTableTableManager($_db, $_db.fotosVistoria)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_fotosVistoriaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItensPinturaTable, List<ItensPinturaData>>
      _itensPinturaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.itensPintura,
              aliasName: $_aliasNameGenerator(
                  db.vistorias.id, db.itensPintura.vistoriaId));

  $$ItensPinturaTableProcessedTableManager get itensPinturaRefs {
    final manager = $$ItensPinturaTableTableManager($_db, $_db.itensPintura)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itensPinturaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItensEstruturaTable, List<ItensEstruturaData>>
      _itensEstruturaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.itensEstrutura,
              aliasName: $_aliasNameGenerator(
                  db.vistorias.id, db.itensEstrutura.vistoriaId));

  $$ItensEstruturaTableProcessedTableManager get itensEstruturaRefs {
    final manager = $$ItensEstruturaTableTableManager($_db, $_db.itensEstrutura)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itensEstruturaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$VidrosVistoriaTable, List<VidrosVistoriaData>>
      _vidrosVistoriaRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vidrosVistoria,
              aliasName: $_aliasNameGenerator(
                  db.vistorias.id, db.vidrosVistoria.vistoriaId));

  $$VidrosVistoriaTableProcessedTableManager get vidrosVistoriaRefs {
    final manager = $$VidrosVistoriaTableTableManager($_db, $_db.vidrosVistoria)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vidrosVistoriaRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ConsultasAutocredTable,
      List<ConsultasAutocredData>> _consultasAutocredRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.consultasAutocred,
          aliasName: $_aliasNameGenerator(
              db.vistorias.id, db.consultasAutocred.vistoriaId));

  $$ConsultasAutocredTableProcessedTableManager get consultasAutocredRefs {
    final manager = $$ConsultasAutocredTableTableManager(
            $_db, $_db.consultasAutocred)
        .filter((f) => f.vistoriaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_consultasAutocredRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VistoriasTableFilterComposer
    extends Composer<_$AppDatabase, $VistoriasTable> {
  $$VistoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numeroLaudo => $composableBuilder(
      column: $table.numeroLaudo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipoVistoria => $composableBuilder(
      column: $table.tipoVistoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unidade => $composableBuilder(
      column: $table.unidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parecerTecnico => $composableBuilder(
      column: $table.parecerTecnico,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statusFinal => $composableBuilder(
      column: $table.statusFinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assinaturaPath => $composableBuilder(
      column: $table.assinaturaPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dataHora => $composableBuilder(
      column: $table.dataHora, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vistoriadorId => $composableBuilder(
      column: $table.vistoriadorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vistoriadorNome => $composableBuilder(
      column: $table.vistoriadorNome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vistoriadorCpf => $composableBuilder(
      column: $table.vistoriadorCpf,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoesGerais => $composableBuilder(
      column: $table.observacoesGerais,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pdfUrl => $composableBuilder(
      column: $table.pdfUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get etapaAtual => $composableBuilder(
      column: $table.etapaAtual, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> veiculosRefs(
      Expression<bool> Function($$VeiculosTableFilterComposer f) f) {
    final $$VeiculosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.veiculos,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VeiculosTableFilterComposer(
              $db: $db,
              $table: $db.veiculos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itensVistoriaRefs(
      Expression<bool> Function($$ItensVistoriaTableFilterComposer f) f) {
    final $$ItensVistoriaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensVistoriaTableFilterComposer(
              $db: $db,
              $table: $db.itensVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> fotosVistoriaRefs(
      Expression<bool> Function($$FotosVistoriaTableFilterComposer f) f) {
    final $$FotosVistoriaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fotosVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FotosVistoriaTableFilterComposer(
              $db: $db,
              $table: $db.fotosVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itensPinturaRefs(
      Expression<bool> Function($$ItensPinturaTableFilterComposer f) f) {
    final $$ItensPinturaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPintura,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPinturaTableFilterComposer(
              $db: $db,
              $table: $db.itensPintura,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itensEstruturaRefs(
      Expression<bool> Function($$ItensEstruturaTableFilterComposer f) f) {
    final $$ItensEstruturaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensEstrutura,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensEstruturaTableFilterComposer(
              $db: $db,
              $table: $db.itensEstrutura,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> vidrosVistoriaRefs(
      Expression<bool> Function($$VidrosVistoriaTableFilterComposer f) f) {
    final $$VidrosVistoriaTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vidrosVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VidrosVistoriaTableFilterComposer(
              $db: $db,
              $table: $db.vidrosVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> consultasAutocredRefs(
      Expression<bool> Function($$ConsultasAutocredTableFilterComposer f) f) {
    final $$ConsultasAutocredTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.consultasAutocred,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConsultasAutocredTableFilterComposer(
              $db: $db,
              $table: $db.consultasAutocred,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VistoriasTableOrderingComposer
    extends Composer<_$AppDatabase, $VistoriasTable> {
  $$VistoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numeroLaudo => $composableBuilder(
      column: $table.numeroLaudo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipoVistoria => $composableBuilder(
      column: $table.tipoVistoria,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unidade => $composableBuilder(
      column: $table.unidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parecerTecnico => $composableBuilder(
      column: $table.parecerTecnico,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statusFinal => $composableBuilder(
      column: $table.statusFinal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assinaturaPath => $composableBuilder(
      column: $table.assinaturaPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dataHora => $composableBuilder(
      column: $table.dataHora, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vistoriadorId => $composableBuilder(
      column: $table.vistoriadorId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vistoriadorNome => $composableBuilder(
      column: $table.vistoriadorNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vistoriadorCpf => $composableBuilder(
      column: $table.vistoriadorCpf,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoesGerais => $composableBuilder(
      column: $table.observacoesGerais,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pdfUrl => $composableBuilder(
      column: $table.pdfUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get etapaAtual => $composableBuilder(
      column: $table.etapaAtual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VistoriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VistoriasTable> {
  $$VistoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get numeroLaudo => $composableBuilder(
      column: $table.numeroLaudo, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get tipoVistoria => $composableBuilder(
      column: $table.tipoVistoria, builder: (column) => column);

  GeneratedColumn<String> get clienteNome => $composableBuilder(
      column: $table.clienteNome, builder: (column) => column);

  GeneratedColumn<String> get unidade =>
      $composableBuilder(column: $table.unidade, builder: (column) => column);

  GeneratedColumn<String> get parecerTecnico => $composableBuilder(
      column: $table.parecerTecnico, builder: (column) => column);

  GeneratedColumn<String> get statusFinal => $composableBuilder(
      column: $table.statusFinal, builder: (column) => column);

  GeneratedColumn<String> get assinaturaPath => $composableBuilder(
      column: $table.assinaturaPath, builder: (column) => column);

  GeneratedColumn<DateTime> get dataHora =>
      $composableBuilder(column: $table.dataHora, builder: (column) => column);

  GeneratedColumn<String> get vistoriadorId => $composableBuilder(
      column: $table.vistoriadorId, builder: (column) => column);

  GeneratedColumn<String> get vistoriadorNome => $composableBuilder(
      column: $table.vistoriadorNome, builder: (column) => column);

  GeneratedColumn<String> get vistoriadorCpf => $composableBuilder(
      column: $table.vistoriadorCpf, builder: (column) => column);

  GeneratedColumn<String> get observacoesGerais => $composableBuilder(
      column: $table.observacoesGerais, builder: (column) => column);

  GeneratedColumn<String> get pdfUrl =>
      $composableBuilder(column: $table.pdfUrl, builder: (column) => column);

  GeneratedColumn<int> get etapaAtual => $composableBuilder(
      column: $table.etapaAtual, builder: (column) => column);

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> veiculosRefs<T extends Object>(
      Expression<T> Function($$VeiculosTableAnnotationComposer a) f) {
    final $$VeiculosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.veiculos,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VeiculosTableAnnotationComposer(
              $db: $db,
              $table: $db.veiculos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itensVistoriaRefs<T extends Object>(
      Expression<T> Function($$ItensVistoriaTableAnnotationComposer a) f) {
    final $$ItensVistoriaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensVistoriaTableAnnotationComposer(
              $db: $db,
              $table: $db.itensVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> fotosVistoriaRefs<T extends Object>(
      Expression<T> Function($$FotosVistoriaTableAnnotationComposer a) f) {
    final $$FotosVistoriaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fotosVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FotosVistoriaTableAnnotationComposer(
              $db: $db,
              $table: $db.fotosVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itensPinturaRefs<T extends Object>(
      Expression<T> Function($$ItensPinturaTableAnnotationComposer a) f) {
    final $$ItensPinturaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensPintura,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensPinturaTableAnnotationComposer(
              $db: $db,
              $table: $db.itensPintura,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itensEstruturaRefs<T extends Object>(
      Expression<T> Function($$ItensEstruturaTableAnnotationComposer a) f) {
    final $$ItensEstruturaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itensEstrutura,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItensEstruturaTableAnnotationComposer(
              $db: $db,
              $table: $db.itensEstrutura,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> vidrosVistoriaRefs<T extends Object>(
      Expression<T> Function($$VidrosVistoriaTableAnnotationComposer a) f) {
    final $$VidrosVistoriaTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vidrosVistoria,
        getReferencedColumn: (t) => t.vistoriaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VidrosVistoriaTableAnnotationComposer(
              $db: $db,
              $table: $db.vidrosVistoria,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> consultasAutocredRefs<T extends Object>(
      Expression<T> Function($$ConsultasAutocredTableAnnotationComposer a) f) {
    final $$ConsultasAutocredTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.consultasAutocred,
            getReferencedColumn: (t) => t.vistoriaId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ConsultasAutocredTableAnnotationComposer(
                  $db: $db,
                  $table: $db.consultasAutocred,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$VistoriasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VistoriasTable,
    Vistoria,
    $$VistoriasTableFilterComposer,
    $$VistoriasTableOrderingComposer,
    $$VistoriasTableAnnotationComposer,
    $$VistoriasTableCreateCompanionBuilder,
    $$VistoriasTableUpdateCompanionBuilder,
    (Vistoria, $$VistoriasTableReferences),
    Vistoria,
    PrefetchHooks Function(
        {bool veiculosRefs,
        bool itensVistoriaRefs,
        bool fotosVistoriaRefs,
        bool itensPinturaRefs,
        bool itensEstruturaRefs,
        bool vidrosVistoriaRefs,
        bool consultasAutocredRefs})> {
  $$VistoriasTableTableManager(_$AppDatabase db, $VistoriasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VistoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VistoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VistoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> numeroLaudo = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> tipoVistoria = const Value.absent(),
            Value<String?> clienteNome = const Value.absent(),
            Value<String?> unidade = const Value.absent(),
            Value<String?> parecerTecnico = const Value.absent(),
            Value<String?> statusFinal = const Value.absent(),
            Value<String?> assinaturaPath = const Value.absent(),
            Value<DateTime> dataHora = const Value.absent(),
            Value<String> vistoriadorId = const Value.absent(),
            Value<String?> vistoriadorNome = const Value.absent(),
            Value<String?> vistoriadorCpf = const Value.absent(),
            Value<String?> observacoesGerais = const Value.absent(),
            Value<String?> pdfUrl = const Value.absent(),
            Value<int> etapaAtual = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VistoriasCompanion(
            id: id,
            numeroLaudo: numeroLaudo,
            status: status,
            tipoVistoria: tipoVistoria,
            clienteNome: clienteNome,
            unidade: unidade,
            parecerTecnico: parecerTecnico,
            statusFinal: statusFinal,
            assinaturaPath: assinaturaPath,
            dataHora: dataHora,
            vistoriadorId: vistoriadorId,
            vistoriadorNome: vistoriadorNome,
            vistoriadorCpf: vistoriadorCpf,
            observacoesGerais: observacoesGerais,
            pdfUrl: pdfUrl,
            etapaAtual: etapaAtual,
            sincronizado: sincronizado,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String numeroLaudo,
            Value<String> status = const Value.absent(),
            Value<String> tipoVistoria = const Value.absent(),
            Value<String?> clienteNome = const Value.absent(),
            Value<String?> unidade = const Value.absent(),
            Value<String?> parecerTecnico = const Value.absent(),
            Value<String?> statusFinal = const Value.absent(),
            Value<String?> assinaturaPath = const Value.absent(),
            Value<DateTime> dataHora = const Value.absent(),
            required String vistoriadorId,
            Value<String?> vistoriadorNome = const Value.absent(),
            Value<String?> vistoriadorCpf = const Value.absent(),
            Value<String?> observacoesGerais = const Value.absent(),
            Value<String?> pdfUrl = const Value.absent(),
            Value<int> etapaAtual = const Value.absent(),
            Value<bool> sincronizado = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VistoriasCompanion.insert(
            id: id,
            numeroLaudo: numeroLaudo,
            status: status,
            tipoVistoria: tipoVistoria,
            clienteNome: clienteNome,
            unidade: unidade,
            parecerTecnico: parecerTecnico,
            statusFinal: statusFinal,
            assinaturaPath: assinaturaPath,
            dataHora: dataHora,
            vistoriadorId: vistoriadorId,
            vistoriadorNome: vistoriadorNome,
            vistoriadorCpf: vistoriadorCpf,
            observacoesGerais: observacoesGerais,
            pdfUrl: pdfUrl,
            etapaAtual: etapaAtual,
            sincronizado: sincronizado,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VistoriasTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {veiculosRefs = false,
              itensVistoriaRefs = false,
              fotosVistoriaRefs = false,
              itensPinturaRefs = false,
              itensEstruturaRefs = false,
              vidrosVistoriaRefs = false,
              consultasAutocredRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (veiculosRefs) db.veiculos,
                if (itensVistoriaRefs) db.itensVistoria,
                if (fotosVistoriaRefs) db.fotosVistoria,
                if (itensPinturaRefs) db.itensPintura,
                if (itensEstruturaRefs) db.itensEstrutura,
                if (vidrosVistoriaRefs) db.vidrosVistoria,
                if (consultasAutocredRefs) db.consultasAutocred
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (veiculosRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            Veiculo>(
                        currentTable: table,
                        referencedTable:
                            $$VistoriasTableReferences._veiculosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .veiculosRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (itensVistoriaRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            ItensVistoriaData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._itensVistoriaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .itensVistoriaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (fotosVistoriaRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            FotosVistoriaData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._fotosVistoriaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .fotosVistoriaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (itensPinturaRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            ItensPinturaData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._itensPinturaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .itensPinturaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (itensEstruturaRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            ItensEstruturaData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._itensEstruturaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .itensEstruturaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (vidrosVistoriaRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            VidrosVistoriaData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._vidrosVistoriaRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .vidrosVistoriaRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items),
                  if (consultasAutocredRefs)
                    await $_getPrefetchedData<Vistoria, $VistoriasTable,
                            ConsultasAutocredData>(
                        currentTable: table,
                        referencedTable: $$VistoriasTableReferences
                            ._consultasAutocredRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VistoriasTableReferences(db, table, p0)
                                .consultasAutocredRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vistoriaId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$VistoriasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VistoriasTable,
    Vistoria,
    $$VistoriasTableFilterComposer,
    $$VistoriasTableOrderingComposer,
    $$VistoriasTableAnnotationComposer,
    $$VistoriasTableCreateCompanionBuilder,
    $$VistoriasTableUpdateCompanionBuilder,
    (Vistoria, $$VistoriasTableReferences),
    Vistoria,
    PrefetchHooks Function(
        {bool veiculosRefs,
        bool itensVistoriaRefs,
        bool fotosVistoriaRefs,
        bool itensPinturaRefs,
        bool itensEstruturaRefs,
        bool vidrosVistoriaRefs,
        bool consultasAutocredRefs})>;
typedef $$VeiculosTableCreateCompanionBuilder = VeiculosCompanion Function({
  required String id,
  required String vistoriaId,
  required String placa,
  Value<String?> chassiVeiculo,
  Value<String?> chassiBin,
  Value<String?> motorVeiculo,
  Value<String?> motorBin,
  Value<String?> cambioVeiculo,
  Value<String?> cambioBin,
  Value<String?> renavam,
  Value<String?> marca,
  Value<String?> modelo,
  Value<int?> anoFabricacao,
  Value<int?> anoModelo,
  Value<String?> cor,
  Value<String?> combustivel,
  Value<int?> km,
  Value<String?> municipio,
  Value<String?> uf,
  Value<String?> numeroGrv,
  Value<String> tipo,
  Value<bool> motorDivergente,
  Value<bool> chassiDivergente,
  Value<bool> cambioDivergente,
  Value<int> rowid,
});
typedef $$VeiculosTableUpdateCompanionBuilder = VeiculosCompanion Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String> placa,
  Value<String?> chassiVeiculo,
  Value<String?> chassiBin,
  Value<String?> motorVeiculo,
  Value<String?> motorBin,
  Value<String?> cambioVeiculo,
  Value<String?> cambioBin,
  Value<String?> renavam,
  Value<String?> marca,
  Value<String?> modelo,
  Value<int?> anoFabricacao,
  Value<int?> anoModelo,
  Value<String?> cor,
  Value<String?> combustivel,
  Value<int?> km,
  Value<String?> municipio,
  Value<String?> uf,
  Value<String?> numeroGrv,
  Value<String> tipo,
  Value<bool> motorDivergente,
  Value<bool> chassiDivergente,
  Value<bool> cambioDivergente,
  Value<int> rowid,
});

final class $$VeiculosTableReferences
    extends BaseReferences<_$AppDatabase, $VeiculosTable, Veiculo> {
  $$VeiculosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.veiculos.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VeiculosTableFilterComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chassiVeiculo => $composableBuilder(
      column: $table.chassiVeiculo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chassiBin => $composableBuilder(
      column: $table.chassiBin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motorVeiculo => $composableBuilder(
      column: $table.motorVeiculo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motorBin => $composableBuilder(
      column: $table.motorBin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cambioVeiculo => $composableBuilder(
      column: $table.cambioVeiculo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cambioBin => $composableBuilder(
      column: $table.cambioBin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get renavam => $composableBuilder(
      column: $table.renavam, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anoModelo => $composableBuilder(
      column: $table.anoModelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get km => $composableBuilder(
      column: $table.km, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipio => $composableBuilder(
      column: $table.municipio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uf => $composableBuilder(
      column: $table.uf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get numeroGrv => $composableBuilder(
      column: $table.numeroGrv, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get motorDivergente => $composableBuilder(
      column: $table.motorDivergente,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get chassiDivergente => $composableBuilder(
      column: $table.chassiDivergente,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get cambioDivergente => $composableBuilder(
      column: $table.cambioDivergente,
      builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VeiculosTableOrderingComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chassiVeiculo => $composableBuilder(
      column: $table.chassiVeiculo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chassiBin => $composableBuilder(
      column: $table.chassiBin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motorVeiculo => $composableBuilder(
      column: $table.motorVeiculo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motorBin => $composableBuilder(
      column: $table.motorBin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cambioVeiculo => $composableBuilder(
      column: $table.cambioVeiculo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cambioBin => $composableBuilder(
      column: $table.cambioBin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get renavam => $composableBuilder(
      column: $table.renavam, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anoModelo => $composableBuilder(
      column: $table.anoModelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get km => $composableBuilder(
      column: $table.km, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipio => $composableBuilder(
      column: $table.municipio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uf => $composableBuilder(
      column: $table.uf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get numeroGrv => $composableBuilder(
      column: $table.numeroGrv, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get motorDivergente => $composableBuilder(
      column: $table.motorDivergente,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get chassiDivergente => $composableBuilder(
      column: $table.chassiDivergente,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get cambioDivergente => $composableBuilder(
      column: $table.cambioDivergente,
      builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VeiculosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get placa =>
      $composableBuilder(column: $table.placa, builder: (column) => column);

  GeneratedColumn<String> get chassiVeiculo => $composableBuilder(
      column: $table.chassiVeiculo, builder: (column) => column);

  GeneratedColumn<String> get chassiBin =>
      $composableBuilder(column: $table.chassiBin, builder: (column) => column);

  GeneratedColumn<String> get motorVeiculo => $composableBuilder(
      column: $table.motorVeiculo, builder: (column) => column);

  GeneratedColumn<String> get motorBin =>
      $composableBuilder(column: $table.motorBin, builder: (column) => column);

  GeneratedColumn<String> get cambioVeiculo => $composableBuilder(
      column: $table.cambioVeiculo, builder: (column) => column);

  GeneratedColumn<String> get cambioBin =>
      $composableBuilder(column: $table.cambioBin, builder: (column) => column);

  GeneratedColumn<String> get renavam =>
      $composableBuilder(column: $table.renavam, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao, builder: (column) => column);

  GeneratedColumn<int> get anoModelo =>
      $composableBuilder(column: $table.anoModelo, builder: (column) => column);

  GeneratedColumn<String> get cor =>
      $composableBuilder(column: $table.cor, builder: (column) => column);

  GeneratedColumn<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => column);

  GeneratedColumn<int> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumn<String> get municipio =>
      $composableBuilder(column: $table.municipio, builder: (column) => column);

  GeneratedColumn<String> get uf =>
      $composableBuilder(column: $table.uf, builder: (column) => column);

  GeneratedColumn<String> get numeroGrv =>
      $composableBuilder(column: $table.numeroGrv, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<bool> get motorDivergente => $composableBuilder(
      column: $table.motorDivergente, builder: (column) => column);

  GeneratedColumn<bool> get chassiDivergente => $composableBuilder(
      column: $table.chassiDivergente, builder: (column) => column);

  GeneratedColumn<bool> get cambioDivergente => $composableBuilder(
      column: $table.cambioDivergente, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VeiculosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VeiculosTable,
    Veiculo,
    $$VeiculosTableFilterComposer,
    $$VeiculosTableOrderingComposer,
    $$VeiculosTableAnnotationComposer,
    $$VeiculosTableCreateCompanionBuilder,
    $$VeiculosTableUpdateCompanionBuilder,
    (Veiculo, $$VeiculosTableReferences),
    Veiculo,
    PrefetchHooks Function({bool vistoriaId})> {
  $$VeiculosTableTableManager(_$AppDatabase db, $VeiculosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VeiculosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VeiculosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VeiculosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String> placa = const Value.absent(),
            Value<String?> chassiVeiculo = const Value.absent(),
            Value<String?> chassiBin = const Value.absent(),
            Value<String?> motorVeiculo = const Value.absent(),
            Value<String?> motorBin = const Value.absent(),
            Value<String?> cambioVeiculo = const Value.absent(),
            Value<String?> cambioBin = const Value.absent(),
            Value<String?> renavam = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<int?> anoFabricacao = const Value.absent(),
            Value<int?> anoModelo = const Value.absent(),
            Value<String?> cor = const Value.absent(),
            Value<String?> combustivel = const Value.absent(),
            Value<int?> km = const Value.absent(),
            Value<String?> municipio = const Value.absent(),
            Value<String?> uf = const Value.absent(),
            Value<String?> numeroGrv = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<bool> motorDivergente = const Value.absent(),
            Value<bool> chassiDivergente = const Value.absent(),
            Value<bool> cambioDivergente = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VeiculosCompanion(
            id: id,
            vistoriaId: vistoriaId,
            placa: placa,
            chassiVeiculo: chassiVeiculo,
            chassiBin: chassiBin,
            motorVeiculo: motorVeiculo,
            motorBin: motorBin,
            cambioVeiculo: cambioVeiculo,
            cambioBin: cambioBin,
            renavam: renavam,
            marca: marca,
            modelo: modelo,
            anoFabricacao: anoFabricacao,
            anoModelo: anoModelo,
            cor: cor,
            combustivel: combustivel,
            km: km,
            municipio: municipio,
            uf: uf,
            numeroGrv: numeroGrv,
            tipo: tipo,
            motorDivergente: motorDivergente,
            chassiDivergente: chassiDivergente,
            cambioDivergente: cambioDivergente,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            required String placa,
            Value<String?> chassiVeiculo = const Value.absent(),
            Value<String?> chassiBin = const Value.absent(),
            Value<String?> motorVeiculo = const Value.absent(),
            Value<String?> motorBin = const Value.absent(),
            Value<String?> cambioVeiculo = const Value.absent(),
            Value<String?> cambioBin = const Value.absent(),
            Value<String?> renavam = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<int?> anoFabricacao = const Value.absent(),
            Value<int?> anoModelo = const Value.absent(),
            Value<String?> cor = const Value.absent(),
            Value<String?> combustivel = const Value.absent(),
            Value<int?> km = const Value.absent(),
            Value<String?> municipio = const Value.absent(),
            Value<String?> uf = const Value.absent(),
            Value<String?> numeroGrv = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<bool> motorDivergente = const Value.absent(),
            Value<bool> chassiDivergente = const Value.absent(),
            Value<bool> cambioDivergente = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VeiculosCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            placa: placa,
            chassiVeiculo: chassiVeiculo,
            chassiBin: chassiBin,
            motorVeiculo: motorVeiculo,
            motorBin: motorBin,
            cambioVeiculo: cambioVeiculo,
            cambioBin: cambioBin,
            renavam: renavam,
            marca: marca,
            modelo: modelo,
            anoFabricacao: anoFabricacao,
            anoModelo: anoModelo,
            cor: cor,
            combustivel: combustivel,
            km: km,
            municipio: municipio,
            uf: uf,
            numeroGrv: numeroGrv,
            tipo: tipo,
            motorDivergente: motorDivergente,
            chassiDivergente: chassiDivergente,
            cambioDivergente: cambioDivergente,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VeiculosTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$VeiculosTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$VeiculosTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VeiculosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VeiculosTable,
    Veiculo,
    $$VeiculosTableFilterComposer,
    $$VeiculosTableOrderingComposer,
    $$VeiculosTableAnnotationComposer,
    $$VeiculosTableCreateCompanionBuilder,
    $$VeiculosTableUpdateCompanionBuilder,
    (Veiculo, $$VeiculosTableReferences),
    Veiculo,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$ItensVistoriaTableCreateCompanionBuilder = ItensVistoriaCompanion
    Function({
  required String id,
  required String vistoriaId,
  required String categoria,
  required String nome,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> etapa,
  Value<int> ordem,
  Value<int> rowid,
});
typedef $$ItensVistoriaTableUpdateCompanionBuilder = ItensVistoriaCompanion
    Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String> categoria,
  Value<String> nome,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> etapa,
  Value<int> ordem,
  Value<int> rowid,
});

final class $$ItensVistoriaTableReferences extends BaseReferences<_$AppDatabase,
    $ItensVistoriaTable, ItensVistoriaData> {
  $$ItensVistoriaTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.itensVistoria.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItensVistoriaTableFilterComposer
    extends Composer<_$AppDatabase, $ItensVistoriaTable> {
  $$ItensVistoriaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etapa => $composableBuilder(
      column: $table.etapa, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensVistoriaTableOrderingComposer
    extends Composer<_$AppDatabase, $ItensVistoriaTable> {
  $$ItensVistoriaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoria => $composableBuilder(
      column: $table.categoria, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etapa => $composableBuilder(
      column: $table.etapa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensVistoriaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItensVistoriaTable> {
  $$ItensVistoriaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => column);

  GeneratedColumn<String> get etapa =>
      $composableBuilder(column: $table.etapa, builder: (column) => column);

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensVistoriaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItensVistoriaTable,
    ItensVistoriaData,
    $$ItensVistoriaTableFilterComposer,
    $$ItensVistoriaTableOrderingComposer,
    $$ItensVistoriaTableAnnotationComposer,
    $$ItensVistoriaTableCreateCompanionBuilder,
    $$ItensVistoriaTableUpdateCompanionBuilder,
    (ItensVistoriaData, $$ItensVistoriaTableReferences),
    ItensVistoriaData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$ItensVistoriaTableTableManager(_$AppDatabase db, $ItensVistoriaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItensVistoriaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItensVistoriaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItensVistoriaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String> categoria = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> etapa = const Value.absent(),
            Value<int> ordem = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensVistoriaCompanion(
            id: id,
            vistoriaId: vistoriaId,
            categoria: categoria,
            nome: nome,
            status: status,
            observacao: observacao,
            etapa: etapa,
            ordem: ordem,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            required String categoria,
            required String nome,
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> etapa = const Value.absent(),
            Value<int> ordem = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensVistoriaCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            categoria: categoria,
            nome: nome,
            status: status,
            observacao: observacao,
            etapa: etapa,
            ordem: ordem,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItensVistoriaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$ItensVistoriaTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$ItensVistoriaTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItensVistoriaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItensVistoriaTable,
    ItensVistoriaData,
    $$ItensVistoriaTableFilterComposer,
    $$ItensVistoriaTableOrderingComposer,
    $$ItensVistoriaTableAnnotationComposer,
    $$ItensVistoriaTableCreateCompanionBuilder,
    $$ItensVistoriaTableUpdateCompanionBuilder,
    (ItensVistoriaData, $$ItensVistoriaTableReferences),
    ItensVistoriaData,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$FotosVistoriaTableCreateCompanionBuilder = FotosVistoriaCompanion
    Function({
  required String id,
  required String vistoriaId,
  Value<String?> itemId,
  required String legenda,
  Value<String?> etapa,
  Value<String?> statusFoto,
  Value<String?> observacao,
  Value<bool> obrigatoria,
  Value<String?> pathLocal,
  Value<String?> urlSupabase,
  Value<String?> storagePath,
  Value<int> ordem,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$FotosVistoriaTableUpdateCompanionBuilder = FotosVistoriaCompanion
    Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String?> itemId,
  Value<String> legenda,
  Value<String?> etapa,
  Value<String?> statusFoto,
  Value<String?> observacao,
  Value<bool> obrigatoria,
  Value<String?> pathLocal,
  Value<String?> urlSupabase,
  Value<String?> storagePath,
  Value<int> ordem,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FotosVistoriaTableReferences extends BaseReferences<_$AppDatabase,
    $FotosVistoriaTable, FotosVistoriaData> {
  $$FotosVistoriaTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.fotosVistoria.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FotosVistoriaTableFilterComposer
    extends Composer<_$AppDatabase, $FotosVistoriaTable> {
  $$FotosVistoriaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get legenda => $composableBuilder(
      column: $table.legenda, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get etapa => $composableBuilder(
      column: $table.etapa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statusFoto => $composableBuilder(
      column: $table.statusFoto, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get obrigatoria => $composableBuilder(
      column: $table.obrigatoria, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pathLocal => $composableBuilder(
      column: $table.pathLocal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get urlSupabase => $composableBuilder(
      column: $table.urlSupabase, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FotosVistoriaTableOrderingComposer
    extends Composer<_$AppDatabase, $FotosVistoriaTable> {
  $$FotosVistoriaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get legenda => $composableBuilder(
      column: $table.legenda, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get etapa => $composableBuilder(
      column: $table.etapa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statusFoto => $composableBuilder(
      column: $table.statusFoto, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get obrigatoria => $composableBuilder(
      column: $table.obrigatoria, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pathLocal => $composableBuilder(
      column: $table.pathLocal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get urlSupabase => $composableBuilder(
      column: $table.urlSupabase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FotosVistoriaTableAnnotationComposer
    extends Composer<_$AppDatabase, $FotosVistoriaTable> {
  $$FotosVistoriaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get legenda =>
      $composableBuilder(column: $table.legenda, builder: (column) => column);

  GeneratedColumn<String> get etapa =>
      $composableBuilder(column: $table.etapa, builder: (column) => column);

  GeneratedColumn<String> get statusFoto => $composableBuilder(
      column: $table.statusFoto, builder: (column) => column);

  GeneratedColumn<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => column);

  GeneratedColumn<bool> get obrigatoria => $composableBuilder(
      column: $table.obrigatoria, builder: (column) => column);

  GeneratedColumn<String> get pathLocal =>
      $composableBuilder(column: $table.pathLocal, builder: (column) => column);

  GeneratedColumn<String> get urlSupabase => $composableBuilder(
      column: $table.urlSupabase, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => column);

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FotosVistoriaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FotosVistoriaTable,
    FotosVistoriaData,
    $$FotosVistoriaTableFilterComposer,
    $$FotosVistoriaTableOrderingComposer,
    $$FotosVistoriaTableAnnotationComposer,
    $$FotosVistoriaTableCreateCompanionBuilder,
    $$FotosVistoriaTableUpdateCompanionBuilder,
    (FotosVistoriaData, $$FotosVistoriaTableReferences),
    FotosVistoriaData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$FotosVistoriaTableTableManager(_$AppDatabase db, $FotosVistoriaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FotosVistoriaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FotosVistoriaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FotosVistoriaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String?> itemId = const Value.absent(),
            Value<String> legenda = const Value.absent(),
            Value<String?> etapa = const Value.absent(),
            Value<String?> statusFoto = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<bool> obrigatoria = const Value.absent(),
            Value<String?> pathLocal = const Value.absent(),
            Value<String?> urlSupabase = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<int> ordem = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FotosVistoriaCompanion(
            id: id,
            vistoriaId: vistoriaId,
            itemId: itemId,
            legenda: legenda,
            etapa: etapa,
            statusFoto: statusFoto,
            observacao: observacao,
            obrigatoria: obrigatoria,
            pathLocal: pathLocal,
            urlSupabase: urlSupabase,
            storagePath: storagePath,
            ordem: ordem,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            Value<String?> itemId = const Value.absent(),
            required String legenda,
            Value<String?> etapa = const Value.absent(),
            Value<String?> statusFoto = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<bool> obrigatoria = const Value.absent(),
            Value<String?> pathLocal = const Value.absent(),
            Value<String?> urlSupabase = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<int> ordem = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FotosVistoriaCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            itemId: itemId,
            legenda: legenda,
            etapa: etapa,
            statusFoto: statusFoto,
            observacao: observacao,
            obrigatoria: obrigatoria,
            pathLocal: pathLocal,
            urlSupabase: urlSupabase,
            storagePath: storagePath,
            ordem: ordem,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FotosVistoriaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$FotosVistoriaTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$FotosVistoriaTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FotosVistoriaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FotosVistoriaTable,
    FotosVistoriaData,
    $$FotosVistoriaTableFilterComposer,
    $$FotosVistoriaTableOrderingComposer,
    $$FotosVistoriaTableAnnotationComposer,
    $$FotosVistoriaTableCreateCompanionBuilder,
    $$FotosVistoriaTableUpdateCompanionBuilder,
    (FotosVistoriaData, $$FotosVistoriaTableReferences),
    FotosVistoriaData,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$ItensPinturaTableCreateCompanionBuilder = ItensPinturaCompanion
    Function({
  required String id,
  required String vistoriaId,
  required String peca,
  Value<String> status,
  Value<int?> espessuraMicra,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});
typedef $$ItensPinturaTableUpdateCompanionBuilder = ItensPinturaCompanion
    Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String> peca,
  Value<String> status,
  Value<int?> espessuraMicra,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});

final class $$ItensPinturaTableReferences extends BaseReferences<_$AppDatabase,
    $ItensPinturaTable, ItensPinturaData> {
  $$ItensPinturaTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.itensPintura.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItensPinturaTableFilterComposer
    extends Composer<_$AppDatabase, $ItensPinturaTable> {
  $$ItensPinturaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peca => $composableBuilder(
      column: $table.peca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get espessuraMicra => $composableBuilder(
      column: $table.espessuraMicra,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPinturaTableOrderingComposer
    extends Composer<_$AppDatabase, $ItensPinturaTable> {
  $$ItensPinturaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peca => $composableBuilder(
      column: $table.peca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get espessuraMicra => $composableBuilder(
      column: $table.espessuraMicra,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPinturaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItensPinturaTable> {
  $$ItensPinturaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peca =>
      $composableBuilder(column: $table.peca, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get espessuraMicra => $composableBuilder(
      column: $table.espessuraMicra, builder: (column) => column);

  GeneratedColumn<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => column);

  GeneratedColumn<String> get fotoUrl =>
      $composableBuilder(column: $table.fotoUrl, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensPinturaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItensPinturaTable,
    ItensPinturaData,
    $$ItensPinturaTableFilterComposer,
    $$ItensPinturaTableOrderingComposer,
    $$ItensPinturaTableAnnotationComposer,
    $$ItensPinturaTableCreateCompanionBuilder,
    $$ItensPinturaTableUpdateCompanionBuilder,
    (ItensPinturaData, $$ItensPinturaTableReferences),
    ItensPinturaData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$ItensPinturaTableTableManager(_$AppDatabase db, $ItensPinturaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItensPinturaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItensPinturaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItensPinturaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String> peca = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> espessuraMicra = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensPinturaCompanion(
            id: id,
            vistoriaId: vistoriaId,
            peca: peca,
            status: status,
            espessuraMicra: espessuraMicra,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            required String peca,
            Value<String> status = const Value.absent(),
            Value<int?> espessuraMicra = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensPinturaCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            peca: peca,
            status: status,
            espessuraMicra: espessuraMicra,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItensPinturaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$ItensPinturaTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$ItensPinturaTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItensPinturaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItensPinturaTable,
    ItensPinturaData,
    $$ItensPinturaTableFilterComposer,
    $$ItensPinturaTableOrderingComposer,
    $$ItensPinturaTableAnnotationComposer,
    $$ItensPinturaTableCreateCompanionBuilder,
    $$ItensPinturaTableUpdateCompanionBuilder,
    (ItensPinturaData, $$ItensPinturaTableReferences),
    ItensPinturaData,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$ItensEstruturaTableCreateCompanionBuilder = ItensEstruturaCompanion
    Function({
  required String id,
  required String vistoriaId,
  required String peca,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});
typedef $$ItensEstruturaTableUpdateCompanionBuilder = ItensEstruturaCompanion
    Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String> peca,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});

final class $$ItensEstruturaTableReferences extends BaseReferences<
    _$AppDatabase, $ItensEstruturaTable, ItensEstruturaData> {
  $$ItensEstruturaTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.itensEstrutura.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItensEstruturaTableFilterComposer
    extends Composer<_$AppDatabase, $ItensEstruturaTable> {
  $$ItensEstruturaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peca => $composableBuilder(
      column: $table.peca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensEstruturaTableOrderingComposer
    extends Composer<_$AppDatabase, $ItensEstruturaTable> {
  $$ItensEstruturaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peca => $composableBuilder(
      column: $table.peca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensEstruturaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItensEstruturaTable> {
  $$ItensEstruturaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peca =>
      $composableBuilder(column: $table.peca, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => column);

  GeneratedColumn<String> get fotoUrl =>
      $composableBuilder(column: $table.fotoUrl, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItensEstruturaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItensEstruturaTable,
    ItensEstruturaData,
    $$ItensEstruturaTableFilterComposer,
    $$ItensEstruturaTableOrderingComposer,
    $$ItensEstruturaTableAnnotationComposer,
    $$ItensEstruturaTableCreateCompanionBuilder,
    $$ItensEstruturaTableUpdateCompanionBuilder,
    (ItensEstruturaData, $$ItensEstruturaTableReferences),
    ItensEstruturaData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$ItensEstruturaTableTableManager(
      _$AppDatabase db, $ItensEstruturaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItensEstruturaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItensEstruturaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItensEstruturaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String> peca = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensEstruturaCompanion(
            id: id,
            vistoriaId: vistoriaId,
            peca: peca,
            status: status,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            required String peca,
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItensEstruturaCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            peca: peca,
            status: status,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItensEstruturaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$ItensEstruturaTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$ItensEstruturaTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItensEstruturaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItensEstruturaTable,
    ItensEstruturaData,
    $$ItensEstruturaTableFilterComposer,
    $$ItensEstruturaTableOrderingComposer,
    $$ItensEstruturaTableAnnotationComposer,
    $$ItensEstruturaTableCreateCompanionBuilder,
    $$ItensEstruturaTableUpdateCompanionBuilder,
    (ItensEstruturaData, $$ItensEstruturaTableReferences),
    ItensEstruturaData,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$VidrosVistoriaTableCreateCompanionBuilder = VidrosVistoriaCompanion
    Function({
  required String id,
  required String vistoriaId,
  required String posicao,
  Value<String?> codigoEncontrado,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});
typedef $$VidrosVistoriaTableUpdateCompanionBuilder = VidrosVistoriaCompanion
    Function({
  Value<String> id,
  Value<String> vistoriaId,
  Value<String> posicao,
  Value<String?> codigoEncontrado,
  Value<String> status,
  Value<String?> observacao,
  Value<String?> fotoUrl,
  Value<int> rowid,
});

final class $$VidrosVistoriaTableReferences extends BaseReferences<
    _$AppDatabase, $VidrosVistoriaTable, VidrosVistoriaData> {
  $$VidrosVistoriaTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias(
          $_aliasNameGenerator(db.vidrosVistoria.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id')!;

    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VidrosVistoriaTableFilterComposer
    extends Composer<_$AppDatabase, $VidrosVistoriaTable> {
  $$VidrosVistoriaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posicao => $composableBuilder(
      column: $table.posicao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get codigoEncontrado => $composableBuilder(
      column: $table.codigoEncontrado,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VidrosVistoriaTableOrderingComposer
    extends Composer<_$AppDatabase, $VidrosVistoriaTable> {
  $$VidrosVistoriaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posicao => $composableBuilder(
      column: $table.posicao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get codigoEncontrado => $composableBuilder(
      column: $table.codigoEncontrado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoUrl => $composableBuilder(
      column: $table.fotoUrl, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VidrosVistoriaTableAnnotationComposer
    extends Composer<_$AppDatabase, $VidrosVistoriaTable> {
  $$VidrosVistoriaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get posicao =>
      $composableBuilder(column: $table.posicao, builder: (column) => column);

  GeneratedColumn<String> get codigoEncontrado => $composableBuilder(
      column: $table.codigoEncontrado, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get observacao => $composableBuilder(
      column: $table.observacao, builder: (column) => column);

  GeneratedColumn<String> get fotoUrl =>
      $composableBuilder(column: $table.fotoUrl, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VidrosVistoriaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VidrosVistoriaTable,
    VidrosVistoriaData,
    $$VidrosVistoriaTableFilterComposer,
    $$VidrosVistoriaTableOrderingComposer,
    $$VidrosVistoriaTableAnnotationComposer,
    $$VidrosVistoriaTableCreateCompanionBuilder,
    $$VidrosVistoriaTableUpdateCompanionBuilder,
    (VidrosVistoriaData, $$VidrosVistoriaTableReferences),
    VidrosVistoriaData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$VidrosVistoriaTableTableManager(
      _$AppDatabase db, $VidrosVistoriaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VidrosVistoriaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VidrosVistoriaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VidrosVistoriaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vistoriaId = const Value.absent(),
            Value<String> posicao = const Value.absent(),
            Value<String?> codigoEncontrado = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VidrosVistoriaCompanion(
            id: id,
            vistoriaId: vistoriaId,
            posicao: posicao,
            codigoEncontrado: codigoEncontrado,
            status: status,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vistoriaId,
            required String posicao,
            Value<String?> codigoEncontrado = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> observacao = const Value.absent(),
            Value<String?> fotoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VidrosVistoriaCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            posicao: posicao,
            codigoEncontrado: codigoEncontrado,
            status: status,
            observacao: observacao,
            fotoUrl: fotoUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VidrosVistoriaTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$VidrosVistoriaTableReferences._vistoriaIdTable(db),
                    referencedColumn:
                        $$VidrosVistoriaTableReferences._vistoriaIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VidrosVistoriaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VidrosVistoriaTable,
    VidrosVistoriaData,
    $$VidrosVistoriaTableFilterComposer,
    $$VidrosVistoriaTableOrderingComposer,
    $$VidrosVistoriaTableAnnotationComposer,
    $$VidrosVistoriaTableCreateCompanionBuilder,
    $$VidrosVistoriaTableUpdateCompanionBuilder,
    (VidrosVistoriaData, $$VidrosVistoriaTableReferences),
    VidrosVistoriaData,
    PrefetchHooks Function({bool vistoriaId})>;
typedef $$ConsultasBinTableCreateCompanionBuilder = ConsultasBinCompanion
    Function({
  required String id,
  required String placa,
  Value<String?> chassi,
  Value<String?> dadosJson,
  Value<bool> restricoes,
  Value<bool> debitos,
  Value<bool> leilao,
  Value<bool> sinistro,
  Value<String?> situacao,
  Value<String?> proprietarioAtual,
  Value<String?> historicoProprietariosJson,
  Value<String?> marca,
  Value<String?> modelo,
  Value<int?> anoFabricacao,
  Value<int?> anoModelo,
  Value<String?> cor,
  Value<String?> combustivel,
  Value<String?> motorFabrica,
  Value<String?> motorEstadual,
  Value<DateTime> consultadoEm,
  Value<int> rowid,
});
typedef $$ConsultasBinTableUpdateCompanionBuilder = ConsultasBinCompanion
    Function({
  Value<String> id,
  Value<String> placa,
  Value<String?> chassi,
  Value<String?> dadosJson,
  Value<bool> restricoes,
  Value<bool> debitos,
  Value<bool> leilao,
  Value<bool> sinistro,
  Value<String?> situacao,
  Value<String?> proprietarioAtual,
  Value<String?> historicoProprietariosJson,
  Value<String?> marca,
  Value<String?> modelo,
  Value<int?> anoFabricacao,
  Value<int?> anoModelo,
  Value<String?> cor,
  Value<String?> combustivel,
  Value<String?> motorFabrica,
  Value<String?> motorEstadual,
  Value<DateTime> consultadoEm,
  Value<int> rowid,
});

class $$ConsultasBinTableFilterComposer
    extends Composer<_$AppDatabase, $ConsultasBinTable> {
  $$ConsultasBinTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chassi => $composableBuilder(
      column: $table.chassi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get restricoes => $composableBuilder(
      column: $table.restricoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get debitos => $composableBuilder(
      column: $table.debitos, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get leilao => $composableBuilder(
      column: $table.leilao, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sinistro => $composableBuilder(
      column: $table.sinistro, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get situacao => $composableBuilder(
      column: $table.situacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proprietarioAtual => $composableBuilder(
      column: $table.proprietarioAtual,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get historicoProprietariosJson => $composableBuilder(
      column: $table.historicoProprietariosJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get anoModelo => $composableBuilder(
      column: $table.anoModelo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motorFabrica => $composableBuilder(
      column: $table.motorFabrica, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motorEstadual => $composableBuilder(
      column: $table.motorEstadual, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get consultadoEm => $composableBuilder(
      column: $table.consultadoEm, builder: (column) => ColumnFilters(column));
}

class $$ConsultasBinTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsultasBinTable> {
  $$ConsultasBinTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chassi => $composableBuilder(
      column: $table.chassi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get restricoes => $composableBuilder(
      column: $table.restricoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get debitos => $composableBuilder(
      column: $table.debitos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get leilao => $composableBuilder(
      column: $table.leilao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sinistro => $composableBuilder(
      column: $table.sinistro, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get situacao => $composableBuilder(
      column: $table.situacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proprietarioAtual => $composableBuilder(
      column: $table.proprietarioAtual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get historicoProprietariosJson => $composableBuilder(
      column: $table.historicoProprietariosJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marca => $composableBuilder(
      column: $table.marca, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelo => $composableBuilder(
      column: $table.modelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anoModelo => $composableBuilder(
      column: $table.anoModelo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cor => $composableBuilder(
      column: $table.cor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motorFabrica => $composableBuilder(
      column: $table.motorFabrica,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motorEstadual => $composableBuilder(
      column: $table.motorEstadual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get consultadoEm => $composableBuilder(
      column: $table.consultadoEm,
      builder: (column) => ColumnOrderings(column));
}

class $$ConsultasBinTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsultasBinTable> {
  $$ConsultasBinTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get placa =>
      $composableBuilder(column: $table.placa, builder: (column) => column);

  GeneratedColumn<String> get chassi =>
      $composableBuilder(column: $table.chassi, builder: (column) => column);

  GeneratedColumn<String> get dadosJson =>
      $composableBuilder(column: $table.dadosJson, builder: (column) => column);

  GeneratedColumn<bool> get restricoes => $composableBuilder(
      column: $table.restricoes, builder: (column) => column);

  GeneratedColumn<bool> get debitos =>
      $composableBuilder(column: $table.debitos, builder: (column) => column);

  GeneratedColumn<bool> get leilao =>
      $composableBuilder(column: $table.leilao, builder: (column) => column);

  GeneratedColumn<bool> get sinistro =>
      $composableBuilder(column: $table.sinistro, builder: (column) => column);

  GeneratedColumn<String> get situacao =>
      $composableBuilder(column: $table.situacao, builder: (column) => column);

  GeneratedColumn<String> get proprietarioAtual => $composableBuilder(
      column: $table.proprietarioAtual, builder: (column) => column);

  GeneratedColumn<String> get historicoProprietariosJson => $composableBuilder(
      column: $table.historicoProprietariosJson, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<int> get anoFabricacao => $composableBuilder(
      column: $table.anoFabricacao, builder: (column) => column);

  GeneratedColumn<int> get anoModelo =>
      $composableBuilder(column: $table.anoModelo, builder: (column) => column);

  GeneratedColumn<String> get cor =>
      $composableBuilder(column: $table.cor, builder: (column) => column);

  GeneratedColumn<String> get combustivel => $composableBuilder(
      column: $table.combustivel, builder: (column) => column);

  GeneratedColumn<String> get motorFabrica => $composableBuilder(
      column: $table.motorFabrica, builder: (column) => column);

  GeneratedColumn<String> get motorEstadual => $composableBuilder(
      column: $table.motorEstadual, builder: (column) => column);

  GeneratedColumn<DateTime> get consultadoEm => $composableBuilder(
      column: $table.consultadoEm, builder: (column) => column);
}

class $$ConsultasBinTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConsultasBinTable,
    ConsultasBinData,
    $$ConsultasBinTableFilterComposer,
    $$ConsultasBinTableOrderingComposer,
    $$ConsultasBinTableAnnotationComposer,
    $$ConsultasBinTableCreateCompanionBuilder,
    $$ConsultasBinTableUpdateCompanionBuilder,
    (
      ConsultasBinData,
      BaseReferences<_$AppDatabase, $ConsultasBinTable, ConsultasBinData>
    ),
    ConsultasBinData,
    PrefetchHooks Function()> {
  $$ConsultasBinTableTableManager(_$AppDatabase db, $ConsultasBinTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsultasBinTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsultasBinTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsultasBinTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> placa = const Value.absent(),
            Value<String?> chassi = const Value.absent(),
            Value<String?> dadosJson = const Value.absent(),
            Value<bool> restricoes = const Value.absent(),
            Value<bool> debitos = const Value.absent(),
            Value<bool> leilao = const Value.absent(),
            Value<bool> sinistro = const Value.absent(),
            Value<String?> situacao = const Value.absent(),
            Value<String?> proprietarioAtual = const Value.absent(),
            Value<String?> historicoProprietariosJson = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<int?> anoFabricacao = const Value.absent(),
            Value<int?> anoModelo = const Value.absent(),
            Value<String?> cor = const Value.absent(),
            Value<String?> combustivel = const Value.absent(),
            Value<String?> motorFabrica = const Value.absent(),
            Value<String?> motorEstadual = const Value.absent(),
            Value<DateTime> consultadoEm = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsultasBinCompanion(
            id: id,
            placa: placa,
            chassi: chassi,
            dadosJson: dadosJson,
            restricoes: restricoes,
            debitos: debitos,
            leilao: leilao,
            sinistro: sinistro,
            situacao: situacao,
            proprietarioAtual: proprietarioAtual,
            historicoProprietariosJson: historicoProprietariosJson,
            marca: marca,
            modelo: modelo,
            anoFabricacao: anoFabricacao,
            anoModelo: anoModelo,
            cor: cor,
            combustivel: combustivel,
            motorFabrica: motorFabrica,
            motorEstadual: motorEstadual,
            consultadoEm: consultadoEm,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String placa,
            Value<String?> chassi = const Value.absent(),
            Value<String?> dadosJson = const Value.absent(),
            Value<bool> restricoes = const Value.absent(),
            Value<bool> debitos = const Value.absent(),
            Value<bool> leilao = const Value.absent(),
            Value<bool> sinistro = const Value.absent(),
            Value<String?> situacao = const Value.absent(),
            Value<String?> proprietarioAtual = const Value.absent(),
            Value<String?> historicoProprietariosJson = const Value.absent(),
            Value<String?> marca = const Value.absent(),
            Value<String?> modelo = const Value.absent(),
            Value<int?> anoFabricacao = const Value.absent(),
            Value<int?> anoModelo = const Value.absent(),
            Value<String?> cor = const Value.absent(),
            Value<String?> combustivel = const Value.absent(),
            Value<String?> motorFabrica = const Value.absent(),
            Value<String?> motorEstadual = const Value.absent(),
            Value<DateTime> consultadoEm = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsultasBinCompanion.insert(
            id: id,
            placa: placa,
            chassi: chassi,
            dadosJson: dadosJson,
            restricoes: restricoes,
            debitos: debitos,
            leilao: leilao,
            sinistro: sinistro,
            situacao: situacao,
            proprietarioAtual: proprietarioAtual,
            historicoProprietariosJson: historicoProprietariosJson,
            marca: marca,
            modelo: modelo,
            anoFabricacao: anoFabricacao,
            anoModelo: anoModelo,
            cor: cor,
            combustivel: combustivel,
            motorFabrica: motorFabrica,
            motorEstadual: motorEstadual,
            consultadoEm: consultadoEm,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConsultasBinTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConsultasBinTable,
    ConsultasBinData,
    $$ConsultasBinTableFilterComposer,
    $$ConsultasBinTableOrderingComposer,
    $$ConsultasBinTableAnnotationComposer,
    $$ConsultasBinTableCreateCompanionBuilder,
    $$ConsultasBinTableUpdateCompanionBuilder,
    (
      ConsultasBinData,
      BaseReferences<_$AppDatabase, $ConsultasBinTable, ConsultasBinData>
    ),
    ConsultasBinData,
    PrefetchHooks Function()>;
typedef $$ConsultasAutocredTableCreateCompanionBuilder
    = ConsultasAutocredCompanion Function({
  required String id,
  Value<String?> vistoriaId,
  Value<String?> placa,
  Value<String?> chassi,
  Value<String?> motor,
  required int codigoConsulta,
  Value<String?> idPesquisaAutocred,
  Value<String> status,
  Value<String?> retornoBruto,
  Value<String?> dadosTratadosJson,
  Value<String?> arquivoPesquisaUrl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ConsultasAutocredTableUpdateCompanionBuilder
    = ConsultasAutocredCompanion Function({
  Value<String> id,
  Value<String?> vistoriaId,
  Value<String?> placa,
  Value<String?> chassi,
  Value<String?> motor,
  Value<int> codigoConsulta,
  Value<String?> idPesquisaAutocred,
  Value<String> status,
  Value<String?> retornoBruto,
  Value<String?> dadosTratadosJson,
  Value<String?> arquivoPesquisaUrl,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ConsultasAutocredTableReferences extends BaseReferences<
    _$AppDatabase, $ConsultasAutocredTable, ConsultasAutocredData> {
  $$ConsultasAutocredTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VistoriasTable _vistoriaIdTable(_$AppDatabase db) =>
      db.vistorias.createAlias($_aliasNameGenerator(
          db.consultasAutocred.vistoriaId, db.vistorias.id));

  $$VistoriasTableProcessedTableManager? get vistoriaId {
    final $_column = $_itemColumn<String>('vistoria_id');
    if ($_column == null) return null;
    final manager = $$VistoriasTableTableManager($_db, $_db.vistorias)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vistoriaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ConsultasAutocredTableFilterComposer
    extends Composer<_$AppDatabase, $ConsultasAutocredTable> {
  $$ConsultasAutocredTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chassi => $composableBuilder(
      column: $table.chassi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motor => $composableBuilder(
      column: $table.motor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get codigoConsulta => $composableBuilder(
      column: $table.codigoConsulta,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idPesquisaAutocred => $composableBuilder(
      column: $table.idPesquisaAutocred,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get retornoBruto => $composableBuilder(
      column: $table.retornoBruto, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dadosTratadosJson => $composableBuilder(
      column: $table.dadosTratadosJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arquivoPesquisaUrl => $composableBuilder(
      column: $table.arquivoPesquisaUrl,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$VistoriasTableFilterComposer get vistoriaId {
    final $$VistoriasTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableFilterComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConsultasAutocredTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsultasAutocredTable> {
  $$ConsultasAutocredTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placa => $composableBuilder(
      column: $table.placa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chassi => $composableBuilder(
      column: $table.chassi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motor => $composableBuilder(
      column: $table.motor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get codigoConsulta => $composableBuilder(
      column: $table.codigoConsulta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idPesquisaAutocred => $composableBuilder(
      column: $table.idPesquisaAutocred,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get retornoBruto => $composableBuilder(
      column: $table.retornoBruto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dadosTratadosJson => $composableBuilder(
      column: $table.dadosTratadosJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arquivoPesquisaUrl => $composableBuilder(
      column: $table.arquivoPesquisaUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$VistoriasTableOrderingComposer get vistoriaId {
    final $$VistoriasTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableOrderingComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConsultasAutocredTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsultasAutocredTable> {
  $$ConsultasAutocredTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get placa =>
      $composableBuilder(column: $table.placa, builder: (column) => column);

  GeneratedColumn<String> get chassi =>
      $composableBuilder(column: $table.chassi, builder: (column) => column);

  GeneratedColumn<String> get motor =>
      $composableBuilder(column: $table.motor, builder: (column) => column);

  GeneratedColumn<int> get codigoConsulta => $composableBuilder(
      column: $table.codigoConsulta, builder: (column) => column);

  GeneratedColumn<String> get idPesquisaAutocred => $composableBuilder(
      column: $table.idPesquisaAutocred, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get retornoBruto => $composableBuilder(
      column: $table.retornoBruto, builder: (column) => column);

  GeneratedColumn<String> get dadosTratadosJson => $composableBuilder(
      column: $table.dadosTratadosJson, builder: (column) => column);

  GeneratedColumn<String> get arquivoPesquisaUrl => $composableBuilder(
      column: $table.arquivoPesquisaUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VistoriasTableAnnotationComposer get vistoriaId {
    final $$VistoriasTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vistoriaId,
        referencedTable: $db.vistorias,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VistoriasTableAnnotationComposer(
              $db: $db,
              $table: $db.vistorias,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConsultasAutocredTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConsultasAutocredTable,
    ConsultasAutocredData,
    $$ConsultasAutocredTableFilterComposer,
    $$ConsultasAutocredTableOrderingComposer,
    $$ConsultasAutocredTableAnnotationComposer,
    $$ConsultasAutocredTableCreateCompanionBuilder,
    $$ConsultasAutocredTableUpdateCompanionBuilder,
    (ConsultasAutocredData, $$ConsultasAutocredTableReferences),
    ConsultasAutocredData,
    PrefetchHooks Function({bool vistoriaId})> {
  $$ConsultasAutocredTableTableManager(
      _$AppDatabase db, $ConsultasAutocredTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsultasAutocredTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsultasAutocredTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsultasAutocredTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> vistoriaId = const Value.absent(),
            Value<String?> placa = const Value.absent(),
            Value<String?> chassi = const Value.absent(),
            Value<String?> motor = const Value.absent(),
            Value<int> codigoConsulta = const Value.absent(),
            Value<String?> idPesquisaAutocred = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> retornoBruto = const Value.absent(),
            Value<String?> dadosTratadosJson = const Value.absent(),
            Value<String?> arquivoPesquisaUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsultasAutocredCompanion(
            id: id,
            vistoriaId: vistoriaId,
            placa: placa,
            chassi: chassi,
            motor: motor,
            codigoConsulta: codigoConsulta,
            idPesquisaAutocred: idPesquisaAutocred,
            status: status,
            retornoBruto: retornoBruto,
            dadosTratadosJson: dadosTratadosJson,
            arquivoPesquisaUrl: arquivoPesquisaUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> vistoriaId = const Value.absent(),
            Value<String?> placa = const Value.absent(),
            Value<String?> chassi = const Value.absent(),
            Value<String?> motor = const Value.absent(),
            required int codigoConsulta,
            Value<String?> idPesquisaAutocred = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> retornoBruto = const Value.absent(),
            Value<String?> dadosTratadosJson = const Value.absent(),
            Value<String?> arquivoPesquisaUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConsultasAutocredCompanion.insert(
            id: id,
            vistoriaId: vistoriaId,
            placa: placa,
            chassi: chassi,
            motor: motor,
            codigoConsulta: codigoConsulta,
            idPesquisaAutocred: idPesquisaAutocred,
            status: status,
            retornoBruto: retornoBruto,
            dadosTratadosJson: dadosTratadosJson,
            arquivoPesquisaUrl: arquivoPesquisaUrl,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConsultasAutocredTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vistoriaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (vistoriaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vistoriaId,
                    referencedTable:
                        $$ConsultasAutocredTableReferences._vistoriaIdTable(db),
                    referencedColumn: $$ConsultasAutocredTableReferences
                        ._vistoriaIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ConsultasAutocredTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConsultasAutocredTable,
    ConsultasAutocredData,
    $$ConsultasAutocredTableFilterComposer,
    $$ConsultasAutocredTableOrderingComposer,
    $$ConsultasAutocredTableAnnotationComposer,
    $$ConsultasAutocredTableCreateCompanionBuilder,
    $$ConsultasAutocredTableUpdateCompanionBuilder,
    (ConsultasAutocredData, $$ConsultasAutocredTableReferences),
    ConsultasAutocredData,
    PrefetchHooks Function({bool vistoriaId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VistoriadoresTableTableManager get vistoriadores =>
      $$VistoriadoresTableTableManager(_db, _db.vistoriadores);
  $$VistoriasTableTableManager get vistorias =>
      $$VistoriasTableTableManager(_db, _db.vistorias);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db, _db.veiculos);
  $$ItensVistoriaTableTableManager get itensVistoria =>
      $$ItensVistoriaTableTableManager(_db, _db.itensVistoria);
  $$FotosVistoriaTableTableManager get fotosVistoria =>
      $$FotosVistoriaTableTableManager(_db, _db.fotosVistoria);
  $$ItensPinturaTableTableManager get itensPintura =>
      $$ItensPinturaTableTableManager(_db, _db.itensPintura);
  $$ItensEstruturaTableTableManager get itensEstrutura =>
      $$ItensEstruturaTableTableManager(_db, _db.itensEstrutura);
  $$VidrosVistoriaTableTableManager get vidrosVistoria =>
      $$VidrosVistoriaTableTableManager(_db, _db.vidrosVistoria);
  $$ConsultasBinTableTableManager get consultasBin =>
      $$ConsultasBinTableTableManager(_db, _db.consultasBin);
  $$ConsultasAutocredTableTableManager get consultasAutocred =>
      $$ConsultasAutocredTableTableManager(_db, _db.consultasAutocred);
}
