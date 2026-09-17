import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_vistoria/features/auth/presentation/blocs/auth_bloc.dart';

void main() {
  group('Master Profile & Role Tests', () {
    test('User with role "master" should be recognized as isMaster', () {
      final user = User(
        id: 'user-master-1',
        appMetadata: {},
        userMetadata: {'role': 'master', 'name': 'Admin Master'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(user.appRole, 'master');
      expect(user.isMaster, isTrue);
      expect(user.displayName, 'Admin Master');
    });

    test('User with role "admin_master" should be recognized as isMaster', () {
      final user = User(
        id: 'user-master-2',
        appMetadata: {},
        userMetadata: {'role': 'admin_master', 'name': 'Super Admin'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(user.appRole, 'admin_master');
      expect(user.isMaster, isTrue);
      expect(user.displayName, 'Super Admin');
    });

    test('Legacy CPF 42136154800 should be recognized as isMaster', () {
      final user = User(
        id: 'user-master-3',
        appMetadata: {},
        userMetadata: {'role': 'empresa'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: '42136154800@appvistoria.com.br',
      );

      expect(user.isMaster, isTrue);
    });

    test('Regular company and user should NOT be isMaster', () {
      final empresaUser = User(
        id: 'empresa-1',
        appMetadata: {},
        userMetadata: {'role': 'empresa', 'name': 'Ultra Visão Indaiatuba'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: '08420171000181@appvistoria.com.br',
      );

      final regularUser = User(
        id: 'usuario-1',
        appMetadata: {},
        userMetadata: {'role': 'usuario', 'name': 'João Silva'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: '43664222806@appvistoria.com.br',
      );

      expect(empresaUser.isMaster, isFalse);
      expect(empresaUser.appRole, 'empresa');
      expect(regularUser.isMaster, isFalse);
      expect(regularUser.appRole, 'usuario');
    });
  });
}
