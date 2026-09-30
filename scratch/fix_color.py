import re

file_path = r"c:\Users\Caio\Desktop\app_vistoria\lib\features\master\presentation\widgets\aba_empresas_master_widget.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Remove the first occurrence of _openAdvancedColorPicker (which is inside _AbaEmpresasMasterWidgetState)
start = content.find("  void _openAdvancedColorPicker() {")
if start != -1:
    end = content.find("  Color _parseColor(String hex) {", start)
    if end != -1:
        content = content[:start] + content[end:]

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Fixed _corCtrl error")