import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:levio/services/local_database.dart';
import 'package:levio/services/app_logger.dart';
import 'package:levio/services/cloud_backend_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'theme/app_theme.dart';

/// Main application state manager
///
/// Singleton pattern for centralized state management with:
/// - Local database persistence
/// - Secure data handling
/// - Comprehensive logging
class Singleton extends ChangeNotifier {
  static final Singleton _instance = Singleton._internal();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final LocalDatabase _db = LocalDatabase();
  final CloudBackendService _cloud = CloudBackendService();
  final AppLogger _logger = AppLogger();
  final Uuid _uuid = const Uuid();

  factory Singleton() => _instance;

  void notifyListenersSafe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Singleton._internal();

  // App state
  bool _initialized = false;
  bool firstTime = true;
  int page = 0;
  List<List<String>> log = [];
  List<List<String>> schedule = [];

  // Speech therapy exercises for Parkinson's (YouTube video IDs)
  // Using real LSVT LOUD and Parkinson Voice Project videos
  Map<String, List<String>> speeches = {
    "0ndTdBnVwFY": [
      "LSVT LOUD Introduction",
      "Official LSVT LOUD voice exercise introduction by Dr. Cynthia Fox. Learn the fundamentals of voice therapy for Parkinson's.",
      "9:55",
      "Source: LSVTGLOBAL (YouTube)"
    ],
    "dzKy4vKp5_I": [
      "Voice Exercises with Rachel",
      "Power for Parkinson's voice exercises led by speech therapist Rachel Stern. Daily vocal warm-ups and strengthening.",
      "25:00",
      "Source: Power for Parkinsons (YouTube)"
    ],
    "0TKUdR5Nisk": [
      "Beatles Sing Along",
      "Fun vocal strength class with sing-alongs, warm-ups, and tongue twisters to improve vocal power and range.",
      "45:00",
      "Source: Power for Parkinsons (YouTube)"
    ],
    "zO5KQb4mUFA": [
      "Speaking with INTENT",
      "SPEAK OUT! therapy presentation on speaking and swallowing strategies for Parkinson's by certified provider.",
      "53:00",
      "Source: UT Southwestern Medical Center (YouTube)"
    ],
    "RmWOwGvyVZI": [
      "LSVT BIG & LOUD Combined",
      "Complete LSVT program combining voice (LOUD) and movement (BIG) exercises for comprehensive therapy.",
      "15:00",
      "Source: Parkinson's Foundation (YouTube)"
    ],
  };

  // Physical therapy exercises (verified YouTube video IDs)
  // Using Davis Phinney Foundation, Power for Parkinson's, and Parkinson's UK videos
  Map<String, List<String>> exercises = {
    "QbWyxn8XE-I": [
      "Exercise Essentials: Intro",
      "Davis Phinney Foundation's introduction to exercise for Parkinson's. Learn why exercise is essential.",
      "10:00",
      "Source: Davis Phinney Foundation (YouTube)"
    ],
    "AZV3_NfcpVs": [
      "Sit 'n' Fit Workout",
      "Parkinson's Association chair-based aerobic exercises. 12-minute seated workout for all fitness levels.",
      "12:00",
      "Source: Parkinson's Foundation (YouTube)"
    ],
    "HHtgtNmBivo": [
      "Chair Workout for Balance",
      "Power for Parkinson's 35-minute chair workout to improve gait, balance, cognition, and mobility.",
      "35:00",
      "Source: Power for Parkinsons (YouTube)"
    ],
    "4wB43bbSdm8": [
      "Seated Workout",
      "Ageless Grace method seated workout focusing on brain health and body movement coordination.",
      "12:00",
      "Source: Parkinson's Foundation (YouTube)"
    ],
    "No2EIvShhP0": [
      "Reach Your Peak Chair Class",
      "Parkinson's UK chair workout with both physical and mental exercises to manage symptoms.",
      "30:00",
      "Source: Parkinson's UK (YouTube)"
    ],
    "RfI_v-HQb5I": [
      "Managing Symptoms Exercises",
      "Great seated exercises specifically designed for managing Parkinson's symptoms safely at home.",
      "20:00",
      "Source: Power for Parkinsons (YouTube)"
    ],
  };

