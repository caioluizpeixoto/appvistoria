import re

file_path = r"c:\Users\Caio\Desktop\app_vistoria\lib\features\master\presentation\widgets\aba_empresas_master_widget.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Adicionar import
if "flutter_colorpicker" not in content:
    content = content.replace("import 'package:image_picker/image_picker.dart';", "import 'package:image_picker/image_picker.dart';\nimport 'package:flutter_colorpicker/flutter_colorpicker.dart';")

# Adicionar o metodo _openAdvancedColorPicker()
metodo = """
  void _openAdvancedColorPicker() {
    Color pickerColor = _parseColor(_corCtrl.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paleta Avançada', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (Color color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                final hex = pickerColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                _corCtrl.text = '#' + hex.substring(2);
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
"""

if "_openAdvancedColorPicker" not in content:
    content = content.replace("  Color _parseColor(String hex) {", metodo + "\n  Color _parseColor(String hex) {")

# Adicionar botao de cor avançada no build
btn_html = """
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openAdvancedColorPicker,
                      icon: const Icon(Icons.colorize_rounded, color: Colors.black87),
                      label: const Text('Ajuste Fino de Cor (Arraste e Escolha)', style: TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
"""

content = content.replace("                    const SizedBox(height: 12);\n                    _buildTextField(", btn_html)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Colorpicker adicionado!")