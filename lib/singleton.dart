import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:levio/services/app_logger.dart';
import 'package:levio/services/cloud_backend_service.dart';
import 'package:levio/services/content_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'theme/app_theme.dart';

/// Main application state manager
///
/// Singleton pattern for centralized state management with:
/// - Cloud database persistence
/// - Secure data handling
/// - Comprehensive logging
class Singleton extends ChangeNotifier {
  static final Singleton _instance = Singleton._internal();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final CloudBackendService _cloud = CloudBackendService();
  final ContentModerationService _moderation = ContentModerationService();
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
  final Set<String> joinedCommunityGroups = <String>{};
  String? _lastCommunityError;

  /// Initialize singleton services
  Future<void> initialize({bool isProduction = false}) async {
    if (_initialized) return;

    _logger.init(isProduction: isProduction);
    await _cloud.initialize();
    _initialized = true;
    _logger.info('Singleton initialized');
  }

  void setFirstTime(b) {
    firstTime = b;
    notifyListenersSafe();
  }

  Future<void> setUID(String uid) async {
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

  bool get isCloudConnected => _cloud.isEnabled;
  bool get isCloudConfigured => _cloud.isConfigured;
  String get backendStatusDescription => _cloud.statusDescription;
  String? get cloudSessionUserId => _cloud.cloudUserId;

  String? consumeLastCommunityError() {
    final error = _lastCommunityError;
    _lastCommunityError = null;
    return error;
  }

  void setCurrentUrl(url) {
    currentURL = url;
    notifyListenersSafe();
  }

  // ==================== Cloud Data Operations ====================

  Future<String?> _resolveUserId() async {
    final storedUid = await getUID();
    final cloudUid = _cloud.cloudUserId;
    final resolvedUid = cloudUid ?? storedUid;

    if (resolvedUid != null && storedUid != resolvedUid) {
      await setUID(resolvedUid);
    }

    return resolvedUid;
  }

  Map<String, dynamic> _decodeDataField(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Keep empty map when persisted payload is malformed.
      }
    }
    return <String, dynamic>{};
  }

  String _normalizedDisplayName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Levio Member' : trimmed;
  }

  String _effectiveProfileImage(String? candidate) {
    final trimmed = candidate?.trim() ?? '';
    return trimmed.isEmpty ? 'images/711128.png' : trimmed;
  }

  Future<bool> _ensureCloudUserRecord(String uid) async {
    return _cloud.upsertUser(
      id: uid,
      name: _normalizedDisplayName(name == '[Name]' ? '' : name),
      age: age,
      profileImage: _effectiveProfileImage(image),
      email: email == '[Email]' ? null : email,
    );
  }

  /// Load user data from cloud backend
  Future<bool> loadUser() async {
    try {
      if (!_cloud.isEnabled) {
        _logger.warning('Cloud backend is not available for user loading.');
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _logger.debug('No cloud user ID found');
        return false;
      }

      final userData = await _cloud.getUser(uid);
      if (userData == null) {
        _logger.debug('User not found in cloud database');
        return false;
      }

      final userName = userData['name']?.toString().trim() ?? '';
      final userEmail = userData['email']?.toString().trim() ?? '';
      final userImage = userData['profile_image']?.toString().trim() ?? '';

      name = userName.isEmpty ? '[Name]' : userName;
      email = userEmail.isEmpty ? '[Email]' : userEmail;
      age = (userData['age'] as num?)?.toInt() ?? 0;
      image = userImage.isEmpty ? 'images/711128.png' : userImage;

      final cloudLogs = await _cloud.getLogs(uid);
      log.clear();
      logIDs.clear();
      for (final logEntry in cloudLogs) {
        final parsedData = _decodeDataField(logEntry['data']);
        log.add(<String>[
          (logEntry['event_time'] ?? parsedData['time'] ?? '').toString(),
          (logEntry['symptom'] ??
                  parsedData['symptom'] ??
                  logEntry['title'] ??
                  '')
              .toString(),
          (logEntry['severity'] ?? parsedData['severity'] ?? '').toString(),
        ]);
        logIDs.add((logEntry['id'] ?? '').toString());
      }
      sortTime();

      final cloudSchedules = await _cloud.getSchedules(uid);
      schedule.clear();
      scheduleIDs.clear();
      for (final scheduleEntry in cloudSchedules) {
        final parsedData = _decodeDataField(scheduleEntry['data']);
        schedule.add(<String>[
          (parsedData['name'] ?? scheduleEntry['title'] ?? '').toString(),
          (scheduleEntry['details'] ?? parsedData['details'] ?? '').toString(),
          (scheduleEntry['days'] ?? parsedData['days'] ?? '').toString(),
        ]);
        scheduleIDs.add((scheduleEntry['id'] ?? '').toString());
      }

      calcMeds();
      notifyListenersSafe();
      _logger.info('User data loaded from cloud successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error loading user', e, stackTrace);
      return false;
    }
  }

  Future<CloudAuthProfile?> signInWithGoogle() async {
    return _cloud.signInWithGoogle();
  }

  Future<bool> createOrSyncAuthenticatedUser({
    required String displayName,
    String? userEmail,
    String? profileImage,
  }) async {
    try {
      if (!_cloud.isEnabled) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;

      final normalizedName = _normalizedDisplayName(displayName);
      final normalizedEmail = (userEmail != null && userEmail.trim().isNotEmpty)
          ? userEmail.trim()
          : null;
      final normalizedImage = _effectiveProfileImage(profileImage ?? image);

      final prefs = await _prefs;
      await prefs.setString('userID', uid);

      final synced = await _cloud.upsertUser(
        id: uid,
        name: normalizedName,
        age: age,
        profileImage: normalizedImage,
        email: normalizedEmail,
      );
      if (!synced) return false;

      name = normalizedName;
      email = normalizedEmail ?? '[Email]';
      image = normalizedImage;
      firstTime = false;

      await loadUser();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error syncing authenticated user', e, stackTrace);
      return false;
    }
  }

  /// Create a new user in cloud database
  Future<bool> createUser(String userName, int age) async {
    try {
      if (!_cloud.isEnabled) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;

      final normalizedName = _normalizedDisplayName(userName);
      final created = await _cloud.upsertUser(
        id: uid,
        name: normalizedName,
        age: age,
        profileImage: _effectiveProfileImage(image),
        email: email == '[Email]' ? null : email,
      );
      if (!created) return false;

      final prefs = await _prefs;
      await prefs.setString('userID', uid);
      name = normalizedName;
      this.age = age;

      notifyListenersSafe();
      _logger.info('User created successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error creating user', e, stackTrace);
      return false;
    }
  }

  /// Update user data in cloud database
  Future<bool> updateUser(
      {String? userName,
      int? age,
      String? profileImage,
      String? userEmail}) async {
    try {
      if (!_cloud.isEnabled) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;

      final nextName =
          userName != null ? _normalizedDisplayName(userName) : name;
      final nextEmail = userEmail != null
          ? (userEmail.trim().isEmpty ? '[Email]' : userEmail.trim())
          : email;
      final nextAge = age ?? this.age;
      final nextImage = profileImage != null
          ? _effectiveProfileImage(profileImage)
          : _effectiveProfileImage(image);

      final updated = await _cloud.upsertUser(
        id: uid,
        name: nextName,
        age: nextAge,
        profileImage: nextImage,
        email: nextEmail == '[Email]' ? null : nextEmail,
      );
      if (!updated) return false;

      name = nextName;
      email = nextEmail;
      this.age = nextAge;
      image = nextImage;

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error updating user', e, stackTrace);
      return false;
    }
  }

  /// Save a new log entry
  Future<bool> saveLog(String time, String symptom, String severity) async {
    try {
      if (!_cloud.isEnabled) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;
      if (!await _ensureCloudUserRecord(uid)) return false;

      final logId = _uuid.v4();
      final data = jsonEncode({
        'time': time,
        'symptom': symptom,
        'severity': severity,
      });

      final saved = await _cloud.saveLog(
        id: logId,
        userId: uid,
        title: symptom,
        data: data,
        time: time,
        symptom: symptom,
        severity: severity,
      );
      if (!saved) return false;

      log.add(<String>[time, symptom, severity]);
      logIDs.add(logId);
      sortTime();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error saving log', e, stackTrace);
      return false;
    }
  }

  /// Update an existing log entry
  Future<bool> updateLogEntry(
      int index, String time, String symptom, String severity) async {
    try {
      if (!_cloud.isEnabled) return false;
      if (index < 0 || index >= logIDs.length) return false;

      final logId = logIDs[index];
      if (logId.isEmpty) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;

      final data = jsonEncode({
        'time': time,
        'symptom': symptom,
        'severity': severity,
      });

      final updated = await _cloud.saveLog(
        id: logId,
        userId: uid,
        title: symptom,
        data: data,
        time: time,
        symptom: symptom,
        severity: severity,
      );
      if (!updated) return false;

      log[index] = <String>[time, symptom, severity];
      sortTime();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error updating log', e, stackTrace);
      return false;
    }
  }

  /// Delete a log entry
  Future<bool> deleteLog(int index) async {
    try {
      if (!_cloud.isEnabled) return false;
      if (index < 0 || index >= logIDs.length) return false;

      final logId = logIDs[index];
      if (logId.isEmpty) return false;

      final deleted = await _cloud.deleteLog(logId);
      if (!deleted) return false;

      log.removeAt(index);
      logIDs.removeAt(index);
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error deleting log', e, stackTrace);
      return false;
    }
  }

  /// Save a new schedule entry
  Future<bool> saveSchedule(String medName, String details, String days) async {
    try {
      if (!_cloud.isEnabled) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;
      if (!await _ensureCloudUserRecord(uid)) return false;

      final scheduleId = _uuid.v4();
      final data = jsonEncode({
        'name': medName,
        'details': details,
        'days': days,
      });

      final saved = await _cloud.saveSchedule(
        id: scheduleId,
        userId: uid,
        title: medName,
        data: data,
        days: days,
        details: details,
      );
      if (!saved) return false;

      schedule.add(<String>[medName, details, days]);
      scheduleIDs.add(scheduleId);
      calcMeds();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error saving schedule', e, stackTrace);
      return false;
    }
  }

  /// Update an existing schedule entry
  Future<bool> updateScheduleEntry(
      int index, String medName, String details, String days) async {
    try {
      if (!_cloud.isEnabled) return false;
      if (index < 0 || index >= scheduleIDs.length) return false;

      final scheduleId = scheduleIDs[index];
      if (scheduleId.isEmpty) return false;

      final uid = await _resolveUserId();
      if (uid == null) return false;

      final data = jsonEncode({
        'name': medName,
        'details': details,
        'days': days,
      });

      final updated = await _cloud.saveSchedule(
        id: scheduleId,
        userId: uid,
        title: medName,
        data: data,
        days: days,
        details: details,
      );
      if (!updated) return false;

      schedule[index] = <String>[medName, details, days];
      calcMeds();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error updating schedule', e, stackTrace);
      return false;
    }
  }

  /// Delete a schedule entry
  Future<bool> deleteScheduleEntry(int index) async {
    try {
      if (!_cloud.isEnabled) return false;
      if (index < 0 || index >= scheduleIDs.length) return false;

      final scheduleId = scheduleIDs[index];
      if (scheduleId.isEmpty) return false;

      final deleted = await _cloud.deleteSchedule(scheduleId);
      if (!deleted) return false;

      schedule.removeAt(index);
      scheduleIDs.removeAt(index);
      calcMeds();
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error deleting schedule', e, stackTrace);
      return false;
    }
  }

  /// Delete entire account and all associated data
  Future<bool> deleteAccount() async {
    try {
      final uid = await _resolveUserId();
      if (uid != null && !await _cloud.deleteUser(uid)) {
        _logger.error('Failed to delete user from cloud database');
        return false;
      }

      log.clear();
      logIDs.clear();
      schedule.clear();
      scheduleIDs.clear();
      communityPosts.clear();
      communityComments.clear();
      joinedCommunityGroups.clear();
      name = '[Name]';
      email = '[Email]';
      image = 'images/711128.png';
      postNum = 0;
      exerNum = 0;
      firstTime = true;
      age = 0;

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

  /// Sign out current user while preserving app preferences like theme.
  Future<bool> signOut() async {
    try {
      final cloudSignedOut = await _cloud.signOut();

      log.clear();
      logIDs.clear();
      schedule.clear();
      scheduleIDs.clear();
      communityPosts.clear();
      communityComments.clear();
      joinedCommunityGroups.clear();
      name = '[Name]';
      email = '[Email]';
      image = 'images/711128.png';
      postNum = 0;
      exerNum = 0;
      firstTime = true;
      age = 0;
      page = 0;
      _lastCommunityError = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userID');
      await prefs.remove('community_alias');

      notifyListenersSafe();
      return cloudSignedOut;
    } catch (e, stackTrace) {
      _logger.error('Error signing out', e, stackTrace);
      return false;
    }
  }

  // ==================== Community Operations ====================

  Future<String> _communityDisplayName() async {
    if (name.trim().isNotEmpty && name != '[Name]') {
      return name.trim();
    }

    final prefs = await _prefs;
    final existingAlias = prefs.getString('community_alias');
    if (existingAlias != null && existingAlias.trim().isNotEmpty) {
      return existingAlias;
    }

    final alias = 'Member-${Random().nextInt(9000) + 1000}';
    await prefs.setString('community_alias', alias);
    return alias;
  }

  Future<List<Map<String, dynamic>>> loadCommunityPosts({
    int limit = 50,
  }) async {
    try {
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return communityPosts;
      }

      final cloudPosts = await _cloud.getCommunityPosts(limit: limit);
      final uid = await _resolveUserId();
      final postIds = cloudPosts
          .map((post) => post['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      Set<String> likedPostIds = <String>{};
      Map<String, int> commentCounts = <String, int>{};

      if (uid != null && postIds.isNotEmpty) {
        likedPostIds = await _cloud.getLikedPostIds(
          userId: uid,
          postIds: postIds,
        );
      }
      if (postIds.isNotEmpty) {
        commentCounts = await _cloud.getCommunityCommentCounts(postIds);
      }

      final normalizedPosts = cloudPosts.map((post) {
        final copy = Map<String, dynamic>.from(post);
        final postId = copy['id']?.toString() ?? '';
        copy['liked_by_me'] = likedPostIds.contains(postId);
        copy['comment_count'] = commentCounts[postId] ?? 0;
        return copy;
      }).toList();

      communityPosts
        ..clear()
        ..addAll(normalizedPosts);
      postNum = communityPosts.length;
      notifyListenersSafe();
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
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return false;
      }

      if (!await _ensureCloudUserRecord(uid)) {
        _lastCommunityError = 'Unable to verify your profile.';
        return false;
      }

      final moderation = _moderation.moderateContent(
        content,
        allowLinks: false,
        userId: uid,
      );
      if (!moderation.isApproved) {
        _lastCommunityError = moderation.rejectionReason ??
            'Post does not meet community safety guidelines.';
        return false;
      }

      final safeContent = (moderation.sanitizedContent ?? content).trim();
      if (safeContent.isEmpty) {
        _lastCommunityError = 'Post cannot be empty.';
        return false;
      }

      final postId = _uuid.v4();
      final displayName = await _communityDisplayName();
      final createdAt = DateTime.now().toIso8601String();

      final saved = await _cloud.saveCommunityPost(
        id: postId,
        userId: uid,
        userName: displayName,
        content: safeContent,
        category: category,
        profileImage: image,
      );
      if (!saved) {
        _lastCommunityError = 'Unable to share post right now.';
        return false;
      }

      communityPosts.insert(0, <String, dynamic>{
        'id': postId,
        'user_id': uid,
        'user_name': displayName,
        'profile_image': image,
        'content': safeContent,
        'category': category,
        'likes': 0,
        'created_at': createdAt,
        'updated_at': createdAt,
      });
      postNum = communityPosts.length;
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error creating community post', e, stackTrace);
      _lastCommunityError = 'Unable to share post right now.';
      return false;
    }
  }

  Future<bool> updateCommunityPost({
    required String postId,
    required String content,
    String? category,
  }) async {
    try {
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return false;
      }

      final moderation = _moderation.moderateContent(
        content,
        allowLinks: false,
        userId: uid,
      );
      if (!moderation.isApproved) {
        _lastCommunityError = moderation.rejectionReason ??
            'Post does not meet community safety guidelines.';
        return false;
      }

      final safeContent = (moderation.sanitizedContent ?? content).trim();
      if (safeContent.isEmpty) {
        _lastCommunityError = 'Post cannot be empty.';
        return false;
      }

      final updated = await _cloud.updateCommunityPost(
        postId: postId,
        content: safeContent,
        category: category,
      );
      if (!updated) {
        _lastCommunityError = 'Unable to update post right now.';
        return false;
      }

      final index = communityPosts.indexWhere((post) => post['id'] == postId);
      if (index != -1) {
        communityPosts[index]['content'] = safeContent;
        communityPosts[index]['category'] = category;
        communityPosts[index]['updated_at'] = DateTime.now().toIso8601String();
      }

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error updating community post', e, stackTrace);
      _lastCommunityError = 'Unable to update post right now.';
      return false;
    }
  }

  Future<bool> deleteCommunityPost(String postId) async {
    try {
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final deleted = await _cloud.deleteCommunityPost(postId);
      if (!deleted) {
        _lastCommunityError = 'Unable to delete post right now.';
        return false;
      }

      communityPosts.removeWhere((post) => post['id'] == postId);
      communityComments.remove(postId);
      postNum = communityPosts.length;
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error deleting community post', e, stackTrace);
      _lastCommunityError = 'Unable to delete post right now.';
      return false;
    }
  }

  Future<bool> likeCommunityPost(String postId) async {
    try {
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return false;
      }

      if (!await _ensureCloudUserRecord(uid)) {
        _lastCommunityError = 'Unable to verify your profile.';
        return false;
      }

      final likeResult = await _cloud.likeCommunityPost(
        postId: postId,
        userId: uid,
      );
      if (likeResult == null) {
        _lastCommunityError = 'Unable to like post right now.';
        return false;
      }
      if (!likeResult) {
        _lastCommunityError = 'You already liked this post.';
        return false;
      }

      final idx = communityPosts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) {
        final likes = (communityPosts[idx]['likes'] as num?)?.toInt() ?? 0;
        communityPosts[idx]['likes'] = likes + 1;
        communityPosts[idx]['liked_by_me'] = true;
      }
      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error liking post', e, stackTrace);
      _lastCommunityError = 'Unable to like post right now.';
      return false;
    }
  }

  Future<Set<String>> loadJoinedCommunityGroups() async {
    try {
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return joinedCommunityGroups;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return joinedCommunityGroups;
      }

      final joined = await _cloud.getJoinedCommunityGroupIds(uid);
      joinedCommunityGroups
        ..clear()
        ..addAll(joined);
      notifyListenersSafe();
      return joinedCommunityGroups;
    } catch (e, stackTrace) {
      _logger.error('Error loading community groups', e, stackTrace);
      _lastCommunityError = 'Unable to load groups right now.';
      return joinedCommunityGroups;
    }
  }

  Future<bool> setCommunityGroupMembership({
    required String groupId,
    required bool isJoined,
  }) async {
    try {
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return false;
      }

      if (!await _ensureCloudUserRecord(uid)) {
        _lastCommunityError = 'Unable to verify your profile.';
        return false;
      }

      final updated = await _cloud.setCommunityGroupMembership(
        userId: uid,
        groupId: groupId,
        isJoined: isJoined,
      );
      if (!updated) {
        _lastCommunityError = 'Unable to update group membership.';
        return false;
      }

      if (isJoined) {
        joinedCommunityGroups.add(groupId);
      } else {
        joinedCommunityGroups.remove(groupId);
      }

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error updating community group membership', e, stackTrace);
      _lastCommunityError = 'Unable to update group membership.';
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadCommunityComments(
      String postId) async {
    try {
      if (!_cloud.isEnabled) {
        return communityComments[postId] ?? <Map<String, dynamic>>[];
      }

      final cloudComments = await _cloud.getCommunityComments(postId);
      communityComments[postId] = cloudComments;
      notifyListenersSafe();
      return cloudComments;
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
      _lastCommunityError = null;
      if (!_cloud.isEnabled) {
        _lastCommunityError = 'Cloud sync unavailable.';
        return false;
      }

      final uid = await _resolveUserId();
      if (uid == null) {
        _lastCommunityError = 'Complete profile setup first.';
        return false;
      }

      if (!await _ensureCloudUserRecord(uid)) {
        _lastCommunityError = 'Unable to verify your profile.';
        return false;
      }

      final moderation = _moderation.moderateContent(
        content,
        allowLinks: false,
        userId: uid,
      );
      if (!moderation.isApproved) {
        _lastCommunityError = moderation.rejectionReason ??
            'Comment does not meet community safety guidelines.';
        return false;
      }

      final safeContent = (moderation.sanitizedContent ?? content).trim();
      if (safeContent.isEmpty) {
        _lastCommunityError = 'Comment cannot be empty.';
        return false;
      }

      final commentId = _uuid.v4();
      final displayName = await _communityDisplayName();
      final createdAt = DateTime.now().toIso8601String();

      final saved = await _cloud.saveCommunityComment(
        id: commentId,
        postId: postId,
        userId: uid,
        userName: displayName,
        content: safeContent,
        profileImage: image,
      );
      if (!saved) {
        _lastCommunityError = 'Unable to add comment right now.';
        return false;
      }

      final cache = communityComments.putIfAbsent(
        postId,
        () => <Map<String, dynamic>>[],
      );
      cache.add(<String, dynamic>{
        'id': commentId,
        'post_id': postId,
        'user_id': uid,
        'user_name': displayName,
        'profile_image': image,
        'content': safeContent,
        'created_at': createdAt,
      });

      final postIdx = communityPosts.indexWhere((post) => post['id'] == postId);
      if (postIdx != -1) {
        final current =
            (communityPosts[postIdx]['comment_count'] as num?)?.toInt() ?? 0;
        communityPosts[postIdx]['comment_count'] = current + 1;
      }

      notifyListenersSafe();
      return true;
    } catch (e, stackTrace) {
      _logger.error('Error creating comment', e, stackTrace);
      _lastCommunityError = 'Unable to add comment right now.';
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

  /// Get in-memory cache statistics for debugging
  Future<Map<String, int>> getDatabaseStats() async {
    return <String, int>{
      'logs': log.length,
      'schedules': schedule.length,
      'community_posts_cache': communityPosts.length,
      'community_comment_threads_cache': communityComments.length,
    };
  }
}
