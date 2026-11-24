import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:motion_engine/motion_engine.dart';
import 'package:parkiwell/motion_coach/motion_coach_home_screen.dart';
import 'package:parkiwell/motion_coach/motion_coach_session.dart';
import 'package:parkiwell/motion_coach/motion_exercise_catalog.dart';
import 'package:parkiwell/motion_coach/motion_pose_bridge.dart';
import 'package:parkiwell/motion_coach/motion_reference_library.dart';
import 'package:parkiwell/motion_coach/motion_routine_catalog.dart';
import 'package:parkiwell/motion_coach/motion_routine_controller.dart';
import 'package:parkiwell/motion_coach/motion_session_history.dart';

const _exerciseIds = <String>[
  'seated_knee_extension',
  'seated_heel_raise',
  'seated_toe_lift',
  'seated_upper_body_turn',
  'seated_chest_press',
  'standing_back_leg_reach',
  'supported_shallow_knee_bend',
];

const _routineIds = <String>['seated_mobility_v1', 'supported_movement_v1'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MotionReferenceLibrary library = MotionReferenceLibrary();

  for (final String exerciseId in _exerciseIds) {
    test(
      '$exerciseId reaches a scored result through the camera adapter',
      () async {
        final exercise = motionExerciseById(exerciseId);
        final template = await library.templateFor(exerciseId);
        final demo = await library.loadDemonstration(exerciseId);
        expect(demo.frameCount, greaterThan(2));
        expect(demo.pointsXy.length, demo.frameCount * 33 * 2);
        expect(
          template['required_landmarks'],
          exercise.engineSpec.requiredLandmarks,
        );
        final review = template['review']! as Map<String, Object?>;
        expect(review['status'], 'draft');
        expect(review['source'], containsPair('kind', 'analytic'));

        final routine = singleExerciseRoutine(exercise);
        final controller = MotionRoutineController(
          routine: routine,
          library: library,
        );
        addTearDown(controller.dispose);
        final replay = _replays()[exerciseId]! as Map<String, Object?>;
        final neutral = (replay['cycles']! as List).first.first as List;
        int timestampMs = 0;
        for (int index = 0; index < 20; index++) {
          controller.handleSample(_sample(neutral, timestampMs));
          timestampMs += 50;
        }
        expect(controller.isFramingReady, isTrue);
        controller.start();

        final int target = routine.steps.single.targetRepetitions;
        for (int index = 0; index < target; index++) {
          final cycles = replay['cycles']! as List;
          for (final frame in cycles[index % cycles.length] as List) {
            controller.handleSample(_sample(frame as List, timestampMs));
            timestampMs += 50;
          }
        }
        expect(controller.phase, MotionRoutinePhase.complete);
        final record = MotionSessionRecord.fromEvaluation(
          controller.evaluation!,
          completedAt: DateTime.utc(2026, 11, 24),
        );
        expect(record.assessedSteps, 1);
        final step = record.steps.single;
        expect(step.completedRepetitions, target);
        expect(
          step.repetitions.every(
            (rep) => rep.romDeg > 0 && rep.tempoSeconds > 0,
          ),
          isTrue,
        );
        expect(step.evidenceStatements, isNotEmpty);
        if (exercise.engineSpec.laterality == ExerciseLaterality.alternating) {
          expect(step.repetitions.map((rep) => rep.side).toSet(), {
            'left',
            'right',
          });
        }
      },
    );
  }

  test(
    'both new routines advance through their measured exercises and rests',
    () async {
      final seen = <String>{};
      final replays = _replays();
      for (final String assetId in _routineIds) {
        final description = motionRoutineCatalog.singleWhere(
          (item) => item.routineAssetId == assetId,
        );
        final definition = await library.loadRoutine(assetId);
        expect(
          description.requiresStanding,
          definition.steps.any(
            (step) =>
                motionExerciseById(step.exerciseId).posture ==
                MotionExercisePosture.standing,
          ),
        );
        final session = RoutineSession(
          definition,
          engineVersion: 'test',
          templateLoader: library.template,
        );
        final events = <RoutineSessionEvent>[...session.start(0)];
        int timestampMs = 50;
        for (final step in definition.steps) {
          seen.add(step.exerciseId);
          final replay = replays[step.exerciseId]! as Map<String, Object?>;
          final cycles = replay['cycles']! as List;
          final neutral = cycles.first.first as List;
          final start = timestampMs;
          while (session.phase == RoutineSessionPhase.rest ||
              timestampMs <= start + 500) {
            events.addAll(
              session.addFrame(
                poseFrameFromDetection(_sample(neutral, timestampMs).detection),
              ),
            );
            timestampMs += 50;
          }
          for (int index = 0; index < step.targetRepetitions; index++) {
            for (final frame in cycles[index % cycles.length] as List) {
              // Once the engine advances, hold the remainder for the next step.
              if (session.phase != RoutineSessionPhase.active) break;
              events.addAll(
                session.addFrame(
                  poseFrameFromDetection(
                    _sample(frame as List, timestampMs).detection,
                  ),
                ),
              );
              timestampMs += 50;
            }
          }
        }
        expect(
          events.whereType<RoutineStepStarted>(),
          hasLength(definition.steps.length),
        );
        expect(
          events.whereType<RoutineRestStarted>(),
          hasLength(definition.steps.length - 1),
        );
        expect(events.whereType<RoutineSessionCompleted>(), hasLength(1));
        final record = MotionSessionRecord.fromEvaluation(
          session.evaluation!,
          completedAt: DateTime.utc(2026, 11, 24),
        );
        expect(record.assessedSteps, definition.steps.length);
        expect(
          record.completedRepetitions,
          definition.steps.fold<int>(
            0,
            (sum, step) => sum + step.targetRepetitions,
          ),
        );
      }
      expect(seen, _exerciseIds.toSet());
    },
  );

  test('rejects opposite directions and a whole-body turn', () async {
    final replays = _replays();
    for (final MapEntry<String, Object?> entry in replays.entries) {
      final exerciseId = entry.key;
      final replay = entry.value! as Map<String, Object?>;
      final List? rejected = replay['rejected'] as List?;
      if (rejected == null) continue;
      await library.templateFor(exerciseId);

      final coach = LiveExerciseCoach(
        exerciseSpecById(exerciseId),
        library.configFor(exerciseId),
      );
      int timestampMs = 0;
      for (int repeat = 0; repeat < 3; repeat++) {
        for (final frame in rejected) {
          final detection = _sample(frame as List, timestampMs).detection;
          coach.addFrame(poseFrameFromDetection(detection));
          timestampMs += 50;
        }
      }
      expect(coach.completedRepetitions, isEmpty, reason: exerciseId);
    }
  });
}

Map<String, Object?> _replays() =>
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File(
                'test/fixtures/expanded_motion_exercises.v1.json.gz',
              ).readAsBytesSync(),
            ),
          ),
        )
        as Map<String, Object?>;

MotionPoseSample _sample(List frame, int timeMs) {
  final world = List<MotionPoseLandmark>.generate(33, (index) {
    final offset = index * 3;
    return MotionPoseLandmark(
      x: (frame[offset] as num).toDouble(),
      y: (frame[offset + 1] as num).toDouble(),
      z: (frame[offset + 2] as num).toDouble(),
      visibility: 1,
      presence: 1,
    );
  });
  return MotionPoseSample(
    detection: MotionPoseDetection(
      timestampMs: timeMs,
      worldLandmarks: world,
      normalizedLandmarks: world
          .map(
            (point) => MotionPoseLandmark(
              x: 0.5 + point.x * 0.55,
              y: 0.46 + point.y * 0.55,
              z: point.z,
              visibility: 1,
              presence: 1,
            ),
          )
          .toList(),
      inferenceMs: 10,
    ),
    frameWidth: 720,
    frameHeight: 1280,
  );
}
