import 'dart:math' as math;

import 'package:motion_engine/motion_engine.dart';
import 'package:test/test.dart';

const String _armRaise = 'seated_bilateral_lateral_arm_raise';
const String _march = 'seated_alternating_march';

void main() {
  test('distinguishes quick repetitions from slower completed movements', () {
    final quick = _FeatureReplay(_armRaise).cycle(65, 65, intervalMs: 40);
    final slow = _FeatureReplay(_armRaise).cycle(65, 65, intervalMs: 200);

    expect(quick.cue?.kind.code, 'slower_pace');
    expect(slow.cue?.kind.code, 'tempo');
    expect(quick.cue?.text, isNot(slow.cue?.text));
    expect(quick.repetition.score.tempoScore, lessThan(correctionThreshold));
    expect(slow.repetition.score.tempoScore, lessThan(correctionThreshold));
  });

  test('offers a range-balancing cue on a clearly unequal bilateral rep', () {
    final cue = _FeatureReplay(_armRaise).cycle(100, 32, intervalMs: 80).cue;

    expect(cue?.kind.code, 'symmetry');
    expect(cue?.isCorrective, isTrue);
  });

  test('prompts a switch after two confident same-side reps', () {
    final replay = _FeatureReplay(_march);
    final first = replay.cycle(65, 0, intervalMs: 80);
    final second = replay.cycle(65, 0, intervalMs: 80);

    expect(first.repetition.side, 'left');
    expect(first.cue?.kind.code, isNot('alternation'));
    expect(second.repetition.side, 'left');
    expect(second.cue?.kind.code, 'alternation');

    final third = replay.cycle(0, 65, intervalMs: 80);
    expect(third.repetition.side, 'right');
    expect(third.cue?.kind.code, isNot('alternation'));

    final ambiguous = replay.cycle(65, 62, intervalMs: 80);
    final nextLeft = replay.cycle(65, 0, intervalMs: 80);
    expect(ambiguous.repetition.side, 'unknown');
    expect(ambiguous.cue?.kind.code, isNot('alternation'));
    expect(nextLeft.cue?.kind.code, isNot('alternation'));
  });

  test('a pause at the peak produces one timely cue before the rep ends', () {
    final replay = _FeatureReplay(_armRaise);
    _raiseInSteps(replay.add);
    final List<LiveExerciseCue> cues = [];
    for (int i = 0; i < 68; i++) {
      replay.add(65, 65);
      if (replay.coach.inProgressCue case final LiveExerciseCue cue) {
        cues.add(cue);
      }
    }

    expect(cues.map((cue) => cue.kind.code), ['return_to_start']);
    expect(replay.coach.completedRepetitions, isEmpty);
    _lowerInSteps(replay.add);
    expect(replay.coach.completedRepetitions, hasLength(1));
  });

  test('a tracking gap cannot be used as evidence of a stationary hold', () {
    final replay = _FeatureReplay(_armRaise);
    _raiseInSteps(replay.add);
    replay.add(65, 65);
    replay.timestampMs += 5000;
    replay.add(65, 65);
    expect(replay.coach.inProgressCue, isNull);

    replay.coach.addFrame(
      PoseFrame(timestampMs: replay.timestampMs, landmarks: null),
    );
    replay.timestampMs += 80;
    for (int i = 0; i < 45; i++) {
      replay.add(65, 65);
      expect(replay.coach.inProgressCue, isNull);
    }
    expect(replay.coach.completedRepetitions, isEmpty);
  });

  test('the session emits and records a cue before it scores a movement', () {
    final session = RoutineSession(
      RoutineDefinition(
        routineId: 'cue_replay',
        routineVersion: 1,
        displayName: 'Replay',
        steps: <RoutineStepDefinition>[
          RoutineStepDefinition(
            exerciseId: _armRaise,
            targetRepetitions: 1,
            maximumDurationS: 40,
            restDurationS: 0,
          ),
        ],
      ),
      engineVersion: 'test',
      templateLoader: (_) => <String, Object?>{
        'template_version': 1,
        'primary_signal': 'arm_elevation_mean',
        'rep': {
          'rom_deg': {
            'arm_elevation_mean': {'median': 65},
          },
          'tempo_s': {'median': 4},
        },
        'reference_series': {
          'features': {
            'arm_elevation_mean': [0, 10, 30, 65, 30, 10, 0],
          },
          'sampling_hz': 1,
        },
        'confidence_policy': {
          'visibility_threshold': 0.5,
          'minimum_session_coverage': 0.8,
        },
      },
    );
    session.start(0);
    int timestampMs = 0;
    final List<RoutineSessionEvent> events = [];
    void add(double left, double right) {
      events.addAll(session.addFrame(_armFrame(left, right, timestampMs)));
      timestampMs += 80;
    }

    _raiseInSteps(add);
    for (int i = 0; i < 60; i++) {
      add(65, 65);
    }
    final cue = events.whereType<RoutineCueIssued>().single;
    expect(cue.cue.kind.code, 'return_to_start');
    expect(cue.stepIndex, 0);
    expect(cue.timestampMs, greaterThan(0));
    expect(events.whereType<RoutineRepetitionScored>(), isEmpty);

    _lowerInSteps(add);
    final result = events.whereType<RoutineStepCompleted>().single.result;
    expect(result['completed_repetitions'], 1);
    expect(result['coverage'], 1);
    expect(result['cues'], [
      equals({'code': 'return_to_start', 'count': 1})
    ]);
  });
}

