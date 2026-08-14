class MarcaModeloResult {
  final String marca;
  final String modelo;

  const MarcaModeloResult({
    required this.marca,
    required this.modelo,
  });

  @override
  String toString() => 'MarcaModeloResult(marca: $marca, modelo: $modelo)';
}

class VeiculoParser {
  static const List<String> _knownCompositeBrands = [
    'MERCEDES-BENZ',
    'MERCEDES BENZ',
    'M.BENZ',
    'M. BENZ',
    'LAND ROVER',
    'L. ROVER',
    'ALFA ROMEO',
    'ASTON MARTIN',
    'ROLLS ROYCE',
    'GREAT WALL',
    'CAOA CHERY',
    'HARLEY-DAVIDSON',
    'HARLEY DAVIDSON',
  ];

  static const Set<String> _importPrefixes = {
    'I',
    'IMP',
    'IP',
    'IMPORTADO',
    'IMPORT',
  };

  /// Extrai de forma inteligente a marca e o modelo de strings brutas do Detran/Denatran/Radar.
  /// Exemplos:
  /// - "I/JEEP I/JEEP GCHEROKEE LTD3.6L" -> Marca: "JEEP", Modelo: "GCHEROKEE LTD3.6L"
  /// - "I/JEEP CHEROKEE"                -> Marca: "JEEP", Modelo: "CHEROKEE"
  /// - "VW/GOL 1.0"                     -> Marca: "VW", Modelo: "GOL 1.0"
  /// - "FIAT/PALIO ATTRACTIV 1.0"       -> Marca: "FIAT", Modelo: "PALIO ATTRACTIV 1.0"
  /// - "I/BMW 320I"                     -> Marca: "BMW", Modelo: "320I"
  /// - "I/M.BENZ C180"                  -> Marca: "M.BENZ", Modelo: "C180"
  /// - "I/FORD I/FORD RANGER XLS"       -> Marca: "FORD", Modelo: "RANGER XLS"
  /// - "CHEVROLET/ONIX PLUS 1.0T"       -> Marca: "CHEVROLET", Modelo: "ONIX PLUS 1.0T"
  static MarcaModeloResult extrairMarcaModelo(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const MarcaModeloResult(marca: '', modelo: '');
    }

    String text = raw.trim().toUpperCase();

    // 1. Remover prefixo de importação no início se houver (ex: "I/", "IMP/", "IP/", "I - ", etc.)
    text = text.replaceFirst(RegExp(r'^(I|IMP|IP|IMPORTADO)\s*[\/\-]\s*'), '').trim();
    if (text.startsWith(RegExp(r'^(I|IMP)\s+'))) {
      text = text.replaceFirst(RegExp(r'^(I|IMP)\s+'), '').trim();
    }

    // 2. Tratar se ainda tiver barras ou repetições de importação internas
    // Ex: "JEEP I/JEEP GCHEROKEE LTD3.6L" -> remove "I/JEEP " ou similar
    text = text.replaceAll(RegExp(r'\b(I|IMP|IP)\/'), '').trim();

    // 3. Se tiver barra separando marca do modelo: ex: "VW/GOL 1.0" ou "JEEP/COMPASS"
    if (text.contains('/')) {
      final parts = text.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length == 1) {
        text = parts[0];
      } else if (parts.isNotEmpty) {
        // Se a primeira parte ainda for prefixo 'I' ou 'IMP', ignore
        int brandIndex = 0;
        if (_importPrefixes.contains(parts[0])) {
          brandIndex = 1;
        }
        if (brandIndex < parts.length) {
          final marca = parts[brandIndex];
          final modeloParts = parts.sublist(brandIndex + 1);
          
          // Se o modelo começar repetindo a marca (ex: marca="JEEP", modelo="JEEP GCHEROKEE")
          String modelo = modeloParts.join(' ').trim();
          while (modelo.startsWith('$marca ') || modelo == marca) {
            if (modelo == marca) {
              modelo = '';
              break;
            }
            modelo = modelo.substring(marca.length).trim();
          }
          if (modelo.isEmpty && modeloParts.isEmpty) {
            return MarcaModeloResult(marca: marca, modelo: marca);
          }
          return MarcaModeloResult(
            marca: marca,
            modelo: modelo.isNotEmpty ? modelo : marca,
          );
        }
      }
    }

    // 4. Se não tem barras, verificar marcas compostas conhecidas no início
    for (final compBrand in _knownCompositeBrands) {
      if (text.startsWith(compBrand)) {
        final marca = compBrand;
        String modelo = text.substring(compBrand.length).trim();
        while (modelo.startsWith('$marca ') || modelo == marca) {
          if (modelo == marca) {
            modelo = '';
            break;
          }
          modelo = modelo.substring(marca.length).trim();
        }
        return MarcaModeloResult(
          marca: marca,
          modelo: modelo.isNotEmpty ? modelo : marca,
        );
      }
    }

    // 5. Separação por espaço (primeira palavra é a marca, o restante é o modelo)
    final spaceParts = text.split(RegExp(r'\s+'));
    if (spaceParts.length <= 1) {
      return MarcaModeloResult(marca: text, modelo: text);
    }

    final marca = spaceParts[0].trim();
    var remaining = spaceParts.sublist(1).join(' ').trim();

    // Se o restante começar repetindo a marca (ex: "JEEP GCHEROKEE" ou "JEEP JEEP GCHEROKEE")
    while (remaining.startsWith('$marca ') || remaining == marca) {
      if (remaining == marca) {
        remaining = '';
        break;
      }
      remaining = remaining.substring(marca.length).trim();
    }

    return MarcaModeloResult(
      marca: marca,
      modelo: remaining.isNotEmpty ? remaining : marca,
    );
  }
}
