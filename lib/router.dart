import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // TODO: restaurar autenticação — iniciar em /splash com guard de auth
    initialLocation: '/home',
    // redirect: (context, state) {
    //   final authState = authBloc.state;
    //   final isAuth = authState is AuthAuthenticated;
    //   final isSplash = state.matchedLocation == '/splash';
    //   final isLogin = state.matchedLocation == '/login';
    //   if (isSplash) return null;
    //   if (!isAuth && !isLogin) return '/login';
    //   if (isAuth && isLogin) return '/home';
    //   return null;
    // },
    // refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
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
