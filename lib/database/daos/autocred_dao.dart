import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'autocred_dao.g.dart';

@DriftAccessor(tables: [ConsultasAutocred])
class AutocredDao extends DatabaseAccessor<AppDatabase> with _$AutocredDaoMixin {
  AutocredDao(super.db);

  Future<List<ConsultasAutocredData>> listarConsultas() =>
      (select(consultasAutocred)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<ConsultasAutocredData?> buscarConsultaPorIdPesquisa(String idPesquisa) =>
      (select(consultasAutocred)..where((t) => t.idPesquisaAutocred.equals(idPesquisa))).getSingleOrNull();

  Future<ConsultasAutocredData?> buscarConsultaPorVistoria(String vistoriaId) async {
    final query = select(consultasAutocred)
      ..where((t) => t.vistoriaId.equals(vistoriaId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<ConsultasAutocredData?> buscarConsultaPorPlaca(String placa) async {
    final query = select(consultasAutocred)
      ..where((t) => t.placa.equals(placa))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Stream<ConsultasAutocredData?> watchConsultaPorVistoria(String vistoriaId) {
    final query = select(consultasAutocred)
      ..where((t) => t.vistoriaId.equals(vistoriaId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<int> inserirOuAtualizarConsulta(ConsultasAutocredCompanion item) =>
      into(consultasAutocred).insertOnConflictUpdate(item);
}
