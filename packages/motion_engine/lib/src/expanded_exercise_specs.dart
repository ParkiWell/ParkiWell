part of 'exercise_specs.dart';

final class _TorsoTurnFeature extends FeatureDefinition {
  const _TorsoTurnFeature();
}

final class _AnkleLiftFeature extends FeatureDefinition {
  const _AnkleLiftFeature(this.side, {required this.toes});

  final String side;
  final bool toes;

  double evaluate(List<PoseLandmark>? points) {
    final Vector3? ankle = _resolvePoint('${side}_ankle', points, null);
    final Vector3? toe = _resolvePoint('${side}_foot_index', points, null);
    if (ankle == null || toe == null) return double.nan;
    final Vector3 foot = toe - ankle;
    final double length = math.sqrt(foot.x * foot.x + foot.z * foot.z);
    if (length < 1e-5) return double.nan;
    return math.max(
        0, math.atan2(toes ? -foot.y : foot.y, length) * 180 / math.pi);
  }
}

final class _BackwardThighFeature extends FeatureDefinition {
  const _BackwardThighFeature(this.side);

  final String side;
}

Vector3? _horizontalAxis(List<PoseLandmark>? points, String landmark) {
  final Vector3? left = _resolvePoint('left_$landmark', points, null);
  final Vector3? right = _resolvePoint('right_$landmark', points, null);
  if (left == null || right == null) return null;
  final Vector3 delta = right - left;
  return Vector3(delta.x, 0, delta.z);
}

final Map<String, ExerciseSpec> _expandedExercises = {
  'seated_knee_extension': _pairedAngle(
    id: 'seated_knee_extension',
    title: 'Seated knee extensions',
    instruction: 'Straighten one leg comfortably, lower it, then switch legs.',
    landmarks: const ['hip', 'knee', 'ankle'],
    alternating: true,
    amplitude: 'If comfortable, straighten the next leg a little further.',
  ),
  'seated_heel_raise': _seatedAnkleLift(
    id: 'seated_heel_raise',
    title: 'Seated heel raises',
    instruction: 'Keep your toes down. Lift both heels, then lower them.',
    amplitude: 'If comfortable, lift your heels a little higher next time.',
  ),
  'seated_toe_lift': _seatedAnkleLift(
    id: 'seated_toe_lift',
    title: 'Seated toe lifts',
    instruction: 'Keep your heels down. Lift both toes, then lower them.',
    toes: true,
    amplitude: 'If comfortable, lift your toes a little higher next time.',
  ),
  'seated_upper_body_turn': ExerciseSpec(
    exerciseId: 'seated_upper_body_turn',
    displayName: 'Seated upper-body turns',
    instruction:
        'Turn your shoulders gently, come back to center, then try the other side.',
    posture: ExercisePosture.seated,
    features: const {'turn': _TorsoTurnFeature()},
    primarySignal: 'turn',
    laterality: ExerciseLaterality.none,
    requiredLandmarks: const [
      'left_shoulder',
      'right_shoulder',
      'left_hip',
      'right_hip',
    ],
    cues: const ExerciseCueTexts(
      amplitude: 'If comfortable, turn a little further on the next movement.',
    ),
  ),
  'seated_chest_press': _pairedAngle(
    id: 'seated_chest_press',
    title: 'Seated chest presses',
    instruction:
        'Start with bent elbows. Reach both hands forward, then bring them back.',
    landmarks: const ['shoulder', 'elbow', 'wrist'],
    amplitude: 'If comfortable, reach a little further on the next press.',
  ),
  'standing_back_leg_reach': ExerciseSpec(
    exerciseId: 'standing_back_leg_reach',
    displayName: 'Supported backward leg reaches',
    instruction:
        'Hold a stable support. Reach one leg slightly behind you, return, then switch.',
    posture: ExercisePosture.standing,
    features: const {
      'movement_l': _BackwardThighFeature('left'),
      'movement_r': _BackwardThighFeature('right'),
      'movement':
          PairFeatureDefinition(PairCombine.max, 'movement_l', 'movement_r'),
    },
    primarySignal: 'movement',
    laterality: ExerciseLaterality.alternating,
    sideFeatures: const ['movement_l', 'movement_r'],
    requiredLandmarks: const [
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle',
    ],
    cues: const ExerciseCueTexts(
      amplitude:
          'If comfortable, make the next backward reach a little larger.',
    ),
  ),
  'supported_shallow_knee_bend': _pairedAngle(
    id: 'supported_shallow_knee_bend',
    title: 'Supported shallow knee bends',
    instruction:
        'Hold a stable support. Bend both knees a little, then straighten.',
    landmarks: const ['hip', 'knee', 'ankle'],
    posture: ExercisePosture.standing,
    invert: true,
    amplitude: 'Keep the bend shallow and return to standing smoothly.',
  ),
};

ExerciseSpec _seatedAnkleLift({
  required String id,
  required String title,
  required String instruction,
  required String amplitude,
  bool toes = false,
}) =>
    ExerciseSpec(
      exerciseId: id,
      displayName: title,
      instruction: instruction,
      posture: ExercisePosture.seated,
      features: {
        'movement_l': _AnkleLiftFeature('left', toes: toes),
        'movement_r': _AnkleLiftFeature('right', toes: toes),
        'movement': const PairFeatureDefinition(
            PairCombine.mean, 'movement_l', 'movement_r'),
      },
      primarySignal: 'movement',
      laterality: ExerciseLaterality.bilateralSync,
      sideFeatures: const ['movement_l', 'movement_r'],
      requiredLandmarks: const [
        'left_knee',
        'right_knee',
        'left_ankle',
        'right_ankle',
        'left_foot_index',
        'right_foot_index',
      ],
      cues: ExerciseCueTexts(amplitude: amplitude),
    );

ExerciseSpec _pairedAngle({
  required String id,
  required String title,
  required String instruction,
  required List<String> landmarks,
  required String amplitude,
  ExercisePosture posture = ExercisePosture.seated,
  bool alternating = false,
  bool invert = false,
}) {
  AngleFeatureDefinition angle(String side) => AngleFeatureDefinition(
        '${side}_${landmarks[0]}',
        '${side}_${landmarks[1]}',
        '${side}_${landmarks[2]}',
        invert: invert,
      );

  return ExerciseSpec(
    exerciseId: id,
    displayName: title,
    instruction: instruction,
    posture: posture,
    features: {
      'movement_l': angle('left'),
      'movement_r': angle('right'),
      'movement': PairFeatureDefinition(
        alternating ? PairCombine.max : PairCombine.mean,
        'movement_l',
        'movement_r',
      ),
    },
    primarySignal: 'movement',
    laterality: alternating
        ? ExerciseLaterality.alternating
        : ExerciseLaterality.bilateralSync,
    sideFeatures: const ['movement_l', 'movement_r'],
    requiredLandmarks: [
      for (final landmark in landmarks) ...[
        'left_$landmark',
        'right_$landmark'
      ],
    ],
    cues: ExerciseCueTexts(amplitude: amplitude),
  );
}
