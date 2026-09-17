import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_vistoria/injection_container.dart';
import 'package:app_vistoria/database/app_database.dart' as import_app_database;
import 'package:app_vistoria/core/services/sync_service.dart' as import_sync_service;
import 'package:app_vistoria/core/services/device_security_service.dart' as import_device_sec;
import 'package:app_vistoria/core/services/empresa_rodape_helper.dart' as import_rodape;

// ── Events ────────────────────────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckSession extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  AuthLoginRequested({required this.username, required this.password});
  @override
  List<Object?> get props => [username];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String username;
  final String password;
  final String role;
  AuthRegisterRequested(
      {required this.name,
      required this.username,
      required this.password,
      this.role = 'usuario'});
  @override
  List<Object?> get props => [name, username, role];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final AuthState supabaseAuthState;
  AuthStateChanged(this.supabaseAuthState);
  @override
  List<Object?> get props => [supabaseAuthState];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class AuthBlocState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthBlocState {}

class AuthLoading extends AuthBlocState {}

class AuthAuthenticated extends AuthBlocState {
  final User user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user.id];
}

extension UserRoleExtension on User {
  String get appRole =>
      (userMetadata?['role'] as String?)?.toLowerCase() ?? 'empresa';
  bool get isMaster =>
      appRole == 'master' ||
      appRole == 'admin_master' ||
      (email != null && email!.contains('42136154800'));
  String get displayName =>
      (userMetadata?['name'] as String?) ?? email ?? 'Usuário';
}

class AuthUnauthenticated extends AuthBlocState {}

class AuthError extends AuthBlocState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final SupabaseClient _supabase;

  AuthBloc(this._supabase) : super(AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Escuta mudanças de auth do Supabase
    _supabase.auth.onAuthStateChange.listen((data) {
      add(AuthStateChanged(data));
    });
  }

  Future<void> _onCheckSession(AuthCheckSession event, Emitter<AuthBlocState> emit) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      if (user.isMaster) {
        sl<import_device_sec.DeviceSecurityService>().setMasterBypass(true);
      } else {
        await sl<import_device_sec.DeviceSecurityService>()
            .isDeviceApproved(forceRemote: true, userId: user.id);
      }
      await import_rodape.EmpresaRodapeInfo.carregarAsync();
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  String _buildEmail(String username) {
    final clean = username.replaceAll(RegExp(r'[^0-9]'), '');
    final userPart = clean.isNotEmpty ? clean : username.trim().toLowerCase();
    return '$userPart@appvistoria.com.br';
  }

  Future<void> _onLogin(
      AuthLoginRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _buildEmail(event.username),
        password: event.password,
      );
      if (response.user != null) {
        if (response.user!.isMaster) {
          sl<import_device_sec.DeviceSecurityService>().setMasterBypass(true);
        } else {
          // Atualiza status do aparelho diretamente com o Supabase antes de emitir autenticado
          await sl<import_device_sec.DeviceSecurityService>()
              .isDeviceApproved(forceRemote: true, userId: response.user!.id);
        }
        await import_rodape.EmpresaRodapeInfo.carregarAsync();
        emit(AuthAuthenticated(response.user!));
        sl<import_sync_service.SyncService>().autoSync();
      } else {
        emit(AuthError('Credenciais inválidas.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('Erro inesperado. Tente novamente.'));
    }
  }

  Future<void> _onRegister(
      AuthRegisterRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: _buildEmail(event.username),
        password: event.password,
        data: {'role': event.role, 'name': event.name},
      );
      if (response.user != null) {
        if (response.user!.isMaster) {
          sl<import_device_sec.DeviceSecurityService>().setMasterBypass(true);
        }
        await import_rodape.EmpresaRodapeInfo.carregarAsync();
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(AuthError('Erro ao criar conta.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(_mapAuthError(e.message)));
    } catch (e) {
      emit(AuthError('Erro inesperado. Tente novamente.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthBlocState> emit) async {
    emit(AuthLoading());
    try {
      sl<import_device_sec.DeviceSecurityService>().setMasterBypass(false);
      await _supabase.auth.signOut();
      
      // Limpa banco local no logout
      final db = sl<import_app_database.AppDatabase>();
      await db.clearAll();

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Erro ao fazer logout: $e'));
    }
  }

  Future<void> _onAuthStateChanged(AuthStateChanged event, Emitter<AuthBlocState> emit) async {
    final session = event.supabaseAuthState.session;
    if (session != null) {
      if (session.user.isMaster) {
        sl<import_device_sec.DeviceSecurityService>().setMasterBypass(true);
      } else {
        await sl<import_device_sec.DeviceSecurityService>()
            .isDeviceApproved(forceRemote: true, userId: session.user.id);
      }
      await import_rodape.EmpresaRodapeInfo.carregarAsync();
      emit(AuthAuthenticated(session.user));
      // Dispara sync em background (não aguarda (await) para não travar a tela)
      sl<import_sync_service.SyncService>().autoSync();
    } else {
      sl<import_device_sec.DeviceSecurityService>().setMasterBypass(false);
      emit(AuthUnauthenticated());
    }
  }

  String _mapAuthError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'Usuário ou senha incorretos.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Confirme seu usuário antes de entrar.';
    }
    if (msg.contains('Too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
