import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class DetalhesLaudoMasterSheet extends StatelessWidget {
  final Map<String, dynamic> laudo;

  const DetalhesLaudoMasterSheet({super.key, required this.laudo});

  static void show(BuildContext context, Map<String, dynamic> laudo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DetalhesLaudoMasterSheet(laudo: laudo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numeroLaudo = laudo['numero_laudo'] ?? 'S/N';
    final placa = laudo['placa'] ?? 'SEM PLACA';
    final chassi = laudo['chassi'] ?? 'NÃO INFORMADO';
    final status = (laudo['status'] as String? ?? 'em_andamento').toUpperCase();

    final dadosCompletos = laudo['dados_completos'] as Map<String, dynamic>?;
    final vistoriaJson = dadosCompletos?['vistoria'] as Map<String, dynamic>?;
    final veiculoJson = dadosCompletos?['veiculo'] as Map<String, dynamic>?;

    final rawEmpresaNome = (laudo['empresa_nome'] as String?) ??
        (vistoriaJson?['unidade'] as String?) ??
        '';
    final empresaCnpj = (laudo['empresa_cnpj'] as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final userId = laudo['user_id'] as String? ?? '';

    String empresaNome = rawEmpresaNome;
    if (empresaNome.isEmpty ||
        empresaNome.contains('NÃO CADASTRADA') ||
        empresaNome.contains('NÃO IDENTIFICADA') ||
        empresaNome == 'APP VISTORIA') {
      if (empresaCnpj == '11977969000133' || userId == '1ca7c0b0-69f6-4baf-989c-4711fa1a0a81') {
        empresaNome = 'SUMARÉ VISTORIAS';
      } else if (empresaCnpj == '08420171000181') {
        empresaNome = 'ULTRA VISÃO INDAIATUBA';
      } else if (empresaCnpj == '08420171000424') {
        empresaNome = 'ULTRA VISÃO SALTO';
      } else if (empresaCnpj == '22931906000162') {
        empresaNome = 'ULTRA VISÃO MONTE MOR';
      } else if (empresaCnpj == '24868718000162') {
        empresaNome = 'AUTO PROVE VISTORIAS';
      } else if (empresaNome.isEmpty) {
        empresaNome = 'EMPRESA NÃO IDENTIFICADA';
      }
    }

    final vistoriador = vistoriaJson?['vistoriadorNome'] as String? ?? 'Não informado';
    final parecer = vistoriaJson?['parecerTecnico'] as String? ??
        vistoriaJson?['statusFinal'] as String? ??
        laudo['status'] as String? ??
        'Em análise';

    final marca = (veiculoJson?['marca'] as String? ?? '').trim();
    final modelo = (veiculoJson?['modelo'] as String? ?? '').trim();
    String marcaModelo = '';
    if (marca.isNotEmpty && modelo.isNotEmpty) {
      final marcaUpper = marca.toUpperCase();
      final modeloUpper = modelo.toUpperCase();
      final firstWord = modeloUpper.split(RegExp(r'[\s/]+')).first;
      final isDup = modeloUpper.startsWith(marcaUpper) ||
          marcaUpper.startsWith(firstWord) ||
          (marcaUpper.contains('VOLKSWAGEN') && (modeloUpper.startsWith('VW') || modeloUpper.startsWith('I/VW'))) ||
          (marcaUpper.contains('VW') && (modeloUpper.startsWith('VW') || modeloUpper.startsWith('VOLKSWAGEN'))) ||
          (marcaUpper.contains('CHEVROLET') && (modeloUpper.startsWith('GM') || modeloUpper.startsWith('CHEV'))) ||
          (marcaUpper.contains('FIAT') && modeloUpper.startsWith('FIAT'));

      marcaModelo = isDup ? modelo : '$marca $modelo';
    } else {
      marcaModelo = modelo.isNotEmpty ? modelo : (marca.isNotEmpty ? marca : 'SEM VEÍCULO');
    }

    final ano = '${veiculoJson?['anoFabricacao'] ?? '-'}/${veiculoJson?['anoModelo'] ?? '-'}';
    final cor = veiculoJson?['cor'] ?? '-';
    final km = veiculoJson?['km']?.toString() ?? '-';

    final createdAtStr = laudo['created_at'] as String?;
    DateTime? data;
    if (createdAtStr != null) {
      data = DateTime.tryParse(createdAtStr);
    }
    final dataFormatada = data != null
        ? DateFormat('dd/MM/yyyy às HH:mm').format(data.toLocal())
        : 'Data não informada';

    final pdfUrl = vistoriaJson?['pdfUrl'] as String? ?? laudo['pdf_url'] as String?;
    final vistoriaId = laudo['id']?.toString() ?? '';
    final webUrl = 'https://cmcpmppgpbrufrxznost.supabase.co/functions/v1/visualizar-laudo?id=$vistoriaId';

    Color statusColor;
    if (status.contains('APROVADO') && !status.contains('APONTAMENTO')) {
      statusColor = AppTheme.success;
    } else if (status.contains('REPROVADO')) {
      statusColor = AppTheme.error;
    } else if (status.contains('APONTAMENTO')) {
      statusColor = AppTheme.warning;
    } else {
      statusColor = AppTheme.primary;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppTheme.primary),
                    tooltip: 'Compartilhar Link do Laudo',
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'Laudo Cautelar do Veículo $placa (Laudo nº $numeroLaudo)\nVisualização: $webUrl',
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Veículo & Placa
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: Text(
                          placa,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              marcaModelo.isNotEmpty ? marcaModelo : 'Veículo sem marca/modelo',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Laudo nº $numeroLaudo',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Empresa Emissora Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business_rounded, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Empresa Emissora',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          empresaNome,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 16, color: AppTheme.textHint),
                            const SizedBox(width: 6),
                            Text(
                              'Vistoriador: $vistoriador',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textHint),
                            const SizedBox(width: 6),
                            Text(
                              'Emitido em: $dataFormatada',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detalhes do Veículo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ficha Técnica do Veículo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Chassi', chassi),
                        _infoRow('Ano Fab/Mod', ano),
                        _infoRow('Cor', cor),
                        _infoRow('KM', km != '-' ? '$km km' : '-'),
                        _infoRow('Parecer', parecer),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ações Master
                  if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fecha o modal
                        final placaQuery = Uri.encodeComponent(placa.trim());
                        context.push('/pdf-preview/$vistoriaId?path=$pdfUrl&placa=$placaQuery');
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Visualizar Laudo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
