import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/vistoria_wizard_state.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/services/ocr_crlv_service.dart';
import '../placa_camera_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Step 2 — Dados do Veículo
class StepDadosVeiculo extends StatefulWidget {
  const StepDadosVeiculo({super.key});

  @override
  State<StepDadosVeiculo> createState() => _StepDadosVeiculoState();
}

class _StepDadosVeiculoState extends State<StepDadosVeiculo> {
  final _placaCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anoFabCtrl = TextEditingController();
  final _anoModCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _combustivelCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _renavamCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _numeroGrvCtrl = TextEditingController();
  // BIN vs veículo
  final _chassiBinCtrl = TextEditingController();
  final _chassiVeiculoCtrl = TextEditingController();
  final _motorBinCtrl = TextEditingController();
  final _motorVeiculoCtrl = TextEditingController();
  final _cambioBinCtrl = TextEditingController();
  final _cambioVeiculoCtrl = TextEditingController();

  bool _isLoadingOcr = false;
  bool _foiPreenchidoPelaConsulta = false;
  late VistoriaWizardState _wizardStateRef;

  @override
  void initState() {
    super.initState();
    _wizardStateRef = context.read<VistoriaWizardState>();
    _wizardStateRef.addListener(_onStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = _wizardStateRef;
      _placaCtrl.text = s.placa;
      _marcaCtrl.text = s.marca;
      _modeloCtrl.text = s.modelo;
      _anoFabCtrl.text = s.anoFabricacao;
      _anoModCtrl.text = s.anoModelo;
      _corCtrl.text = s.cor;
      _combustivelCtrl.text = s.combustivel;
      _municipioCtrl.text = s.municipio;
      _ufCtrl.text = s.uf;
      _renavamCtrl.text = s.renavam;
      _kmCtrl.text = s.km;
      _numeroGrvCtrl.text = s.numeroGrv;
      _chassiBinCtrl.text = s.chassiBin;
      _chassiVeiculoCtrl.text = s.chassiVeiculo;
      _motorBinCtrl.text = s.motorBin;
      _motorVeiculoCtrl.text = s.motorVeiculo;
      _cambioBinCtrl.text = s.cambioBin;
      _cambioVeiculoCtrl.text = s.cambioVeiculo;
    });
  }

  void _onStateChanged() {
    if (!mounted) return;

    if (_wizardStateRef.statusConsulta == 'concluida') {
      // Como o DB pode disparar o 'statusConsulta = concluida' antes de o DAO de Veiculo sincronizar
      // os dados do veículo, aguardamos até que pelo menos um dado básico tenha chegado.
      if (_wizardStateRef.marca.isEmpty && _wizardStateRef.anoFabricacao.isEmpty && _wizardStateRef.renavam.isEmpty) {
        return;
      }

      if (!_foiPreenchidoPelaConsulta) {
        _foiPreenchidoPelaConsulta = true;
        setState(() {
          if (_placaCtrl.text.isEmpty && _wizardStateRef.placa.isNotEmpty) _placaCtrl.text = _wizardStateRef.placa;
          if (_marcaCtrl.text.isEmpty && _wizardStateRef.marca.isNotEmpty) _marcaCtrl.text = _wizardStateRef.marca;
          if (_modeloCtrl.text.isEmpty && _wizardStateRef.modelo.isNotEmpty) _modeloCtrl.text = _wizardStateRef.modelo;
          if (_anoFabCtrl.text.isEmpty && _wizardStateRef.anoFabricacao.isNotEmpty) _anoFabCtrl.text = _wizardStateRef.anoFabricacao;
          if (_anoModCtrl.text.isEmpty && _wizardStateRef.anoModelo.isNotEmpty) _anoModCtrl.text = _wizardStateRef.anoModelo;
          if (_corCtrl.text.isEmpty && _wizardStateRef.cor.isNotEmpty) _corCtrl.text = _wizardStateRef.cor;
          if (_combustivelCtrl.text.isEmpty && _wizardStateRef.combustivel.isNotEmpty) _combustivelCtrl.text = _wizardStateRef.combustivel;
          if (_municipioCtrl.text.isEmpty && _wizardStateRef.municipio.isNotEmpty) _municipioCtrl.text = _wizardStateRef.municipio;
          if (_ufCtrl.text.isEmpty && _wizardStateRef.uf.isNotEmpty) _ufCtrl.text = _wizardStateRef.uf;
          if (_renavamCtrl.text.isEmpty && _wizardStateRef.renavam.isNotEmpty) _renavamCtrl.text = _wizardStateRef.renavam;
          if (_chassiBinCtrl.text.isEmpty && _wizardStateRef.chassiBin.isNotEmpty) _chassiBinCtrl.text = _wizardStateRef.chassiBin;
          if (_chassiVeiculoCtrl.text.isEmpty && _wizardStateRef.chassiVeiculo.isNotEmpty) _chassiVeiculoCtrl.text = _wizardStateRef.chassiVeiculo;
          if (_motorBinCtrl.text.isEmpty && _wizardStateRef.motorBin.isNotEmpty) _motorBinCtrl.text = _wizardStateRef.motorBin;
          if (_motorVeiculoCtrl.text.isEmpty && _wizardStateRef.motorVeiculo.isNotEmpty) _motorVeiculoCtrl.text = _wizardStateRef.motorVeiculo;
        });
      }
    } else if (_wizardStateRef.statusConsulta == 'pendente' || _wizardStateRef.statusConsulta == 'andamento') {
      _foiPreenchidoPelaConsulta = false;
    }
  }

  @override
  void dispose() {
    _wizardStateRef.removeListener(_onStateChanged);
    for (final c in [
      _placaCtrl, _marcaCtrl, _modeloCtrl, _anoFabCtrl, _anoModCtrl,
      _corCtrl, _combustivelCtrl, _municipioCtrl, _ufCtrl, _renavamCtrl,
      _kmCtrl, _numeroGrvCtrl, _chassiBinCtrl, _chassiVeiculoCtrl,
      _motorBinCtrl, _motorVeiculoCtrl, _cambioBinCtrl, _cambioVeiculoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _persistir(VistoriaWizardState s) {
    s.placa = _placaCtrl.text;
    s.marca = _marcaCtrl.text;
    s.modelo = _modeloCtrl.text;
    s.anoFabricacao = _anoFabCtrl.text;
    s.anoModelo = _anoModCtrl.text;
    s.cor = _corCtrl.text;
    s.combustivel = _combustivelCtrl.text;
    s.municipio = _municipioCtrl.text;
    s.uf = _ufCtrl.text;
    s.renavam = _renavamCtrl.text;
    s.km = _kmCtrl.text;
    s.numeroGrv = _numeroGrvCtrl.text;
    s.chassiBin = _chassiBinCtrl.text;
    s.chassiVeiculo = _chassiVeiculoCtrl.text;
    s.motorBin = _motorBinCtrl.text;
    s.motorVeiculo = _motorVeiculoCtrl.text;
    s.cambioBin = _cambioBinCtrl.text;
    s.cambioVeiculo = _cambioVeiculoCtrl.text;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    
    // O preenchimento automático agora é tratado apenas no _onStateChanged para evitar bugs de TextField no build()

    final chassiDivergente = _chassiBinCtrl.text.isNotEmpty &&
        _chassiVeiculoCtrl.text.isNotEmpty &&
        _chassiBinCtrl.text != _chassiVeiculoCtrl.text;
    final motorDivergente = _motorBinCtrl.text.isNotEmpty &&
        _motorVeiculoCtrl.text.isNotEmpty &&
        _motorBinCtrl.text != _motorVeiculoCtrl.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Botão OCR CRLV ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoadingOcr ? null : () => _scanCrlv(ImageSource.camera),
              icon: _isLoadingOcr
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.document_scanner_rounded),
              label: Text(_isLoadingOcr ? 'Analisando documento...' : 'Ler CRLV via Câmera (Mágico)'),
            ),
          ),
          const SizedBox(height: 16),

          if (!state.isChecklist)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primary),
                ),
                onPressed: () {
                  setState(() {
                    if (state.placa.isNotEmpty) _placaCtrl.text = state.placa;
                    if (state.marca.isNotEmpty) _marcaCtrl.text = state.marca;
                    if (state.modelo.isNotEmpty) _modeloCtrl.text = state.modelo;
                    if (state.anoFabricacao.isNotEmpty) _anoFabCtrl.text = state.anoFabricacao;
                    if (state.anoModelo.isNotEmpty) _anoModCtrl.text = state.anoModelo;
                    if (state.cor.isNotEmpty) _corCtrl.text = state.cor;
                    if (state.combustivel.isNotEmpty) _combustivelCtrl.text = state.combustivel;
                    if (state.municipio.isNotEmpty) _municipioCtrl.text = state.municipio;
                    if (state.uf.isNotEmpty) _ufCtrl.text = state.uf;
                    if (state.renavam.isNotEmpty) _renavamCtrl.text = state.renavam;
                    if (state.km.isNotEmpty) _kmCtrl.text = state.km;
                    if (state.numeroGrv.isNotEmpty) _numeroGrvCtrl.text = state.numeroGrv;
                    if (state.chassiBin.isNotEmpty) _chassiBinCtrl.text = state.chassiBin;
                    if (state.chassiVeiculo.isNotEmpty) _chassiVeiculoCtrl.text = state.chassiVeiculo;
                    if (state.motorBin.isNotEmpty) _motorBinCtrl.text = state.motorBin;
                    if (state.motorVeiculo.isNotEmpty) _motorVeiculoCtrl.text = state.motorVeiculo;
                    if (state.cambioBin.isNotEmpty) _cambioBinCtrl.text = state.cambioBin;
                    if (state.cambioVeiculo.isNotEmpty) _cambioVeiculoCtrl.text = state.cambioVeiculo;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulário atualizado com os últimos dados pesquisados/salvos!'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Atualizar / Preencher Formulario'),
              ),
            ),
          
          if (state.arquivoPesquisaUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.conforme,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final uri = Uri.parse(state.arquivoPesquisaUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Ver Pesquisa'),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          const SizedBox(height: 24),

          _buildSection(
            icon: Icons.directions_car_rounded,
            title: 'Identificação',
            children: [
              _buildRow([
                _buildField('Placa', _placaCtrl,
                    icon: Icons.credit_card_rounded,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded),
                      tooltip: 'Scanear Placa',
                      onPressed: () async {
                        final placa = await Navigator.of(context).push<String?>(
                          MaterialPageRoute(builder: (_) => const PlacaCameraScreen()),
                        );
                        if (placa != null) {
                          setState(() {
                            final limpo = placa.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                            final formatted = limpo.length >= 7 ? '${limpo.substring(0, 3)}-${limpo.substring(3, 7)}' : limpo;
                            _placaCtrl.text = formatted;
                          });
                        }
                      },
                    ),
                    caps: TextCapitalization.characters,
                    onChanged: (_) => setState(() {})),
                _buildField('Renavam', _renavamCtrl,
                    icon: Icons.confirmation_num_rounded),
              ]),
              const SizedBox(height: 12),
              _buildRow([
                _buildField('Marca', _marcaCtrl,
                    caps: TextCapitalization.words),
                _buildField('Modelo', _modeloCtrl,
                    caps: TextCapitalization.words),
              ]),
              const SizedBox(height: 12),
              _buildRow([
                _buildField('Ano Fab.', _anoFabCtrl,
                    keyboard: TextInputType.number),
                _buildField('Ano Mod.', _anoModCtrl,
                    keyboard: TextInputType.number),
              ]),
              const SizedBox(height: 12),
              _buildRow([
                _buildField('Cor', _corCtrl,
                    icon: Icons.color_lens_rounded,
                    caps: TextCapitalization.words),
                _buildField('Combustível', _combustivelCtrl),
              ]),
              const SizedBox(height: 12),
              _buildRow([
                _buildField('Município', _municipioCtrl,
                    caps: TextCapitalization.words),
                _buildField('UF', _ufCtrl,
                    caps: TextCapitalization.characters),
              ]),
              const SizedBox(height: 12),
              _buildRow([
                _buildField('KM / Hodômetro', _kmCtrl,
                    icon: Icons.speed_rounded,
                    keyboard: TextInputType.number),
                _buildField('Nº GRV', _numeroGrvCtrl),
              ]),
            ],
          ),

          if (!state.isChecklist) ...[
            const SizedBox(height: 24),

          // ── Chassi: BIN vs Veículo ────────────────────────────────────────
          _buildSection(
            icon: Icons.tag_rounded,
            title: 'Chassi',
            children: [
              _buildField('Chassi na BIN (consulta)',
                  _chassiBinCtrl,
                  icon: Icons.cloud_done_rounded,
                  caps: TextCapitalization.characters,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              _buildField('Chassi no veículo (encontrado)',
                  _chassiVeiculoCtrl,
                  icon: Icons.search_rounded,
                  caps: TextCapitalization.characters,
                  onChanged: (_) => setState(() {})),
              if (chassiDivergente) _buildDivergenciaAlert('Chassi'),
            ],
          ),

          const SizedBox(height: 24),

          // ── Motor: BIN vs Veículo ────────────────────────────────────────
          _buildSection(
            icon: Icons.settings_rounded,
            title: 'Motor',
            children: [
              _buildField('Motor na BIN (consulta)', _motorBinCtrl,
                  icon: Icons.cloud_done_rounded,
                  caps: TextCapitalization.characters,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              _buildField('Motor no veículo (encontrado)', _motorVeiculoCtrl,
                  icon: Icons.search_rounded,
                  caps: TextCapitalization.characters,
                  onChanged: (_) => setState(() {})),
              if (motorDivergente) _buildDivergenciaAlert('Motor'),
            ],
          ),

          const SizedBox(height: 24),

          // ── Câmbio: BIN vs Veículo ───────────────────────────────────────
          _buildSection(
            icon: Icons.settings_input_component_rounded,
            title: 'Câmbio',
            children: [
              _buildField('Câmbio na BIN', _cambioBinCtrl,
                  caps: TextCapitalization.characters),
              const SizedBox(height: 10),
              _buildField('Câmbio no veículo', _cambioVeiculoCtrl,
                  caps: TextCapitalization.characters),
            ],
          ),

          ],
          const SizedBox(height: 32),
          // Botão salvar dados
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _persistir(state);
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                state.notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados do veículo salvos!'),
                    backgroundColor: AppTheme.conforme,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar Dados do Veículo'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children
          .expand((c) => [Expanded(child: c), const SizedBox(width: 10)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    Widget? suffixIcon,
    TextCapitalization caps = TextCapitalization.none,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      textCapitalization: caps,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
    );
  }

  Widget _buildDivergenciaAlert(String campo) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.naoConformeLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.naoConforme.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: AppTheme.naoConforme, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠️ $campo DIVERGENTE: o valor da BIN difere do encontrado no veículo!',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.naoConforme,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanCrlv(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    if (pickedFile == null) return;

    setState(() => _isLoadingOcr = true);

    try {
      final file = File(pickedFile.path);
      final result = await OcrCrlvService.scanImage(file);

      if (result.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível encontrar dados legíveis na imagem.'),
              backgroundColor: AppTheme.naoConforme,
            ),
          );
        }
      } else {
        setState(() {
          if (result.placa.isNotEmpty) _placaCtrl.text = result.placa;
          if (result.renavam.isNotEmpty) _renavamCtrl.text = result.renavam;
          if (result.chassi.isNotEmpty) {
            _chassiVeiculoCtrl.text = result.chassi;
            if (!context.read<VistoriaWizardState>().isChecklist) _chassiBinCtrl.text = result.chassi; // auto fill bin if cautious
          }
          if (result.cor.isNotEmpty) _corCtrl.text = result.cor;
          if (result.combustivel.isNotEmpty) _combustivelCtrl.text = result.combustivel;
          if (result.anoFabricacao.isNotEmpty) _anoFabCtrl.text = result.anoFabricacao;
          if (result.anoModelo.isNotEmpty) _anoModCtrl.text = result.anoModelo;
          if (result.marcaModelo.isNotEmpty) _marcaCtrl.text = result.marcaModelo;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados capturados com sucesso! Revise os campos preenchidos.'),
              backgroundColor: AppTheme.conforme,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingOcr = false);
    }
  }
}
