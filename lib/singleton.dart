import 'package:flutter/material.dart';
import 'package:parkinson/Firebase/firebase_cloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

class Singleton extends ChangeNotifier {
  static final Singleton _instance = Singleton._internal();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // passes the instantiation to the _instance object
  factory Singleton() => _instance;

  void notifyListenersSafe() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // initialize our variables
  Singleton._internal();
  bool firstTime = false;
  int page = 0;
  List<List<String>> log = [];
  List<List<String>> schedule = [];

  Map<String, List<String>> speeches = {
    "https://www2.cs.uic.edu/~i101/SoundFiles/BabyElephantWalk60.wav": [
      "Test Audio 1",
      "This is the first test audio"
    ],
    "https://www2.cs.uic.edu/~i101/SoundFiles/PinkPanther30.wav": [
      "Test Audio 2",
      "This is the second test audio"
    ]
  };

  Map<String, List<String>> exercises = {
    "AM3m9IPjkNE": [
      "Test Video 1",
      "This is the first test video",
    ],
    "_mKAqrA3weA": [
      "Test Video 2",
      "This is the second test video",
    ],
    "JxS5E-kZc2s": [
      "Test Video 3",
      "This is the third test video",
    ]
  };

  String currentURL = "";
  String name = "[Name]";
  String email = "[Email]";
  String image = "images/711128.png";
  int postNum = 0;
  int exerNum = 0;

  void setFirstTime(b) {
    firstTime = b;
    notifyListenersSafe();
  }

  void setUID(String uid) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('userID', uid);
  }

  Future<String> getUID() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString('userID')!;
  }

  void setTheme(bool t) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setBool('theme', t);
  }

  Future<bool> getTheme() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getBool('theme')!;
  }

  void setSound(double s) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setDouble('sound', s);
  }

  Future<double> getSound() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getDouble('sound')!;
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

  void sortTime() {
    List<List<String>> dTime = [];
    for (int i = 0; i < log.length; i++) {
      List<String> time = log[i][0].split(' ');
      dTime.add([
        "${time[3]}-${monthMap[time[2]]}-${time[1]} ${time[0].substring(0, time[0].length - 1)}:00",
        '$i'
      ]);
    }
    dTime.sort((a, b) {
      DateTime dateTimeA = DateTime.parse(a[0]);
      DateTime dateTimeB = DateTime.parse(b[0]);
      return dateTimeA.compareTo(dateTimeB);
    });

    sortLog(dTime.toList());
    notifyListenersSafe();
  }

  void sortLog(t) {
    List<List<String>> tempList = [];
    tempList.addAll(log);
    log.clear();
    for (int i = 0; i < tempList.length; i++) {
      log.add(tempList[int.parse(t[i][1])]);
    }
    notifyListenersSafe();
  }

  void addLogList(
    String time,
    String symptom,
    String severity,
  ) {
    List<String> logList = [time, symptom, severity];
    log.add(logList);
    sortTime();
    notifyListenersSafe();
  }

  void addScheduleList(String name, String details, String days) {
    List<String> scheduleList = [name, details, days];
    schedule.add(scheduleList);
    notifyListenersSafe();
  }

  List<String> logIDs = [];

  void setLogIDs(List<String> l) {
    log.clear();
    for (int i = 0; i < l.length; i++) {
      FirebaseCloud().getLogs(l[i]);
    }
    logIDs = l;
    notifyListenersSafe();
  }

  List<String> scheduleIDs = [];

  void setScheduleIDs(List<String> s) {
    schedule.clear();
    for (int i = 0; i < s.length; i++) {
      FirebaseCloud().getSchedules(s[i]);
    }
    scheduleIDs = s;
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
    List<double> values = [];
    values = medsPerDay.values.toList();
    values.sort();
    barY = values[medsPerDay.length - 1] + 1;
  }

  void calcMeds() {
    for (int i = 0; i < schedule.length; i++) {
      if (!medicationNames.contains(schedule[i][0])) {
        if (schedule[i][2] == "Everyday") {
          for (var key in medsPerDay.keys) {
            final day = <String, double>{key: medsPerDay[key]! + 1};
            medsPerDay.addEntries(day.entries);
          }
        } else {
          for (var key in medsPerDay.keys) {
            if (schedule[i][2].contains(key)) {
              final day = <String, double>{key: medsPerDay[key]! + 1};
              medsPerDay.addEntries(day.entries);
            }
          }
        }
        medicationNames.add(schedule[i][0]);
      }
    }
    calcBarY();
  }

  // Theme management - using modern color scheme
  int colorMode = 0; // 0 = light, 1 = dark

  void switchColorTheme(bool isDark) {
    if (isDark) {
      colorMode = 1;
    } else {
      colorMode = 0;
    }
    setTheme(isDark);
    notifyListenersSafe();
  }

  // Get current colors based on mode
  AppColors get currentColors {
    return colorMode == 1 ? AppTheme.darkColors : AppTheme.lightColors;
  }

  void setCurrentUrl(url) {
    currentURL = url;
    notifyListenersSafe();
  }

  void deleteList(String listName, List<String> list, index) {
    String docID = list[index];
    FirebaseCloud().deleteDocument(listName, docID);
  }

  void deleteEntireList(int index, String listName) {
    if (listName == "logs") {
      log.removeAt(index);
      FirebaseCloud().deleteCloudList(index, listName);
      deleteList(listName, logIDs, index);
    }

    if (listName == "schedules") {
      schedule.removeAt(index);
      FirebaseCloud().deleteCloudList(index, listName);
      deleteList(listName, scheduleIDs, index);
    }
    notifyListenersSafe();
  }

  Future deleteAccount() async {
    while (log.isNotEmpty) {
      deleteEntireList(0, "logs");
    }

    while (schedule.isNotEmpty) {
      deleteEntireList(0, "schedules");
    }

    FirebaseCloud().deleteDocument("users", await getUID());

    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.clear();
    });

    notifyListenersSafe();
  }
}
