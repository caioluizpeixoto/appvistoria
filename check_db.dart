import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('c:\\Users\\Caio\\Desktop\\app_vistoria\\sqlite.db');
  final rs = db.select('SELECT id, placa, vistoria_id, arquivo_pesquisa_url FROM consultas_autocred');
  print('Resultados:');
  for (final row in rs) {
    print(row);
  }
}
