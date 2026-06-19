import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/image_service.dart';
import '../../../../injection_container.dart';
import '../../domain/vistoria_wizard_state.dart';

/// Widget padrão de inspeção de um item.
/// Cada item tem: foto(s), status, observação, e upload automático.
class InspecaoItemWidget extends StatefulWidget {
  final String itemId;
  final String label;
  final List<String> statusOptions;
  final bool obrigatoria;
  final bool showCodigoField;
  final String? codigoLabel;
  final String? codigoHint;
  final String? infoTexto; // Texto informativo extra (ex: chassi da BIN)
  final bool showDivergenciaAlert;

  const InspecaoItemWidget({
    super.key,
    required this.itemId,
    required this.label,
    required this.statusOptions,
    this.obrigatoria = false,
    this.showCodigoField = false,
    this.codigoLabel,
    this.codigoHint,
    this.infoTexto,
    this.showDivergenciaAlert = false,
  });

  @override
  State<InspecaoItemWidget> createState() => _InspecaoItemWidgetState();
}

class _InspecaoItemWidgetState extends State<InspecaoItemWidget> {
  final _imagePicker = ImagePicker();
  final _obsController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<VistoriaWizardState>();
      _obsController.text = state.getObs(widget.itemId);
      
      var cod = state.getCodigo(widget.itemId);
      if (cod.isEmpty && widget.itemId == 'foto_placa') {
        cod = state.placa;
        state.setCodigo(widget.itemId, cod);
      }
      _codigoController.text = cod;
    });
  }

  @override
  void dispose() {
    _obsController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xFile == null || !mounted) return;

    final state = context.read<VistoriaWizardState>();
    final file = File(xFile.path);

    // Adiciona localmente de imediato para feedback rápido
    state.addFotoLocal(widget.itemId, xFile.path);

    // Upload em background
    setState(() => _uploading = true);
    try {
      final imageService = sl<ImageService>();
      final url = await imageService.uploadImage(
        vistoriaId: state.vistoriaId,
        categoria: widget.itemId,
        imageFile: file,
      );
      if (url != null && mounted) {
        state.addFotoUrl(widget.itemId, url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no upload: $e'),
            backgroundColor: AppTheme.naoConforme,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VistoriaWizardState>();
    final fotos = state.getFotosLocais(widget.itemId);
    final statusAtual = state.getStatus(widget.itemId);
    final hasFoto = state.hasFoto(widget.itemId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.obrigatoria && !hasFoto
              ? AppTheme.naoConforme.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (widget.obrigatoria)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.naoConformeLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Obrigatória',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.naoConforme,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info extra (ex: chassi da BIN) ───────────────────────────────
          if (widget.infoTexto != null && widget.infoTexto!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.infoTexto!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Grade de fotos ────────────────────────────────────────────────
          if (fotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fotos.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    if (i == fotos.length) {
                      // Botão de adicionar mais
                      return GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: AppTheme.primary, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'Adicionar',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(fotos[i]),
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => state.removeFoto(widget.itemId, i),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppTheme.naoConforme,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // ── Botões de foto (se não tem foto ainda) ────────────────────────
          if (fotos.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: widget.obrigatoria
                              ? AppTheme.naoConforme.withValues(alpha: 0.6)
                              : AppTheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      onPressed: _uploading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        _uploading ? 'Enviando...' : 'Câmera',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                            color: AppTheme.primary, width: 0.5),
                      ),
                      onPressed: _uploading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Galeria',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

          // ── Campo de código encontrado (vidros, placas etc.) ──────────────
          if (widget.showCodigoField)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextFormField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: widget.codigoLabel ?? 'Código encontrado',
                  hintText: widget.codigoHint,
                  prefixIcon:
                      const Icon(Icons.qr_code_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onChanged: (v) =>
                    state.setCodigo(widget.itemId, v),
              ),
            ),

          // ── Status ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: DropdownButtonFormField<String>(
              value: statusAtual.isEmpty ? null : statusAtual,
              hint: const Text('Selecionar status'),
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(
                  _statusIcon(statusAtual),
                  size: 18,
                  color: _statusColor(statusAtual),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              items: [
                ...widget.statusOptions,
                if (statusAtual.isNotEmpty && !widget.statusOptions.contains(statusAtual)) statusAtual,
              ].map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(s),
                        size: 16,
                        color: _statusColor(s),
                      ),
                      const SizedBox(width: 8),
                      Text(s, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) state.setStatus(widget.itemId, v);
              },
            ),
          ),

          // ── Alerta de divergência ─────────────────────────────────────────
          if (widget.showDivergenciaAlert &&
              statusAtual.toLowerCase().contains('divergente'))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.naoConformeLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.naoConforme.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: AppTheme.naoConforme, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Divergência detectada! Registre o motivo nas observações.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.naoConforme),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Observação ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextFormField(
              controller: _obsController,
              maxLines: 3,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                hintText: 'Descreva detalhes relevantes...',
                prefixIcon: Icon(Icons.notes_rounded, size: 18),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => state.setObs(widget.itemId, v),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.isEmpty) return AppTheme.textHint;
    final s = status.toLowerCase();
    
    // NÃO CONFORME (Vermelho)
    if (s.contains('divergente') || s.contains('adulteração') || s.contains('reprovado') ||
        s.contains('não original') || s.contains('substituído') || s.contains('ausente') ||
        s.contains('danificado') || s.contains('colisão')) {
      return AppTheme.naoConforme;
    }
    
    // COM OBSERVAÇÃO (Laranja/Amarelo)
    if (s.contains('reparo') || s.contains('repintura') || s.contains('observação') || 
        s.contains('envelopado') || s.contains('amassado') || s.contains('riscado') ||
        s.contains('soldado') || s.contains('avaria') || s.contains('massa')) {
      return AppTheme.comObs;
    }
    
    // CONFORME (Verde)
    if (s.contains('original') || s.contains('perfeito') || s.contains('padr') || 
        s.contains('regular') || s.contains('sem reparo')) {
      return AppTheme.conforme;
    }
    
    // NEUTRO (Cinza) - "Não analisado" ou outros
    return AppTheme.textSecondary;
  }

  IconData _statusIcon(String status) {
    if (status.isEmpty) return Icons.help_outline_rounded;
    final s = status.toLowerCase();
    
    // NÃO CONFORME
    if (s.contains('divergente') || s.contains('adulteração') || s.contains('reprovado') ||
        s.contains('não original') || s.contains('ausente') || s.contains('colisão')) {
      return Icons.cancel_rounded;
    }
    if (s.contains('substituído')) {
      return Icons.swap_horizontal_circle_rounded;
    }
    if (s.contains('danificado')) {
      return Icons.broken_image_rounded;
    }

    // COM OBSERVAÇÃO
    if (s.contains('reparo') || s.contains('soldado') || s.contains('avaria')) {
      return Icons.build_circle_rounded;
    }
    if (s.contains('repintura') || s.contains('massa') || s.contains('envelopado')) {
      return Icons.format_paint_rounded;
    }
    if (s.contains('observação') || s.contains('amassado') || s.contains('riscado')) {
      return Icons.warning_rounded;
    }

    // CONFORME
    if (s.contains('original') || s.contains('perfeito') || s.contains('padr') || 
        s.contains('regular') || s.contains('sem reparo')) {
      return Icons.check_circle_rounded;
    }

    // NEUTRO
    if (s.contains('não analisado')) {
      return Icons.remove_circle_outline_rounded;
    }
    
    return Icons.radio_button_unchecked_rounded;
  }
}
