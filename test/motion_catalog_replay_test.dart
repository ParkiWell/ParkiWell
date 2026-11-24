import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:motion_engine/motion_engine.dart';
import 'package:parkiwell/motion_coach/motion_coach_session.dart';
import 'package:parkiwell/motion_coach/motion_pose_bridge.dart';
import 'package:parkiwell/motion_coach/motion_reference_library.dart';
import 'package:parkiwell/motion_coach/motion_routine_controller.dart';
import 'package:parkiwell/motion_coach/motion_session_history.dart';

const Map<String, int> _originalExercises = <String, int>{
  'seated_bilateral_lateral_arm_raise': 3,
  'seated_bilateral_forward_reach': 3,
  'seated_bilateral_elbow_flexion': 3,
  'seated_alternating_march': 4,
  'sit_to_stand': 3,
  'seated_lateral_trunk_lean': 4,
  'standing_hip_flexion': 4,
  'standing_knee_flexion': 4,
  'standing_side_leg_raise': 4,
  'standing_heel_raise': 4,
};

const _niaExpected = <String, ({int reps, double coverage, bool assessed})>{
  'seated_bilateral_lateral_arm_raise': (
    reps: 3,
    coverage: 0.71,
    assessed: false,
  ),
  'seated_bilateral_forward_reach': (reps: 4, coverage: 0.99, assessed: true),
  'seated_bilateral_elbow_flexion': (reps: 6, coverage: 0.99, assessed: true),
  'sit_to_stand': (reps: 1, coverage: 1, assessed: true),
  'standing_hip_flexion': (reps: 2, coverage: 0.62, assessed: false),
  'standing_knee_flexion': (reps: 1, coverage: 0.56, assessed: false),
  'standing_side_leg_raise': (reps: 3, coverage: 0.68, assessed: false),
  'standing_heel_raise': (reps: 0, coverage: 0.18, assessed: false),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MotionReferenceLibrary library = MotionReferenceLibrary();
  final Map<String, Object?> document =
      jsonDecode(
            utf8.decode(
              gzip.decode(
                File(
                  'test/fixtures/motion-replays.v1.json.gz',
                ).readAsBytesSync(),
              ),
            ),
          )
          as Map<String, Object?>;
  final exercises = document['exercises']! as Map<String, Object?>;

  _PoseReplay load(String exerciseId, String source) {
    final variants = exercises[exerciseId]! as Map<String, Object?>;
    return _PoseReplay(variants[source]! as Map<String, Object?>);
  }

  for (final MapEntry<String, int> exercise in _originalExercises.entries) {
    test(
      '${exercise.key} counts all ${exercise.value} analytic movements',
      () async {
        final _PoseReplay replay = load(exercise.key, 'synthetic');
        final MotionRoutineController controller = await _controller(
          library,
          exercise.key,
          exercise.value + 1,
        );
        addTearDown(controller.dispose);
        final int startIndex = _start(controller, replay);
        expect(startIndex, greaterThanOrEqualTo(0));
        _feed(controller, replay, startIndex + 1);
        expect(controller.repSerial, exercise.value);
        expect(controller.finishEarly(), isTrue);
        final MotionSessionRecord record = _record(controller);
        expect(record.overallScore, inInclusiveRange(1, 100));
        _verifyEvidence(record.steps.single, exercise.value);
        if (exerciseSpecById(exercise.key).laterality ==
            ExerciseLaterality.alternating) {
          expect(record.steps.single.repetitions.map((rep) => rep.side), [
            'left',
            'right',
            'left',
            'right',
          ]);
        }
      },
    );
  }

  for (final String exerciseId in _niaExpected.keys) {
    test('$exerciseId NIA replay respects tracking coverage', () async {
      final _PoseReplay replay = load(exerciseId, 'nia');
      final MotionRoutineController controller = await _controller(
        library,
        exerciseId,
        20,
      );
      addTearDown(controller.dispose);
      final int startIndex = _start(controller, replay);
      expect(startIndex, greaterThanOrEqualTo(0));
      _feed(controller, replay, startIndex + 1);
      controller.skipCurrentStep();
      final MotionSessionRecord record = _record(controller);
      final MotionSessionStep step = record.steps.single;
      final expected = _niaExpected[exerciseId]!;
      expect(step.completedRepetitions, expected.reps);
      expect(step.coverage, closeTo(expected.coverage, 0.03));
      expect(step.assessed, expected.assessed);
      if (expected.assessed) {
        _verifyEvidence(step, expected.reps);
      } else {
        expect(step.reasonCodes, contains(reasonLowCoverage));
        expect(step.overallScore, isNull);
        expect(record.overallScore, isNull);
      }
    });
  }

  for (final String assetId in <String>[
    'seated_foundation_v1',
    'full_body_v1',
  ]) {
    test(
      '$assetId follows the bundled sequence through rest, cues, and summary',
      () async {
        final RoutineDefinition routine = await library.loadRoutine(assetId);
        final MotionRoutineController controller = MotionRoutineController(
          routine: routine,
          library: library,
        );
        addTearDown(controller.dispose);
        int timestamp = 0;
        for (int stepIndex = 0; stepIndex < routine.steps.length; stepIndex++) {
          final _PoseReplay replay = load(
            routine.steps[stepIndex].exerciseId,
            'synthetic',
          );
          int firstMovementFrame = 1;
          if (stepIndex == 0) {
            final int startIndex = _start(controller, replay);
            expect(startIndex, greaterThanOrEqualTo(0));
            timestamp = replay.timestampAt(startIndex);
            firstMovementFrame = startIndex + 1;
          } else {
            expect(controller.phase, MotionRoutinePhase.rest);
            expect(
              controller.upcomingExercise?.exerciseId,
              routine.steps[stepIndex].exerciseId,
            );
            for (
              int tick = 0;
              tick < 500 && controller.phase == MotionRoutinePhase.rest;
              tick++
            ) {
              timestamp += 33;
              controller.handleSample(replay.sample(0, timestampMs: timestamp));
            }
          }
          expect(controller.phase, MotionRoutinePhase.active);
          expect(controller.stepIndex, stepIndex);
          for (
            int index = firstMovementFrame;
            index < replay.frames.length &&
                controller.phase == MotionRoutinePhase.active;
            index++
          ) {
            timestamp +=
                replay.timestampAt(index) - replay.timestampAt(index - 1);
            controller.handleSample(
              replay.sample(index, timestampMs: timestamp),
            );
          }
        }
        expect(controller.phase, MotionRoutinePhase.complete);
        expect(controller.cueSerial, greaterThan(0));
        final MotionSessionRecord record = _record(controller);
        expect(record.assessedSteps, routine.steps.length);
        expect(record.overallScore, inInclusiveRange(1, 100));
        for (int index = 0; index < routine.steps.length; index++) {
          expect(
            record.steps[index].exerciseId,
            routine.steps[index].exerciseId,
          );
          _verifyEvidence(
            record.steps[index],
            routine.steps[index].targetRepetitions,
          );
        }
      },
    );
  }

  test('a second detected person suppresses pose evidence and cues', () async {
    final String exerciseId = _originalExercises.keys.first;
    final _PoseReplay replay = load(exerciseId, 'synthetic');
    final MotionRoutineController controller = await _controller(
      library,
      exerciseId,
      3,
    );
    addTearDown(controller.dispose);
    final int startIndex = _start(controller, replay);
    expect(startIndex, greaterThanOrEqualTo(0));
    _feed(controller, replay, startIndex + 1, poseCount: 2);
    expect(controller.framingStatus, MotionFramingStatus.multiplePeople);
    expect(controller.repSerial, 0);
    expect(controller.cueSerial, 0);
    controller.skipCurrentStep();
    final MotionSessionStep step = _record(controller).steps.single;
    expect(step.assessed, isFalse);
    expect(step.coverage, 0);
    expect(step.repetitions, isEmpty);
    expect(step.reasonCodes, contains(reasonLowCoverage));
  });

  const wrongPlanePairs = <(String, String)>[
    ('seated_bilateral_forward_reach', 'seated_bilateral_lateral_arm_raise'),
    ('seated_bilateral_lateral_arm_raise', 'seated_bilateral_forward_reach'),
    ('standing_side_leg_raise', 'standing_hip_flexion'),
    ('standing_hip_flexion', 'standing_side_leg_raise'),
  ];
  for (final (observedId, coachedId) in wrongPlanePairs) {
    test('$observedId does not count as $coachedId', () async {
      final _PoseReplay replay = load(observedId, 'synthetic');
      final MotionRoutineController controller = await _controller(
        library,
        coachedId,
        5,
      );
      addTearDown(controller.dispose);
      final int startIndex = _start(controller, replay);
      expect(startIndex, greaterThanOrEqualTo(0));
      _feed(controller, replay, startIndex + 1);
      expect(controller.repSerial, 0);
    });
  }

  test(
    'out-of-frame wrists cannot earn reps despite high landmark confidence',
    () async {
      final String exerciseId = _originalExercises.keys.first;
      final _PoseReplay replay = load(exerciseId, 'synthetic');
      final MotionRoutineController controller = await _controller(
        library,
        exerciseId,
        3,
      );
      addTearDown(controller.dispose);
      final int startIndex = _start(controller, replay);
      expect(startIndex, greaterThanOrEqualTo(0));
      for (int index = startIndex + 1; index < replay.frames.length; index++) {
        controller.handleSample(replay.sample(index, clippedWrists: true));
      }
      expect(controller.framingStatus, MotionFramingStatus.showMoreBody);
      expect(controller.repSerial, 0);
      expect(controller.cueSerial, 0);
      controller.skipCurrentStep();
      final MotionSessionStep step = _record(controller).steps.single;
      expect(step.overallScore, isNull);
      expect(step.coverage, 0);
    },
  );
}

