import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Create Users', () async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    final supabase = Supabase.instance.client;

    final users = [
      {'username': '43664222806', 'role': 'usuario'},
      {'username': '11977969000133', 'role': 'empresa'},
      {'username': '24868718000162', 'role': 'empresa'},
    ];

    for (var u in users) {
      final username = u['username']!;
      final role = u['role']!;
      final email = '$username@appvistoria.com.br';
      final password = 'Mudar123!';

      print('Creating $username with role $role ...');

      try {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'role': role},
        );
        print('Success: ${res.user?.id}');
      } catch (e) {
        print('Error creating $username: $e');
      }
    }
  });
}
