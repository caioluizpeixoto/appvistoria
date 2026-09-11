import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "    // Especificações e Manutenção"
start_idx = content.find(start_marker)

end_marker = "      }));\n    }\n  }\n\n  static pw.Widget _buildSituacaoGeralRow("
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print(f"Indices not found. start: {start_idx}, end: {end_idx}")
    # let's try finding just the end marker's partial
    idx2 = content.find("static pw.Widget _buildSituacaoGeralRow")
    print(f"buildSituacaoGeralRow is at {idx2}")
else:
    print(f"Indices found: {start_idx} to {end_idx}")

