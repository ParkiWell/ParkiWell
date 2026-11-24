import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:parkiwell/utils/session_wakelock.dart';
import 'package:flutter/services.dart';
import 'package:motion_engine/motion_engine.dart';

import '../services/app_logger.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../utils/orientation_policy.dart';
import '../widgets/modern_card.dart';
import 'motion_analysis.dart' show motionCoachAvailable;
import 'motion_capture_driver.dart';
import 'motion_coach_preferences.dart';
import 'motion_coach_screen.dart' show MotionCaptureDriverFactory;
import 'motion_coach_session.dart';
import 'motion_cue_speaker.dart';
import 'motion_demonstration_view.dart';
import 'motion_exercise_catalog.dart';
import 'motion_reference_library.dart';
import 'motion_routine_catalog.dart';
import 'motion_routine_controller.dart';
import 'motion_routine_results_screen.dart';
import 'motion_session_history.dart';
import 'motion_skeleton_overlay.dart';

enum _RoutineScreenPhase { initializing, ready, running, suspended, error }

enum _RoutineExit { discard, save }

/// Guided multi-exercise routine.
///
/// Unlike the single-exercise motion check, nothing is recorded: the camera
/// stream is consumed frame by frame and discarded, so no video file is ever
/// created. Only the engine's derived scores survive the session.
class MotionRoutineScreen extends StatefulWidget {
  const MotionRoutineScreen({
    super.key,
    required this.description,
    required this.routine,
    required this.library,
    this.driverFactory,
    this.cueSpeaker,
    this.history,
    this.onSessionLogged,
    this.preferences,
  });

  final MotionRoutineDescription description;
  final RoutineDefinition routine;
  final MotionReferenceLibrary library;
  final MotionCaptureDriverFactory? driverFactory;
  final MotionCueSpeaker? cueSpeaker;
  final MotionSessionHistory? history;

  /// Called once when a session completes, so it counts in the app's shared
  /// recovery tracking (weekly plan, history). Injectable for tests; the
  /// default logs through the app [Singleton].
  final Future<void> Function(MotionSessionRecord record)? onSessionLogged;

  /// Cue delivery preferences; defaults to the shared app-wide instance.
  final MotionCoachPreferences? preferences;

  @override
  State<MotionRoutineScreen> createState() => _MotionRoutineScreenState();
}

