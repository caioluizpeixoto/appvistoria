import re

file_path = r"c:\Users\Caio\Desktop\app_vistoria\lib\core\services\pdf_generator_service.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

if "package:http/http.dart" not in content:
    content = content.replace("import 'package:supabase_flutter/supabase_flutter.dart';", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:http/http.dart' as http;")

# Inject class variables and method
class_vars = """
  PdfColor _dynamicThemeColor = _kOrange;
  pw.ImageProvider? _dynamicLogoImage;
  pw.ImageProvider? _dynamicWatermarkImage;

  Future<void> _loadEmpresaConfig() async {
    _dynamicThemeColor = _kOrange;
    _dynamicLogoImage = null;
    _dynamicWatermarkImage = null;
    try {
      final supa = Supabase.instance.client;
      final user = supa.auth.currentUser;
      if (user != null) {
        final cnpj = user.userMetadata?['cnpj'];
        if (cnpj != null && cnpj.toString().isNotEmpty) {
          final data = await supa
              .from('empresas')
              .select('cor_pdf, logo_topo_url, logo_marca_dagua_url')
              .eq('cnpj', cnpj)
              .maybeSingle();
              
          if (data != null) {
            final cor = data['cor_pdf'];
            if (cor != null && cor.toString().isNotEmpty) {
              final hex = cor.toString().replaceAll('#', '');
              _dynamicThemeColor = PdfColor.fromHex('#$hex');
            }
            final logoTopo = data['logo_topo_url'];
            if (logoTopo != null && logoTopo.toString().isNotEmpty) {
              final res = await http.get(Uri.parse(logoTopo));
              if (res.statusCode == 200) {
                _dynamicLogoImage = pw.MemoryImage(res.bodyBytes);
              }
            }
            final logoMarca = data['logo_marca_dagua_url'];
            if (logoMarca != null && logoMarca.toString().isNotEmpty) {
              final res = await http.get(Uri.parse(logoMarca));
              if (res.statusCode == 200) {
                _dynamicWatermarkImage = pw.MemoryImage(res.bodyBytes);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar config da empresa: $e');
    }
  }

"""

if "_dynamicThemeColor" not in content:
    content = content.replace("class PdfGeneratorService {", "class PdfGeneratorService {\n" + class_vars)

# Load config at start of generateLaudoCompleto
if "await _loadEmpresaConfig();" not in content:
    content = content.replace(
        "Future<String?> generateLaudoCompleto({",
        "Future<String?> generateLaudoCompleto({\n" + "    required Vistoria vistoria,\n    required Veiculo veiculo,\n    VistoriaWizardState? wizardState,\n  }) async {\n    await _loadEmpresaConfig();\n    // _rest_"
    )
    # the replacement above breaks signature if not careful. Let's do it safely
    content = content.replace(
        "  Future<String?> generateLaudoCompleto({\n    required Vistoria vistoria,\n    required Veiculo veiculo,\n    VistoriaWizardState? wizardState,\n  }) async {\n    await _loadEmpresaConfig();\n    // _rest_",
        "  Future<String?> generateLaudoCompleto({\n    required Vistoria vistoria,\n    required Veiculo veiculo,\n    VistoriaWizardState? wizardState,\n  }) async {\n    await _loadEmpresaConfig();"
    )
    # Fix the duplicate signature replace issue:
    content = re.sub(
        r"Future<String\?> generateLaudoCompleto\(\{\s*required Vistoria vistoria,\s*required Veiculo veiculo,\s*VistoriaWizardState\? wizardState,\s*\}\) async \{",
        "Future<String?> generateLaudoCompleto({\n    required Vistoria vistoria,\n    required Veiculo veiculo,\n    VistoriaWizardState? wizardState,\n  }) async {\n    await _loadEmpresaConfig();",
        content,
        count=1
    )

# Use _dynamicThemeColor instead of _kOrange in buildFichaTecnicaPages
content = content.replace("final themeGreen = _kOrange; // amarelo ouro", "final themeGreen = _dynamicThemeColor;")
content = content.replace("return _kOrange;", "return _dynamicThemeColor;")
content = content.replace("PdfColor.fromHex('#263238')", "_dynamicThemeColor") # Just to make sure table headers get it
content = content.replace("color: _kOrange", "color: _dynamicThemeColor")
content = content.replace("bgColor: _kOrange", "bgColor: _dynamicThemeColor")

# Update logo loading
old_logo = """    // Carregar logo se existir (senão usa placeholder)
    pw.ImageProvider? logoImage = await _loadAssetImage([
      'assets/images/topo.pdf.png',
      'assets/images/topo.pdf.PNG',
      'assets/images/topo.png',
      'assets/images/logo.pdf.png',
      'assets/images/logo.png',
    ]);
    pw.ImageProvider? marcaAguaBw = logoImage;"""

new_logo = """    // Carregar logo se existir (senão usa placeholder)
    pw.ImageProvider? logoImage = _dynamicLogoImage ?? await _loadAssetImage([
      'assets/images/topo.pdf.png',
      'assets/images/topo.pdf.PNG',
      'assets/images/topo.png',
      'assets/images/logo.pdf.png',
      'assets/images/logo.png',
    ]);
    pw.ImageProvider? marcaAguaBw = _dynamicWatermarkImage ?? logoImage;"""

content = content.replace(old_logo, new_logo)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patch aplicado com sucesso")