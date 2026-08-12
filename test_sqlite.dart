import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
void main() {
  final dbs = ['app_db.sqlite', 'db.sqlite', 'sqlite.db'];
  for (var dbPath in dbs) {
    if (!File(dbPath).existsSync()) continue;
    print('Testing $dbPath...');
    final db = sqlite3.open(dbPath);
    try {
      final tables = db.select("SELECT name FROM sqlite_master WHERE type='table'");
      print('Tables: $tables');
      if (tables.toString().contains('consultas_autocred') || tables.toString().contains('laudos')) {
        final rs = db.select('SELECT retorno_bruto FROM consultas_autocred ORDER BY id DESC LIMIT 1');
        for (final row in rs) {
          final ret = row['retorno_bruto'].toString();
          print(ret.length > 500 ? ret.substring(0, 500) : ret);
        }
      }
    } catch(e) { print(e); }
  }
}
