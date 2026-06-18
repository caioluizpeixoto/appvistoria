import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    final docDir = await getApplicationDocumentsDirectory();
    print('Doc dir: \${docDir.path}');
  } catch (e) {
    print('Could not get doc dir: $e');
  }
}
