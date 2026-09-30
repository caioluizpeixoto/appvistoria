import re

file_path = r"c:\Users\Caio\Desktop\app_vistoria\lib\features\master\presentation\widgets\aba_empresas_master_widget.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_build_method = """  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova Empresa White-Label',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF183523)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cadastre uma nova empresa franqueada ou cliente. Ela terá seu próprio acesso e laudos com sua marca e cor.',
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),

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
              title: 'Customização do Laudo (PDF)',
              icon: Icons.palette_rounded,
              children: [
                _buildTextField(
                  controller: _corCtrl,
                  label: 'Cor Predominante (Hexadecimal)',
                  icon: Icons.color_lens_rounded,
                ),
                const SizedBox(height: 16),
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
                                _logoFile != null ? p.basename(_logoFile!.path) : 'Formato PNG ou JPG recomendado',
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
            const SizedBox(height: 40),
          ],
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
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

start_idx = content.find("  @override\n  Widget build(BuildContext context) {")
if start_idx != -1:
    content = content[:start_idx] + new_build_method

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("UI Refactored")