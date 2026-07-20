import 'dart:convert';

String _v(Map<String, dynamic> data, List<String> keys, {String fallback = 'NAO'}) {
  String? searchRecursive(dynamic node, String targetKey) {
    if (node is Map) {
      final lowerTarget = targetKey.toLowerCase();
      for (var entry in node.entries) {
        if (entry.key.toString().toLowerCase() == lowerTarget) {
          if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
            return entry.value.toString().trim();
          }
        }
      }
      for (var entry in node.entries) {
        final result = searchRecursive(entry.value, targetKey);
        if (result != null) return result;
      }
    } else if (node is Iterable) {
      for (var item in node) {
        final result = searchRecursive(item, targetKey);
        if (result != null) return result;
      }
    }
    return null;
  }
  for (var k in keys) {
    final result = searchRecursive(data, k);
    if (result != null) return result;
  }
  return fallback;
}
void main() {
  final jsonString = '''{"consulta":{"resultados":[{"retorno":{"data":{"placa":"ABC1234","ipva":[{"basecalculo":"R\$ 1.000,00"}]}}}]}}''';
  final data = jsonDecode(jsonString);
  print('Placa: ' + _v(data, ['placa']));
  print('IPVA Base: ' + _v(data, ['ipva_basecalculo', 'basecalculo']));
}