class _MotionRoutineScreenState extends State<MotionRoutineScreen>
    with WidgetsBindingObserver {
  final AppLogger _logger = AppLogger();
  late final MotionRoutineController _controller;
  late final MotionCueSpeaker _cueSpeaker;
  late final MotionCoachPreferences _preferences;
  MotionCaptureDriver? _driver;
  Future<void>? _cameraCleanup;
  _RoutineScreenPhase _phase = _RoutineScreenPhase.initializing;
  MotionDemonstrationLoop? _demonstration;
  String? _demonstrationExerciseId;
  int _handledRepSerial = 0;
  int _handledCueSerial = 0;
  int _announcedStepIndex = -1;
  MotionRoutinePhase _lastSeenPhase = MotionRoutinePhase.framing;
  bool _finishing = false;
  int _generation = 0;
  String _errorTitle = 'The guided routine is unavailable';
  String _errorBody = 'Please try again.';
  bool _cameraDenied = false;
  bool _showingSessionDialog = false;

  @override
  void initState() {
    super.initState();
    // Keep the screen awake during a guided session; users with impaired
    // fine motor control cannot quickly re-wake a locked device mid-set.
    unawaited(acquireSessionWakelock());
    // The pose templates only allow portrait capture; hold the UI to the
    // same orientation so the preview, overlay, and landmarks always agree.
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]),
    );
    _controller = MotionRoutineController(
      routine: widget.routine,
      library: widget.library,
    );
    _cueSpeaker = widget.cueSpeaker ?? PlatformMotionCueSpeaker();
    _preferences = widget.preferences ?? MotionCoachPreferences.shared;
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);
    if (!_preferences.isLoaded) unawaited(_preferences.load());
    unawaited(_cueSpeaker.initialize());
    unawaited(_loadDemonstration());
    unawaited(_initialize());
  }

  @override
  void dispose() {
    unawaited(releaseSessionWakelock());
    unawaited(SystemChrome.setPreferredOrientations(appPreferredOrientations));
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    unawaited(_cueSpeaker.dispose());
    unawaited(_releaseCamera());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ignore transient inactive (Control Center swipe, permission dialog,
    // incoming call banner). A backgrounded session waits for an explicit
    // resume before turning the camera back on.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_suspend());
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.repSerial > _handledRepSerial) {
      _handledRepSerial = _controller.repSerial;
      if (_preferences.hapticsEnabled) HapticUtils.selectionClick();
    }
    final LiveExerciseCue? cue = _controller.cue;
    if (_controller.cueSerial > _handledCueSerial && cue != null) {
      _handledCueSerial = _controller.cueSerial;
      if (_preferences.speechEnabled) unawaited(_cueSpeaker.speak(cue.text));
    }
    // Rest is a pause in coaching: silence any in-flight cue rather than
    // letting it finish over the countdown.
    if (_controller.phase == MotionRoutinePhase.rest &&
        _lastSeenPhase != MotionRoutinePhase.rest) {
      unawaited(_cueSpeaker.stop());
    }
    // Announce each newly started step by its reviewed catalog copy, so a
    // person who is not watching the screen knows what to do next.
    if (_controller.isStarted &&
        _controller.phase == MotionRoutinePhase.active &&
        _controller.stepIndex != _announcedStepIndex) {
      _announcedStepIndex = _controller.stepIndex;
      if (_preferences.speechEnabled) {
        final MotionExerciseDefinition exercise = _controller.currentExercise;
        unawaited(
          _cueSpeaker.speak('${exercise.title}. ${exercise.instructions}'),
        );
      }
    }
    _lastSeenPhase = _controller.phase;
    if (_demonstrationExerciseId != _demonstrationTargetId) {
      unawaited(_loadDemonstration());
    }
    if (_controller.phase == MotionRoutinePhase.complete) {
      unawaited(_finish());
    }
    setState(() {});
  }

  /// During rest, the guide previews the next exercise so the person can
  /// reposition for it; otherwise it mirrors the current step.
  String get _demonstrationTargetId =>
      (_controller.upcomingExercise ?? _controller.currentExercise).exerciseId;

  Future<void> _loadDemonstration() async {
    final String exerciseId = _demonstrationTargetId;
    _demonstrationExerciseId = exerciseId;
    try {
      final MotionDemonstrationLoop loop = await widget.library
          .loadDemonstration(exerciseId);
      if (!mounted || _demonstrationExerciseId != exerciseId) return;
      setState(() => _demonstration = loop);
    } on Object catch (error, stackTrace) {
      // The written instruction is the fallback; a missing guide animation
      // must not stop the routine. Guarded like the success path so a stale
      // failure can never clobber a newer step's loaded guide.
      _logger.warning(
        'Demonstration loop failed to load for $exerciseId',
        error,
        stackTrace,
      );
      if (!mounted || _demonstrationExerciseId != exerciseId) return;
      setState(() => _demonstration = null);
    }
  }

  Future<void> _initialize() async {
    final int generation = ++_generation;
    setState(() => _phase = _RoutineScreenPhase.initializing);
    await _releaseCamera();
    if (!mounted || generation != _generation) return;
    if (!motionCoachAvailable) {
      setState(() {
        _phase = _RoutineScreenPhase.error;
        _cameraDenied = false;
        _errorTitle = 'Motion Coach is unavailable';
        _errorBody = 'Camera coaching is currently turned off.';
      });
      return;
    }

    final MotionCaptureDriver driver =
        (widget.driverFactory ?? CameraMotionCaptureDriver.new)();
    _driver = driver;
    try {
      await driver.initialize(
        (MotionPoseSample sample) {
          if (mounted && generation == _generation) {
            _controller.handleSample(sample);
          }
        },
        onPersistentFailure: () {
          if (generation == _generation) _onDetectorFailure();
        },
      );
      if (!mounted || generation != _generation) return;
      setState(() => _phase = _RoutineScreenPhase.ready);
    } on CameraException catch (error) {
      if (!mounted || generation != _generation) return;
      unawaited(_releaseCamera());
      final bool denied =
          error.code == 'CameraAccessDenied' ||
          error.code == 'CameraAccessDeniedWithoutPrompt' ||
          error.code == 'CameraAccessRestricted';
      setState(() {
        _phase = _RoutineScreenPhase.error;
        _cameraDenied = denied;
        _errorTitle = denied
            ? 'Camera access is needed'
            : 'Camera could not start';
        _errorBody = denied
            ? 'Allow Camera access for ParkiWell in your phone settings, '
                  'then return and try again.'
            : error.code == 'NoCamera'
            ? 'Motion Coach needs a camera. Try on a phone or tablet with a camera.'
            : 'Close other apps using the camera, then try again.';
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      unawaited(_releaseCamera());
      setState(() {
        _phase = _RoutineScreenPhase.error;
        _cameraDenied = false;
        _errorTitle = 'The guided routine could not start';
        _errorBody =
            'The on-device motion model could not be prepared. Restart '
            'ParkiWell and try again.';
      });
    }
  }

  /// Pose detection has failed continuously; treat it like any other fatal
  /// startup problem rather than leaving the person on "Looking for you".
  void _onDetectorFailure() {
    if (!mounted || _phase == _RoutineScreenPhase.error) return;
    ++_generation;
    unawaited(_releaseCamera());
    unawaited(_cueSpeaker.stop());
    setState(() {
      _phase = _RoutineScreenPhase.error;
      _cameraDenied = false;
      _errorTitle = 'Movement tracking stopped working';
      _errorBody =
          'The camera stopped tracking movement. Try reopening the camera.';
    });
    _controller.pause();
  }

  Future<void> _releaseCamera() {
    final MotionCaptureDriver? driver = _driver;
    _driver = null;
    if (driver == null) return _cameraCleanup ?? Future<void>.value();
    return _cameraCleanup = _disposeDriver(driver);
  }

  Future<void> _disposeDriver(MotionCaptureDriver driver) async {
    try {
      await driver.dispose();
    } on Object catch (error, stackTrace) {
      _logger.warning('Motion camera cleanup failed', error, stackTrace);
    }
  }

  Future<void> _suspend() async {
    if (_phase == _RoutineScreenPhase.suspended || _finishing) return;
    ++_generation;
    setState(() => _phase = _RoutineScreenPhase.suspended);
    _controller.pause();
    unawaited(_cueSpeaker.stop());
    await _releaseCamera();
  }

  void _start() {
    if (_phase != _RoutineScreenPhase.ready || !_controller.isFramingReady) {
      return;
    }
    if (!motionCoachAvailable) {
      unawaited(_initialize());
      return;
    }
    if (_controller.isPaused) {
      if (!_controller.resume()) return;
    } else {
      _controller.start();
    }
    if (_preferences.hapticsEnabled) HapticUtils.mediumImpact();
    setState(() => _phase = _RoutineScreenPhase.running);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final Map<String, Object?>? evaluation = _controller.evaluation;
    if (_preferences.hapticsEnabled) HapticUtils.success();
    unawaited(_cueSpeaker.stop());
    await _releaseCamera();
    if (evaluation == null || !mounted) return;

    // The evaluation is parsed exactly once. If the document itself cannot
    // be parsed there is nothing to show; anything downstream of a
    // successful parse (saving) failing must not cost the person their
    // results.
    final MotionSessionRecord record;
    try {
      record = MotionSessionRecord.fromEvaluation(
        evaluation,
        completedAt: DateTime.now(),
        endedEarly: _controller.endedEarly,
      );
    } on Object catch (error, stackTrace) {
      // The engine emitted a document this build cannot parse; that is a
      // defect worth hearing about, not a user-facing condition.
      _logger.error(
        'Session evaluation could not be parsed',
        error,
        stackTrace,
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    bool saved = true;
    try {
      await (widget.history ?? MotionSessionHistory.shared).add(record);
    } on Object catch (error, stackTrace) {
      _logger.warning('Session history write failed', error, stackTrace);
      saved = false;
    }
    // Count the completed session in the app's shared recovery tracking.
    // Best effort: a logging failure must not block the results screen.
    if (record.assessedSteps > 0) {
      try {
        await (widget.onSessionLogged ?? _logToRecoveryTracking)(record);
      } on Object catch (error, stackTrace) {
        _logger.warning('Recovery tracking log failed', error, stackTrace);
      }
    }
    // Queue the full result for account backup. Fire-and-forget: it
    // respects the sync preference internally and never blocks results.
    if (saved && widget.onSessionLogged == null) {
      unawaited(
        Singleton().queueMotionSessionSync(
          record: record,
          evaluation: evaluation,
        ),
      );
    }
    if (!mounted) return;
    // An exercise can finish while its skip dialog is open. Close that
    // dialog before swapping the session route for its results.
    final ModalRoute<Object?>? ownRoute = ModalRoute.of(context);
    if (ownRoute != null && !ownRoute.isCurrent) {
      Navigator.of(
        context,
      ).popUntil((Route<Object?> route) => route == ownRoute);
    }
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MotionRoutineResultsScreen(
          title: widget.description.title,
          record: record,
          saved: saved,
        ),
      ),
    );
  }

  static Future<void> _logToRecoveryTracking(MotionSessionRecord record) =>
      Singleton().recordMotionCoachSession(
        recordId: record.id,
        routineId: record.routineId,
        title: 'Motion coach: ${record.routineName}',
        completedAt: record.completedAt,
      );

  Future<void> _confirmExit() async {
    // Completion navigation is already in flight; a concurrent pop here
    // would race the pushReplacement onto a route being removed.
    if (_finishing || _showingSessionDialog) return;
    if (!_controller.isStarted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _showingSessionDialog = true;
    final bool wasRunning = _phase == _RoutineScreenPhase.running;
    if (wasRunning) {
      _controller.pause();
      unawaited(_cueSpeaker.stop());
      setState(() => _phase = _RoutineScreenPhase.ready);
    }
    final _RoutineExit? leave = await showDialog<_RoutineExit>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('End this session?'),
        content: Text(
          _controller.canFinishEarly
              ? 'Save the movements you completed, or discard this session.'
              : 'If you end now, this session will be discarded.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return to session'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_RoutineExit.discard),
            child: const Text('Discard session'),
          ),
          if (_controller.canFinishEarly)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_RoutineExit.save),
              child: const Text('Save and end'),
            ),
        ],
      ),
    );
    _showingSessionDialog = false;
    if (!mounted || _finishing) return;
    switch (leave) {
      case _RoutineExit.save:
        _controller.finishEarly();
      case _RoutineExit.discard:
        Navigator.of(context).pop();
      case null:
        if (wasRunning) _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_controller.isStarted && !_finishing,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.description.title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close session',
            onPressed: _finishing ? null : () => unawaited(_confirmExit()),
          ),
        ),
        body: SafeArea(
          top: false,
          child: _finishing
              ? const _RoutineLoading(label: 'Saving results…')
              : switch (_phase) {
                  _RoutineScreenPhase.error => _buildMessage(
                    context,
                    icon: Icons.error_outline_rounded,
                    title: _errorTitle,
                    body: _errorBody,
                    actionLabel: 'Try again',
                    onAction: () => unawaited(_initialize()),
                    secondaryActionLabel: _cameraDenied
                        ? 'Open Settings'
                        : null,
                    onSecondaryAction: _cameraDenied
                        ? () => unawaited(AppSettings.openAppSettings())
                        : null,
                  ),
                  _RoutineScreenPhase.suspended => _buildMessage(
                    context,
                    icon: Icons.pause_circle_outline_rounded,
                    title: _controller.isStarted
                        ? 'Session paused'
                        : 'Camera off',
                    body: _controller.isStarted
                        ? 'Your completed repetitions are still here. Open the camera when you’re ready to continue.'
                        : 'Open the camera when you’re ready to check your position.',
                    actionLabel: 'Open camera',
                    onAction: () => unawaited(_initialize()),
                  ),
                  _RoutineScreenPhase.initializing => const _RoutineLoading(
                    label: 'Opening camera…',
                  ),
                  _RoutineScreenPhase.ready ||
                  _RoutineScreenPhase.running => _buildSession(context),
                },
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final colors = context.colors;
    final bool running = _phase == _RoutineScreenPhase.running;
    final MotionExerciseDefinition exercise =
        _controller.upcomingExercise ?? _controller.currentExercise;
    final bool preparingNext = _controller.upcomingExercise != null;
    final int visibleStep = _controller.stepIndex + (preparingNext ? 2 : 1);

    return Column(
      children: <Widget>[
        LinearProgressIndicator(
          value: _controller.progress,
          minHeight: 6,
          semanticsLabel: 'Routine progress',
          backgroundColor: colors.primary.withValues(alpha: 0.12),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      '${preparingNext ? 'Next · ' : ''}Step $visibleStep of '
                      '${_controller.stepCount} · ${exercise.postureLabel}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        exercise.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      running && !preparingNext
                          ? exercise.instructions
                          : exercise.setupHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tablets and other wide viewports get the stage beside the
                    // status column instead of stacked, keeping the camera and
                    // the numbers visible together without scrolling.
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final Widget status = _buildStatusColumn(
                              context,
                              running: running,
                            );
                            if (constraints.maxWidth < 720) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  if (running) status else _buildStage(context),
                                  const SizedBox(height: 16),
                                  if (running) _buildStage(context) else status,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(flex: 3, child: _buildStage(context)),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: status),
                              ],
                            );
                          },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildSessionActions(context, running: running),
      ],
    );
  }

  Widget _buildStatusColumn(BuildContext context, {required bool running}) {
    return running ? _buildLiveStatus(context) : _buildFramingStatus(context);
  }

  Widget _buildSessionActions(BuildContext context, {required bool running}) {
    final bool canSkip =
        running && _controller.phase == MotionRoutinePhase.active;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (running)
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_suspend()),
                    icon: const Icon(Icons.pause_rounded),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    label: const Text('Pause session'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _controller.isFramingReady ? _start : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    label: Text(
                      _controller.isPaused ? 'Resume session' : 'Start routine',
                    ),
                  ),
                if (canSkip)
                  TextButton.icon(
                    onPressed: () => unawaited(_confirmSkipStep()),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Skip this exercise'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Camera preview beside the reference figure, so the person can compare
  /// what they are doing with what the exercise asks for.
  Widget _buildStage(BuildContext context) {
    final colors = context.colors;
    final MotionDemonstrationLoop? demonstration =
        _demonstration?.exerciseId == _demonstrationTargetId
        ? _demonstration
        : null;
    // Scales with the viewport so small phones keep the controls on screen
    // and tall phones get a larger preview; clamped to sane bounds.
    final double stageHeight = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      220.0,
      340.0,
    );
    return SizedBox(
      height: stageHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: const Color(0xFF14264A),
                child: _driver?.isInitialized == true
                    ? FittedBox(
                        fit: BoxFit.contain,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: stageHeight / _driver!.aspectRatio,
                          height: stageHeight,
                          // The overlay shares the preview's exact coordinate
                          // box so normalized landmarks map straight onto it.
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              // RepaintBoundary keeps camera-rate skeleton
                              // repaints from dirtying the surrounding
                              // cards and gradients.
                              RepaintBoundary(child: _driver!.buildPreview()),
                              RepaintBoundary(
                                child: MotionSkeletonOverlay(
                                  frame: _controller.skeleton,
                                  mirrored: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Text(
                    'Guide',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: demonstration == null
                        ? const SizedBox.expand()
                        : Semantics(
                            label:
                                'Animated demonstration of the reference '
                                'movement',
                            child: MotionDemonstrationView(
                              key: ValueKey<String>(demonstration.exerciseId),
                              loop: demonstration,
                              color: colors.primary,
                              playing:
                                  _controller.phase !=
                                  MotionRoutinePhase.complete,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSkipStep() async {
    if (_finishing || _showingSessionDialog) return;
    _showingSessionDialog = true;
    final int stepIndex = _controller.stepIndex;
    final MotionExerciseDefinition exercise = _controller.currentExercise;
    final bool? skip = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Skip ${exercise.title}?'),
        content: const Text(
          'The movements you completed in this exercise still count. The '
          'routine moves on to the next exercise.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    // The routine keeps running behind the dialog; the step the person
    // agreed to skip may have finished on its own. Skipping is only honored
    // while that same step is still the active one, otherwise a confirm
    // would silently skip the following exercise instead.
    _showingSessionDialog = false;
    if (skip == true &&
        mounted &&
        _phase == _RoutineScreenPhase.running &&
        _controller.stepIndex == stepIndex &&
        _controller.phase == MotionRoutinePhase.active) {
      if (_preferences.hapticsEnabled) HapticUtils.lightImpact();
      _controller.skipCurrentStep();
    }
  }

  /// Guidance for a framing problem, phrased for someone mid-session.
  static String _framingGuidance(MotionFramingStatus status) =>
      switch (status) {
        MotionFramingStatus.ready => '',
        MotionFramingStatus.multiplePeople =>
          'More than one person is in view. Movements cannot be counted '
              'until only you are in frame.',
        MotionFramingStatus.showMoreBody =>
          'Part of you is out of frame. Move so your head, hands, and hips '
              'are all visible.',
        MotionFramingStatus.showLowerBody =>
          'Your legs are out of frame. Step back or tilt the phone down so '
              'your knees and feet stay visible.',
        MotionFramingStatus.moveCloser =>
          'You look far away. Move a little closer to the phone.',
        MotionFramingStatus.lookingForPerson =>
          'The camera lost you. Step back into view to keep counting.',
      };

  Widget _buildFramingStatus(BuildContext context) {
    final colors = context.colors;
    final bool ready = _controller.isFramingReady;
    final String message = switch (_controller.framingStatus) {
      MotionFramingStatus.ready => 'You are in frame. Start when ready.',
      MotionFramingStatus.multiplePeople =>
        'More than one person is in view. The routine needs a single person '
            'in frame.',
      MotionFramingStatus.showMoreBody =>
        'Move so your head, both hands, and both hips are inside the frame.',
      MotionFramingStatus.showLowerBody =>
        'This exercise measures your legs. Step back or tilt the phone down '
            'so your knees and feet are inside the frame.',
      MotionFramingStatus.moveCloser =>
        'Move a little closer to the phone, or lift it higher.',
      MotionFramingStatus.lookingForPerson => 'Looking for you…',
    };
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      backgroundColor: (ready ? colors.success : colors.warning).withValues(
        alpha: 0.11,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            ready
                ? Icons.check_circle_rounded
                : Icons.center_focus_weak_rounded,
            color: ready ? colors.success : colors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatus(BuildContext context) {
    final colors = context.colors;
    if (_controller.phase == MotionRoutinePhase.rest) {
      final MotionExerciseDefinition? upcoming = _controller.upcomingExercise;
      return ModernCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        backgroundColor: colors.primary.withValues(alpha: 0.1),
        child: Column(
          children: <Widget>[
            Text(
              'Rest',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${_controller.restRemainingSeconds.ceil()} seconds',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
            if (upcoming != null) ...[
              const SizedBox(height: 12),
              Text(
                'Next: ${upcoming.title}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                upcoming.setupHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final ExerciseRepScore? score = _controller.lastRepScore;
    final LiveExerciseCue? cue = _controller.cue;
    // Hysteresis can leave isFramingReady false for a few frames after the
    // status itself recovers; the banner keys off the actionable guidance so
    // it never shows empty text.
    final String framingGuidance = _framingGuidance(_controller.framingStatus);
    final bool trackingLost =
        _controller.phase == MotionRoutinePhase.active &&
        !_controller.isFramingReady &&
        framingGuidance.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (trackingLost) ...[
          Semantics(
            liveRegion: true,
            child: ModernCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              backgroundColor: colors.warning.withValues(alpha: 0.14),
              child: Row(
                children: <Widget>[
                  Icon(Icons.visibility_off_rounded, color: colors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      framingGuidance,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ModernCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Repetitions',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_controller.completedRepetitions} of '
                        '${_controller.targetRepetitions}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              if (score != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Last movement',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${score.overall.round()}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (cue != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: 'Motion coach: ${cue.text}',
            child: ModernCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              child: Text(
                cue.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: colors.warning),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.videocam_outlined),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
              label: Text(actionLabel),
            ),
            if (_controller.canFinishEarly) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => unawaited(_confirmExit()),
                child: const Text('End session'),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoutineLoading extends StatelessWidget {
  const _RoutineLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Semantics(liveRegion: true, child: Text(label)),
      ],
    ),
  );
}
