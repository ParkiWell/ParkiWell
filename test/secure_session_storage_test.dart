import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiwell/services/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates only the configured backend legacy session', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sb-testing-auth-token': 'old testing session',
      'sb-production-auth-token': 'production session',
    });
    final storage = SecureSessionStorage(
      supabaseUrl: 'https://production.supabase.co',
    );

    await storage.initialize();

    expect(await storage.accessToken(), 'production session');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), isEmpty);
  });
}
