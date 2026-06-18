import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'injection_container.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initDependencies();

  runApp(const CautelarApp());
}

class CautelarApp extends StatefulWidget {
  const CautelarApp({super.key});

  @override
  State<CautelarApp> createState() => _CautelarAppState();
}

class _CautelarAppState extends State<CautelarApp> {
  late final AuthBloc _authBloc;
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(sl());
    _router = buildRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Vistorias',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
