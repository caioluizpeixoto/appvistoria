import re

with open(r'lib\core\services\pdf_generator_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "    // Especificações e Manutenção"
start_idx = content.find(start_marker)

end_marker_str = "    }\n  }\n\n  static pw.Widget _buildSituacaoGeralRow("
end_idx = content.find(end_marker_str)
if end_idx == -1:
    end_marker_str = "      }));\n    }\n  }\n\n  static pw.Widget _buildSituacaoGeralRow("
    end_idx = content.find(end_marker_str)
if end_idx == -1:
    # let's just find _buildSituacaoGeralRow and backtrack
    idx = content.find("static pw.Widget _buildSituacaoGeralRow(")
    # backtrack to find the close of generateLaudoCompleto
    end_idx = content.rfind("    }\n  }\n", 0, idx)

original_block = content[start_idx:end_idx]

# Let's verify what we have
with open("scratch/original_block.txt", "w", encoding="utf-8") as out:
    out.write(original_block)
