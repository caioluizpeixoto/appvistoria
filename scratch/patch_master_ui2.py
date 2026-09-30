import re

file_path = r"c:\Users\Caio\Desktop\app_vistoria\lib\features\master\presentation\widgets\aba_empresas_master_widget.dart"

new_code = """import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:path/path.dart' as p;

class AbaEmpresasMasterWidget extends StatefulWidget {
  const AbaEmpresasMasterWidget({super.key});

  @override
  State<AbaEmpresasMasterWidget> createState() => _AbaEmpresasMasterWidgetState();
}

class _AbaEmpresasMasterWidgetState extends State<AbaEmpresasMasterWidget> {
  List<Map<String, dynamic>> _empresas = [];
  bool _isLoadingList = true;

  @override
  void initState() {
    super.initState();
    _fetchEmpresas();
  }

  Future<void> _fetchEmpresas() async {
    setState(() => _isLoadingList = true);
    try {
      final supa = Supabase.instance.client;
      final data = await supa.from('empresas').select().order('created_at', ascending: false);
      setState(() {
        _empresas = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Erro ao buscar empresas: $e');
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  void _abrirFormularioCadastro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FormularioEmpresaBottomSheet(),
    ).then((_) {
      // Recarrega a lista quando o modal fechar
      _fetchEmpresas();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _empresas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Nenhuma empresa cadastrada.', style: TextStyle(color: Colors.black54, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _empresas.length,
              itemBuilder: (context, index) {
                final emp = _empresas[index];
                final corHex = emp['cor_pdf'] ?? '#FFCA28';
                final Color empColor = _parseColor(corHex);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: empColor,
                      backgroundImage: emp['logo_topo_url'] != null ? NetworkImage(emp['logo_topo_url']) : null,
                      child: emp['logo_topo_url'] == null
                          ? const Icon(Icons.business, color: Colors.white)
                          : null,
                    ),
                    title: Text(emp['razao_social'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('CNPJ: ${emp['cnpj']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        Text('Login: ${emp['email']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioCadastro,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('Nova Empresa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF183523);
  }
}

class _FormularioEmpresaBottomSheet extends StatefulWidget {
  const _FormularioEmpresaBottomSheet();

  @override
  State<_FormularioEmpresaBottomSheet> createState() => _FormularioEmpresaBottomSheetState();
}

class _FormularioEmpresaBottomSheetState extends State<_FormularioEmpresaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _razaoCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _corCtrl = TextEditingController(text: '#FFCA28');
  
  File? _logoFile;
  bool _isLoading = false;

  final List<String> _presetColors = [
    '#FFCA28', // Amarelo Ouro
    '#2196F3', // Azul
    '#4CAF50', // Verde
    '#F44336', // Vermelho
    '#FF9800', // Laranja
    '#9C27B0', // Roxo
    '#E91E63', // Rosa
    '#607D8B', // Azul Metálico
    '#222222', // Preto
  ];

  @override
  void dispose() {
    _razaoCtrl.dispose();
    _cnpjCtrl.dispose();
    _enderecoCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _corCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final supa = Supabase.instance.client;
      final session = supa.auth.currentSession;
      if (session == null) throw Exception('Não autenticado.');

      final cnpjLimpo = _cnpjCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      
      final existingEmpresa = await supa.from('empresas').select('id').eq('cnpj', cnpjLimpo).maybeSingle();
      if (existingEmpresa != null) {
        throw Exception('Já existe uma empresa com este CNPJ cadastrado!');
      }

      String? logoUrl;
      if (_logoFile != null) {
        final ext = p.extension(_logoFile!.path).isNotEmpty ? p.extension(_logoFile!.path) : '.png';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cnpjLimpo$ext';
        final filePath = 'logos/$fileName';
        
        await supa.storage.from('laudos-pdf').upload(
          filePath,
          _logoFile!,
          fileOptions: const FileOptions(upsert: true),
        );
        logoUrl = supa.storage.from('laudos-pdf').getPublicUrl(filePath);
      }

      await supa.from('empresas').insert({
        'razao_social': _razaoCtrl.text.trim(),
        'cnpj': cnpjLimpo,
        'endereco': _enderecoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'cor_pdf': _corCtrl.text.trim(),
        'logo_topo_url': logoUrl,
        'logo_marca_dagua_url': logoUrl,
      });

      final res = await supa.functions.invoke(
        'admin-create-user',
        body: {
          'email': _emailCtrl.text.trim(),
          'password': _senhaCtrl.text,
          'nome': _razaoCtrl.text.trim(),
          'empresa_nome': _razaoCtrl.text.trim(),
          'cnpj': cnpjLimpo,
        },
      );
      
      if (res.status != 200) {
        await supa.from('empresas').delete().eq('cnpj', cnpjLimpo);
        throw Exception(res.data?['error'] ?? 'Erro ao criar usuário.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Empresa e Usuário cadastrados com sucesso!'), backgroundColor: AppTheme.conforme)
        );
        Navigator.pop(context); // Fecha o bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro: $e'), backgroundColor: AppTheme.naoConforme)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF183523);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nova Empresa',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF183523)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // DADOS DA EMPRESA
                _buildSectionCard(
                  title: 'Dados da Empresa',
                  icon: Icons.business_rounded,
                  children: [
                    _buildTextField(
                      controller: _razaoCtrl,
                      label: 'Razão Social / Nome Fantasia',
                      icon: Icons.storefront_rounded,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cnpjCtrl,
                      label: 'CNPJ (Somente números)',
                      icon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _enderecoCtrl,
                      label: 'Endereço e Contatos (Será exibido no laudo)',
                      icon: Icons.location_on_rounded,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // LOGIN
                _buildSectionCard(
                  title: 'Acesso (Login do Cliente)',
                  icon: Icons.lock_person_rounded,
                  children: [
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'E-mail de Login',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _senhaCtrl,
                      label: 'Senha Inicial',
                      icon: Icons.password_rounded,
                      obscureText: true,
                      validator: (v) => (v != null && v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // CUSTOMIZAÇÃO
                _buildSectionCard(
                  title: 'Customização do Laudo',
                  icon: Icons.palette_rounded,
                  children: [
                    const Text('Cor Predominante', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    
                    // Color Picker Horizontal
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetColors.length,
                        itemBuilder: (context, index) {
                          final colorHex = _presetColors[index];
                          final isSelected = _corCtrl.text.toUpperCase() == colorHex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _corCtrl.text = colorHex;
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: _parseColor(colorHex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _corCtrl,
                      label: 'Hexadecimal (Customizado)',
                      icon: Icons.tag_rounded,
                    ),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300, width: 1.5, strokeAlign: BorderSide.strokeAlignOutside),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.upload_file_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _logoFile != null ? 'Logo Selecionada' : 'Selecionar Logo',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _logoFile != null ? p.basename(_logoFile!.path) : 'PNG/JPG Recomendado (Opcional)',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_logoFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_logoFile!, width: 48, height: 48, fit: BoxFit.cover),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // BTN SALVAR
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _salvar,
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Cadastrar Empresa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183523),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      onChanged: (v) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_code)

print("Patch UI com Lista e Cores Aplicado")