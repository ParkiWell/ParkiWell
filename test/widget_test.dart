import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levio/Main/manage.dart';
import 'package:levio/Main/recovery.dart';
import 'package:levio/main.dart';
import 'package:levio/navbar.dart';
import 'package:levio/routes.dart';
import 'package:levio/screens/splash_screen.dart';
import 'package:levio/singleton.dart';
import 'package:levio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Singleton singleton;

  Future<void> pumpTestApp(
    WidgetTester tester, {
    required Widget home,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light,
        routes: namedRoutes,
        home: home,
      ),
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    singleton = Singleton();
  });

  setUp(() {
    singleton.log.clear();
    singleton.logIDs.clear();
    singleton.schedule.clear();
    singleton.scheduleIDs.clear();
    singleton.name = '[Name]';
    singleton.email = '[Email]';
    singleton.firstTime = true;
    singleton.page = 0;
    singleton.currentURL = '';
    singleton.exerNum = 0;
    singleton.postNum = 0;
  });

  testWidgets('Enhanced splash renders branded UI elements', (tester) async {
    await pumpTestApp(
      tester,
      home: SplashScreen(
        onComplete: () {},
      ),
    );

    expect(find.text('Levio'), findsOneWidget);
    expect(find.text('Preparing your care workspace'), findsOneWidget);
    expect(find.text('Personalized Parkinson\'s care,\norganized every day.'),
        findsOneWidget);

    // Flush the delayed start timer used by splash animation bootstrap.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('App starts on splash for first-time users', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Preparing your care workspace'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
  });

  test('Named routes contain all feature entry points', () {
    expect(
      namedRoutes.keys,
      containsAll(<String>{
        '/editLogScreen',
        '/editScheduleScreen',
        '/logScreen',
        '/scheduleScreen',
        '/exerciseScreen',
        '/exerciseVideoScreen',
        '/speechAudio',
        '/gamesScreen',
        '/speechScreen',
        '/settingsScreen',
      }),
    );
  });

  test('Log sorting keeps log IDs aligned with entries', () {
    singleton.log.addAll(<List<String>>[
      <String>['09:00, 01 January 2024', 'Tremor', 'Mild'],
      <String>['10:00, 05 January 2024', 'Balance', 'Moderate'],
    ]);
    singleton.logIDs.addAll(<String>['id-old', 'id-new']);

    singleton.sortTime(descending: true);

    expect(singleton.log.first[1], equals('Balance'));
    expect(singleton.logIDs.first, equals('id-new'));
    expect(singleton.log.last[1], equals('Tremor'));
    expect(singleton.logIDs.last, equals('id-old'));
  });

  test('Medication aggregation calculates daily totals', () {
    singleton.schedule.addAll(<List<String>>[
      <String>['Levodopa', '100mg', 'Everyday'],
      <String>['Carbidopa', '25mg', 'Every Monday, Wednesday, Friday'],
    ]);

    singleton.calcMeds();

    expect(singleton.medsPerDay['Monday'], equals(2));
    expect(singleton.medsPerDay['Tuesday'], equals(1));
    expect(singleton.medsPerDay['Wednesday'], equals(2));
    expect(singleton.medsPerDay['Friday'], equals(2));
    expect(singleton.medsPerDay['Sunday'], equals(1));
  });

  test('Offline log save writes local state and marks pending sync', () async {
    final saved = await singleton.saveLog(
      '08:30, 12 February 2026',
      'Tremor',
      'Moderate',
    );

    expect(saved, isTrue);
    expect(singleton.log.length, equals(1));
    expect(singleton.log.first[1], equals('Tremor'));
    expect(singleton.lastSyncStatus.toLowerCase(), contains('pending'));
  });

  test('Backup export and import round-trips core data', () async {
    singleton.name = 'Alex';
    singleton.email = 'alex@example.com';
    singleton.log.add(<String>['09:00, 10 February 2026', 'Fatigue', 'Mild']);
    singleton.logIDs.add('log-1');
    singleton.schedule.add(<String>['Levodopa', '100mg', 'Everyday']);
    singleton.scheduleIDs.add('schedule-1');

    final backup = singleton.exportBackupJson();

    singleton.name = '[Name]';
    singleton.email = '[Email]';
    singleton.log.clear();
    singleton.logIDs.clear();
    singleton.schedule.clear();
    singleton.scheduleIDs.clear();

    final imported = await singleton.importBackupJson(backup);

    expect(imported, isTrue);
    expect(singleton.name, equals('Alex'));
    expect(singleton.email, equals('alex@example.com'));
    expect(singleton.log.length, equals(1));
    expect(singleton.schedule.length, equals(1));
  });

  testWidgets('Manage and recovery screens expose core feature cards', (
    tester,
  ) async {
    await pumpTestApp(tester, home: const ManageScreen());
    expect(find.text('Symptom Log'), findsOneWidget);
    expect(find.text('Medications'), findsOneWidget);

    await pumpTestApp(tester, home: const RecoveryScreen());
    expect(find.text('Speech Therapy'), findsOneWidget);
    expect(find.text('Physical Exercises'), findsOneWidget);
  });

  testWidgets('Navbar renders all primary tabs', (tester) async {
    singleton.firstTime = false;
    singleton.name = 'Test User';

    await pumpTestApp(tester, home: const Navbar());

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Manage'), findsWidgets);
    expect(find.text('Recovery'), findsWidgets);
    expect(find.text('Community'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
