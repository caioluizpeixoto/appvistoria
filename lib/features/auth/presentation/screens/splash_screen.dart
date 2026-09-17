import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/device_security_service.dart';
import '../blocs/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthCheckSession());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Se for Master, bypass imediato
          if (state.user.isMaster) {
            context.go('/home');
            return;
          }
          final isApproved = await sl<DeviceSecurityService>()
              .isDeviceApproved(userId: state.user.id);
          if (!context.mounted) return;
          if (isApproved) {
            context.go('/home');
          } else {
            context.go('/dispositivo-pendente');
          }
        } else if (state is AuthUnauthenticated) {
          final isApproved =
              await sl<DeviceSecurityService>().isDeviceApproved();
          if (!context.mounted) return;
          if (isApproved) {
            context.go('/login');
          } else {
            context.go('/dispositivo-pendente');
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1565C0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 52,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vistorias',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vistoria Cautelar Profissional',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
