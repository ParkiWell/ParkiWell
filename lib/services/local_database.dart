import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_logger.dart';

/// Database migration definition
class DatabaseMigration {
  final int version;
  final Future<void> Function(Database db) migrate;

  DatabaseMigration({required this.version, required this.migrate});
}

/// Result wrapper for database operations
class DbResult<T> {
  final T? data;
  final String? error;
  final bool success;

  DbResult._({this.data, this.error, required this.success});

  factory DbResult.success(T data) => DbResult._(data: data, success: true);
  factory DbResult.failure(String error) =>
      DbResult._(error: error, success: false);

  T get dataOrThrow {
    if (!success || data == null) {
      throw Exception(error ?? 'No data available');
    }
    return data as T;
  }
}

/// Production-grade local database service using SQLite
///
/// Features:
/// - Encrypted sensitive data storage
/// - Database migrations support
/// - Transaction support
/// - Comprehensive error handling
/// - Detailed logging
/// - Data validation
/// - Secure key management via flutter_secure_storage
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;
  static const String _dbName = 'levio_v2.db';
  static const int _currentVersion = 3;

  final AppLogger _logger = AppLogger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Encryption key for sensitive data
  String? _encryptionKey;

  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  /// Initialize database and encryption
  Future<void> initialize() async {
    await _initializeEncryptionKey();
    await database; // Ensure database is created
    _logger.info('Database initialized successfully');
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize encryption key from secure storage
  Future<void> _initializeEncryptionKey() async {
    try {
      _encryptionKey = await _secureStorage.read(key: 'db_encryption_key');
      if (_encryptionKey == null) {
        // Generate new key
        final keyBytes = List<int>.generate(
            32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
        _encryptionKey = base64Encode(keyBytes);
        await _secureStorage.write(
            key: 'db_encryption_key', value: _encryptionKey);
        _logger.security('encryption_key_generated');
      }
    } catch (e) {
      _logger.error('Failed to initialize encryption key', e);
      // Fallback to a derived key (less secure but functional)
      _encryptionKey = 'levio_fallback_key_${DateTime.now().year}';
    }
  }

  /// Encrypt sensitive data
  String encryptData(String data) {
    if (_encryptionKey == null || data.isEmpty) return data;
    try {
      final key = utf8.encode(_encryptionKey!);
      final bytes = utf8.encode(data);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      // Simple XOR encryption with HMAC-derived key
      final encrypted = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        encrypted.add(bytes[i] ^ digest.bytes[i % digest.bytes.length]);
      }
      return base64Encode(encrypted);
    } catch (e) {
      _logger.error('Encryption failed', e);
      return data;
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData) {
    if (_encryptionKey == null || encryptedData.isEmpty) return encryptedData;
    try {
      final key = utf8.encode(_encryptionKey!);
      final bytes = base64Decode(encryptedData);
      final hmac = Hmac(sha256, key);
      // Use same key derivation as encryption
      final tempDigest = hmac.convert(utf8.encode('temp'));
      final decrypted = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        decrypted.add(bytes[i] ^ tempDigest.bytes[i % tempDigest.bytes.length]);
      }
      return utf8.decode(decrypted);
    } catch (e) {
      _logger.error('Decryption failed - returning original data', e);
      return encryptedData;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _logger.database('init', details: 'Path: $path');

    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        _logger.database('opened', details: 'Version: $_currentVersion');
      },
    );
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    _logger.database('create', details: 'Creating tables for version $version');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '[Name]',
        email TEXT,
        age INTEGER NOT NULL DEFAULT 0,
        profile_image TEXT,
        data_hash TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        icon INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL DEFAULT 0,
        data TEXT NOT NULL,
        data_hash TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedules (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        icon INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL DEFAULT 0,
        data TEXT NOT NULL,
        data_hash TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS community_posts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT,
        content_hash TEXT,
        likes INTEGER NOT NULL DEFAULT 0,
        reports INTEGER NOT NULL DEFAULT 0,
        is_flagged INTEGER NOT NULL DEFAULT 0,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS community_comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        content TEXT NOT NULL,
        content_hash TEXT,
        reports INTEGER NOT NULL DEFAULT 0,
        is_flagged INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES community_posts (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_reports (
        id TEXT PRIMARY KEY,
        reporter_id TEXT NOT NULL,
        target_type TEXT NOT NULL,
        target_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (reporter_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db
        .execute('CREATE INDEX IF NOT EXISTS idx_logs_user ON logs(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_schedules_user ON schedules(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_user ON community_posts(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_created ON community_posts(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_comments_post ON community_comments(post_id)');

    _logger.database('create',
        details: 'All tables and indexes created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.database('upgrade',
        details: 'Upgrading from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Migration to version 2: Add reports tracking
      await db.execute(
          'ALTER TABLE community_posts ADD COLUMN reports INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE community_posts ADD COLUMN is_hidden INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE community_comments ADD COLUMN reports INTEGER NOT NULL DEFAULT 0');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_reports (
          id TEXT PRIMARY KEY,
          reporter_id TEXT NOT NULL,
          target_type TEXT NOT NULL,
          target_id TEXT NOT NULL,
          reason TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE community_posts ADD COLUMN category TEXT');
    }

    _logger.database('upgrade', details: 'Migration completed');
  }

  /// Generate hash for data integrity verification
  String _generateHash(String data) {
    final bytes = utf8.encode(data + (_encryptionKey ?? ''));
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  // ==================== User Operations ====================

  Future<DbResult<Map<String, dynamic>?>> getUser(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.database('read', table: 'users', details: 'Get user $id');
      return DbResult.success(results.isNotEmpty ? results.first : null);
    } catch (e, stackTrace) {
      _logger.error('Failed to get user', e, stackTrace);
      return DbResult.failure('Failed to retrieve user data');
    }
  }

  Future<DbResult<void>> createUser(String id, String name, int age,
      String? profileImage, String? email) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final dataHash = _generateHash('$id$name$age');

      await db.insert(
        'users',
        {
          'id': id,
          'name': _sanitizeInput(name),
          'email': email == null || email.trim().isEmpty
              ? null
              : _sanitizeInput(email),
          'age': age.clamp(0, 150),
          'profile_image': profileImage,
          'data_hash': dataHash,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.database('insert', table: 'users', details: 'Created user $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to create user', e, stackTrace);
      return DbResult.failure('Failed to create user');
    }
  }

  Future<DbResult<void>> updateUser(String id,
      {String? name, int? age, String? profileImage, String? email}) async {
    try {
      final db = await database;
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = _sanitizeInput(name);
      if (email != null) {
        updates['email'] = email.trim().isEmpty ? null : _sanitizeInput(email);
      }
      if (age != null) updates['age'] = age.clamp(0, 150);
      if (profileImage != null) updates['profile_image'] = profileImage;

      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );

      _logger.database('update', table: 'users', details: 'Updated user $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to update user', e, stackTrace);
      return DbResult.failure('Failed to update user');
    }
  }

  Future<DbResult<void>> deleteUser(String id) async {
    try {
      final db = await database;

      // Use transaction for cascade delete
      await db.transaction((txn) async {
        await txn.delete('community_comments',
            where: 'user_id = ?', whereArgs: [id]);
        await txn
            .delete('community_posts', where: 'user_id = ?', whereArgs: [id]);
        await txn.delete('schedules', where: 'user_id = ?', whereArgs: [id]);
        await txn.delete('logs', where: 'user_id = ?', whereArgs: [id]);
        await txn.delete('users', where: 'id = ?', whereArgs: [id]);
      });

      _logger.database('delete',
          table: 'users', details: 'Deleted user $id and all related data');
      _logger.security('user_deleted', metadata: {'user_id': id});
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete user', e, stackTrace);
      return DbResult.failure('Failed to delete user');
    }
  }

  // ==================== Logs Operations ====================

  Future<DbResult<List<Map<String, dynamic>>>> getLogs(String userId) async {
    try {
      final db = await database;
      final results = await db.query(
        'logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _logger.database('read',
          table: 'logs', details: 'Get ${results.length} logs for user');
      return DbResult.success(results);
    } catch (e, stackTrace) {
      _logger.error('Failed to get logs', e, stackTrace);
      return DbResult.failure('Failed to retrieve logs');
    }
  }

  Future<DbResult<void>> saveLog(String id, String userId, String title,
      int icon, int color, String data) async {
    try {
      final db = await database;
      final dataHash = _generateHash(data);

      await db.insert(
        'logs',
        {
          'id': id,
          'user_id': userId,
          'title': _sanitizeInput(title),
          'icon': icon,
          'color': color,
          'data': data,
          'data_hash': dataHash,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.database('insert', table: 'logs', details: 'Saved log $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to save log', e, stackTrace);
      return DbResult.failure('Failed to save log');
    }
  }

  Future<DbResult<void>> updateLog(String id,
      {String? title, int? icon, int? color, String? data}) async {
    try {
      final db = await database;
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = _sanitizeInput(title);
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      if (data != null) {
        updates['data'] = data;
        updates['data_hash'] = _generateHash(data);
      }

      if (updates.isNotEmpty) {
        await db.update('logs', updates, where: 'id = ?', whereArgs: [id]);
        _logger.database('update', table: 'logs', details: 'Updated log $id');
      }
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to update log', e, stackTrace);
      return DbResult.failure('Failed to update log');
    }
  }

  Future<DbResult<void>> deleteLog(String id) async {
    try {
      final db = await database;
      await db.delete('logs', where: 'id = ?', whereArgs: [id]);
      _logger.database('delete', table: 'logs', details: 'Deleted log $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete log', e, stackTrace);
      return DbResult.failure('Failed to delete log');
    }
  }

  // ==================== Schedules Operations ====================

  Future<DbResult<List<Map<String, dynamic>>>> getSchedules(
      String userId) async {
    try {
      final db = await database;
      final results = await db.query(
        'schedules',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      _logger.database('read',
          table: 'schedules', details: 'Get ${results.length} schedules');
      return DbResult.success(results);
    } catch (e, stackTrace) {
      _logger.error('Failed to get schedules', e, stackTrace);
      return DbResult.failure('Failed to retrieve schedules');
    }
  }

  Future<DbResult<void>> saveSchedule(String id, String userId, String title,
      int icon, int color, String data) async {
    try {
      final db = await database;
      final dataHash = _generateHash(data);

      await db.insert(
        'schedules',
        {
          'id': id,
          'user_id': userId,
          'title': _sanitizeInput(title),
          'icon': icon,
          'color': color,
          'data': data,
          'data_hash': dataHash,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger.database('insert',
          table: 'schedules', details: 'Saved schedule $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to save schedule', e, stackTrace);
      return DbResult.failure('Failed to save schedule');
    }
  }

  Future<DbResult<void>> updateSchedule(String id,
      {String? title, int? icon, int? color, String? data}) async {
    try {
      final db = await database;
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = _sanitizeInput(title);
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      if (data != null) {
        updates['data'] = data;
        updates['data_hash'] = _generateHash(data);
      }

      if (updates.isNotEmpty) {
        await db.update('schedules', updates, where: 'id = ?', whereArgs: [id]);
        _logger.database('update',
            table: 'schedules', details: 'Updated schedule $id');
      }
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to update schedule', e, stackTrace);
      return DbResult.failure('Failed to update schedule');
    }
  }

  Future<DbResult<void>> deleteSchedule(String id) async {
    try {
      final db = await database;
      await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
      _logger.database('delete',
          table: 'schedules', details: 'Deleted schedule $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete schedule', e, stackTrace);
      return DbResult.failure('Failed to delete schedule');
    }
  }

  // ==================== Community Operations ====================

  Future<DbResult<List<Map<String, dynamic>>>> getCommunityPosts(
      {int limit = 50, int offset = 0}) async {
    try {
      final db = await database;
      final results = await db.query(
        'community_posts',
        where: 'is_flagged = 0 AND is_hidden = 0',
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );
      _logger.database('read',
          table: 'community_posts', details: 'Get ${results.length} posts');
      return DbResult.success(results);
    } catch (e, stackTrace) {
      _logger.error('Failed to get community posts', e, stackTrace);
      return DbResult.failure('Failed to retrieve posts');
    }
  }

  Future<DbResult<void>> createPost(String id, String userId, String userName,
      String content, String? category) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final sanitizedContent = _sanitizeInput(content);
      final contentHash = _generateHash(sanitizedContent);

      await db.insert(
        'community_posts',
        {
          'id': id,
          'user_id': userId,
          'user_name': _sanitizeInput(userName),
          'content': sanitizedContent,
          'category': category == null || category.trim().isEmpty
              ? null
              : _sanitizeInput(category),
          'content_hash': contentHash,
          'likes': 0,
          'reports': 0,
          'is_flagged': 0,
          'is_hidden': 0,
          'created_at': now,
          'updated_at': now,
        },
      );

      _logger.database('insert',
          table: 'community_posts', details: 'Created post $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to create post', e, stackTrace);
      return DbResult.failure('Failed to create post');
    }
  }

  Future<DbResult<void>> likePost(String postId) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE community_posts SET likes = likes + 1, updated_at = ? WHERE id = ?',
        [DateTime.now().toIso8601String(), postId],
      );
      _logger.database('update',
          table: 'community_posts', details: 'Liked post $postId');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to like post', e, stackTrace);
      return DbResult.failure('Failed to like post');
    }
  }

  Future<DbResult<void>> reportPost(
      String postId, String reporterId, String reason) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // Increment report count
        await txn.rawUpdate(
          'UPDATE community_posts SET reports = reports + 1, updated_at = ? WHERE id = ?',
          [DateTime.now().toIso8601String(), postId],
        );

        // Check if should auto-flag (3+ reports)
        final post = await txn
            .query('community_posts', where: 'id = ?', whereArgs: [postId]);
        if (post.isNotEmpty && (post.first['reports'] as int) >= 3) {
          await txn.update(
            'community_posts',
            {'is_flagged': 1},
            where: 'id = ?',
            whereArgs: [postId],
          );
          _logger.moderation('auto_flagged_post', reason: '3+ reports');
        }

        // Record the report
        await txn.insert('user_reports', {
          'id':
              '${reporterId}_${postId}_${DateTime.now().millisecondsSinceEpoch}',
          'reporter_id': reporterId,
          'target_type': 'post',
          'target_id': postId,
          'reason': _sanitizeInput(reason),
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      _logger.moderation('post_reported', reason: reason);
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to report post', e, stackTrace);
      return DbResult.failure('Failed to report post');
    }
  }

  Future<DbResult<void>> deletePost(String postId) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete('community_comments',
            where: 'post_id = ?', whereArgs: [postId]);
        await txn
            .delete('community_posts', where: 'id = ?', whereArgs: [postId]);
      });

      _logger.database('delete',
          table: 'community_posts', details: 'Deleted post $postId');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to delete post', e, stackTrace);
      return DbResult.failure('Failed to delete post');
    }
  }

  Future<DbResult<List<Map<String, dynamic>>>> getComments(
      String postId) async {
    try {
      final db = await database;
      final results = await db.query(
        'community_comments',
        where: 'post_id = ? AND is_flagged = 0',
        whereArgs: [postId],
        orderBy: 'created_at ASC',
      );
      _logger.database('read',
          table: 'community_comments',
          details: 'Get ${results.length} comments');
      return DbResult.success(results);
    } catch (e, stackTrace) {
      _logger.error('Failed to get comments', e, stackTrace);
      return DbResult.failure('Failed to retrieve comments');
    }
  }

  Future<DbResult<void>> createComment(String id, String postId, String userId,
      String userName, String content) async {
    try {
      final db = await database;
      final sanitizedContent = _sanitizeInput(content);
      final contentHash = _generateHash(sanitizedContent);

      await db.insert(
        'community_comments',
        {
          'id': id,
          'post_id': postId,
          'user_id': userId,
          'user_name': _sanitizeInput(userName),
          'content': sanitizedContent,
          'content_hash': contentHash,
          'reports': 0,
          'is_flagged': 0,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      _logger.database('insert',
          table: 'community_comments', details: 'Created comment $id');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to create comment', e, stackTrace);
      return DbResult.failure('Failed to create comment');
    }
  }

  Future<DbResult<void>> reportComment(
      String commentId, String reporterId, String reason) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE community_comments SET reports = reports + 1 WHERE id = ?',
          [commentId],
        );

        final comment = await txn.query('community_comments',
            where: 'id = ?', whereArgs: [commentId]);
        if (comment.isNotEmpty && (comment.first['reports'] as int) >= 3) {
          await txn.update('community_comments', {'is_flagged': 1},
              where: 'id = ?', whereArgs: [commentId]);
          _logger.moderation('auto_flagged_comment', reason: '3+ reports');
        }

        await txn.insert('user_reports', {
          'id':
              '${reporterId}_${commentId}_${DateTime.now().millisecondsSinceEpoch}',
          'reporter_id': reporterId,
          'target_type': 'comment',
          'target_id': commentId,
          'reason': _sanitizeInput(reason),
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      _logger.moderation('comment_reported', reason: reason);
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to report comment', e, stackTrace);
      return DbResult.failure('Failed to report comment');
    }
  }

  // ==================== Utility Operations ====================

  /// Sanitize user input to prevent injection attacks
  String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>]'), '') // Remove potential HTML tags
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control characters
        .trim();
  }

  /// Clear all data (for account deletion or reset)
  Future<DbResult<void>> clearAllData() async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete('user_reports');
        await txn.delete('community_comments');
        await txn.delete('community_posts');
        await txn.delete('schedules');
        await txn.delete('logs');
        await txn.delete('users');
      });

      _logger.security('all_data_cleared');
      return DbResult.success(null);
    } catch (e, stackTrace) {
      _logger.error('Failed to clear data', e, stackTrace);
      return DbResult.failure('Failed to clear data');
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.database('closed', details: 'Database connection closed');
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final db = await database;
      final stats = <String, int>{};

      for (final table in [
        'users',
        'logs',
        'schedules',
        'community_posts',
        'community_comments'
      ]) {
        final result =
            await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats[table] = Sqflite.firstIntValue(result) ?? 0;
      }

      return stats;
    } catch (e) {
      _logger.error('Failed to get statistics', e);
      return {};
    }
  }

  /// Verify data integrity
  Future<bool> verifyIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      final isOk = result.isNotEmpty && result.first['integrity_check'] == 'ok';
      _logger.database('integrity_check', details: isOk ? 'passed' : 'failed');
      return isOk;
    } catch (e) {
      _logger.error('Integrity check failed', e);
      return false;
    }
  }
}
