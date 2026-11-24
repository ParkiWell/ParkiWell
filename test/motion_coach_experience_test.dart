import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_engine/motion_engine.dart';
import 'package:parkiwell/motion_coach/motion_coach_home_screen.dart';
import 'package:parkiwell/motion_coach/motion_demonstration_view.dart';
import 'package:parkiwell/motion_coach/motion_exercise_catalog.dart';
import 'package:parkiwell/motion_coach/motion_reference_library.dart';
import 'package:parkiwell/motion_coach/motion_routine_catalog.dart';
import 'package:parkiwell/motion_coach/motion_routine_results_screen.dart';
import 'package:parkiwell/motion_coach/motion_session_history.dart';
import 'package:parkiwell/motion_coach/motion_session_intro_sheet.dart';
import 'package:parkiwell/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('only shows a demonstration for the selected movement', (
    tester,
  ) async {
    final library = _PreviewLibrary();
    await _show(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(
              showMotionSessionIntro(
                context,
                description: seatedFoundationRoutine,
                routine: _PreviewLibrary.routine,
                library: library,
              ),
            ),
            child: const Text('Preview'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Preview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    library.finishLoading(seatedAlternatingMarchExercise.exerciseId);
    await tester.pump();

    Finder demo() => find.byType(MotionDemonstrationView);
    expect(demo(), findsOneWidget);
    expect(
      tester.widget<MotionDemonstrationView>(demo()).loop.exerciseId,
      seatedAlternatingMarchExercise.exerciseId,
    );

    await tester.tap(find.byTooltip('Next exercise preview'));
    await tester.pump();
    expect(find.text('Exercise 2 of 2'), findsOneWidget);
    expect(demo(), findsNothing);

    await tester.tap(find.byTooltip('Previous exercise preview'));
    await tester.pump();
    library.finishLoading(seatedTrunkLeanExercise.exerciseId);
    await tester.pump();
    expect(find.text('Exercise 1 of 2'), findsOneWidget);
    expect(
      tester.widget<MotionDemonstrationView>(demo()).loop.exerciseId,
      seatedAlternatingMarchExercise.exerciseId,
    );
  });

  testWidgets('a compact, large-text coach gives access to empty history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 670));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    try {
      final library = _PreviewLibrary()
        ..finishLoading(seatedAlternatingMarchExercise.exerciseId);
      await _show(
        tester,
        MotionCoachHomeScreen(
          library: library,
          history: MotionSessionHistory(),
        ),
        scale: 2,
        dark: true,
      );
      await tester.pumpAndSettle();

      final progress = find.text('Your progress');
      await tester.ensureVisible(progress);
      await tester.tap(progress);
      await tester.pumpAndSettle();

      expect(find.text('No sessions yet'), findsOneWidget);
      await tester.tap(find.text('Back to Motion coach'));
      await tester.pumpAndSettle();

      final preview = find.text('Preview routine');
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(find.text('Open camera and begin').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shows an early finish on a large-text result', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 670));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _show(
      tester,
      MotionRoutineResultsScreen(
        title: 'Seated foundation',
        record: MotionSessionRecord(
          id: '92e102ec-8151-442d-ac2c-3ab800e3592a',
          completedAt: DateTime.now(),
          routineId: 'seated_foundation_v1',
          routineName: 'Seated foundation',
          engineVersion: '0.3.0',
          overallScore: 81,
          assessedSteps: 1,
          totalSteps: 4,
          endedEarly: true,
          strengths: const [],
          focusAreas: const [],
          steps: const [],
        ),
      ),
      scale: 2,
    );
    expect(find.textContaining('Ended early'), findsOneWidget);
    expect(find.text('Done').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  double scale = 1,
  bool dark = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: true, textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: screen,
  ),
);

class _PreviewLibrary extends MotionReferenceLibrary {
  static final routine = RoutineDefinition(
    routineId: seatedFoundationRoutine.routineAssetId,
    routineVersion: 1,
    displayName: seatedFoundationRoutine.title,
    steps: [
      for (final exercise in [
        seatedAlternatingMarchExercise,
        seatedTrunkLeanExercise,
      ])
        RoutineStepDefinition(
          exerciseId: exercise.exerciseId,
          targetRepetitions: 3,
          maximumDurationS: 90,
          restDurationS: 0,
        ),
    ],
  );

  final _loads = <String, Completer<MotionDemonstrationLoop>>{};

  @override
  Future<RoutineDefinition> loadRoutine(String routineId) async => routine;

  @override
  Future<MotionDemonstrationLoop> loadDemonstration(String exerciseId) =>
      _loads.putIfAbsent(exerciseId, Completer.new).future;

  void finishLoading(String exerciseId) {
    _loads
        .putIfAbsent(exerciseId, Completer.new)
        .complete(
          MotionDemonstrationLoop(
            exerciseId: exerciseId,
            frameCount: 1,
            frameIntervalMs: 100,
            pointsXy: List.generate(66, (index) => (index % 7) / 7),
          ),
        );
  }
}
