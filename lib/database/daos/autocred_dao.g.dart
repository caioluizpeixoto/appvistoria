// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autocred_dao.dart';

// ignore_for_file: type=lint
mixin _$AutocredDaoMixin on DatabaseAccessor<AppDatabase> {
  $VistoriasTable get vistorias => attachedDatabase.vistorias;
  $ConsultasAutocredTable get consultasAutocred =>
      attachedDatabase.consultasAutocred;
  AutocredDaoManager get managers => AutocredDaoManager(this);
}

class AutocredDaoManager {
  final _$AutocredDaoMixin _db;
  AutocredDaoManager(this._db);
  $$VistoriasTableTableManager get vistorias =>
      $$VistoriasTableTableManager(_db.attachedDatabase, _db.vistorias);
  $$ConsultasAutocredTableTableManager get consultasAutocred =>
      $$ConsultasAutocredTableTableManager(
          _db.attachedDatabase, _db.consultasAutocred);
}
