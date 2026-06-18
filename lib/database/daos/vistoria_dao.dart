import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';

part 'vistoria_dao.g.dart';

@DriftAccessor(tables: [
  Vistorias,
  Veiculos,
  ItensVistoria,
  FotosVistoria,
  ItensPintura,
  ItensEstrutura,
  VidrosVistoria,
])
class VistoriaDao extends DatabaseAccessor<AppDatabase>
    with _$VistoriaDaoMixin {
  VistoriaDao(super.db);

  // ── Vistorias ──────────────────────────────────────────────────────────────

  Future<List<Vistoria>> listarVistorias() =>
      (select(vistorias)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Vistoria>> listarNaoSincronizadas() =>
      (select(vistorias)..where((t) => t.sincronizado.equals(false))).get();

  Future<Vistoria?> buscarPorId(String id) =>
      (select(vistorias)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> inserirVistoria(VistoriasCompanion v) =>
      into(vistorias).insert(v);

  Future<int> atualizarVistoria(VistoriasCompanion v) {
    if (!v.id.present) throw ArgumentError('ID is required for update');
    return (update(vistorias)..where((t) => t.id.equals(v.id.value))).write(v);
  }

  Future<int> deletarVistoria(String id) =>
      (delete(vistorias)..where((t) => t.id.equals(id))).go();

  Future<void> marcarSincronizado(String id) =>
      (update(vistorias)..where((t) => t.id.equals(id)))
          .write(const VistoriasCompanion(sincronizado: Value(true)));

  /// Atualiza etapa atual do wizard e updatedAt
  Future<void> atualizarEtapa(String id, int etapa) =>
      (update(vistorias)..where((t) => t.id.equals(id))).write(
        VistoriasCompanion(
          etapaAtual: Value(etapa),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Atualiza status/parecer/assinatura/statusFinal
  Future<void> atualizarConclusao({
    required String id,
    required String statusFinal,
    required String parecerTecnico,
    String? assinaturaPath,
    String? vistoriadorNome,
    String? vistoriadorCpf,
  }) =>
      (update(vistorias)..where((t) => t.id.equals(id))).write(
        VistoriasCompanion(
          statusFinal: Value(statusFinal),
          parecerTecnico: Value(parecerTecnico),
          assinaturaPath: Value(assinaturaPath),
          vistoriadorNome: Value(vistoriadorNome),
          vistoriadorCpf: Value(vistoriadorCpf),
          status: const Value('concluido'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── Veículos ──────────────────────────────────────────────────────────────

  Future<Veiculo?> buscarVeiculoPorVistoria(String vistoriaId) =>
      (select(veiculos)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .getSingleOrNull();

  Future<int> inserirVeiculo(VeiculosCompanion v) => into(veiculos).insert(v);

  Future<int> atualizarVeiculo(VeiculosCompanion v) {
    if (!v.id.present) throw ArgumentError('ID is required for update');
    return (update(veiculos)..where((t) => t.id.equals(v.id.value))).write(v);
  }

  // ── Itens ─────────────────────────────────────────────────────────────────

  Future<List<ItensVistoriaData>> listarItensPorVistoria(
          String vistoriaId) =>
      (select(itensVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.categoria),
              (t) => OrderingTerm.asc(t.ordem),
            ]))
          .get();

  Future<List<ItensVistoriaData>> listarItensPorEtapa(
          String vistoriaId, String etapa) =>
      (select(itensVistoria)
            ..where((t) =>
                t.vistoriaId.equals(vistoriaId) & t.etapa.equals(etapa)))
          .get();

  Future<int> inserirItem(ItensVistoriaCompanion item) =>
      into(itensVistoria).insert(item);

  Future<void> inserirItensLote(List<ItensVistoriaCompanion> itens) async {
    await batch((b) => b.insertAll(itensVistoria, itens));
  }

  Future<bool> atualizarItem(ItensVistoriaCompanion item) =>
      update(itensVistoria).replace(item);

  Future<int> inserirOuAtualizarItem(ItensVistoriaCompanion item) =>
      into(itensVistoria).insertOnConflictUpdate(item);

  // ── Fotos ─────────────────────────────────────────────────────────────────

  Future<List<FotosVistoriaData>> listarFotosPorVistoria(
          String vistoriaId) =>
      (select(fotosVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .get();

  Future<List<FotosVistoriaData>> listarFotosPorItem(
          String vistoriaId, String itemId) =>
      (select(fotosVistoria)
            ..where((t) =>
                t.vistoriaId.equals(vistoriaId) & t.itemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .get();

  Future<List<FotosVistoriaData>> listarFotosPorEtapa(
          String vistoriaId, String etapa) =>
      (select(fotosVistoria)
            ..where((t) =>
                t.vistoriaId.equals(vistoriaId) & t.etapa.equals(etapa))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .get();

  Future<int> inserirFoto(FotosVistoriaCompanion foto) =>
      into(fotosVistoria).insert(foto);

  Future<bool> atualizarFoto(FotosVistoriaCompanion foto) =>
      update(fotosVistoria).replace(foto);

  Future<int> deletarFoto(String id) =>
      (delete(fotosVistoria)..where((t) => t.id.equals(id))).go();

  Future<int> deletarFotosPorVistoria(String vistoriaId) =>
      (delete(fotosVistoria)..where((t) => t.vistoriaId.equals(vistoriaId))).go();

  Future<int> deletarItensPorVistoria(String vistoriaId) =>
      (delete(itensVistoria)..where((t) => t.vistoriaId.equals(vistoriaId))).go();

  Future<int> contarFotosObrigatoriasFaltando(String vistoriaId) async {
    final fotos = await listarFotosPorVistoria(vistoriaId);
    final obrigatorias = fotos.where((f) => f.obrigatoria).toList();
    final comFoto = obrigatorias.where((f) => f.urlSupabase != null || f.pathLocal != null).length;
    return obrigatorias.length - comFoto;
  }

  // ── Pintura ───────────────────────────────────────────────────────────────

  Future<List<ItensPinturaData>> listarPinturaPorVistoria(
          String vistoriaId) =>
      (select(itensPintura)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarPintura(ItensPinturaCompanion item) =>
      into(itensPintura).insertOnConflictUpdate(item);

  // ── Estrutura ─────────────────────────────────────────────────────────────

  Future<List<ItensEstruturaData>> listarEstruturaPorVistoria(
          String vistoriaId) =>
      (select(itensEstrutura)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarEstrutura(ItensEstruturaCompanion item) =>
      into(itensEstrutura).insertOnConflictUpdate(item);

  // ── Vidros ────────────────────────────────────────────────────────────────

  Future<List<VidrosVistoriaData>> listarVidrosPorVistoria(
          String vistoriaId) =>
      (select(vidrosVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarVidro(VidrosVistoriaCompanion item) =>
      into(vidrosVistoria).insertOnConflictUpdate(item);
}
