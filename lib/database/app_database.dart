import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_tables.dart';
import 'daos/vistoria_dao.dart';
import 'daos/bin_dao.dart';
import 'daos/autocred_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Vistoriadores,
    Vistorias,
    Veiculos,
    ItensVistoria,
    FotosVistoria,
    ItensPintura,
    ItensEstrutura,
    VidrosVistoria,
    ConsultasBin,
    ConsultasAutocred,
  ],
  daos: [
    VistoriaDao,
    BinDao,
    AutocredDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Novas colunas em Vistorias
            await m.addColumn(vistorias, vistorias.tipoVistoria);
            await m.addColumn(vistorias, vistorias.unidade);
            await m.addColumn(vistorias, vistorias.parecerTecnico);
            await m.addColumn(vistorias, vistorias.statusFinal);
            await m.addColumn(vistorias, vistorias.assinaturaPath);
            await m.addColumn(vistorias, vistorias.vistoriadorNome);
            await m.addColumn(vistorias, vistorias.vistoriadorCpf);
            await m.addColumn(vistorias, vistorias.etapaAtual);
            // Novas colunas em Veiculos
            await m.addColumn(veiculos, veiculos.municipio);
            await m.addColumn(veiculos, veiculos.uf);
            await m.addColumn(veiculos, veiculos.numeroGrv);
            // Novas colunas em ItensVistoria
            await m.addColumn(itensVistoria, itensVistoria.etapa);
            // Novas colunas em FotosVistoria
            await m.addColumn(fotosVistoria, fotosVistoria.etapa);
            await m.addColumn(fotosVistoria, fotosVistoria.statusFoto);
            await m.addColumn(fotosVistoria, fotosVistoria.observacao);
            await m.addColumn(fotosVistoria, fotosVistoria.obrigatoria);
            // Novas colunas em ItensPintura
            await m.addColumn(itensPintura, itensPintura.fotoUrl);
            // Novas colunas em ItensEstrutura
            await m.addColumn(itensEstrutura, itensEstrutura.fotoUrl);
            // Nova tabela VidrosVistoria
            await m.createTable(vidrosVistoria);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cautelar_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
