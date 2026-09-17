import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/relatorio_filtros_model.dart';
import '../cubit/relatorios_cubit.dart';
import '../cubit/relatorios_state.dart';

class RelatorioFiltrosModal extends StatefulWidget {
  final RelatoriosCubit cubit;
  final RelatorioFiltrosModel filtros;

  const RelatorioFiltrosModal({
    super.key,
    required this.cubit,
    required this.filtros,
  });

  @override
  State<RelatorioFiltrosModal> createState() => _RelatorioFiltrosModalState();
}

class _RelatorioFiltrosModalState extends State<RelatorioFiltrosModal> {
  String? _cliente;
  String? _tipoServico;
  String? _perito;
  String? _digitador;
  String? _status;

  @override
  void initState() {
    super.initState();
    _cliente = widget.filtros.cliente;
    _tipoServico = widget.filtros.tipoServico;
    _perito = widget.filtros.perito;
    _digitador = widget.filtros.digitador;
    _status = widget.filtros.status;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    List<String> clientes = [];
    List<String> servicos = [];
    List<String> peritos = [];
    List<String> digitadores = [];
    List<String> statusList = [];

    if (state is RelatoriosLoaded) {
      clientes = state.dashboard.clientesDisponiveis;
      servicos = state.dashboard.servicosDisponiveis;
      peritos = state.dashboard.peritosDisponiveis;
      digitadores = state.dashboard.digitadoresDisponiveis;
      statusList = state.dashboard.statusDisponiveis;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Filtros Detalhados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Cliente
              _buildDropdownField(
                label: 'Cliente',
                value: _cliente,
                items: clientes,
                hint: 'Todos os clientes',
                onChanged: (val) => setState(() => _cliente = val),
              ),
              const SizedBox(height: 14),

              // 2. Tipo de Serviço
              _buildDropdownField(
                label: 'Tipo de Serviço',
                value: _tipoServico,
                items: servicos,
                hint: 'Todos os serviços',
                onChanged: (val) => setState(() => _tipoServico = val),
              ),
              const SizedBox(height: 14),

              // 3. Perito / Vistoriador
              _buildDropdownField(
                label: 'Perito / Vistoriador',
                value: _perito,
                items: peritos,
                hint: 'Todos os peritos',
                onChanged: (val) => setState(() => _perito = val),
              ),
              const SizedBox(height: 14),

              // 4. Digitador
              _buildDropdownField(
                label: 'Digitador / Operador',
                value: _digitador,
                items: digitadores,
                hint: 'Todos os digitadores',
                onChanged: (val) => setState(() => _digitador = val),
              ),
              const SizedBox(height: 14),

              // 5. Status da Vistoria
              _buildDropdownField(
                label: 'Status da Vistoria',
                value: _status,
                items: statusList,
                hint: 'Todos os status',
                onChanged: (val) => setState(() => _status = val),
              ),
              const SizedBox(height: 24),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _cliente = null;
                          _tipoServico = null;
                          _perito = null;
                          _digitador = null;
                          _status = null;
                        });
                        widget.cubit.aplicarFiltrosSecundarios(
                          clearCliente: true,
                          clearTipoServico: true,
                          clearPerito: true,
                          clearDigitador: true,
                          clearUnidade: true,
                          clearStatus: true,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.cubit.aplicarFiltrosSecundarios(
                          cliente: _cliente,
                          clearCliente: _cliente == null || _cliente == 'todos',
                          tipoServico: _tipoServico,
                          clearTipoServico:
                              _tipoServico == null || _tipoServico == 'todos',
                          perito: _perito,
                          clearPerito: _perito == null || _perito == 'todos',
                          digitador: _digitador,
                          clearDigitador:
                              _digitador == null || _digitador == 'todos',
                          clearUnidade: true,
                          status: _status,
                          clearStatus: _status == null || _status == 'todos',
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: validValue,
              hint: Text(hint, style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(hint, style: const TextStyle(color: AppTheme.textSecondary)),
                ),
                ...items.map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
