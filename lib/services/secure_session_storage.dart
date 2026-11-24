import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

/// Keeps the Supabase auth session (refresh token) in the platform
/// keystore instead of plaintext SharedPreferences.
///
/// The health cache is encrypted at rest; leaving the credential that can
/// read the same data server-side in plaintext beside it would defeat the
/// point. A legacy plaintext session written by the default storage is
/// migrated on first launch and removed from SharedPreferences.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    FlutterSecureStorage? secureStorage,
    String? supabaseUrl,
  }) : _backendHost = Uri.tryParse(
         supabaseUrl ?? BackendConfig.supabaseUrl,
       )?.host,
       _secure =
           secureStorage ??
           const FlutterSecureStorage(
             // Keys must never leave the device: first_unlock_this_device
             // keeps them out of encrypted iCloud/iTunes backups, matching
             // the Android backup exclusion.
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           );

  static const String _key = 'parkiwell_supabase_session_v1';
  static Future<void> _sessionOperations = Future<void>.value();
  final String? _backendHost;
  final FlutterSecureStorage _secure;

  static Future<T> _inOrder<T>(Future<T> Function() operation) {
    final result = _sessionOperations.then((_) => operation());
    _sessionOperations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('sb-') && k.endsWith('-auth-token'))
          .toList();
      final reference = _backendHost?.split('.').first;
      final value = reference == null || reference.isEmpty
          ? null
          : prefs.get('sb-$reference-auth-token');
      try {
        if (value is String && value.isNotEmpty && !await hasAccessToken()) {
          await persistSession(value);
        }
      } finally {
        // Erase plaintext credentials even when the keystore is unavailable.
        for (final key in legacyKeys) {
          await prefs.remove(key);
        }
      }
    } on MissingPluginException {
      // No keystore in this environment (tests, desktop shells); Supabase
      // simply starts unauthenticated.
    } catch (_) {
      // Migration is best-effort; a failed migration only means the user
      // signs in again.
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _inOrder(() => _secure.read(key: _key));
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _inOrder(
        () => _secure.write(key: _key, value: persistSessionString),
      );
    } on MissingPluginException {
      // Session stays in memory only for this run.
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _inOrder(() => _secure.delete(key: _key));
    } on MissingPluginException {
      // Nothing persisted to remove.
    }
  }
}
