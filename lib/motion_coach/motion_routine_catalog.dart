import 'package:flutter/material.dart';

/// App-facing description of a committed `routine.v1` document.
///
/// The routine's steps, rep targets, and rests live in the asset the engine
/// validates; only presentation belongs here.
class MotionRoutineDescription {
  const MotionRoutineDescription({
    required this.routineAssetId,
    required this.title,
    required this.summary,
    required this.approximateMinutes,
    required this.icon,
    required this.requiresStanding,
  });

  /// File name (without extension) under `assets/motion/routines/`.
  final String routineAssetId;
  final String title;
  final String summary;
  final int approximateMinutes;
  final IconData icon;

  /// Surfaced up front because a standing step needs a stable chair, more
  /// space, and a phone placed further back.
  final bool requiresStanding;

  String get durationLabel => 'about $approximateMinutes minutes';
}

const MotionRoutineDescription
seatedFoundationRoutine = MotionRoutineDescription(
  routineAssetId: 'seated_foundation_v1',
  title: 'Seated foundation',
  summary:
      'Arm raises, forward reaches, elbow bends, a seated march and a side lean.',
  approximateMinutes: 6,
  icon: Icons.event_seat_rounded,
  requiresStanding: false,
);

const MotionRoutineDescription fullBodyRoutine = MotionRoutineDescription(
  routineAssetId: 'full_body_v1',
  title: 'Full body',
  summary:
      'Arm raises, elbow bends, sit-to-stand, and a seated march. Includes '
      'standing, so use a stable chair with space around it.',
  approximateMinutes: 7,
  icon: Icons.accessibility_new_rounded,
  requiresStanding: true,
);

const MotionRoutineDescription seatedMobilityRoutine = MotionRoutineDescription(
  routineAssetId: 'seated_mobility_v1',
  title: 'Seated mobility',
  summary:
      'Chest presses, upper-body turns, knee extensions, heel raises, and toe lifts from a chair.',
  approximateMinutes: 5,
  icon: Icons.chair_alt_rounded,
  requiresStanding: false,
);

const MotionRoutineDescription supportedMovementRoutine =
    MotionRoutineDescription(
      routineAssetId: 'supported_movement_v1',
      title: 'Supported standing',
      summary:
          'Backward leg reaches and shallow knee bends with a stable support.',
      approximateMinutes: 3,
      icon: Icons.accessibility_rounded,
      requiresStanding: true,
    );

const List<MotionRoutineDescription> motionRoutineCatalog =
    <MotionRoutineDescription>[
      seatedFoundationRoutine,
      fullBodyRoutine,
      seatedMobilityRoutine,
      supportedMovementRoutine,
    ];
