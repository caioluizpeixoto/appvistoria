import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'autocred_dao.g.dart';

@DriftAccessor(tables: [ConsultasAutocred])
class AutocredDao extends DatabaseAccessor<AppDatabase>
    with _$AutocredDaoMixin {
  AutocredDao(super.db);

  Future<List<ConsultasAutocredData>> listarConsultas() =>
      (select(consultasAutocred)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<ConsultasAutocredData?> buscarConsultaPorIdPesquisa(
          String idPesquisa) =>
      (select(consultasAutocred)
            ..where((t) => t.idPesquisaAutocred.equals(idPesquisa)))
          .getSingleOrNull();

  Future<ConsultasAutocredData?> buscarConsultaPorVistoria(
      String vistoriaId) async {
    final query = select(consultasAutocred)
      ..where((t) => t.vistoriaId.equals(vistoriaId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<ConsultasAutocredData?> buscarConsultaPorPlaca(String placa) async {
    final placaLimpa = placa.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final comTraco = placaLimpa.length == 7 ? '${placaLimpa.substring(0, 3)}-${placaLimpa.substring(3)}' : placaLimpa;
    final query = select(consultasAutocred)
      ..where((t) => t.placa.upper().equals(placaLimpa) | t.placa.upper().equals(comTraco) | t.placa.upper().equals(placa.toUpperCase()))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<ConsultasAutocredData?> buscarConsultaPorChassi(String chassi) async {
    final chassiLimpo = chassi.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final query = select(consultasAutocred)
      ..where((t) => t.chassi.upper().equals(chassiLimpo) | t.chassi.upper().equals(chassi.toUpperCase()))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<ConsultasAutocredData?> buscarConsultaPorMotor(String motor) async {
    final motorLimpo = motor.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final query = select(consultasAutocred)
      ..where((t) => t.motor.upper().equals(motorLimpo) | t.motor.upper().equals(motor.toUpperCase()))
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
