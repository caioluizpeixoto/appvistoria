import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _onCheckSession(AuthCheckSession event, Emitter<AuthBlocState> emit) {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  String _buildEmail(String username) {
    final clean = username.replaceAll(RegExp(r'[^0-9]'), '');
    return '$clean@appvistoria.com.br';
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
        emit(AuthAuthenticated(response.user!));
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

  Future<void> _onLogout(
      AuthLogoutRequested event, Emitter<AuthBlocState> emit) async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Ignorar erros de rede ou sessão expirada no backend,
      // queremos forçar o logout local de qualquer forma.
    } finally {
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthStateChanged(
      AuthStateChanged event, Emitter<AuthBlocState> emit) {
    final user = event.supabaseAuthState.session?.user;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
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
