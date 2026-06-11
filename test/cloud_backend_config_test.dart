import 'package:flutter_test/flutter_test.dart';
import 'package:levio/config/backend_config.dart';

void main() {
  test('Supabase backend config follows dart defines', () {
    const provider =
        String.fromEnvironment('BACKEND_PROVIDER', defaultValue: 'none');
    const supabaseUrl =
        String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const supabaseAnonKey =
        String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    if (provider.toLowerCase() == 'supabase') {
      expect(BackendConfig.provider, BackendProvider.supabase);
      expect(BackendConfig.supabaseUrl, supabaseUrl);
      expect(BackendConfig.supabaseAnonKey, supabaseAnonKey);
      expect(BackendConfig.supabaseUrl, isNotEmpty);
      expect(BackendConfig.supabaseAnonKey, isNotEmpty);
      expect(BackendConfig.isCloudBackendEnabled, isTrue);
    } else {
      expect(BackendConfig.provider, BackendProvider.none);
      expect(BackendConfig.isCloudBackendEnabled, isFalse);
    }
  });
}
