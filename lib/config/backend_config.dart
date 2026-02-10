enum BackendProvider {
  none,
  supabase,
}

class BackendConfig {
  static const String _providerValue =
      String.fromEnvironment('BACKEND_PROVIDER', defaultValue: 'none');
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static BackendProvider get provider {
    switch (_providerValue.toLowerCase()) {
      case 'supabase':
        return BackendProvider.supabase;
      default:
        return BackendProvider.none;
    }
  }

  static bool get isSupabaseEnabled =>
      provider == BackendProvider.supabase &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  static bool get isCloudBackendEnabled => isSupabaseEnabled;
}
