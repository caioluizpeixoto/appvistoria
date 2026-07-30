import re
import os

path = r'c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_radar_generator.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix SVGs
content = re.sub(r'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">', r'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">', content)

# Insert the AI section at the end of _buildSecoesFinais
# Let's find the closing of _buildSecoesFinais
# It ends with:
#       pw.Container(
#         width: double.infinity,
#         color: _kBlueLight,
#         padding: const pw.EdgeInsets.all(6),
#         child: pw.Text('Estas informações são confidenciais...
#         )
#       ),
#     ];
#   }

ai_section = '''      ),
      pw.SizedBox(height: 10),
      
      _buildSectionHeader('Avaliação de Mercado e Reparo (IA)', svgIcon: _svgMoney),
      Builder(
        builder: (context) {
          String fipeStr = _v(data, ['valorfipe', 'fipe_valor'], fallback: '0,00');
          double fipeValor = 0.0;
          try {
            fipeStr = fipeStr.replaceFirst('R$', '').replaceFirst('R\$', '').strip();
            fipeStr = fipeStr.replaceAll('.', '').replaceAll(',', '.').strip();
            fipeValor = double.tryParse(fipeStr) ?? 0.0;
          } catch (_) {}
          
          double depreciacao = fipeValor * 0.15; // 15% de depreciação padrão se não tiver outro
          // tenta pegar da base caso exista (se for API de IA externa)
          String depStr = _v(data, ['valor_reparo', 'depreciacao'], fallback: '');
          if (depStr.isNotEmpty && depStr != 'N/A') {
             try {
                String d = depStr.replaceFirst('R$', '').replaceFirst('R\$', '').strip().replaceAll('.', '').replaceAll(',', '.').strip();
                double val = double.tryParse(d) ?? depreciacao;
                if (val > 0) depreciacao = val;
             } catch (_) {}
          }
          
          double valorVenda = fipeValor - depreciacao;
          if (valorVenda < 0) valorVenda = 0.0;
          
          String formatCurrency(double v) {
            String s = v.toStringAsFixed(2).replaceAll('.', ',');
            // Add thousands separator if needed
            RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
            math.Match? match;
            String intPart = s.split(',')[0];
            String decPart = s.split(',')[1];
            intPart = intPart.replaceAllMapped(reg, (Match m) => '.');
            return 'R\$ ' + intPart + ',' + decPart;
          }
          
          return _buildDataGrid([
            ['Valor FIPE', formatCurrency(fipeValor), 'Depreciação / Concêrto', formatCurrency(depreciacao)],
            ['Valor de Venda (No Estado)', formatCurrency(valorVenda), '', ''],
          ]);
        },
      ),
    ];'''
# Wait, Builder requires flutter/widgets, but this is a pdf package.
# pw.Builder does not exist in pdf package. It's pw.Widget, we can just execute the code or use a lambda?
# In dart, we can just write an IIFE: () { ... }()
'''

ai_section_dart = """      ),
      pw.SizedBox(height: 10),
      
      _buildSectionHeader('Avaliação de Mercado e Reparo (IA)', svgIcon: _svgMoney),
      (() {
        String fipeStr = _v(data, ['valorfipe', 'fipe_valor'], fallback: '0,00');
        double fipeValor = 0.0;
        try {
          fipeStr = fipeStr.replaceAll('R\$', '').replaceAll(r'R$', '').replaceAll(' ', '');
          fipeStr = fipeStr.replaceAll('.', '').replaceAll(',', '.');
          fipeValor = double.tryParse(fipeStr) ?? 0.0;
        } catch (_) {}
        
        double depreciacao = fipeValor * 0.15; // 15% de depreciação padrão
        String depStr = _v(data, ['valor_reparo', 'depreciacao'], fallback: '');
        if (depStr.isNotEmpty && depStr != 'N/A' && depStr != 'Não informado') {
           try {
              String d = depStr.replaceAll('R\$', '').replaceAll(r'R$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
              double val = double.tryParse(d) ?? depreciacao;
              if (val > 0) depreciacao = val;
           } catch (_) {}
        }
        
        double valorVenda = fipeValor - depreciacao;
        if (valorVenda < 0) valorVenda = 0.0;
        
        String formatCurrency(double v) {
          String s = v.toStringAsFixed(2).replaceAll('.', ',');
          String intPart = s.split(',')[0];
          String decPart = s.split(',')[1];
          intPart = intPart.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "\.");
          return 'R\$ ' + intPart + ',' + decPart;
        }
        
        return _buildDataGrid([
          ['Valor FIPE', formatCurrency(fipeValor), 'Depreciação / Conserto', formatCurrency(depreciacao)],
          ['Valor de Venda (No Estado)', formatCurrency(valorVenda), '', ''],
        ]);
      })(),
    ];"""

content = content.replace("      ),\n    ];", ai_section_dart)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
