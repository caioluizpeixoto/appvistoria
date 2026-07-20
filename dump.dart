import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = 'C:\\Users\\Caio\\Documents\\cautelar_app.sqlite';
  final db = sqlite3.open(dbPath);
  final tables = db.select("SELECT name FROM sqlite_master WHERE type='table'");
  print(tables);
  db.dispose();
}
