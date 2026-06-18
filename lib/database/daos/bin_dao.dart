import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'bin_dao.g.dart';

@DriftAccessor(tables: [ConsultasBin, Vistoriadores])
class BinDao extends DatabaseAccessor<AppDatabase> with _$BinDaoMixin {
  BinDao(super.db);

  Future<ConsultasBinData?> buscarPorPlaca(String placa) =>
      (select(consultasBin)..where((t) => t.placa.equals(placa)))
          .getSingleOrNull();

  Future<int> inserirOuAtualizarBin(ConsultasBinCompanion item) =>
      into(consultasBin).insertOnConflictUpdate(item);

  // ── Vistoriador (perfil local) ─────────────────────────────────────────────

  Future<Vistoriadore?> buscarVistoriadorPorId(String id) =>
      (select(vistoriadores)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> inserirOuAtualizarVistoriador(VistoriadoresCompanion v) =>
      into(vistoriadores).insertOnConflictUpdate(v);
}
