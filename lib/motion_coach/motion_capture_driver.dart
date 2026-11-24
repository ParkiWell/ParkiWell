import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_logger.dart';
import 'motion_coach_session.dart';
import 'motion_pose_bridge.dart';

typedef MotionSampleCallback = void Function(MotionPoseSample sample);

abstract interface class MotionCaptureDriver {
  bool get isInitialized;
  bool get isRecording;
  double get aspectRatio;

  /// [onPersistentFailure] fires once if pose detection keeps throwing frame
  /// after frame. Without it a broken detector is indistinguishable from "no
  /// person in view" and the screen waits forever.
  Future<void> initialize(
    MotionSampleCallback onSample, {
    VoidCallback? onPersistentFailure,
  });
  Widget buildPreview();
  Future<void> startRecording();
  Future<String> stopRecording();
  Future<void> cancelRecording();
  Future<void> dispose();
}

/// Internal signal that [CameraMotionCaptureDriver.dispose] ran while
/// [CameraMotionCaptureDriver.initialize] was still between awaits.
class _DisposedDuringInitialize implements Exception {
  const _DisposedDuringInitialize();
}

class CameraMotionCaptureDriver implements MotionCaptureDriver {
  CameraMotionCaptureDriver({MotionPoseBridge? poseBridge})
    : _poseBridge = poseBridge ?? MotionPoseBridge();

  /// Consecutive detect() exceptions before the driver reports the detector
  /// as broken; roughly three seconds of frames at the low end of the
  /// supported rate. Detections that simply find nobody do not count.
  static const int persistentFailureThreshold = 45;

  final MotionPoseBridge _poseBridge;
  final AppLogger _logger = AppLogger();
  final Stopwatch _clock = Stopwatch();
  CameraController? _camera;
  CameraDescription? _description;
  MotionSampleCallback? _onSample;
  VoidCallback? _onPersistentFailure;
  Future<void>? _initialization;
  Future<void>? _disposal;
  Future<void>? _recordingStart;
  int _consecutiveDetectionFailures = 0;
  bool _persistentFailureReported = false;
  bool _processingFrame = false;
  bool _disposed = false;

  @override
  bool get isInitialized => _camera?.value.isInitialized == true;

  @override
  bool get isRecording => _camera?.value.isRecordingVideo == true;

  @override
  double get aspectRatio => _camera?.value.aspectRatio ?? 3 / 4;

