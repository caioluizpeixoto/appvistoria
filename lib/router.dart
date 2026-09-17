import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/vistoria/domain/vistoria_type.dart';
import 'features/vistoria/presentation/screens/home_screen.dart';
import 'features/vistoria/presentation/screens/identificacao_screen.dart';
import 'features/vistoria/presentation/screens/inspecao_screen.dart';
import 'features/vistoria/presentation/screens/pintura_screen.dart';
import 'features/vistoria/presentation/screens/fotos_screen.dart';
import 'features/vistoria/presentation/screens/revisao_screen.dart';
import 'features/vistoria/presentation/screens/vistoria_wizard_screen.dart';
import 'features/pdf/presentation/screens/pdf_preview_screen.dart';
import 'features/consulta_bin/presentation/screens/historico_consultas_screen.dart';
import 'features/vistoria/presentation/screens/historico_vistorias_screen.dart';
import 'features/vistoria/presentation/screens/historico_radar_screen.dart';
import 'features/vistoria/presentation/screens/vistoriadores_screen.dart';
import 'features/vistoria/presentation/screens/clientes_screen.dart';
import 'features/wallet/presentation/screens/carteira_screen.dart';
import 'features/wallet/presentation/screens/adicionar_saldo_screen.dart';
import 'features/wallet/presentation/screens/minhas_recargas_screen.dart';
import 'injection_container.dart';
import 'core/services/device_security_service.dart';
import 'features/master/presentation/screens/painel_master_screen.dart';
import 'features/master/presentation/screens/dispositivo_pendente_screen.dart';
import 'features/relatorios/presentation/screens/relatorios_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuth = authState is AuthAuthenticated;
      final isMaster = isAuth && authState.user.isMaster;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isDispositivo = state.matchedLocation == '/dispositivo-pendente';

      if (isSplash) return null;
      if (isDispositivo) return null;

      // Allow unauthenticated users to access login and register
      if (!isAuth) {
        if (isLogin || isRegister) return null;
        return '/login';
      }

      // If they ARE authenticated, check device security
      final deviceSec = sl<DeviceSecurityService>();
      final isApproved = isMaster || deviceSec.isCachedApproved;
      if (!isApproved) {
        if (isDispositivo) return null;
        return '/dispositivo-pendente';
      }

      // Se está autenticado e aprovado, não deve ficar no login, registro ou tela de pendente
      if (isLogin || isRegister || isDispositivo) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dispositivo-pendente',
        builder: (ctx, state) => const DispositivoPendenteScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (ctx, state) => const HomeScreen(),
      ),
      // Identificação de veículo — recebe o tipo de vistoria pelo slug
      GoRoute(
        path: '/identificacao/:tipo',
        builder: (ctx, state) {
          final slug = state.pathParameters['tipo'] ?? 'cautelar-carro';
          final tipo = TipoVistoria.fromSlug(slug);
          final extraData = state.extra as Map<String, dynamic>?;
          return IdentificacaoScreen(tipo: tipo, dadosIniciais: extraData);
        },
      ),
      GoRoute(
        path: '/historico-consultas',
        builder: (ctx, state) => const HistoricoConsultasScreen(),
      ),
      GoRoute(
        path: '/historico-vistorias',
        builder: (ctx, state) => const HistoricoVistoriasScreen(),
      ),
      GoRoute(
        path: '/historico-radar',
        builder: (ctx, state) => const HistoricoRadarScreen(),
      ),
      GoRoute(
        path: '/vistoriadores',
        builder: (ctx, state) => const VistoriadoresScreen(),
      ),
      GoRoute(
        path: '/clientes',
        builder: (ctx, state) => const ClientesScreen(),
      ),
      // Carteira Financeira Pré-paga
      GoRoute(
        path: '/carteira',
        builder: (ctx, state) => const CarteiraScreen(),
      ),
      GoRoute(
        path: '/carteira/adicionar-saldo',
        builder: (ctx, state) => const AdicionarSaldoScreen(),
      ),
      GoRoute(
        path: '/carteira/recargas',
        builder: (ctx, state) => const MinhasRecargasScreen(),
      ),
      // Relatórios e Dashboard Executivo
      GoRoute(
        path: '/relatorios',
        builder: (ctx, state) => const RelatoriosScreen(),
      ),
      // Painel Master (Admin Master)
      GoRoute(
        path: '/master/painel',
        builder: (ctx, state) => const PainelMasterScreen(),
      ),
      // Etapas da vistoria
      GoRoute(
        path: '/inspecao/:vistoriaId',
        builder: (ctx, state) => InspecaoScreen(
          vistoriaId: state.pathParameters['vistoriaId']!,
        ),
      ),
      GoRoute(
        path: '/pintura/:vistoriaId',
        builder: (ctx, state) => PinturaScreen(
          vistoriaId: state.pathParameters['vistoriaId']!,
        ),
      ),
      GoRoute(
        path: '/fotos/:vistoriaId',
        builder: (ctx, state) => FotosScreen(
          vistoriaId: state.pathParameters['vistoriaId']!,
        ),
      ),
      GoRoute(
        path: '/revisao/:vistoriaId',
        builder: (ctx, state) => RevisaoScreen(
          vistoriaId: state.pathParameters['vistoriaId']!,
        ),
      ),
      // Novo: Wizard completo de Vistoria Cautelar
      GoRoute(
        path: '/vistoria-wizard/:vistoriaId',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VistoriaWizardScreen(
            vistoriaId: state.pathParameters['vistoriaId']!,
            dadosIniciais: extra?['dadosIniciais'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/pdf-preview/:vistoriaId',
        builder: (ctx, state) => PdfPreviewScreen(
          vistoriaId: state.pathParameters['vistoriaId']!,
          pdfPath: state.uri.queryParameters['path'],
          placa: state.uri.queryParameters['placa'],
        ),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.error}'),
      ),
    ),
  );
}

/// Converte stream do BLoC em Listenable para o GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
