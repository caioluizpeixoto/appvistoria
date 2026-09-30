import re

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace variables to use optional chaining
content = content.replace("s5['motorizacao']", "s5?['motorizacao']")
content = content.replace("s5['transmissao']", "s5?['transmissao']")
content = content.replace("s5['dimensoes']", "s5?['dimensoes']")

content = content.replace("s6['desempenho']", "s6?['desempenho']")
content = content.replace("s6['consumo']", "s6?['consumo']")

content = content.replace("s7['fluidos']", "s7?['fluidos']")
content = content.replace("s7['custos_estimados']", "s7?['custos_estimados']")

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Tipos null-safe corrigidos com sucesso!")