  @override
  Future<void> initialize(
    MotionSampleCallback onSample, {
    VoidCallback? onPersistentFailure,
  }) {
    if (_disposed) {
      throw StateError('A disposed camera driver cannot be reused');
    }
    _onSample = onSample;
    _onPersistentFailure = onPersistentFailure;
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _openCamera();
    } on _DisposedDuringInitialize {
      // The disposer waits for initialization before releasing resources.
    }
  }

  Future<void> _openCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    _throwIfDisposedDuringInitialize();
    final CameraDescription? frontCamera = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.front)
        .firstOrNull;
    if (frontCamera == null) {
      throw CameraException(
        'NoCamera',
        'No front-facing camera is available on this device.',
      );
    }
    _description = frontCamera;
    final CameraController controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.yuv420,
    );
    _camera = controller;
    await controller.initialize();
    _throwIfDisposedDuringInitialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    _throwIfDisposedDuringInitialize();
    await _poseBridge.initialize();
    _throwIfDisposedDuringInitialize();
    _clock.start();
    await controller.startImageStream(_handleImage);
  }

  /// Guard for every await inside [initialize]: [dispose] can run mid-flight
  /// (State.dispose is synchronous and cannot wait for us), and once it has,
  /// any camera resources we create afterwards would leak.
  void _throwIfDisposedDuringInitialize() {
    if (_disposed) {
      throw const _DisposedDuringInitialize();
    }
  }

  @override
  Widget buildPreview() {
    final CameraController? camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(camera);
  }

  @override
  Future<void> startRecording() => _recordingStart ??= _startRecording();

  Future<void> _startRecording() async {
    final CameraController camera = _requireCamera();
    if (camera.value.isStreamingImages) {
      await camera.stopImageStream();
    }
    await camera.startVideoRecording(
      onAvailable: _handleImage,
      enablePersistentRecording: false,
    );
  }

  @override
  Future<String> stopRecording() async {
    final CameraController camera = _requireCamera();
    final XFile file = await camera.stopVideoRecording();
    return file.path;
  }

  @override
  Future<void> cancelRecording() async {
    final CameraController? camera = _camera;
    if (camera?.value.isRecordingVideo != true) return;
    try {
      final XFile file = await camera!.stopVideoRecording();
      final File recording = File(file.path);
      if (await recording.exists()) {
        await recording.delete();
      }
    } on CameraException {
      // The camera already died (lifecycle race); there is nothing to
      // cancel and no recording file to clean up.
    }
  }

  @override
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    _clock.stop();
    _onSample = null;
    _onPersistentFailure = null;
    try {
      await _initialization;
      await _recordingStart;
    } catch (_) {
      // Startup reports its own error; partially opened resources still close.
    }
    final CameraController? camera = _camera;
    _camera = null;
    try {
      if (camera?.value.isRecordingVideo == true) {
        final XFile file = await camera!.stopVideoRecording();
        final File recording = File(file.path);
        if (await recording.exists()) {
          await recording.delete();
        }
      } else if (camera?.value.isStreamingImages == true) {
        await camera!.stopImageStream();
      }
    } catch (_) {
      // The platform may already have released the camera during lifecycle exit.
    }
    try {
      await camera?.dispose();
    } finally {
      await _poseBridge.dispose();
    }
  }

  CameraController _requireCamera() {
    final CameraController? camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      throw StateError('Camera is not initialized');
    }
    return camera;
  }

  Future<void> _handleImage(CameraImage image) async {
    if (_processingFrame || _disposed || _onSample == null) return;
    _processingFrame = true;
    final int timestampMs = _clock.elapsedMilliseconds;
    try {
      final CameraDescription description = _description!;
      final MotionPoseDetection detection = await _poseBridge.detect(
        image: image,
        sensorOrientation: description.sensorOrientation,
        isFrontCamera: description.lensDirection == CameraLensDirection.front,
        timestampMs: timestampMs,
      );
      _consecutiveDetectionFailures = 0;
      if (!_disposed) {
        final bool swapsDimensions =
            description.sensorOrientation.abs() % 180 == 90;
        _onSample?.call(
          MotionPoseSample(
            detection: detection,
            frameWidth: swapsDimensions ? image.height : image.width,
            frameHeight: swapsDimensions ? image.width : image.height,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      _consecutiveDetectionFailures += 1;
      if (_consecutiveDetectionFailures == 1) {
        _logger.warning('Motion pose detection failed', error, stackTrace);
      }
      if (_consecutiveDetectionFailures >= persistentFailureThreshold &&
          !_persistentFailureReported &&
          !_disposed) {
        // Every frame is failing: without this, the detector being broken is
        // indistinguishable from nobody standing in front of the camera and
        // the screen waits on "Looking for you" forever.
        _persistentFailureReported = true;
        _logger.error(
          'Motion pose detection failed '
          '$_consecutiveDetectionFailures frames in a row',
          error,
          stackTrace,
        );
        _onPersistentFailure?.call();
      }
      if (!_disposed) {
        final int orientation = _description?.sensorOrientation ?? 0;
        final bool swapsDimensions = orientation.abs() % 180 == 90;
        _onSample?.call(
          MotionPoseSample(
            detection: MotionPoseDetection.empty(timestampMs: timestampMs),
            frameWidth: swapsDimensions ? image.height : image.width,
            frameHeight: swapsDimensions ? image.width : image.height,
          ),
        );
      }
    } finally {
      _processingFrame = false;
    }
  }
}
