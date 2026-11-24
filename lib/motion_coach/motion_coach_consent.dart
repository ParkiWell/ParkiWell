import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time consent for camera-based motion measurement.
///
/// Every entry point that opens the camera for pose analysis must pass this
/// gate: the motion-check flow, guided routines, and single-exercise practice
/// all process camera frames the same way, so consent given on any one of
/// them covers the others.
/// v2 added the derived-results backup disclosure; bumping the key re-asks
/// everyone who consented before score sync existed.
const String motionCoachConsentKey = 'motion_coach_mediapipe_consent_v2';

Future<bool> ensureMotionCoachConsent(BuildContext context) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(motionCoachConsentKey) == true) return true;
  if (!context.mounted) return false;

  final bool? accepted = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Motion Coach privacy'),
      // Scrollable: three paragraphs at a large accessibility text scale
      // overflow a fixed dialog, and this dialog gates the whole feature.
      content: const SingleChildScrollView(
        child: Text(
          'Guided sessions use the camera as you move. Camera images and pose '
          'landmarks stay on this device. If you choose to record a motion '
          'check from an exercise video, the recording also stays on this '
          'device. Google MediaPipe may receive performance and usage metrics '
          'about its on-device API.\n\n'
          'When you are signed in and result backup is enabled, scores and '
          'repetition counts are backed up to your account. You can manage '
          'result backup in Motion Coach settings.\n\n'
          'Motion Coach offers general movement observations for wellness.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (accepted != true) return false;
  await preferences.setBool(motionCoachConsentKey, true);
  return true;
}
