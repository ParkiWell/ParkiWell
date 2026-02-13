import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'app_logger.dart';

class CloudAuthProfile {
  final String userId;
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  const CloudAuthProfile({
    required this.userId,
    this.email,
    this.fullName,
    this.avatarUrl,
  });
}

class CloudBackendService {
  static final CloudBackendService _instance = CloudBackendService._internal();
  factory CloudBackendService() => _instance;

  CloudBackendService._internal();

  final AppLogger _logger = AppLogger();

  SupabaseClient? _client;
  bool _initialized = false;
  bool _enabled = false;
  String? _cloudUserId;
  String? _lastInitializationError;

  bool get isConfigured => BackendConfig.isCloudBackendEnabled;
  bool get isEnabled => _enabled && _client != null && _cloudUserId != null;
  bool get hasActiveSession => _cloudUserId != null;
  String? get cloudUserId => _cloudUserId;
  String? get lastInitializationError => _lastInitializationError;

  String get statusDescription {
    if (!isConfigured) {
      return 'Cloud backend not configured';
    }
    if (isEnabled) {
      return 'Secure cloud sync connected';
    }
    if (_lastInitializationError != null) {
      return 'Cloud unavailable';
    }
    return 'Connecting...';
  }

  bool _isTransientError(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }

    if (error is PostgrestException) {
      final code = error.code ?? '';
      if (code.startsWith('08') ||
          code == '40001' ||
          code == '40P01' ||
          code == '53300' ||
          code == '57014') {
        return true;
      }
    }

    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('connection') ||
        message.contains('temporar') ||
        message.contains('network');
  }

  Future<T> _withRetry<T>(
    String operationName,
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        lastError = e;

        final canRetry = attempt < maxAttempts && _isTransientError(e);
        if (!canRetry) {
          _logger.error(
            'Cloud $operationName failed (attempt $attempt/$maxAttempts)',
            e,
            stackTrace,
          );
          rethrow;
        }

        final delayMs = 250 * (1 << (attempt - 1));
        _logger.warning(
          'Cloud $operationName transient failure (attempt $attempt/$maxAttempts), retrying in ${delayMs}ms',
          e,
          stackTrace,
        );
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    throw lastError ?? Exception('Cloud $operationName failed');
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isConfigured) {
      _lastInitializationError = 'Cloud backend not configured.';
      _logger.warning('Cloud backend is required but not configured.');
      return;
    }

    try {
      // If already initialized by another part of the app, reuse the client.
      _client = Supabase.instance.client;
      await _establishAuthenticatedSession();
      _enabled = _cloudUserId != null;
      _logger.info(
        _enabled
            ? 'Cloud backend connected to existing Supabase client.'
            : 'Supabase client found, but no authenticated session was available.',
      );
      return;
    } catch (_) {
      // Fallthrough to explicit initialize.
    }

    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        anonKey: BackendConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      );

      _client = Supabase.instance.client;
      await _establishAuthenticatedSession();
      _enabled = _cloudUserId != null;

      if (_enabled) {
        _logger.info('Cloud backend initialized with Supabase.');
      } else {
        _lastInitializationError =
            'Supabase is configured but authentication failed.';
      }
    } catch (e, stackTrace) {
      _enabled = false;
      _lastInitializationError = e.toString();
      _logger.error('Failed to initialize cloud backend', e, stackTrace);
    }
  }

  Future<void> _establishAuthenticatedSession() async {
    if (_client == null) return;

    try {
      final existingSession = _client!.auth.currentSession;
      if (existingSession != null) {
        _cloudUserId = existingSession.user.id;
        _lastInitializationError = null;
        return;
      }

      final authResponse = await _client!.auth.signInAnonymously();
      _cloudUserId = authResponse.user?.id;
      _lastInitializationError = null;

      if (_cloudUserId == null) {
        _logger.warning(
          'Anonymous cloud session could not be established. '
          'Enable anonymous auth in Supabase Auth settings.',
        );
      }
    } catch (e, stackTrace) {
      _cloudUserId = null;
      _lastInitializationError = e.toString();
      _logger.error('Cloud authentication failed', e, stackTrace);
    }
  }

  CloudAuthProfile _profileFromUser(User user) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final fullName =
        (metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'])
            ?.toString()
            .trim();
    final avatarUrl = metadata['avatar_url']?.toString().trim();

    return CloudAuthProfile(
      userId: user.id,
      email: user.email?.trim(),
      fullName: (fullName != null && fullName.isNotEmpty) ? fullName : null,
      avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
    );
  }

  bool _isGoogleUser(User user) {
    final provider = user.appMetadata['provider']?.toString().toLowerCase();
    if (provider == 'google') return true;

    final providers = user.appMetadata['providers'];
    if (providers is List) {
      return providers
          .map((value) => value.toString().toLowerCase())
          .contains('google');
    }

    return false;
  }

  Future<CloudAuthProfile?> signInWithGoogle() async {
    if (!isConfigured) {
      _lastInitializationError =
          'Cloud backend is not configured for Google sign-in.';
      return null;
    }

    if (_client == null) {
      await initialize();
    }

    if (_client == null) return null;

    try {
      final existingUser = _client!.auth.currentUser;
      if (existingUser != null && _isGoogleUser(existingUser)) {
        final profile = _profileFromUser(existingUser);
        _cloudUserId = profile.userId;
        _enabled = true;
        _lastInitializationError = null;
        return profile;
      }

      final initialUserId = existingUser?.id;
      final authStream = _client!.auth.onAuthStateChange;
      late final StreamSubscription<AuthState> subscription;
      final completer = Completer<CloudAuthProfile?>();

      subscription = authStream.listen((event) {
        final user = event.session?.user;
        if (user == null) return;
        if (user.id == initialUserId && !_isGoogleUser(user)) return;
        if (!_isGoogleUser(user)) return;

        if (!completer.isCompleted) {
          completer.complete(_profileFromUser(user));
        }
      });

      final launched = await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: BackendConfig.supabaseAuthRedirectUrl,
      );

      if (!launched) {
        await subscription.cancel();
        return null;
      }

      final profile = await completer.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          final user = _client!.auth.currentUser;
          if (user != null && _isGoogleUser(user)) {
            return _profileFromUser(user);
          }
          return null;
        },
      );

      await subscription.cancel();

      if (profile != null) {
        _cloudUserId = profile.userId;
        _enabled = true;
        _lastInitializationError = null;
      }

      return profile;
    } catch (e, stackTrace) {
      _lastInitializationError = e.toString();
      _logger.error('Google sign-in failed', e, stackTrace);
      return null;
    }
  }

  Future<bool> signOut() async {
    if (_client == null) return false;

    try {
      await _client!.auth.signOut();
      _cloudUserId = null;
      _enabled = false;
      await _establishAuthenticatedSession();
      _enabled = _cloudUserId != null;
      _lastInitializationError = null;
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud sign out failed', e, stackTrace);
      return false;
    }
  }

  String? _effectiveUserId(String? fallbackId) {
    return _cloudUserId ?? fallbackId;
  }

  Future<void> _deleteByUserIfExists(String table, String userId) async {
    try {
      await _client!.from(table).delete().eq('user_id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        _logger.warning('Table $table not found; skipping delete.');
        return;
      }
      rethrow;
    }
  }

  Future<bool> upsertUser({
    required String id,
    required String name,
    required int age,
    String? profileImage,
    String? email,
  }) async {
    if (!isEnabled) return false;

    try {
      final userId = _effectiveUserId(id);
      if (userId == null) return false;

      await _client!.from('users').upsert(
        <String, dynamic>{
          'id': userId,
          'name': name,
          'email': email,
          'age': age,
          'profile_image': profileImage,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud upsert user failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    if (!isEnabled) return false;

    try {
      final userId = _effectiveUserId(id);
      if (userId == null) return false;

      await _deleteByUserIfExists('community_group_memberships', userId);
      await _deleteByUserIfExists('community_post_likes', userId);
      await _deleteByUserIfExists('community_comments', userId);
      await _deleteByUserIfExists('community_posts', userId);
      await _deleteByUserIfExists('logs', userId);
      await _deleteByUserIfExists('schedules', userId);
      await _client!.from('users').delete().eq('id', userId);
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud delete user failed', e, stackTrace);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    if (!isEnabled) return null;

    try {
      final userId = _effectiveUserId(id);
      if (userId == null) return null;

      final result = await _withRetry<Map<String, dynamic>?>(
        'get user',
        () async {
          return _client!.from('users').select().eq('id', userId).maybeSingle();
        },
      );
      return result;
    } catch (e, stackTrace) {
      _logger.error('Cloud get user failed', e, stackTrace);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getLogs(String userId) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return <Map<String, dynamic>>[];

      final result = await _withRetry<List<dynamic>>(
        'get logs',
        () async {
          return _client!
              .from('logs')
              .select()
              .eq('user_id', effectiveUserId)
              .order('created_at', ascending: false);
        },
      );
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get logs failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> getSchedules(String userId) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return <Map<String, dynamic>>[];

      final result = await _withRetry<List<dynamic>>(
        'get schedules',
        () async {
          return _client!
              .from('schedules')
              .select()
              .eq('user_id', effectiveUserId)
              .order('created_at', ascending: false);
        },
      );
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get schedules failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<bool> saveLog({
    required String id,
    required String userId,
    required String title,
    required String data,
    required String time,
    required String symptom,
    required String severity,
  }) async {
    if (!isEnabled) return false;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return false;

      await _withRetry<void>(
        'save log',
        () async {
          await _client!.from('logs').upsert(
            <String, dynamic>{
              'id': id,
              'user_id': effectiveUserId,
              'title': title,
              'data': data,
              'event_time': time,
              'symptom': symptom,
              'severity': severity,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'id',
          );
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud save log failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteLog(String id) async {
    if (!isEnabled) return false;
    try {
      await _withRetry<void>(
        'delete log',
        () async {
          await _client!.from('logs').delete().eq('id', id);
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud delete log failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> saveSchedule({
    required String id,
    required String userId,
    required String title,
    required String data,
    required String days,
    required String details,
  }) async {
    if (!isEnabled) return false;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return false;

      await _withRetry<void>(
        'save schedule',
        () async {
          await _client!.from('schedules').upsert(
            <String, dynamic>{
              'id': id,
              'user_id': effectiveUserId,
              'title': title,
              'data': data,
              'days': days,
              'details': details,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'id',
          );
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud save schedule failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteSchedule(String id) async {
    if (!isEnabled) return false;
    try {
      await _withRetry<void>(
        'delete schedule',
        () async {
          await _client!.from('schedules').delete().eq('id', id);
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud delete schedule failed', e, stackTrace);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts({
    int limit = 100,
  }) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final result = await _withRetry<List<dynamic>>(
        'get community posts',
        () async {
          return _client!
              .from('community_posts')
              .select()
              .order('created_at', ascending: false)
              .limit(limit);
        },
      );
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get posts failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<Set<String>> getLikedPostIds({
    required String userId,
    required List<String> postIds,
  }) async {
    if (!isEnabled || postIds.isEmpty) return <String>{};

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return <String>{};

      final result = await _withRetry<List<dynamic>>(
        'get liked post ids',
        () async {
          return _client!
              .from('community_post_likes')
              .select('post_id')
              .eq('user_id', effectiveUserId)
              .inFilter('post_id', postIds);
        },
      );

      return result
          .map((row) => row['post_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e, stackTrace) {
      _logger.error('Cloud get liked posts failed', e, stackTrace);
      return <String>{};
    }
  }

  Future<bool> saveCommunityPost({
    required String id,
    required String userId,
    required String userName,
    required String content,
    String? category,
    String? profileImage,
  }) async {
    if (!isEnabled) return false;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return false;

      await _withRetry<void>(
        'save community post',
        () async {
          await _client!.from('community_posts').upsert(
            <String, dynamic>{
              'id': id,
              'user_id': effectiveUserId,
              'user_name': userName,
              'profile_image': profileImage,
              'content': content,
              'category': category,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'id',
          );
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud save post failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> updateCommunityPost({
    required String postId,
    required String content,
    String? category,
  }) async {
    if (!isEnabled) return false;

    try {
      final result = await _withRetry<Map<String, dynamic>?>(
        'update community post',
        () async {
          return _client!
              .from('community_posts')
              .update(
                <String, dynamic>{
                  'content': content,
                  'category': category,
                  'updated_at': DateTime.now().toIso8601String(),
                },
              )
              .eq('id', postId)
              .select('id')
              .maybeSingle();
        },
      );

      return result != null;
    } catch (e, stackTrace) {
      _logger.error('Cloud update post failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteCommunityPost(String postId) async {
    if (!isEnabled) return false;

    try {
      final deleted = await _withRetry<Map<String, dynamic>?>(
        'delete community post',
        () async {
          return _client!
              .from('community_posts')
              .delete()
              .eq('id', postId)
              .select('id')
              .maybeSingle();
        },
      );
      return deleted != null;
    } catch (e, stackTrace) {
      _logger.error('Cloud delete post failed', e, stackTrace);
      return false;
    }
  }

  Future<bool> incrementPostLike(String postId) async {
    if (!isEnabled) return false;

    try {
      await _withRetry<void>(
        'increment post like via rpc',
        () async {
          await _client!
              .rpc('increment_post_like', params: {'p_post_id': postId});
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Cloud like RPC failed, falling back to direct update',
        e,
        stackTrace,
      );
    }

    // Compatibility fallback for older schemas where the RPC does not exist.
    try {
      final record = await _withRetry<Map<String, dynamic>?>(
        'fetch post likes fallback',
        () async {
          return _client!
              .from('community_posts')
              .select('likes')
              .eq('id', postId)
              .maybeSingle();
        },
      );
      final currentLikes = (record?['likes'] as num?)?.toInt() ?? 0;
      await _withRetry<void>(
        'increment post like fallback',
        () async {
          await _client!.from('community_posts').update(
            <String, dynamic>{
              'likes': currentLikes + 1,
              'updated_at': DateTime.now().toIso8601String(),
            },
          ).eq('id', postId);
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud like post failed', e, stackTrace);
      return false;
    }
  }

  Future<bool?> likeCommunityPost({
    required String postId,
    required String userId,
  }) async {
    if (!isEnabled) return null;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return null;

      await _withRetry<void>(
        'insert community post like',
        () async {
          await _client!.from('community_post_likes').insert(
            <String, dynamic>{
              'post_id': postId,
              'user_id': effectiveUserId,
            },
          );
        },
      );
    } on PostgrestException catch (e, stackTrace) {
      if (e.code == '23505') {
        return false;
      }
      _logger.error('Cloud like insert failed', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logger.error('Cloud like insert failed', e, stackTrace);
      return null;
    }

    final incremented = await incrementPostLike(postId);
    if (!incremented) return null;
    return true;
  }

  Future<List<Map<String, dynamic>>> getCommunityComments(String postId) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final result = await _withRetry<List<dynamic>>(
        'get community comments',
        () async {
          return _client!
              .from('community_comments')
              .select()
              .eq('post_id', postId)
              .order('created_at', ascending: true);
        },
      );
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get comments failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, int>> getCommunityCommentCounts(
      List<String> postIds) async {
    if (!isEnabled || postIds.isEmpty) return <String, int>{};

    try {
      final result = await _withRetry<List<dynamic>>(
        'get community comment counts',
        () async {
          return _client!
              .from('community_comments')
              .select('post_id')
              .inFilter('post_id', postIds);
        },
      );

      final counts = <String, int>{};
      for (final row in result) {
        final postId = row['post_id']?.toString() ?? '';
        if (postId.isEmpty) continue;
        counts[postId] = (counts[postId] ?? 0) + 1;
      }
      return counts;
    } catch (e, stackTrace) {
      _logger.error('Cloud get comment counts failed', e, stackTrace);
      return <String, int>{};
    }
  }

  Future<bool> saveCommunityComment({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? profileImage,
  }) async {
    if (!isEnabled) return false;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return false;

      await _withRetry<void>(
        'save community comment',
        () async {
          await _client!.from('community_comments').upsert(
            <String, dynamic>{
              'id': id,
              'post_id': postId,
              'user_id': effectiveUserId,
              'user_name': userName,
              'profile_image': profileImage,
              'content': content,
            },
            onConflict: 'id',
          );
        },
      );
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud save comment failed', e, stackTrace);
      return false;
    }
  }

  Future<Set<String>> getJoinedCommunityGroupIds(String userId) async {
    if (!isEnabled) return <String>{};

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return <String>{};

      final result = await _withRetry<List<dynamic>>(
        'get community group memberships',
        () async {
          return _client!
              .from('community_group_memberships')
              .select('group_id')
              .eq('user_id', effectiveUserId);
        },
      );

      return result
          .map((row) => row['group_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e, stackTrace) {
      _logger.error('Cloud get group memberships failed', e, stackTrace);
      return <String>{};
    }
  }

  Future<bool> setCommunityGroupMembership({
    required String userId,
    required String groupId,
    required bool isJoined,
  }) async {
    if (!isEnabled) return false;

    try {
      final effectiveUserId = _effectiveUserId(userId);
      if (effectiveUserId == null) return false;

      if (isJoined) {
        await _withRetry<void>(
          'join community group',
          () async {
            await _client!.from('community_group_memberships').upsert(
              <String, dynamic>{
                'group_id': groupId,
                'user_id': effectiveUserId,
                'updated_at': DateTime.now().toIso8601String(),
              },
              onConflict: 'group_id,user_id',
            );
          },
        );
      } else {
        await _withRetry<void>(
          'leave community group',
          () async {
            await _client!
                .from('community_group_memberships')
                .delete()
                .eq('group_id', groupId)
                .eq('user_id', effectiveUserId);
          },
        );
      }
      return true;
    } catch (e, stackTrace) {
      _logger.error('Cloud update group membership failed', e, stackTrace);
      return false;
    }
  }
}
