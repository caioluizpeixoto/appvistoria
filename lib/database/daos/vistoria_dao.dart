import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_tables.dart';
import '../../injection_container.dart';
import '../../core/services/time_service.dart';

part 'vistoria_dao.g.dart';

@DriftAccessor(tables: [
  Vistorias,
  Veiculos,
  ItensVistoria,
  FotosVistoria,
  ItensPintura,
  ItensEstrutura,
  VidrosVistoria,
  Clientes,
  Vistoriadores,
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

  Future<Vistoria?> buscarPorNumeroLaudoOuId(String termo) async {
    // 1. Busca exata por numeroLaudo
    final porLaudo = await (select(vistorias)
          ..where((t) => t.numeroLaudo.equals(termo)))
        .getSingleOrNull();
    if (porLaudo != null) return porLaudo;

    // 2. Fallback: o app gerava códigos a partir do ID (ex: Timestamp).
    // Se digitou VST-17818265, buscamos se o ID começa com 17818265
    String termoId = termo;
    if (termo.startsWith('VST-')) {
      termoId = termo.substring(4);
    }

    final porId =
        await (select(vistorias)..where((t) => t.id.like('$termoId%'))).get();
    if (porId.isNotEmpty) return porId.first;

    return null;
  }

  Future<int> inserirVistoria(VistoriasCompanion v) =>
      into(vistorias).insert(v);

  Future<int> atualizarVistoria(VistoriasCompanion v) {
    if (!v.id.present) throw ArgumentError('ID is required for update');
    return (update(vistorias)..where((t) => t.id.equals(v.id.value))).write(v);
  }

  Future<int> deletarVistoria(String id) =>
      (delete(vistorias)..where((t) => t.id.equals(id))).go();

  Future<void> excluirVistoriaCompleta(String vistoriaId) async {
    return transaction(() async {
      await (delete(fotosVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(itensVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(itensPintura)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(itensEstrutura)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(vidrosVistoria)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(veiculos)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      await (delete(attachedDatabase.consultasAutocred)
            ..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();
      try {
        await customStatement(
          'DELETE FROM vistoria_precos WHERE vistoria_id = ?',
          [vistoriaId],
        );
      } catch (_) {}
      await (delete(vistorias)..where((t) => t.id.equals(vistoriaId))).go();
    });
  }

  Future<void> _garantirTabelaPrecos() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS vistoria_precos (
        vistoria_id TEXT PRIMARY KEY,
        valor REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> salvarValorVistoria(String vistoriaId, double valor) async {
    await _garantirTabelaPrecos();
    await customStatement(
      'INSERT OR REPLACE INTO vistoria_precos (vistoria_id, valor) VALUES (?, ?)',
      [vistoriaId, valor],
    );
  }

  Future<double?> obterValorVistoria(String vistoriaId) async {
    await _garantirTabelaPrecos();
    final rows = await customSelect(
      'SELECT valor FROM vistoria_precos WHERE vistoria_id = ?',
      variables: [Variable.withString(vistoriaId)],
    ).get();
    if (rows.isNotEmpty) {
      return rows.first.read<double>('valor');
    }
    return null;
  }

  Future<void> marcarSincronizado(String id) =>
      (update(vistorias)..where((t) => t.id.equals(id)))
          .write(const VistoriasCompanion(sincronizado: Value(true)));

  /// Atualiza etapa atual do wizard e updatedAt
  Future<void> atualizarEtapa(String id, int etapa) =>
      (update(vistorias)..where((t) => t.id.equals(id))).write(
        VistoriasCompanion(
          etapaAtual: Value(etapa),
          updatedAt: Value(sl<TimeService>().nowBrasilia()),
        ),
      );

  /// Atualiza status/parecer/assinatura/statusFinal
  Future<void> atualizarConclusao({
    required String id,
    required String statusFinal,
    required String parecerTecnico,
    String? assinaturaPath,
    String? assinaturaClientePath,
    String? vistoriadorNome,
    String? vistoriadorCpf,
    String? pdfUrl,
  }) =>
      (update(vistorias)..where((t) => t.id.equals(id))).write(
        VistoriasCompanion(
          statusFinal: Value(statusFinal),
          parecerTecnico: Value(parecerTecnico),
          assinaturaPath: Value(assinaturaPath),
          assinaturaClientePath: Value(assinaturaClientePath),
          vistoriadorNome: Value(vistoriadorNome),
          vistoriadorCpf: Value(vistoriadorCpf),
          pdfUrl: Value(pdfUrl),
          status: const Value('concluido'),
          sincronizado: const Value(false),
          updatedAt: Value(sl<TimeService>().nowBrasilia()),
        ),
      );

  // ── Veículos ──────────────────────────────────────────────────────────────

  Future<Veiculo?> buscarVeiculoPorVistoria(String vistoriaId) =>
      (select(veiculos)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .getSingleOrNull();

  Stream<Veiculo?> watchVeiculoPorVistoria(String vistoriaId) =>
      (select(veiculos)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .watchSingleOrNull();

  Future<Veiculo?> buscarVeiculoPorPlaca(String placa) async {
    final results =
        await (select(veiculos)..where((t) => t.placa.equals(placa))).get();
    if (results.isEmpty) return null;
    return results.last; // Retorna o mais recente caso haja vários antigos
  }

  // ── Sincronização ──────────────────────────────────────────────────────────
  Future<void> upsertCliente(ClientesCompanion c) =>
      into(clientes).insert(c, mode: InsertMode.insertOrReplace);

  Future<void> upsertVistoriador(VistoriadoresCompanion v) =>
      into(vistoriadores).insert(v, mode: InsertMode.insertOrReplace);

  Future<void> upsertVistoria(VistoriasCompanion v) =>
      into(vistorias).insert(v, mode: InsertMode.insertOrReplace);

  Future<void> upsertVeiculo(VeiculosCompanion v) =>
      into(veiculos).insert(v, mode: InsertMode.insertOrReplace);

  Future<int> inserirVeiculo(VeiculosCompanion v) => into(veiculos).insert(v);

  Future<int> atualizarVeiculo(VeiculosCompanion v) {
    if (!v.id.present) throw ArgumentError('ID is required for update');
    return (update(veiculos)..where((t) => t.id.equals(v.id.value))).write(v);
  }

  // ── Itens ─────────────────────────────────────────────────────────────────

  Future<List<ItensVistoriaData>> listarItensPorVistoria(String vistoriaId) =>
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
            ..where(
                (t) => t.vistoriaId.equals(vistoriaId) & t.etapa.equals(etapa)))
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

  Future<int> deletarItensPorEtapa(String vistoriaId, String etapa) =>
      (delete(itensVistoria)..where((t) => t.vistoriaId.equals(vistoriaId) & t.etapa.equals(etapa))).go();

  // ── Fotos ─────────────────────────────────────────────────────────────────

  Future<List<FotosVistoriaData>> listarFotosPorVistoria(String vistoriaId) =>
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
            ..where(
                (t) => t.vistoriaId.equals(vistoriaId) & t.etapa.equals(etapa))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .get();

  Future<int> inserirFoto(FotosVistoriaCompanion foto) =>
      into(fotosVistoria).insert(foto);

  Future<int> inserirOuAtualizarFoto(FotosVistoriaCompanion foto) =>
      into(fotosVistoria).insertOnConflictUpdate(foto);

  Future<bool> atualizarFoto(FotosVistoriaCompanion foto) =>
      update(fotosVistoria).replace(foto);

  Future<int> deletarFoto(String id) =>
      (delete(fotosVistoria)..where((t) => t.id.equals(id))).go();

  Future<int> deletarFotosPorVistoria(String vistoriaId) =>
      (delete(fotosVistoria)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();

  Future<int> deletarItensPorVistoria(String vistoriaId) =>
      (delete(itensVistoria)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .go();

  Future<int> contarFotosObrigatoriasFaltando(String vistoriaId) async {
    final fotos = await listarFotosPorVistoria(vistoriaId);
    final obrigatorias = fotos.where((f) => f.obrigatoria).toList();
    final comFoto = obrigatorias
        .where((f) => f.urlSupabase != null || f.pathLocal != null)
        .length;
    return obrigatorias.length - comFoto;
  }

  // ── Pintura ───────────────────────────────────────────────────────────────

  Future<List<ItensPinturaData>> listarPinturaPorVistoria(String vistoriaId) =>
      (select(itensPintura)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarPintura(ItensPinturaCompanion item) =>
      into(itensPintura).insertOnConflictUpdate(item);

  // ── Estrutura ─────────────────────────────────────────────────────────────

  Future<List<ItensEstruturaData>> listarEstruturaPorVistoria(
          String vistoriaId) =>
      (select(itensEstrutura)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarEstrutura(ItensEstruturaCompanion item) =>
      into(itensEstrutura).insertOnConflictUpdate(item);

  // ── Vidros ────────────────────────────────────────────────────────────────

  Future<List<VidrosVistoriaData>> listarVidrosPorVistoria(String vistoriaId) =>
      (select(vidrosVistoria)..where((t) => t.vistoriaId.equals(vistoriaId)))
          .get();

  Future<int> inserirOuAtualizarVidro(VidrosVistoriaCompanion item) =>
      into(vidrosVistoria).insertOnConflictUpdate(item);

  // ── Vistoriadores ─────────────────────────────────────────────────────────

  Future<List<Vistoriadore>> listarVistoriadores() =>
      (select(db.vistoriadores)..orderBy([(t) => OrderingTerm.asc(t.nome)])).get();

  Stream<List<Vistoriadore>> watchVistoriadores() =>
      (select(db.vistoriadores)..orderBy([(t) => OrderingTerm.asc(t.nome)])).watch();

  Future<Vistoriadore?> obterVistoriadorAtivo() =>
      (select(db.vistoriadores)..where((t) => t.ativo.equals(true))).getSingleOrNull();

  Future<int> inserirOuAtualizarVistoriador(VistoriadoresCompanion v) =>
      into(db.vistoriadores).insertOnConflictUpdate(v);

  Future<void> definirVistoriadorAtivo(String id) async {
    // Desativa todos
    await (update(db.vistoriadores)).write(const VistoriadoresCompanion(
      ativo: Value(false),
    ));
    // Ativa o selecionado
    await (update(db.vistoriadores)..where((t) => t.id.equals(id))).write(
      const VistoriadoresCompanion(
        ativo: Value(true),
      ),
    );
  }

  Future<int> deletarVistoriador(String id) =>
      (delete(db.vistoriadores)..where((t) => t.id.equals(id))).go();

  // ── Clientes ─────────────────────────────────────────────────────────────

  Future<List<Cliente>> listarClientes() =>
      (select(db.clientes)..orderBy([(t) => OrderingTerm.asc(t.nome)])).get();

  Stream<List<Cliente>> watchClientes() =>
      (select(db.clientes)..orderBy([(t) => OrderingTerm.asc(t.nome)])).watch();

  Future<int> inserirOuAtualizarCliente(ClientesCompanion c) =>
      into(db.clientes).insertOnConflictUpdate(c);

  Future<int> deletarCliente(String id) =>
      (delete(db.clientes)..where((t) => t.id.equals(id))).go();
}
