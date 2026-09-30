with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final valorFipeDouble = _parseFipeValue(data['fipe_valor_oficial']);", """    double? parseFipe(dynamic val) {
      if (val == null) return null;
      final str = val.toString().replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      return double.tryParse(str);
    }
    final valorFipeDouble = parseFipe(data['fipe_valor_oficial']);""")

content = content.replace("item.valorTotalEstimado", "item.custoTotal")

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
