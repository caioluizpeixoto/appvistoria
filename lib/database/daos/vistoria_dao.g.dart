// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vistoria_dao.dart';

// ignore_for_file: type=lint
mixin _$VistoriaDaoMixin on DatabaseAccessor<AppDatabase> {
  $VistoriasTable get vistorias => attachedDatabase.vistorias;
  $VeiculosTable get veiculos => attachedDatabase.veiculos;
  $ItensVistoriaTable get itensVistoria => attachedDatabase.itensVistoria;
  $FotosVistoriaTable get fotosVistoria => attachedDatabase.fotosVistoria;
  $ItensPinturaTable get itensPintura => attachedDatabase.itensPintura;
  $ItensEstruturaTable get itensEstrutura => attachedDatabase.itensEstrutura;
  $VidrosVistoriaTable get vidrosVistoria => attachedDatabase.vidrosVistoria;
  VistoriaDaoManager get managers => VistoriaDaoManager(this);
}

class VistoriaDaoManager {
  final _$VistoriaDaoMixin _db;
  VistoriaDaoManager(this._db);
  $$VistoriasTableTableManager get vistorias =>
      $$VistoriasTableTableManager(_db.attachedDatabase, _db.vistorias);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db.attachedDatabase, _db.veiculos);
  $$ItensVistoriaTableTableManager get itensVistoria =>
      $$ItensVistoriaTableTableManager(_db.attachedDatabase, _db.itensVistoria);
  $$FotosVistoriaTableTableManager get fotosVistoria =>
      $$FotosVistoriaTableTableManager(_db.attachedDatabase, _db.fotosVistoria);
  $$ItensPinturaTableTableManager get itensPintura =>
      $$ItensPinturaTableTableManager(_db.attachedDatabase, _db.itensPintura);
  $$ItensEstruturaTableTableManager get itensEstrutura =>
      $$ItensEstruturaTableTableManager(
          _db.attachedDatabase, _db.itensEstrutura);
  $$VidrosVistoriaTableTableManager get vidrosVistoria =>
      $$VidrosVistoriaTableTableManager(
          _db.attachedDatabase, _db.vidrosVistoria);
}
