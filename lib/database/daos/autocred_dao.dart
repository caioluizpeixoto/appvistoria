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

  Future<int> inserirOuAtualizarConsulta(ConsultasAutocredCompanion item) =>
      into(consultasAutocred).insertOnConflictUpdate(item);
}
