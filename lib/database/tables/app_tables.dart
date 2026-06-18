import 'package:drift/drift.dart';

// ── Tabela: vistoriadores (cache local do perfil) ────────────────────────────
class Vistoriadores extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get cpf => text()();
  TextColumn get unidadeNome => text()();
  TextColumn get unidadeCnpj => text().nullable()();
  TextColumn get cargo => text().withDefault(const Constant('vistoriador'))();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: vistorias ────────────────────────────────────────────────────────
class Vistorias extends Table {
  TextColumn get id => text()();
  TextColumn get numeroLaudo => text().unique()();
  TextColumn get status =>
      text().withDefault(const Constant('em_andamento'))();
  // Novo: tipo de vistoria, cliente, unidade
  TextColumn get tipoVistoria => text().withDefault(const Constant('cautelar_carro'))();
  TextColumn get clienteNome => text().nullable()();
  TextColumn get unidade => text().nullable()();
  // Novo: parecer técnico e status final (quando concluído)
  TextColumn get parecerTecnico => text().nullable()();
  TextColumn get statusFinal => text().nullable()();
  // Novo: path da assinatura digital (salvo localmente)
  TextColumn get assinaturaPath => text().nullable()();
  DateTimeColumn get dataHora => dateTime().withDefault(currentDateAndTime)();
  TextColumn get vistoriadorId => text()();
  TextColumn get vistoriadorNome => text().nullable()();
  TextColumn get vistoriadorCpf => text().nullable()();
  TextColumn get observacoesGerais => text().nullable()();
  TextColumn get pdfUrl => text().nullable()();
  // Novo: progresso do wizard (qual etapa parou)
  IntColumn get etapaAtual => integer().withDefault(const Constant(0))();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: veiculos ─────────────────────────────────────────────────────────
class Veiculos extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get placa => text()();
  TextColumn get chassiVeiculo => text().nullable()();
  TextColumn get chassiBin => text().nullable()();
  TextColumn get motorVeiculo => text().nullable()();
  TextColumn get motorBin => text().nullable()();
  TextColumn get cambioVeiculo => text().nullable()();
  TextColumn get cambioBin => text().nullable()();
  TextColumn get renavam => text().nullable()();
  TextColumn get marca => text().nullable()();
  TextColumn get modelo => text().nullable()();
  IntColumn get anoFabricacao => integer().nullable()();
  IntColumn get anoModelo => integer().nullable()();
  TextColumn get cor => text().nullable()();
  TextColumn get combustivel => text().nullable()();
  IntColumn get km => integer().nullable()();
  // Novo: localização
  TextColumn get municipio => text().nullable()();
  TextColumn get uf => text().nullable()();
  // Novo: número GRV
  TextColumn get numeroGrv => text().nullable()();
  TextColumn get tipo =>
      text().withDefault(const Constant('automovel'))();
  BoolColumn get motorDivergente =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get chassiDivergente =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get cambioDivergente =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: itens_vistoria ───────────────────────────────────────────────────
class ItensVistoria extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get categoria => text()();
  TextColumn get nome => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pendente'))();
  TextColumn get observacao => text().nullable()();
  // Novo: etapa do wizard à qual pertence
  TextColumn get etapa => text().nullable()();
  IntColumn get ordem => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: fotos_vistoria ───────────────────────────────────────────────────
class FotosVistoria extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get itemId => text().nullable()();
  TextColumn get legenda => text()();
  // Novo: etapa e status por foto
  TextColumn get etapa => text().nullable()();
  TextColumn get statusFoto => text().nullable()();
  TextColumn get observacao => text().nullable()();
  BoolColumn get obrigatoria => boolean().withDefault(const Constant(false))();
  TextColumn get pathLocal => text().nullable()();
  TextColumn get urlSupabase => text().nullable()();
  TextColumn get storagePath => text().nullable()();
  IntColumn get ordem => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: itens_pintura ────────────────────────────────────────────────────
class ItensPintura extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get peca => text()();
  TextColumn get status =>
      text().withDefault(const Constant('original'))();
  IntColumn get espessuraMicra => integer().nullable()();
  TextColumn get observacao => text().nullable()();
  // Novo: foto opcional
  TextColumn get fotoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: itens_estrutura ──────────────────────────────────────────────────
class ItensEstrutura extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get peca => text()();
  TextColumn get status =>
      text().withDefault(const Constant('sem_reparo'))();
  TextColumn get observacao => text().nullable()();
  // Novo: foto opcional
  TextColumn get fotoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: vidros_vistoria ──────────────────────────────────────────────────
class VidrosVistoria extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().references(Vistorias, #id)();
  TextColumn get posicao => text()(); // ex: 'dianteiro_direito', 'frontal', etc.
  TextColumn get codigoEncontrado => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('nao_analisado'))();
  TextColumn get observacao => text().nullable()();
  TextColumn get fotoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: consultas_bin ────────────────────────────────────────────────────
class ConsultasBin extends Table {
  TextColumn get id => text()();
  TextColumn get placa => text().unique()();
  TextColumn get chassi => text().nullable()();
  TextColumn get dadosJson => text().nullable()();
  BoolColumn get restricoes => boolean().withDefault(const Constant(false))();
  BoolColumn get debitos => boolean().withDefault(const Constant(false))();
  BoolColumn get leilao => boolean().withDefault(const Constant(false))();
  BoolColumn get sinistro => boolean().withDefault(const Constant(false))();
  TextColumn get situacao => text().nullable()();
  TextColumn get proprietarioAtual => text().nullable()();
  TextColumn get historicoProprietariosJson => text().nullable()();
  TextColumn get marca => text().nullable()();
  TextColumn get modelo => text().nullable()();
  IntColumn get anoFabricacao => integer().nullable()();
  IntColumn get anoModelo => integer().nullable()();
  TextColumn get cor => text().nullable()();
  TextColumn get combustivel => text().nullable()();
  TextColumn get motorFabrica => text().nullable()();
  TextColumn get motorEstadual => text().nullable()();
  DateTimeColumn get consultadoEm =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Tabela: consultas_autocred ────────────────────────────────────────────────────
class ConsultasAutocred extends Table {
  TextColumn get id => text()();
  TextColumn get vistoriaId => text().nullable().references(Vistorias, #id)();
  TextColumn get placa => text().nullable()();
  TextColumn get chassi => text().nullable()();
  TextColumn get motor => text().nullable()();
  IntColumn get codigoConsulta => integer()();
  TextColumn get idPesquisaAutocred => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pendente'))();
  TextColumn get retornoBruto => text().nullable()();
  TextColumn get dadosTratadosJson => text().nullable()();
  TextColumn get arquivoPesquisaUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