class _FeatureReplay {
  _FeatureReplay(String exerciseId)
      : coach = LiveExerciseCoach(
          exerciseSpecById(exerciseId),
          const LiveExerciseCoachConfig(
            referenceRomDeg: 65,
            referenceTempoS: 3,
            globalCueCooldownMs: 0,
            sameCueCooldownMs: 0,
            minimumRepsBetweenCorrections: 2,
          ),
        );

  final LiveExerciseCoach coach;
  int timestampMs = 0;

  LiveExerciseDecision? add(double left, double right, {int intervalMs = 80}) {
    final spec = coach.spec;
    final primary = spec.laterality == ExerciseLaterality.alternating
        ? math.max(left, right)
        : (left + right) / 2;
    final result = coach.addFeatures({
      spec.primarySignal: primary,
      spec.sideFeatures![0]: left,
      spec.sideFeatures![1]: right,
    }, timestampMs);
    timestampMs += intervalMs;
    return result;
  }

  LiveExerciseDecision cycle(double left, double right,
      {required int intervalMs}) {
    final List<LiveExerciseDecision> decisions = [];
    for (int i = 0; i < 58; i++) {
      final double fraction =
          i <= 44 ? (1 - math.cos(i * math.pi / 22)) / 2 : 0;
      final decision =
          add(left * fraction, right * fraction, intervalMs: intervalMs);
      if (decision != null) decisions.add(decision);
    }
    return decisions.single;
  }
}

void _raiseInSteps(void Function(double, double) add) {
  for (int i = 0; i <= 22; i++) {
    final movement = (1 - math.cos(i * math.pi / 22)) / 2 * 65;
    add(movement, movement);
  }
}

void _lowerInSteps(void Function(double, double) add) {
  for (int i = 1; i < 38; i++) {
    final movement = i <= 22 ? (1 + math.cos(i * math.pi / 22)) / 2 * 65 : 0.0;
    add(movement, movement);
  }
}

PoseFrame _armFrame(double leftDeg, double rightDeg, int timestampMs) {
  final points = List<PoseLandmark>.filled(
    33,
    const PoseLandmark(position: null, visibility: 0),
  );
  void landmark(String name, Vector3 position) {
    points[landmarkIndex[name]!] =
        PoseLandmark(position: position, visibility: 1);
  }

  const leftShoulder = Vector3(-0.2, -0.5, 0);
  const rightShoulder = Vector3(0.2, -0.5, 0);
  final left = leftDeg * math.pi / 180;
  final right = rightDeg * math.pi / 180;
  landmark('left_hip', const Vector3(-0.2, 0, 0));
  landmark('right_hip', const Vector3(0.2, 0, 0));
  landmark('left_shoulder', leftShoulder);
  landmark('right_shoulder', rightShoulder);
  landmark(
      'left_wrist', leftShoulder + Vector3(-math.sin(left), math.cos(left), 0));
  landmark('right_wrist',
      rightShoulder + Vector3(math.sin(right), math.cos(right), 0));
  return PoseFrame(timestampMs: timestampMs, landmarks: points);
}