MotionSessionRecord _record(MotionRoutineController controller) =>
    MotionSessionRecord.fromEvaluation(
      controller.evaluation!,
      completedAt: DateTime.utc(2026),
    );

Future<MotionRoutineController> _controller(
  MotionReferenceLibrary library,
  String exerciseId,
  int repetitions,
) async {
  await library.templateFor(exerciseId);
  return MotionRoutineController(
    routine: RoutineDefinition(
      routineId: 'catalog_replay',
      routineVersion: 1,
      displayName: 'Catalog replay',
      steps: <RoutineStepDefinition>[
        RoutineStepDefinition(
          exerciseId: exerciseId,
          targetRepetitions: repetitions,
          maximumDurationS: 90,
          restDurationS: 0,
        ),
      ],
    ),
    library: library,
  );
}

int _start(MotionRoutineController controller, _PoseReplay replay) {
  for (int index = 0; index < replay.frames.length; index++) {
    controller.handleSample(replay.sample(index));
    if (controller.isFramingReady) {
      controller.start();
      return index;
    }
  }
  return -1;
}

void _feed(
  MotionRoutineController controller,
  _PoseReplay replay,
  int start, {
  int poseCount = 1,
}) {
  for (
    int index = start;
    index < replay.frames.length &&
        controller.phase != MotionRoutinePhase.complete;
    index++
  ) {
    controller.handleSample(replay.sample(index, poseCount: poseCount));
  }
}

