// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bin_dao.dart';

// ignore_for_file: type=lint
mixin _$BinDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConsultasBinTable get consultasBin => attachedDatabase.consultasBin;
  $VistoriadoresTable get vistoriadores => attachedDatabase.vistoriadores;
  BinDaoManager get managers => BinDaoManager(this);
}

class BinDaoManager {
  final _$BinDaoMixin _db;
  BinDaoManager(this._db);
  $$ConsultasBinTableTableManager get consultasBin =>
      $$ConsultasBinTableTableManager(_db.attachedDatabase, _db.consultasBin);
  $$VistoriadoresTableTableManager get vistoriadores =>
      $$VistoriadoresTableTableManager(_db.attachedDatabase, _db.vistoriadores);
}
