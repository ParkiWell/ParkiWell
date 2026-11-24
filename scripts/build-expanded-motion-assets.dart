// Run from the app root with: dart run scripts/build-expanded-motion-assets.dart
// The guide, reference measurements, and test frames use the same analytic
// landmarks. This models how the measurements work on known poses.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:motion_engine/motion_engine.dart';

const intervalMs = 50;
const cycleFrames = 96;
const newExerciseIds = [
  'seated_knee_extension',
  'seated_heel_raise',
  'seated_toe_lift',
  'seated_upper_body_turn',
  'seated_chest_press',
  'standing_back_leg_reach',
  'supported_shallow_knee_bend',
];

List<Vector3> pose(String id, double amount, int side, {bool reverse = false}) {
  final bool seated = id.startsWith('seated_');
  final points = List<Vector3>.filled(33, const Vector3(0, -0.69, 0));
  void put(String name, Vector3 point) => points[landmarkIndex[name]!] = point;

  for (final int index in [-1, 1]) {
    final name = index < 0 ? 'left' : 'right';
    final double x = index * 0.17;
    Vector3 hip = Vector3(x, 0, 0);
    Vector3 shoulder = Vector3(index * 0.22, -0.50, 0);
    Vector3 elbow = Vector3(index * 0.29, -0.25, -0.04);
    Vector3 wrist = Vector3(index * 0.27, -0.02, -0.11);
    Vector3 knee = seated ? Vector3(x, 0.08, -0.40) : Vector3(x, 0.42, 0);
    Vector3 ankle = seated ? Vector3(x, 0.48, -0.40) : Vector3(x, 0.84, 0);
    double footAngle = 0;

    if (id == 'seated_knee_extension' && side == index) {
      final double angle = 1.35 * amount;
      ankle = Vector3(
        x,
        knee.y + 0.40 * math.cos(angle),
        knee.z - 0.40 * math.sin(angle),
      );
    }
    if (id == 'seated_heel_raise' || id == 'seated_toe_lift') {
      final bool raisingHeels = (id == 'seated_heel_raise') != reverse;
      footAngle = 0.47 * amount * (raisingHeels ? 1 : -1);
      if (raisingHeels) {
        ankle = Vector3(x, ankle.y - 0.14 * math.sin(footAngle), ankle.z);
      }
    }
    if (id == 'seated_upper_body_turn') {
      final double angle = side * 0.62 * amount;
      shoulder = yaw(shoulder, angle);
      elbow = yaw(elbow, angle);
      wrist = yaw(wrist, angle);
      if (reverse) hip = yaw(hip, angle);
      put('nose', yaw(const Vector3(0, -0.72, -0.11), angle));
    }
    if (id == 'seated_chest_press') {
      elbow = Vector3(
        index * (0.31 - 0.09 * amount),
        -0.34 - 0.10 * amount,
        -0.12 - 0.16 * amount,
      );
      wrist = Vector3(
        index * (0.26 - 0.04 * amount),
        -0.50 + 0.015 * amount,
        -0.19 - 0.37 * amount,
      );
    }
    if (id == 'standing_back_leg_reach' && side == index) {
      final double angle = 0.43 * amount * (reverse ? -1 : 1);
      knee = Vector3(x, 0.42 * math.cos(angle), 0.42 * math.sin(angle));
      ankle = Vector3(x, 2 * knee.y, 2 * knee.z);
    }
    if (id == 'supported_shallow_knee_bend') {
      hip = Vector3(x, 0.09 * amount, 0.08 * amount);
      knee = Vector3(x, 0.45, -0.17 * amount);
      shoulder = Vector3(shoulder.x, shoulder.y + hip.y, 0.015 * amount);
      elbow = Vector3(elbow.x, elbow.y + hip.y, elbow.z);
    }

    put('${name}_hip', hip);
    put('${name}_shoulder', shoulder);
    put('${name}_elbow', elbow);
    put('${name}_wrist', wrist);
    put('${name}_knee', knee);
    put('${name}_ankle', ankle);
    points[index < 0 ? 29 : 30] =
        ankle +
        Vector3(0, -0.06 * math.sin(footAngle), 0.06 * math.cos(footAngle));
    put(
      '${name}_foot_index',
      ankle +
          Vector3(0, 0.14 * math.sin(footAngle), -0.14 * math.cos(footAngle)),
    );
  }
  return points;
}

Vector3 yaw(Vector3 point, double angle) => Vector3(
  point.x * math.cos(angle) + point.z * math.sin(angle),
  point.y,
  -point.x * math.sin(angle) + point.z * math.cos(angle),
);

List<List<Vector3>> cycle(String id, int side, {bool reverse = false}) => [
  for (int frame = 0; frame < cycleFrames; frame++)
    pose(
      id,
      frame < 80 ? (1 - math.cos(frame * math.pi / 40)) / 2 : 0,
      side,
      reverse: reverse,
    ),
];

Object asFrames(List<List<Vector3>> poses) => [
  for (final points in poses)
    [
      for (final point in points) ...[
        rounded(point.x),
        rounded(point.y),
        rounded(point.z),
      ],
    ],
];

