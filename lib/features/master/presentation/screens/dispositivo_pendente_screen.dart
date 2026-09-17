import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/device_security_service.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';

class DispositivoPendenteScreen extends StatefulWidget {
  const DispositivoPendenteScreen({super.key});

  @override
  State<DispositivoPendenteScreen> createState() =>
      _DispositivoPendenteScreenState();
}

class _DispositivoPendenteScreenState extends State<DispositivoPendenteScreen> {
  final DeviceSecurityService _deviceService = sl<DeviceSecurityService>();

  String _deviceId = '';
  String _deviceModel = '';
  String _status = 'pendente';
  String? _motivoBloqueio;
  bool _isLoading = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosDispositivo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _carregarDadosDispositivo() async {
    setState(() => _isLoading = true);

    try {
      final id = await _deviceService.getDeviceId();
      final model = await _deviceService.getDeviceModel();

      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      String? userId;
      if (authState is AuthAuthenticated) {
        userId = authState.user.id;
      }

      final check = await _deviceService.checkDeviceStatus(
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _deviceId = id;
          _deviceModel = model;
          _status = check['status'] ?? 'pendente';
          _motivoBloqueio = check['motivo'];
          _isLoading = false;
        });

        // Se já foi aprovado enquanto estava abrindo, redireciona
        if (check['isApproved'] == true) {
          _redirecionarAprovado();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _redirecionarAprovado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Aparelho autorizado com sucesso!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  Future<void> _verificarStatusNovamente() async {
    setState(() => _isChecking = true);
    try {
      final authState = context.read<AuthBloc>().state;
      String? userId = authState is AuthAuthenticated ? authState.user.id : null;

      final res = await _deviceService.checkDeviceStatus(
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _status = res['status'] ?? 'pendente';
          _motivoBloqueio = res['motivo'];
          _isChecking = false;
        });

        if (res['isApproved'] == true) {
          _redirecionarAprovado();
        } else if (_status == 'bloqueado') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_motivoBloqueio ?? 'Acesso negado para este aparelho.'),
              backgroundColor: Colors.red[700],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aparelho ainda aguardando aprovação do Master.'),
              backgroundColor: Color(0xFFF57C00),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao checar aprovação: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }



  void _copiarId() {
    Clipboard.setData(ClipboardData(text: _deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ ID copiado para a área de transferência!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBloqueado = _status == 'bloqueado';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Ícone Principal de Bloqueio
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBloqueado
                            ? Colors.red.withValues(alpha: 0.15)
                            : const Color(0xFF3A86FF).withValues(alpha: 0.15),
                        border: Border.all(
                          color: isBloqueado
                              ? Colors.red.shade400
                              : const Color(0xFF3A86FF),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isBloqueado
                            ? Icons.phonelink_erase_rounded
                            : Icons.phonelink_lock_rounded,
                        size: 46,
                        color: isBloqueado
                            ? Colors.red.shade400
                            : const Color(0xFF3A86FF),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título e Descrição
                    Text(
                      isBloqueado
                          ? 'Aparelho Bloqueado'
                          : 'Aprovação de Aparelho',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isBloqueado
                          ? (_motivoBloqueio ??
                              'O acesso deste aparelho foi revogado pelo Administrador Master.')
                          : 'Para sua segurança, este aparelho precisa de aprovação antes do uso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card de Identificação do Aparelho
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B263B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF415A77).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'IDENTIFICADOR DO APARELHO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isBloqueado
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : const Color(0xFFF57C00).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isBloqueado ? 'BLOQUEADO' : 'PENDENTE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isBloqueado
                                        ? Colors.redAccent
                                        : const Color(0xFFFFA726),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF3A86FF).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _deviceId,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64DFDF),
                                      letterSpacing: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      color: Colors.white, size: 20),
                                  onPressed: _copiarId,
                                  tooltip: 'Copiar ID',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.smartphone_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Modelo: $_deviceModel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),



                    // Botão 2: Verificar se já foi aprovado
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : _verificarStatusNovamente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A86FF),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 20),
                        label: Text(
                          _isChecking
                              ? 'Consultando autorização...'
                              : 'Verificar se já fui liberado',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão de Trocar Conta / Sair
                    TextButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        context.go('/login');
                      },
                      icon: Icon(Icons.logout_rounded,
                          size: 16, color: Colors.white.withValues(alpha: 0.6)),
                      label: Text(
                        'Entrar com outra conta',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
      ),
    );
  }
}
