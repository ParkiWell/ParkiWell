import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:parkiwell/motion_coach/motion_coach_home_screen.dart';
import 'package:parkiwell/motion_coach/motion_coach_session.dart';
import 'package:parkiwell/motion_coach/motion_exercise_catalog.dart';
import 'package:parkiwell/motion_coach/motion_pose_bridge.dart';
import 'package:parkiwell/motion_coach/motion_reference_library.dart';
import 'package:parkiwell/motion_coach/motion_routine_controller.dart';
import 'package:parkiwell/motion_coach/motion_session_history.dart';
import 'package:path_provider/path_provider.dart';

const _width = 384;
const _height = 480;
const _pixels = _width * _height;
const _yuvBytes = _pixels * 3 ~/ 2;
const _bgraBytes = _pixels * 4;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the bundled native model scores movements from the NIA forward reach video',
    (tester) async {
      final directory = await getApplicationSupportDirectory();
      final bool ios = Platform.isIOS;
      final String format = ios ? 'bgra' : 'yuv';
      final int frameBytes = ios ? _bgraBytes : _yuvBytes;
      final file = await File(
        '${directory.path}/motion-forward-reach.$format',
      ).open();
      addTearDown(file.close);
      final bridge = MotionPoseBridge();
      await bridge.initialize();
      addTearDown(bridge.dispose);

      const exercise = seatedForwardReachExercise;
      final library = MotionReferenceLibrary();
      await library.templateFor(exercise.exerciseId);
      final controller = MotionRoutineController(
        library: library,
        routine: singleExerciseRoutine(exercise),
      );
      addTearDown(controller.dispose);

      int frames = 0;
      int singlePersonFrames = 0;
      while (controller.phase != MotionRoutinePhase.complete) {
        final Uint8List bytes = await file.read(frameBytes);
        if (bytes.isEmpty) break;
        expect(bytes.length, frameBytes);
        final detection = await bridge.detect(
          image: _image(bytes, ios: ios),
          sensorOrientation: 0,
          isFrontCamera: true,
          timestampMs: frames++ * 62,
        );
        if (detection.poseCount == 1) singlePersonFrames++;
        controller.handleSample(
          MotionPoseSample(
            detection: detection,
            frameWidth: _width,
            frameHeight: _height,
          ),
        );
        if (!controller.isStarted && controller.isFramingReady) {
          controller.start();
        }
      }
      expect(singlePersonFrames, greaterThan(80));
      expect(controller.isStarted, isTrue);
      if (controller.phase != MotionRoutinePhase.complete) {
        expect(controller.finishEarly(), isTrue);
      }
      final record = MotionSessionRecord.fromEvaluation(
        controller.evaluation!,
        completedAt: DateTime(2026, 11, 24),
      );
      expect(record.assessedSteps, 1);
      expect(record.completedRepetitions, greaterThanOrEqualTo(2));
      expect(record.steps.single.evidenceStatements, isNotEmpty);
      final double percentage = record.steps.single.coverage! * 100;
      debugPrint(
        'Native replay counted ${record.completedRepetitions} movements '
        'with ${percentage.toStringAsFixed(1)}% usable frames.',
      );
    },
    skip:
        !(Platform.isAndroid || Platform.isIOS) ||
        !const bool.fromEnvironment('PARKIWELL_NATIVE_MOTION_REPLAY'),
  );
}

CameraImage _image(Uint8List bytes, {required bool ios}) {
  Map<String, Object> plane(int start, int end, int stride, {int step = 1}) => {
    'bytes': Uint8List.sublistView(bytes, start, end),
    'bytesPerRow': stride,
    'bytesPerPixel': step,
  };

  // These represent the raw formats the camera plugin supplies on each OS.
  // ignore: deprecated_member_use
  return CameraImage.fromPlatformData({
    'width': _width,
    'height': _height,
    'format': ios ? 1111970369 : 35,
    'planes': ios
        ? [plane(0, _bgraBytes, _width * 4, step: 4)]
        : [
            plane(0, _pixels, _width),
            plane(_pixels, _pixels * 5 ~/ 4, _width ~/ 2),
            plane(_pixels * 5 ~/ 4, _yuvBytes, _width ~/ 2),
          ],
  });
}
