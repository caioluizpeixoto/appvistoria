with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "final motor = s5?['motorizacao'] is Map ? s5?['motorizacao'] as Map : null;",
    "final motor = (s5 != null && s5['motorizacao'] is Map) ? s5['motorizacao'] as Map : null;"
)
content = content.replace(
    "final trans = s5?['transmissao'] is Map ? s5?['transmissao'] as Map : null;",
    "final trans = (s5 != null && s5['transmissao'] is Map) ? s5['transmissao'] as Map : null;"
)
content = content.replace(
    "final dimen = s5?['dimensoes'] is Map ? s5?['dimensoes'] as Map : null;",
    "final dimen = (s5 != null && s5['dimensoes'] is Map) ? s5['dimensoes'] as Map : null;"
)

content = content.replace(
    "final desemp = s6?['desempenho'] is Map ? s6?['desempenho'] as Map : null;",
    "final desemp = (s6 != null && s6['desempenho'] is Map) ? s6['desempenho'] as Map : null;"
)
content = content.replace(
    "final cons = s6?['consumo'] is Map ? s6?['consumo'] as Map : null;",
    "final cons = (s6 != null && s6['consumo'] is Map) ? s6['consumo'] as Map : null;"
)

content = content.replace(
    "final fluidos = s7?['fluidos'] is List ? s7?['fluidos'] as List : null;",
    "final fluidos = (s7 != null && s7['fluidos'] is List) ? s7['fluidos'] as List : null;"
)
content = content.replace(
    "final custos = s7?['custos_estimados'] is List ? s7?['custos_estimados'] as List : null;",
    "final custos = (s7 != null && s7['custos_estimados'] is List) ? s7['custos_estimados'] as List : null;"
)

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Sintaxe corrigida com sucesso!")