void _verifyEvidence(MotionSessionStep step, int expectedRepetitions) {
  expect(step.assessed, isTrue);
  expect(step.completedRepetitions, expectedRepetitions);
  expect(step.repetitions, hasLength(expectedRepetitions));
  expect(step.coverage, greaterThanOrEqualTo(0.8));
  expect(step.evidenceStatements, isNotEmpty);
  for (final MotionSessionRep rep in step.repetitions) {
    expect(rep.romDeg, greaterThan(0));
    expect(rep.tempoSeconds, greaterThan(0));
    expect(rep.overallScore, inInclusiveRange(1, 100));
  }
}

/// Captures contain world landmarks and source visibility. The archived pose
/// format has no image channel, so project those landmarks into a portrait
/// viewport to exercise the app's framing and confidence path as well.
class _PoseReplay {
  _PoseReplay(Map<String, Object?> json)
    : frames = (json['frames']! as List<Object?>).cast<List<Object?>>() {
    double left = double.infinity;
    double right = double.negativeInfinity;
    double top = double.infinity;
    double bottom = double.negativeInfinity;
    for (final List<Object?> frame in frames) {
      final points = (frame[1] as List<Object?>?)?.cast<int>();
      if (points == null) continue;
      for (int offset = 0; offset < points.length; offset += 4) {
        if (points[offset + 3] < 600) continue;
        final double x = points[offset] / 10000;
        final double y = points[offset + 1] / 10000;
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
    _centerX = (left + right) / 2;
    _centerY = (top + bottom) / 2;
    _scaleY = 0.86 / math.max((right - left) * 4 / 3, bottom - top);
  }

  final List<List<Object?>> frames;
  late final double _centerX;
  late final double _centerY;
  late final double _scaleY;

  int timestampAt(int index) => frames[index][0]! as int;

  MotionPoseSample sample(
    int index, {
    int poseCount = 1,
    int? timestampMs,
    bool clippedWrists = false,
  }) {
    final List<Object?> frame = frames[index];
    final int time = timestampMs ?? timestampAt(index);
    final points = (frame[1] as List<Object?>?)?.cast<int>();
    final MotionPoseDetection detection;
    if (points == null) {
      detection = MotionPoseDetection.empty(timestampMs: time);
    } else {
      final world = <Map<String, double>>[];
      final normalized = <Map<String, double>>[];
      for (int offset = 0; offset < points.length; offset += 4) {
        final double x = points[offset] / 10000;
        final double y = points[offset + 1] / 10000;
        final double z = points[offset + 2] / 10000;
        final double confidence = points[offset + 3] / 1000;
        world.add(_point(x, y, z, confidence));
        final bool clipped =
            clippedWrists && (offset == 15 * 4 || offset == 16 * 4);
        normalized.add(
          _point(
            clipped ? 1.15 : 0.5 + (x - _centerX) * _scaleY * 4 / 3,
            0.5 + (y - _centerY) * _scaleY,
            0,
            confidence,
          ),
        );
      }
      detection = MotionPoseDetection.fromMap(<String, Object?>{
        'timestampMs': time,
        'poseCount': poseCount,
        'landmarks': normalized,
        'worldLandmarks': world,
      });
    }
    return MotionPoseSample(
      detection: detection,
      frameWidth: 480,
      frameHeight: 640,
    );
  }
}

Map<String, double> _point(double x, double y, double z, double confidence) =>
    <String, double>{
      'x': x,
      'y': y,
      'z': z,
      'visibility': confidence,
      'presence': confidence,
    };
