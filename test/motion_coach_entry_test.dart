import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkiwell/Main/home.dart';
import 'package:parkiwell/Main/recovery.dart';
import 'package:parkiwell/motion_coach/motion_coach_home_screen.dart';
import 'package:parkiwell/motion_coach/motion_routine_results_screen.dart';
import 'package:parkiwell/motion_coach/motion_session_history.dart';
import 'package:parkiwell/singleton.dart';
import 'package:parkiwell/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Singleton singleton;

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    singleton = Singleton();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    singleton.recoverySessions.clear();
  });

  Future<void> showApp(
    WidgetTester tester,
    Widget screen, {
    double textScale = 1,
    ThemeMode mode = ThemeMode.light,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: mode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: screen),
    ),
  );

  for (final (name, screen) in [
    ('Home', const HomeScreen()),
    ('Recovery', const RecoveryScreen()),
  ]) {
    testWidgets('$name opens Motion coach directly', (tester) async {
      await showApp(tester, screen);
      await tester.tap(find.text('Motion coach'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MotionCoachHomeScreen), findsOneWidget);
    });
  }

  testWidgets('Home keeps Motion coach reachable with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await showApp(tester, const HomeScreen(), textScale: 2);
    expect(find.text('Motion coach').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Recovery keeps Motion coach reachable with larger text in dark mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await showApp(
        tester,
        const RecoveryScreen(),
        textScale: 2,
        mode: ThemeMode.dark,
      );
      expect(find.text('Motion coach').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Log a completed session'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Log a completed session').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home and Recovery hide the camera entry on desktop',
    (tester) async {
      await showApp(tester, const HomeScreen());
      expect(find.text('Motion coach'), findsNothing);
      await showApp(tester, const RecoveryScreen());
      expect(find.text('Motion coach'), findsNothing);
    },
    variant: const TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets('Recovery history opens the matching saved motion result', (
    tester,
  ) async {
    final completedAt = DateTime.now();
    final record = MotionSessionRecord(
      id: '92e102ec-8151-442d-ac2c-3ab800e3592a',
      completedAt: completedAt,
      routineId: 'seated_foundation',
      routineName: 'Seated foundation',
      engineVersion: '0.3.0',
      overallScore: 81,
      assessedSteps: 1,
      totalSteps: 1,
      strengths: const [],
      focusAreas: const [],
      steps: const [],
    );
    await MotionSessionHistory.shared.add(record);
    singleton.recoverySessions.addAll([
      {
        'id': record.id,
        'type': Singleton.recoveryTypePhysical,
        'video_id': '${Singleton.motionSessionIdPrefix}seated_foundation',
        'title': 'Motion coach: Seated foundation',
        'completed_at': completedAt.toIso8601String(),
      },
      {
        'id': 'unlinked-motion-row',
        'type': Singleton.recoveryTypePhysical,
        'video_id': '${Singleton.motionSessionIdPrefix}full_body',
        'title': 'Motion coach: Whole-body movement',
        'completed_at': completedAt.toIso8601String(),
      },
    ]);
    await showApp(tester, const RecoveryScreen());
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    final resultAction = find.byTooltip('View result for Seated foundation');
    expect(resultAction, findsOneWidget);
    expect(find.text('Whole-body movement'), findsOneWidget);
    expect(find.byTooltip('View result for Whole-body movement'), findsNothing);

    await tester.ensureVisible(resultAction);
    await tester.tap(resultAction);
    await tester.pumpAndSettle();

    final result = tester.widget<MotionRoutineResultsScreen>(
      find.byType(MotionRoutineResultsScreen),
    );
    expect(result.record, same(record));
  });
}