double rounded(double value) => double.parse(value.toStringAsFixed(5));

void jsonFile(String path, Object value) =>
    File(path).writeAsStringSync('${jsonEncode(value)}\n');

Map<String, Object> sameQuantiles(double value) => {
  'median': value,
  'p10': value,
  'p90': value,
};

void main() {
  final replays = <String, Object>{};
  for (final id in newExerciseIds) {
    final ExerciseSpec spec = exerciseSpecById(id);
    final left = cycle(id, -1);
    final right = cycle(id, 1);
    final values = [
      for (final points in left.take(80))
        computeFrameFeatures(
          points
              .map((point) => PoseLandmark(position: point, visibility: 1))
              .toList(),
          spec,
        ),
    ];
    final reference = {
      for (final feature in spec.features.keys)
        feature: values.map((row) => rounded(row[feature]!)).toList(),
    };
    final signal = reference[spec.primarySignal]!;
    final rom = signal.reduce(math.max) - signal.reduce(math.min);
    if (rom <= 0) throw StateError('No reference motion for $id');
    jsonFile('assets/motion/templates/$id.template.v1.json', {
      'schema_version': 'exercise-template.v1',
      'template_version': 1,
      'exercise_id': id,
      'display_name': spec.displayName,
      'posture': spec.posture.name,
      'primary_signal': spec.primarySignal,
      'required_landmarks': spec.requiredLandmarks,
      'tracked_features': spec.features.keys.toList(),
      'camera_contract': {
        'view': 'front',
        'allowed_orientations': ['portrait_up'],
      },
      'pose_contract': {
        'coordinate_space': 'mediapipe_world_3d',
        'model': 'pose_landmarker',
        'runtime': 'mediapipe_tasks',
        'version': '0.10',
      },
      'confidence_policy': {
        'maximum_interpolated_gap_frames': 3,
        'minimum_sampling_hz': 15,
        'minimum_session_coverage': 0.8,
        'visibility_threshold': 0.5,
      },
      'reference_series': {
        'features': reference,
        'sampling_hz': 1000 / intervalMs,
      },
      'rep': {
        'rom_deg': {spec.primarySignal: sameQuantiles(rom)},
        'tempo_s': sameQuantiles(4),
      },
      'phases': [
        {'name': 'raise', 'duration_s': sameQuantiles(2)},
        {'name': 'lower', 'duration_s': sameQuantiles(2)},
      ],
      'review': {
        'status': 'draft',
        'source': {
          'kind': 'analytic',
          'generator': 'scripts/build-expanded-motion-assets.dart',
        },
      },
    });

    final bool showAlternate =
        spec.laterality == ExerciseLaterality.alternating ||
        id == 'seated_upper_body_turn';
    final demo = [...left, if (showAlternate) ...right];
    jsonFile('assets/motion/demonstrations/$id.demonstration-loop.v1.json', {
      'schema_version': 'demonstration-loop.v1',
      'exercise_id': id,
      'frame_interval_ms': intervalMs,
      'frame_count': demo.length,
      'landmark_count': 33,
      'points_xy': [
        for (final points in demo)
          for (final p in points) ...[
            rounded(0.5 + 0.61 * yaw(p, 0.62).x),
            rounded(0.47 + 0.52 * (p.y + 0.30 * p.z)),
          ],
      ],
    });
    replays[id] = {
      'cycles': [asFrames(left), if (showAlternate) asFrames(right)],
      if (id == 'seated_heel_raise' ||
          id == 'seated_toe_lift' ||
          id == 'seated_upper_body_turn' ||
          id == 'standing_back_leg_reach')
        'rejected': asFrames(cycle(id, -1, reverse: true)),
    };
  }
  File(
    'test/fixtures/expanded_motion_exercises.v1.json.gz',
  ).writeAsBytesSync(gzip.encode(utf8.encode(jsonEncode(replays))));
  writeRoutine('seated_mobility', 'Seated mobility routine', [
    'seated_chest_press',
    'seated_upper_body_turn',
    'seated_knee_extension',
    'seated_heel_raise',
    'seated_toe_lift',
  ]);
  writeRoutine('supported_movement', 'Supported standing routine', [
    'standing_back_leg_reach',
    'supported_shallow_knee_bend',
  ]);
}

void writeRoutine(String id, String name, List<String> exercises) {
  jsonFile('assets/motion/routines/${id}_v1.json', {
    'schema_version': 'routine.v1',
    'routine_id': id,
    'routine_version': 1,
    'display_name': name,
    'steps': [
      for (int index = 0; index < exercises.length; index++)
        {
          'exercise_id': exercises[index],
          'maximum_duration_s': 60,
          'rest_duration_s': index == exercises.length - 1 ? 0 : 6,
          'target_repetitions':
              exerciseSpecById(exercises[index]).laterality ==
                      ExerciseLaterality.alternating ||
                  exercises[index] == 'seated_upper_body_turn'
              ? 4
              : 3,
        },
    ],
  });
}
