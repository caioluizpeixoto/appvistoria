import re

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace variables
content = content.replace(
    "final s1 = data['secao1_visao_geral'] as Map<String, dynamic>?;",
    "final s1 = data['secao1_visao_geral'] is Map ? data['secao1_visao_geral'] as Map<String, dynamic> : null;"
)
content = content.replace(
    "final s2 = data['secao2_pontos_positivos'] as List<dynamic>?;",
    "final s2 = data['secao2_pontos_positivos'] is List ? data['secao2_pontos_positivos'] as List<dynamic> : null;"
)
content = content.replace(
    "final s3 = data['secao3_pontos_atencao'] as List<dynamic>?;",
    "final s3 = data['secao3_pontos_atencao'] is List ? data['secao3_pontos_atencao'] as List<dynamic> : null;"
)
content = content.replace(
    "final s5 = data['secao5_ficha_tecnica'] as Map<String, dynamic>?;",
    "final s5 = data['secao5_ficha_tecnica'] is Map ? data['secao5_ficha_tecnica'] as Map<String, dynamic> : null;"
)
content = content.replace(
    "final s6 = data['secao6_desempenho_consumo'] as Map<String, dynamic>?;",
    "final s6 = data['secao6_desempenho_consumo'] is Map ? data['secao6_desempenho_consumo'] as Map<String, dynamic> : null;"
)
content = content.replace(
    "final s7 = data['secao7_manutencao_custos'] as Map<String, dynamic>?;",
    "final s7 = data['secao7_manutencao_custos'] is Map ? data['secao7_manutencao_custos'] as Map<String, dynamic> : null;"
)
content = content.replace(
    "final s11 = data['secao11_resumo_executivo'] as Map<String, dynamic>?;",
    "final s11 = data['secao11_resumo_executivo'] is Map ? data['secao11_resumo_executivo'] as Map<String, dynamic> : null;"
)

content = content.replace(
    "final motor = s5['motorizacao'] as Map?;",
    "final motor = s5['motorizacao'] is Map ? s5['motorizacao'] as Map : null;"
)
content = content.replace(
    "final trans = s5['transmissao'] as Map?;",
    "final trans = s5['transmissao'] is Map ? s5['transmissao'] as Map : null;"
)
content = content.replace(
    "final dimen = s5['dimensoes'] as Map?;",
    "final dimen = s5['dimensoes'] is Map ? s5['dimensoes'] as Map : null;"
)
content = content.replace(
    "final desemp = s6['desempenho'] as Map?;",
    "final desemp = s6['desempenho'] is Map ? s6['desempenho'] as Map : null;"
)
content = content.replace(
    "final cons = s6['consumo'] as Map?;",
    "final cons = s6['consumo'] is Map ? s6['consumo'] as Map : null;"
)
content = content.replace(
    "final fluidos = s7['fluidos'] as List?;",
    "final fluidos = s7['fluidos'] is List ? s7['fluidos'] as List : null;"
)
content = content.replace(
    "final custos = s7['custos_estimados'] as List?;",
    "final custos = s7['custos_estimados'] is List ? s7['custos_estimados'] as List : null;"
)

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Tipos corrigidos com sucesso!")
