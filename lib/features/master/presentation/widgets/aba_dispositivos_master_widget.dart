import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../injection_container.dart';

class AbaDispositivosMasterWidget extends StatefulWidget {
  const AbaDispositivosMasterWidget({super.key});

  @override
  State<AbaDispositivosMasterWidget> createState() =>
      _AbaDispositivosMasterWidgetState();
}

class _AbaDispositivosMasterWidgetState
    extends State<AbaDispositivosMasterWidget> {
  final SyncService _syncService = sl<SyncService>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _todosDispositivos = [];
  List<Map<String, dynamic>> _dispositivosFiltrados = [];
  bool _isLoading = true;
  String _filtroStatus = 'todos'; // 'todos', 'pendente', 'aprovado', 'bloqueado'

  int _countPendentes = 0;
  int _countAprovados = 0;
  int _countBloqueados = 0;

  @override
  void initState() {
    super.initState();
    _carregarDispositivos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDispositivos() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _syncService.listarDispositivosMaster();
      if (mounted) {
        setState(() {
          _todosDispositivos = lista;
          _countPendentes = lista
              .where((d) => (d['status'] as String? ?? '').toLowerCase() == 'pendente')
              .length;
          _countAprovados = lista
              .where((d) => (d['status'] as String? ?? '').toLowerCase() == 'aprovado')
              .length;
          _countBloqueados = lista
              .where((d) => (d['status'] as String? ?? '').toLowerCase() == 'bloqueado')
              .length;
          _filtrarDispositivos();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dispositivos: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  void _filtrarDispositivos() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _dispositivosFiltrados = _todosDispositivos.where((d) {
        final status = (d['status'] as String? ?? '').toLowerCase();
        final matchesStatus = _filtroStatus == 'todos' || status == _filtroStatus;

        if (!matchesStatus) return false;

        if (query.isEmpty) return true;

        final id = (d['device_id'] as String? ?? '').toLowerCase();
        final model = (d['device_model'] as String? ?? '').toLowerCase();
        final nome = (d['solicitante_nome'] as String? ?? '').toLowerCase();
        final fone = (d['solicitante_telefone'] as String? ?? '').toLowerCase();

        return id.contains(query) ||
            model.contains(query) ||
            nome.contains(query) ||
            fone.contains(query);
      }).toList();
    });
  }

  Future<void> _aprovar(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Aprovar Aparelho?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja autorizar o aparelho ($deviceId) a utilizar o aplicativo de vistoria?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Liberar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await _syncService.aprovarDispositivoMaster(deviceId);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Aparelho $deviceId aprovado com sucesso!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        _carregarDispositivos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao aprovar aparelho.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bloquear(String deviceId) async {
    final motivoCtrl = TextEditingController(text: 'Acesso revogado pelo Master');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Bloquear Aparelho',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O aparelho $deviceId perderá o acesso imediato ao aplicativo.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Motivo do bloqueio',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Bloqueio'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await _syncService.bloquearDispositivoMaster(
      deviceId,
      motivo: motivoCtrl.text.trim(),
    );

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aparelho $deviceId foi bloqueado.'),
            backgroundColor: Colors.red[700],
          ),
        );
        _carregarDispositivos();
      }
    }
  }

  Future<void> _remover(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text('Excluir Registro',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja remover permanentemente o registro de $deviceId?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _syncService.removerDispositivoMaster(deviceId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro removido.')),
        );
        _carregarDispositivos();
      }
    }
  }

  void _abrirWhatsApp(String? telefone, String deviceId) async {
    if (telefone == null || telefone.isEmpty) return;
    final clean = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final num = clean.startsWith('55') ? clean : '55$clean';
    final url = Uri.parse(
        'https://wa.me/$num?text=${Uri.encodeComponent('Olá! Seu aparelho ID $deviceId foi analisado.')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros e Métricas Rápidas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1B263B),
          child: Column(
            children: [
              // Barra de Busca
              TextField(
                controller: _searchController,
                onChanged: (_) => _filtrarDispositivos(),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por ID, modelo, nome ou telefone...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF3A86FF), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarDispositivos();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0D1B2A),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Pílulas de filtro de status
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFiltroChip('todos', 'Todos', _todosDispositivos.length,
                        Colors.blueGrey),
                    const SizedBox(width: 8),
                    _buildFiltroChip('pendente', 'Pendentes', _countPendentes,
                        const Color(0xFFFFA726),
                        destaque: _countPendentes > 0),
                    const SizedBox(width: 8),
                    _buildFiltroChip('aprovado', 'Aprovados', _countAprovados,
                        const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    _buildFiltroChip('bloqueado', 'Bloqueados', _countBloqueados,
                        Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de Aparelhos
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
                )
              : _dispositivosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phonelink_off_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            _filtroStatus == 'pendente'
                                ? 'Nenhum aparelho pendente de aprovação!'
                                : 'Nenhum dispositivo encontrado.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarDispositivos,
                      color: const Color(0xFF3A86FF),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _dispositivosFiltrados.length,
                        itemBuilder: (context, index) {
                          final item = _dispositivosFiltrados[index];
                          return _buildCardDispositivo(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(
      String status, String label, int count, Color color,
      {bool destaque = false}) {
    final isSelected = _filtroStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _filtroStatus = status;
          _filtrarDispositivos();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.25)
              : const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : destaque
                    ? Colors.orange.shade700
                    : Colors.white12,
            width: isSelected || destaque ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDispositivo(Map<String, dynamic> item) {
    final status = (item['status'] as String? ?? 'pendente').toLowerCase();
    final deviceId = item['device_id'] as String? ?? 'Sem ID';
    final model = item['device_model'] as String? ?? 'Desconhecido';
    final os = item['sistema_operacional'] as String? ?? '';
    final nome = item['solicitante_nome'] as String?;
    final fone = item['solicitante_telefone'] as String?;
    final motivo = item['motivo_bloqueio'] as String?;

    DateTime? createdAt;
    if (item['created_at'] != null) {
      createdAt = DateTime.tryParse(item['created_at'].toString());
    }

    final isPendente = status == 'pendente';
    final isAprovado = status == 'aprovado';
    final isBloqueado = status == 'bloqueado';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isAprovado) {
      statusColor = const Color(0xFF4CAF50);
      statusText = 'LIBERADO';
      statusIcon = Icons.check_circle_rounded;
    } else if (isBloqueado) {
      statusColor = Colors.redAccent;
      statusText = 'BLOQUEADO';
      statusIcon = Icons.block_rounded;
    } else {
      statusColor = const Color(0xFFFFA726);
      statusText = 'AGUARDANDO APROVAÇÃO';
      statusIcon = Icons.pending_actions_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPendente
              ? const Color(0xFFFFA726).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: isPendente ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: Modelo do celular e Badge de Status
            Row(
              children: [
                Icon(Icons.smartphone_rounded, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    os.isNotEmpty && !model.toUpperCase().contains(os.toUpperCase())
                        ? '$model • $os'
                        : model,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 16),

            // Informações do Dispositivo
            Row(
              children: [
                Text(
                  'ID: ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                Expanded(
                  child: SelectableText(
                    deviceId,
                    style: const TextStyle(
                      color: Color(0xFF64DFDF),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded,
                      size: 16, color: Colors.white54),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: deviceId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID copiado!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copiar ID',
                ),
              ],
            ),

            if (nome != null && nome.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Solicitante: ',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (fone != null && fone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 14, color: Colors.white.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Telefone: ',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      fone,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_rounded,
                        size: 16, color: Color(0xFF25D366)),
                    onPressed: () => _abrirWhatsApp(fone, deviceId),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Chamar no WhatsApp',
                  ),
                ],
              ),
            ],

            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Solicitado em: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal())}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],

            if (isBloqueado && motivo != null && motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Motivo: $motivo',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 11),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Ações / Botões
            Row(
              children: [
                if (isPendente) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprovar(deviceId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aprovar Celular',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _bloquear(deviceId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Recusar',
                        style: TextStyle(fontSize: 12)),
                  ),
                ] else if (isAprovado) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _bloquear(deviceId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text('Bloquear / Revogar Acesso',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ] else if (isBloqueado) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprovar(deviceId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Desbloquear e Liberar',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white38, size: 20),
                    onPressed: () => _remover(deviceId),
                    tooltip: 'Remover Registro',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
