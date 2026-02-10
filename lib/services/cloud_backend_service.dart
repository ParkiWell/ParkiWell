import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'app_logger.dart';

class CloudBackendService {
  static final CloudBackendService _instance = CloudBackendService._internal();
  factory CloudBackendService() => _instance;

  CloudBackendService._internal();

  final AppLogger _logger = AppLogger();

  SupabaseClient? _client;
  bool _initialized = false;
  bool _enabled = false;

  bool get isEnabled => _enabled && _client != null;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!BackendConfig.isCloudBackendEnabled) {
      _logger.info('Cloud backend disabled. Running in local-only mode.');
      return;
    }

    try {
      // If already initialized by another part of the app, reuse the client.
      _client = Supabase.instance.client;
      _enabled = true;
      _logger.info('Cloud backend connected to existing Supabase client.');
      return;
    } catch (_) {
      // Fallthrough to explicit initialize.
    }

    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        anonKey: BackendConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
        ),
      );

      _client = Supabase.instance.client;
      _enabled = true;
      _logger.info('Cloud backend initialized with Supabase.');
    } catch (e, stackTrace) {
      _enabled = false;
      _logger.error('Failed to initialize cloud backend', e, stackTrace);
    }
  }

  Future<void> upsertUser({
    required String id,
    required String name,
    required int age,
    String? profileImage,
    String? email,
  }) async {
    if (!isEnabled) return;

    try {
      await _client!.from('users').upsert(
        <String, dynamic>{
          'id': id,
          'name': name,
          'email': email,
          'age': age,
          'profile_image': profileImage,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e, stackTrace) {
      _logger.error('Cloud upsert user failed', e, stackTrace);
    }
  }

  Future<void> deleteUser(String id) async {
    if (!isEnabled) return;

    try {
      await _client!.from('community_comments').delete().eq('user_id', id);
      await _client!.from('community_posts').delete().eq('user_id', id);
      await _client!.from('logs').delete().eq('user_id', id);
      await _client!.from('schedules').delete().eq('user_id', id);
      await _client!.from('users').delete().eq('id', id);
    } catch (e, stackTrace) {
      _logger.error('Cloud delete user failed', e, stackTrace);
    }
  }

  Future<Map<String, dynamic>?> getUser(String id) async {
    if (!isEnabled) return null;

    try {
      final result =
          await _client!.from('users').select().eq('id', id).maybeSingle();
      return result;
    } catch (e, stackTrace) {
      _logger.error('Cloud get user failed', e, stackTrace);
      return null;
    }
  }

  Future<void> saveLog({
    required String id,
    required String userId,
    required String title,
    required String data,
    required String time,
    required String symptom,
    required String severity,
  }) async {
    if (!isEnabled) return;

    try {
      await _client!.from('logs').upsert(
        <String, dynamic>{
          'id': id,
          'user_id': userId,
          'title': title,
          'data': data,
          'event_time': time,
          'symptom': symptom,
          'severity': severity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e, stackTrace) {
      _logger.error('Cloud save log failed', e, stackTrace);
    }
  }

  Future<void> deleteLog(String id) async {
    if (!isEnabled) return;
    try {
      await _client!.from('logs').delete().eq('id', id);
    } catch (e, stackTrace) {
      _logger.error('Cloud delete log failed', e, stackTrace);
    }
  }

  Future<void> saveSchedule({
    required String id,
    required String userId,
    required String title,
    required String data,
    required String days,
    required String details,
  }) async {
    if (!isEnabled) return;

    try {
      await _client!.from('schedules').upsert(
        <String, dynamic>{
          'id': id,
          'user_id': userId,
          'title': title,
          'data': data,
          'days': days,
          'details': details,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e, stackTrace) {
      _logger.error('Cloud save schedule failed', e, stackTrace);
    }
  }

  Future<void> deleteSchedule(String id) async {
    if (!isEnabled) return;
    try {
      await _client!.from('schedules').delete().eq('id', id);
    } catch (e, stackTrace) {
      _logger.error('Cloud delete schedule failed', e, stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts({
    int limit = 100,
  }) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final result = await _client!
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get posts failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveCommunityPost({
    required String id,
    required String userId,
    required String userName,
    required String content,
    String? category,
  }) async {
    if (!isEnabled) return;

    try {
      await _client!.from('community_posts').upsert(
        <String, dynamic>{
          'id': id,
          'user_id': userId,
          'user_name': userName,
          'content': content,
          'category': category,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (e, stackTrace) {
      _logger.error('Cloud save post failed', e, stackTrace);
    }
  }

  Future<void> incrementPostLike(String postId) async {
    if (!isEnabled) return;

    try {
      final record = await _client!
          .from('community_posts')
          .select('likes')
          .eq('id', postId)
          .maybeSingle();
      final currentLikes = (record?['likes'] as num?)?.toInt() ?? 0;
      await _client!.from('community_posts').update(
        <String, dynamic>{
          'likes': currentLikes + 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
      ).eq('id', postId);
    } catch (e, stackTrace) {
      _logger.error('Cloud like post failed', e, stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityComments(String postId) async {
    if (!isEnabled) return <Map<String, dynamic>>[];

    try {
      final result = await _client!
          .from('community_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      _logger.error('Cloud get comments failed', e, stackTrace);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> saveCommunityComment({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String content,
  }) async {
    if (!isEnabled) return;

    try {
      await _client!.from('community_comments').upsert(
        <String, dynamic>{
          'id': id,
          'post_id': postId,
          'user_id': userId,
          'user_name': userName,
          'content': content,
        },
        onConflict: 'id',
      );
    } catch (e, stackTrace) {
      _logger.error('Cloud save comment failed', e, stackTrace);
    }
  }
}
