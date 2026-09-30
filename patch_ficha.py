with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final fichaData = data['data'] as Map;", "final Map<String, dynamic> fichaData = Map<String, dynamic>.from(data['data'] as Map);")

with open(r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
