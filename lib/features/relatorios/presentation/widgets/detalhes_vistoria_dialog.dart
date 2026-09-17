import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/vistoria_relatorio_item_model.dart';

class DetalhesVistoriaDialog extends StatelessWidget {
  final VistoriaRelatorioItemModel item;

  const DetalhesVistoriaDialog({super.key, required this.item});

  void _abrirLaudo(BuildContext context) {
    if (item.pdfUrl != null && item.pdfUrl!.isNotEmpty) {
      Navigator.pop(context);
      final placaQuery = Uri.encodeComponent(item.placa.trim());
      context.push('/pdf-preview/${item.id}?path=${item.pdfUrl}&placa=$placaQuery');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta vistoria ainda não possui PDF de laudo emitido.'),
          backgroundColor: AppTheme.comObs,
        ),
      );
    }
  }

  void _abrirVistoria(BuildContext context) {
    Navigator.pop(context);
    context.push('/vistoria-wizard/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final bool isConcluido = item.isConcluido;
    final Color statusColor =
        isConcluido ? AppTheme.conforme : AppTheme.emAndamento;
    final Color statusBg =
        isConcluido ? AppTheme.conformeLight : AppTheme.emAndamentoLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Cabeçalho do Modal ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.numeroLaudo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Emitido em ${item.dataFormatada}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.statusFinal.isNotEmpty
                          ? item.statusFinal
                          : item.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Corpo com Rolagem dos Detalhes ──────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção Veículo
                    _buildSecao(
                      titulo: 'Dados do Veículo',
                      icon: Icons.directions_car_rounded,
                      campos: [
                        _ItemCampo('Placa', item.placa),
                        _ItemCampo('Chassi', item.chassi),
                        _ItemCampo('Veículo', item.veiculo),
                        _ItemCampo('Ano Mod/Fab', item.ano),
                      ],
                    ),

                    const Divider(height: 28),

                    // Seção Cliente e Operação
                    _buildSecao(
                      titulo: 'Cliente & Operação',
                      icon: Icons.store_rounded,
                      campos: [
                        _ItemCampo('Empresa Responsável', item.empresaNome),
                        _ItemCampo('Cliente Solicitante', item.cliente),
                        _ItemCampo('Perito / Vistoriador', item.perito),
                        _ItemCampo('Digitador / Operador', item.digitador),
                      ],
                    ),

                    const Divider(height: 28),

                    // Seção Serviço e Financeiro
                    _buildSecao(
                      titulo: 'Serviço & Faturamento',
                      icon: Icons.payments_rounded,
                      campos: [
                        _ItemCampo('Tipo de Serviço', item.servico),
                        _ItemCampo(
                          'Valor do Serviço',
                          item.valor > 0 ? item.valorFormatado : 'Não informado',
                          destaque: item.valor > 0,
                        ),
                      ],
                    ),

                    // Seção Parecer Técnico (se preenchido)
                    if (item.parecerTecnico.isNotEmpty) ...[
                      const Divider(height: 28),
                      _buildSecao(
                        titulo: 'Parecer Técnico',
                        icon: Icons.verified_rounded,
                        campos: [
                          _ItemCampo('Conclusão', item.parecerTecnico),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Rodapé com Botões de Ação ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final temPdf = item.pdfUrl != null && item.pdfUrl!.isNotEmpty;
                  final isCompact = constraints.maxWidth < 480;

                  if (isCompact) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _abrirVistoria(context),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: Text(
                                  item.isConcluido ? 'Ver Vistoria' : 'Abrir Vistoria',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (temPdf) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _abrirLaudo(context),
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: const Text(
                                    'Abrir Laudo',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Fechar'),
                        ),
                      ],
                    );
                  }

                  // Desktop / Tablet largo
                  return Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _abrirVistoria(context),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(
                          item.isConcluido ? 'Ver Vistoria' : 'Abrir Vistoria',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      if (temPdf) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _abrirLaudo(context),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('Abrir Laudo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required IconData icon,
    required List<_ItemCampo> campos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: campos.map((c) {
            return SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.valor.isNotEmpty ? c.valor : '-',
                    style: TextStyle(
                      fontSize: c.destaque ? 15 : 13,
                      fontWeight:
                          c.destaque ? FontWeight.w800 : FontWeight.w600,
                      color: c.destaque
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ItemCampo {
  final String label;
  final String valor;
  final bool destaque;

  _ItemCampo(this.label, this.valor, {this.destaque = false});
}
