import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = 'C:\\Users\\Caio\\Documents\\cautelar_app.sqlite';
  print('Opening db at $dbPath');
  if (!File(dbPath).existsSync()) {
    print('DB does not exist.');
    return;
  }
  
  final db = sqlite3.open(dbPath);
  try {
    final ResultSet resultSet = db.select('SELECT retorno_bruto FROM consultas_autocred ORDER BY created_at DESC LIMIT 1');
    if (resultSet.isEmpty) {
      print('No results found.');
    } else {
      for (final row in resultSet) {
        print('--- RETORNO BRUTO ---');
        print(row['retorno_bruto']);
      }
    }
  } catch (e) {
    print('Error querying db: $e');
  } finally {
    db.dispose();
  }
}