  String currentURL = "";
  String name = "[Name]";
  String email = "[Email]";
  int age = 0;
  String image = "images/711128.png";
  int postNum = 0;
  int exerNum = 0;

  // ID tracking
  List<String> logIDs = [];
  List<String> scheduleIDs = [];

  // Community cache
  final List<Map<String, dynamic>> communityPosts = [];
  final Map<String, List<Map<String, dynamic>>> communityComments = {};

  /// Initialize the singleton and database
  Future<void> initialize({bool isProduction = false}) async {
    if (_initialized) return;

    _logger.init(isProduction: isProduction);
    await _db.initialize();
    await _cloud.initialize();
    _initialized = true;
    _logger.info('Singleton initialized');
  }

  void setFirstTime(b) {
    firstTime = b;
    notifyListenersSafe();
  }

  void setUID(String uid) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('userID', uid);
  }

  Future<String?> getUID() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('userID');
  }

  void setTheme(bool t) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool('theme', t);
  }

  Future<bool> getTheme() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool('theme') ?? false;
  }

  void setSound(double s) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setDouble('sound', s);
  }

  Future<double> getSound() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getDouble('sound') ?? 1.0;
  }

  void setPage(int n) {
    page = n;
    notifyListenersSafe();
  }

  void setName(String n) {
    name = n;
    notifyListenersSafe();
  }

  void setImage(String i) {
    image = i;
    notifyListenersSafe();
  }

  void setEmail(String e) {
    email = e;
    notifyListenersSafe();
  }

  void setPostNum(int p) {
    postNum = p;
    notifyListenersSafe();
  }

  void setExerNum(int e) {
    exerNum = e;
    notifyListenersSafe();
  }

  Map<String, String> monthMap = {
    'January': "01",
    'February': "02",
    'March': "03",
    'April': "04",
    'May': "05",
    'June': "06",
    'July': "07",
    'August': "08",
    'September': "09",
    'October': "10",
    'November': "11",
    'December': "12"
  };

  DateTime? _parseLogTimestamp(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;

    final timePart = parts.first.trim();
    final datePart = parts.last.trim();

    final timeSegments = timePart.split(':');
    final dateSegments = datePart.split(' ');

    if (timeSegments.length != 2 || dateSegments.length != 3) return null;

    final hour = int.tryParse(timeSegments[0]);
    final minute = int.tryParse(timeSegments[1]);
    final day = int.tryParse(dateSegments[0]);
    final month = int.tryParse(monthMap[dateSegments[1]] ?? '');
    final year = int.tryParse(dateSegments[2]);

    if (hour == null ||
        minute == null ||
        day == null ||
        month == null ||
        year == null) {
      return null;
    }

    return DateTime(year, month, day, hour, minute);
  }

  void sortTime({bool descending = true}) {
    if (log.length <= 1) return;

    try {
      final order = List<int>.generate(log.length, (i) => i);
      order.sort((a, b) {
        final dateA = _parseLogTimestamp(log[a][0]);
        final dateB = _parseLogTimestamp(log[b][0]);

        if (dateA == null && dateB == null) return a.compareTo(b);
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return descending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });

      sortLog(order);
    } catch (e) {
      _logger.error('Error sorting time', e);
    }

    notifyListenersSafe();
  }

  void sortLog(List<int> order) {
    final oldLogs = List<List<String>>.from(
      log.map((entry) => List<String>.from(entry)),
    );
    final oldLogIds = List<String>.from(logIDs);

    final sortedLogs = <List<String>>[];
    final sortedLogIds = <String>[];

    for (final index in order) {
      if (index < 0 || index >= oldLogs.length) continue;
      sortedLogs.add(oldLogs[index]);
      sortedLogIds.add(index < oldLogIds.length ? oldLogIds[index] : '');
    }

    log
      ..clear()
      ..addAll(sortedLogs);
    logIDs
      ..clear()
      ..addAll(sortedLogIds);
  }

  void addLogList(String time, String symptom, String severity) {
    List<String> logList = [time, symptom, severity];
    log.add(logList);
    logIDs.add('');
    sortTime();
    notifyListenersSafe();
  }

  void addScheduleList(String name, String details, String days) {
    List<String> scheduleList = [name, details, days];
    schedule.add(scheduleList);
    scheduleIDs.add('');
    notifyListenersSafe();
  }

  List<String> month = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  List<String> year = ['2023', '2024', '2025', '2026', '2027', '2028'];

  Map<String, double> medsPerDay = {
    'Monday': 0,
    'Tuesday': 0,
    'Wednesday': 0,
    'Thursday': 0,
    'Friday': 0,
    'Saturday': 0,
    'Sunday': 0
  };

  Set<String> medicationNames = {};
  double barY = 1;

  void calcBarY() {
    List<double> values = medsPerDay.values.toList();
    values.sort();
    barY = values.isNotEmpty ? values.last + 1 : 1;
  }

  void calcMeds() {
    // Reset before calculating
    medsPerDay = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0
    };
    medicationNames.clear();

    for (int i = 0; i < schedule.length; i++) {
      if (schedule[i].length >= 3 &&
          !medicationNames.contains(schedule[i][0])) {
        if (schedule[i][2] == "Everyday") {
          for (var key in medsPerDay.keys) {
            medsPerDay[key] = (medsPerDay[key] ?? 0) + 1;
          }
        } else {
          for (var key in medsPerDay.keys) {
            if (schedule[i][2].contains(key)) {
              medsPerDay[key] = (medsPerDay[key] ?? 0) + 1;
            }
          }
        }
        medicationNames.add(schedule[i][0]);
      }
    }
    calcBarY();
  }

  // Theme management
  int colorMode = 0;

  void switchColorTheme(bool isDark) {
    colorMode = isDark ? 1 : 0;
    setTheme(isDark);
    notifyListenersSafe();
  }

  AppColors get currentColors {
    return colorMode == 1 ? AppTheme.darkColors : AppTheme.lightColors;
  }

  void setCurrentUrl(url) {
    currentURL = url;
    notifyListenersSafe();
  }

  // ==================== Local Database Operations ====================

  /// Load user data from local database
  Future<bool> loadUser() async {
    try {
      final uid = await getUID();
      if (uid == null) {
        _logger.debug('No user ID found');
        return false;
      }

      final userResult = await _db.getUser(uid);
      if (!userResult.success || userResult.data == null) {
        _logger.debug('User not found in database');
        return false;
      }

      final userData = userResult.data!;
      name = userData['name'] ?? '[Name]';
      email = userData['email'] ?? '[Email]';
      age = (userData['age'] as num?)?.toInt() ?? 0;
      image = userData['profile_image'] ?? 'images/711128.png';

      // Load logs
      final logsResult = await _db.getLogs(uid);
      if (logsResult.success) {
        log.clear();
        logIDs.clear();
        for (final logEntry in logsResult.dataOrThrow) {
          try {
            final data = jsonDecode(logEntry['data']);
            log.add([
              data['time'] ?? '',
              data['symptom'] ?? '',
              data['severity'] ?? ''
            ]);
            logIDs.add(logEntry['id']);
          } catch (e) {
            _logger.error('Error parsing log entry', e);
          }
        }
        sortTime();
      }

      // Load schedules
      final schedulesResult = await _db.getSchedules(uid);
      if (schedulesResult.success) {
        schedule.clear();
        scheduleIDs.clear();
        for (final scheduleEntry in schedulesResult.dataOrThrow) {
          try {
            final data = jsonDecode(scheduleEntry['data']);
            schedule.add([
              data['name'] ?? '',
              data['details'] ?? '',
              data['days'] ?? ''
            ]);
            scheduleIDs.add(scheduleEntry['id']);
          } catch (e) {
            _logger.error('Error parsing schedule entry', e);
          }
        }
      }

      calcMeds();
      notifyListenersSafe();
      _logger.info('User data loaded successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error loading user', e, stackTrace);
      return false;
    }
  }

  /// Create a new user in local database
  Future<bool> createUser(String userName, int age) async {
    try {
      final uid = _uuid.v4();
      final result = await _db.createUser(
        uid,
        userName,
        age,
        null,
        email == '[Email]' ? null : email,
      );

      if (result.success) {
        final prefs = await _prefs;
        await prefs.setString('userID', uid);
        name = userName;
        this.age = age;

        await _cloud.upsertUser(
          id: uid,
          name: userName,
          age: age,
          profileImage: image,
          email: email == '[Email]' ? null : email,
        );

        notifyListenersSafe();
        _logger.info('User created successfully');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error creating user', e, stackTrace);
      return false;
    }
  }

  /// Update user data in local database
  Future<bool> updateUser(
      {String? userName,
      int? age,
      String? profileImage,
      String? userEmail}) async {
    try {
      final uid = await getUID();
      if (uid == null) return false;

      final result = await _db.updateUser(uid,
          name: userName,
          age: age,
          profileImage: profileImage,
          email: userEmail);

      if (result.success) {
        if (userName != null) name = userName;
        if (userEmail != null) email = userEmail;
        if (age != null) this.age = age;
        if (profileImage != null) image = profileImage;

        await _cloud.upsertUser(
          id: uid,
          name: name,
          age: this.age,
          profileImage: image,
          email: email == '[Email]' ? null : email,
        );

        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error updating user', e, stackTrace);
      return false;
    }
  }

  /// Save a new log entry
  Future<bool> saveLog(String time, String symptom, String severity) async {
    try {
      final uid = await getUID();
      if (uid == null) return false;

      final logId = _uuid.v4();
      final data = jsonEncode({
        'time': time,
        'symptom': symptom,
        'severity': severity,
      });

      final result = await _db.saveLog(logId, uid, symptom, 0, 0, data);

      if (result.success) {
        log.add([time, symptom, severity]);
        logIDs.add(logId);

        await _cloud.saveLog(
          id: logId,
          userId: uid,
          title: symptom,
          data: data,
          time: time,
          symptom: symptom,
          severity: severity,
        );

        sortTime();
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error saving log', e, stackTrace);
      return false;
    }
  }

  /// Update an existing log entry
  Future<bool> updateLogEntry(
      int index, String time, String symptom, String severity) async {
    try {
      if (index < 0 || index >= logIDs.length) return false;

      final logId = logIDs[index];
      if (logId.isEmpty) return false;
      final data = jsonEncode({
        'time': time,
        'symptom': symptom,
        'severity': severity,
      });

      final result = await _db.updateLog(logId, title: symptom, data: data);

      if (result.success) {
        log[index] = [time, symptom, severity];

        final uid = await getUID();
        if (uid != null) {
          await _cloud.saveLog(
            id: logId,
            userId: uid,
            title: symptom,
            data: data,
            time: time,
            symptom: symptom,
            severity: severity,
          );
        }

        sortTime();
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error updating log', e, stackTrace);
      return false;
    }
  }

  /// Delete a log entry
  Future<bool> deleteLog(int index) async {
    try {
      if (index < 0 || index >= logIDs.length) return false;

      final logId = logIDs[index];
      if (logId.isEmpty) return false;
      final result = await _db.deleteLog(logId);

      if (result.success) {
        log.removeAt(index);
        logIDs.removeAt(index);
        await _cloud.deleteLog(logId);
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error deleting log', e, stackTrace);
      return false;
    }
  }

  /// Save a new schedule entry
  Future<bool> saveSchedule(String medName, String details, String days) async {
    try {
      final uid = await getUID();
      if (uid == null) return false;

      final scheduleId = _uuid.v4();
      final data = jsonEncode({
        'name': medName,
        'details': details,
        'days': days,
      });

      final result =
          await _db.saveSchedule(scheduleId, uid, medName, 0, 0, data);

      if (result.success) {
        schedule.add([medName, details, days]);
        scheduleIDs.add(scheduleId);

        await _cloud.saveSchedule(
          id: scheduleId,
          userId: uid,
          title: medName,
          data: data,
          days: days,
          details: details,
        );

        calcMeds();
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error saving schedule', e, stackTrace);
      return false;
    }
  }

  /// Update an existing schedule entry
  Future<bool> updateScheduleEntry(
      int index, String medName, String details, String days) async {
    try {
      if (index < 0 || index >= scheduleIDs.length) return false;

      final scheduleId = scheduleIDs[index];
      if (scheduleId.isEmpty) return false;
      final data = jsonEncode({
        'name': medName,
        'details': details,
        'days': days,
      });

      final result =
          await _db.updateSchedule(scheduleId, title: medName, data: data);

      if (result.success) {
        schedule[index] = [medName, details, days];

        final uid = await getUID();
        if (uid != null) {
          await _cloud.saveSchedule(
            id: scheduleId,
            userId: uid,
            title: medName,
            data: data,
            days: days,
            details: details,
          );
        }

        calcMeds();
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error updating schedule', e, stackTrace);
      return false;
    }
  }

  /// Delete a schedule entry
  Future<bool> deleteScheduleEntry(int index) async {
    try {
      if (index < 0 || index >= scheduleIDs.length) return false;

      final scheduleId = scheduleIDs[index];
      if (scheduleId.isEmpty) return false;
      final result = await _db.deleteSchedule(scheduleId);

      if (result.success) {
        schedule.removeAt(index);
        scheduleIDs.removeAt(index);
        await _cloud.deleteSchedule(scheduleId);
        calcMeds();
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error deleting schedule', e, stackTrace);
      return false;
    }
  }

  /// Delete entire account and all associated data
  Future<bool> deleteAccount() async {
    try {
      final uid = await getUID();
      if (uid != null) {
        final result = await _db.deleteUser(uid);
        if (!result.success) {
          _logger.error('Failed to delete user from database');
        }
        await _cloud.deleteUser(uid);
      }

      // Clear local state
      log.clear();
      logIDs.clear();
      schedule.clear();
      scheduleIDs.clear();
      name = '[Name]';
      email = '[Email]';
      image = 'images/711128.png';
      postNum = 0;
      exerNum = 0;
      firstTime = true;
      age = 0;

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListenersSafe();
      _logger.info('Account deleted successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error deleting account', e, stackTrace);
      return false;
    }
  }

  // ==================== Community Operations ====================

  String _communityDisplayName() {
    if (name.trim().isNotEmpty && name != '[Name]') {
      return name.trim();
    }
    return 'Member-${Random().nextInt(9000) + 1000}';
  }

  Future<List<Map<String, dynamic>>> loadCommunityPosts({
    int limit = 50,
  }) async {
    try {
      if (_cloud.isEnabled) {
        final cloudPosts = await _cloud.getCommunityPosts(limit: limit);
        if (cloudPosts.isNotEmpty) {
          communityPosts
            ..clear()
            ..addAll(cloudPosts);
          postNum = communityPosts.length;
          notifyListenersSafe();
          return communityPosts;
        }
      }

      final localPosts = await _db.getCommunityPosts(limit: limit);
      if (localPosts.success) {
        communityPosts
          ..clear()
          ..addAll(localPosts.dataOrThrow);
        postNum = communityPosts.length;
        notifyListenersSafe();
      }
      return communityPosts;
    } catch (e, stackTrace) {
      _logger.error('Error loading community posts', e, stackTrace);
      return communityPosts;
    }
  }

  Future<bool> createCommunityPost({
    required String content,
    String? category,
  }) async {
    try {
      final uid = await getUID();
      if (uid == null || content.trim().isEmpty) return false;

      final postId = _uuid.v4();
      final displayName = _communityDisplayName();
      final result =
          await _db.createPost(postId, uid, displayName, content, category);

      if (!result.success) return false;

      final createdAt = DateTime.now().toIso8601String();
      communityPosts.insert(0, <String, dynamic>{
        'id': postId,
        'user_id': uid,
        'user_name': displayName,
        'content': content.trim(),
        'category': category,
        'likes': 0,
        'created_at': createdAt,
        'updated_at': createdAt,
      });
      postNum = communityPosts.length;

      await _cloud.saveCommunityPost(
        id: postId,
        userId: uid,
        userName: displayName,
        content: content.trim(),
        category: category,
      );

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error creating community post', e, stackTrace);
      return false;
    }
  }

  Future<bool> likeCommunityPost(String postId) async {
    try {
      final local = await _db.likePost(postId);
      if (local.success) {
        final idx = communityPosts.indexWhere((p) => p['id'] == postId);
        if (idx != -1) {
          final likes = (communityPosts[idx]['likes'] as num?)?.toInt() ?? 0;
          communityPosts[idx]['likes'] = likes + 1;
        }
        await _cloud.incrementPostLike(postId);
        notifyListenersSafe();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      _logger.error('Error liking post', e, stackTrace);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadCommunityComments(
      String postId) async {
    try {
      if (_cloud.isEnabled) {
        final cloudComments = await _cloud.getCommunityComments(postId);
        if (cloudComments.isNotEmpty) {
          communityComments[postId] = cloudComments;
          notifyListenersSafe();
          return cloudComments;
        }
      }

      final localComments = await _db.getComments(postId);
      if (localComments.success) {
        communityComments[postId] = localComments.dataOrThrow;
        notifyListenersSafe();
      }
      return communityComments[postId] ?? <Map<String, dynamic>>[];
    } catch (e, stackTrace) {
      _logger.error('Error loading comments', e, stackTrace);
      return communityComments[postId] ?? <Map<String, dynamic>>[];
    }
  }

  Future<bool> createCommunityComment({
    required String postId,
    required String content,
  }) async {
    try {
      final uid = await getUID();
      if (uid == null || content.trim().isEmpty) return false;

      final commentId = _uuid.v4();
      final displayName = _communityDisplayName();
      final result =
          await _db.createComment(commentId, postId, uid, displayName, content);

      if (!result.success) return false;

      final createdAt = DateTime.now().toIso8601String();
      final cache = communityComments.putIfAbsent(
        postId,
        () => <Map<String, dynamic>>[],
      );
      cache.add(<String, dynamic>{
        'id': commentId,
        'post_id': postId,
        'user_id': uid,
        'user_name': displayName,
        'content': content.trim(),
        'created_at': createdAt,
      });

      await _cloud.saveCommunityComment(
        id: commentId,
        postId: postId,
        userId: uid,
        userName: displayName,
        content: content.trim(),
      );

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error creating comment', e, stackTrace);
      return false;
    }
  }

  // Legacy method for compatibility
  Future<void> deleteEntireList(int index, String listName) async {
    if (listName == "logs") {
      await deleteLog(index);
    } else if (listName == "schedules") {
      await deleteScheduleEntry(index);
    }
  }

  /// Get database statistics for debugging
  Future<Map<String, int>> getDatabaseStats() async {
    return await _db.getStatistics();
  }
}
