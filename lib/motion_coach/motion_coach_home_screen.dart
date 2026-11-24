import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion_engine/motion_engine.dart';

import '../services/app_logger.dart';
import '../services/cloud_backend_service.dart';
import '../services/feature_flags.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import 'motion_analysis.dart' show motionCoachAvailable;
import 'motion_coach_consent.dart';
import 'motion_coach_layout.dart';
import 'motion_coach_preferences.dart';
import 'motion_demonstration_view.dart';
import 'motion_exercise_catalog.dart';
import 'motion_progress_screen.dart';
import 'motion_reference_library.dart';
import 'motion_routine_catalog.dart';
import 'motion_routine_screen.dart';
import 'motion_session_history.dart';
import 'motion_session_intro_sheet.dart';

/// Entry point for guided routines and single-exercise practice.
class MotionCoachHomeScreen extends StatefulWidget {
  const MotionCoachHomeScreen({super.key, this.library, this.history});

  final MotionReferenceLibrary? library;
  final MotionSessionHistory? history;

  @override
  State<MotionCoachHomeScreen> createState() => _MotionCoachHomeScreenState();
}

class _MotionCoachHomeScreenState extends State<MotionCoachHomeScreen> {
  final AppLogger _logger = AppLogger();
  late final MotionReferenceLibrary _library =
      widget.library ?? MotionReferenceLibrary.shared;
  late final MotionSessionHistory _history =
      widget.history ?? MotionSessionHistory.shared;
  MotionDemonstrationLoop? _featuredPreview;
  bool _opening = false;
  bool _loadingSelection = false;

  @override
  void initState() {
    super.initState();
    FeatureFlags.shared.addListener(_onAvailabilityChanged);
    unawaited(_loadHistory());
    unawaited(_loadFeaturedPreview());
    // Refresh here because the app can remain resident for several days.
    unawaited(FeatureFlags.shared.refresh(CloudBackendService()));
  }

  @override
  void dispose() {
    FeatureFlags.shared.removeListener(_onAvailabilityChanged);
    super.dispose();
  }

  void _onAvailabilityChanged() => setState(() {});

  Future<void> _loadFeaturedPreview() async {
    try {
      final routine = await _library.loadRoutine(
        seatedFoundationRoutine.routineAssetId,
      );
      final preview = await _library.loadDemonstration(
        routine.steps.first.exerciseId,
      );
      if (mounted) setState(() => _featuredPreview = preview);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Featured routine preview unavailable',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _loadHistory() async {
    try {
      await _history.load();
      if (mounted) setState(() {});
    } on Object catch (error, stackTrace) {
      _logger.warning('Could not load motion history', error, stackTrace);
    }
  }

  Future<void> _openProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MotionProgressScreen(history: _history),
      ),
    );
    await _loadHistory();
  }

  void _openSettings() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const _CoachSettingsScreen()),
      ),
    );
  }

  Future<void> _openSession(
    MotionRoutineDescription description, {
    MotionExerciseDefinition? exercise,
  }) async {
    if (_opening || !motionCoachAvailable) return;
    HapticUtils.mediumImpact();
    setState(() {
      _opening = true;
      _loadingSelection = true;
    });
    try {
      final RoutineDefinition routine;
      if (exercise == null) {
        routine = await _library.loadRoutine(description.routineAssetId);
      } else {
        await _library.templateFor(exercise.exerciseId);
        routine = singleExerciseRoutine(exercise);
      }
      if (!mounted) return;
      setState(() => _loadingSelection = false);
      final bool begin = await showMotionSessionIntro(
        context,
        description: description,
        routine: routine,
        library: _library,
      );
      if (!begin || !mounted || !motionCoachAvailable) return;
      if (!await ensureMotionCoachConsent(context) ||
          !mounted ||
          !motionCoachAvailable) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MotionRoutineScreen(
            description: description,
            routine: routine,
            library: _library,
            history: _history,
          ),
        ),
      );
      await _loadHistory();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Motion session ${description.routineAssetId} failed to open',
        error,
        stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This session could not be opened. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _loadingSelection = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final sessionCount = _history.entries.length;
    final practiceAvailable = motionCoachAvailable;
    final canOpen = practiceAvailable && !_opening;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion coach'),
        actions: [
          IconButton(
            tooltip: 'Coaching settings',
            onPressed: _opening ? null : _openSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: _loadingSelection
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  semanticsLabel: 'Opening movement session',
                  color: colors.primary,
                ),
              )
            : null,
      ),
      body: MotionScreenScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Practise at your pace',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              practiceAvailable
                  ? 'Choose a guided routine or practise one movement with live camera feedback.'
                  : 'Live camera coaching is currently unavailable. You can still view your progress.',
              style: text.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            const MotionSectionTitle(title: 'Guided routines'),
            const SizedBox(height: 10),
            _FeaturedRoutine(
              preview: _featuredPreview,
              onPressed: canOpen
                  ? () => unawaited(_openSession(seatedFoundationRoutine))
                  : null,
            ),
            const SizedBox(height: 8),
            for (final routine in motionRoutineCatalog)
              if (routine != seatedFoundationRoutine)
                _CoachRow(
                  icon: routine.icon,
                  title: routine.title,
                  subtitle:
                      '${routine.durationLabel} · ${routine.requiresStanding ? 'Includes standing' : 'Seated'}',
                  onTap: canOpen
                      ? () => unawaited(_openSession(routine))
                      : null,
                ),
            const SizedBox(height: 26),
            const _WeeklyGoalCard(),
            _CoachRow(
              icon: Icons.insights_rounded,
              title: 'Your progress',
              subtitle: sessionCount == 0
                  ? 'See your scores and session history'
                  : '$sessionCount saved ${sessionCount == 1 ? 'session' : 'sessions'}',
              onTap: _opening ? null : () => unawaited(_openProgress()),
            ),
            const SizedBox(height: 26),
            const MotionSectionTitle(
              title: 'Practise one exercise',
              description: 'Choose a seated or standing movement.',
            ),
            const SizedBox(height: 8),
            for (final posture in MotionExercisePosture.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 13, 0, 3),
                child: Semantics(
                  header: true,
                  child: Text(
                    posture == MotionExercisePosture.seated
                        ? 'Seated exercises'
                        : 'Standing exercises',
                    style: text.titleMedium,
                  ),
                ),
              ),
              for (final exercise in motionExerciseCatalog)
                if (exercise.posture == posture)
                  _CoachRow(
                    icon: posture == MotionExercisePosture.seated
                        ? Icons.event_seat_outlined
                        : Icons.accessibility_new_rounded,
                    title: exercise.title,
                    subtitle: _exerciseSubtitle(exercise),
                    onTap: canOpen
                        ? () => unawaited(
                            _openSession(
                              singleExerciseDescription(exercise),
                              exercise: exercise,
                            ),
                          )
                        : null,
                  ),
            ],
            const SizedBox(height: 24),
            _CameraNote(),
          ],
        ),
      ),
    );
  }

  String _exerciseSubtitle(MotionExerciseDefinition exercise) {
    final last = _history.lastResultFor(exercise.exerciseId);
    return '${exercise.maximumRecordingRepetitions} movements'
        '${last == null ? '' : ' · Last score ${last.score.round()}'}';
  }
}

/// A single-exercise practice session, expressed as a one-step routine so it
/// runs through exactly the same engine path as a full routine.
RoutineDefinition singleExerciseRoutine(MotionExerciseDefinition exercise) =>
    RoutineDefinition(
      routineId: 'single_${exercise.exerciseId}',
      routineVersion: 1,
      displayName: exercise.title,
      steps: <RoutineStepDefinition>[
        RoutineStepDefinition(
          exerciseId: exercise.exerciseId,
          targetRepetitions: exercise.maximumRecordingRepetitions,
          // Generous relative to the target: the step ends on the rep count
          // in practice, and a hard stop only protects against a session
          // that is not being tracked at all.
          maximumDurationS: 180,
          restDurationS: 0,
        ),
      ],
    );

MotionRoutineDescription singleExerciseDescription(
  MotionExerciseDefinition exercise,
) => MotionRoutineDescription(
  routineAssetId: 'single_${exercise.exerciseId}',
  title: exercise.title,
  summary: exercise.instructions,
  approximateMinutes: 2,
  icon: Icons.fitness_center_rounded,
  requiresStanding: exercise.posture == MotionExercisePosture.standing,
);

class _FeaturedRoutine extends StatelessWidget {
  const _FeaturedRoutine({required this.preview, required this.onPressed});

  final MotionDemonstrationLoop? preview;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const routine = seatedFoundationRoutine;
    const ink = Color(0xFFF7FAFF);
    const copy = Color(0xFFCCDEFB);
    const mint = Color(0xFF9CE6CF);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14264A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final illustration = ExcludeSemantics(
              child: SizedBox(
                width: constraints.maxWidth >= 400 ? 140 : 86,
                height: constraints.maxWidth >= 400 ? 120 : 94,
                child: preview == null
                    ? const Icon(
                        Icons.event_seat_outlined,
                        color: mint,
                        size: 48,
                      )
                    : MotionDemonstrationView(
                        loop: preview!,
                        color: mint,
                        playing: false,
                      ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.title,
                            style: text.titleLarge?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${routine.durationLabel} · Seated',
                            style: text.bodyMedium?.copyWith(color: copy),
                          ),
                        ],
                      ),
                    ),
                    if (constraints.maxWidth >= 245) illustration,
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  routine.summary,
                  style: text.bodyMedium?.copyWith(color: copy, height: 1.45),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Preview routine'),
                  style: FilledButton.styleFrom(
                    backgroundColor: mint,
                    foregroundColor: const Color(0xFF14264A),
                    disabledBackgroundColor: const Color(0xFF364E73),
                    disabledForegroundColor: copy,
                    minimumSize: const Size(48, 50),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CoachRow extends StatelessWidget {
  const _CoachRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: onTap != null,
      onTap: onTap,
      leading: Icon(
        icon,
        color: onTap == null ? colors.textTertiary : colors.navSelected,
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
      title: Text(title, style: text.titleSmall),
      subtitle: Text(
        subtitle,
        style: text.bodySmall?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard();

  @override
  Widget build(BuildContext context) {
    final singleton = Singleton();
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: singleton,
      builder: (context, child) {
        final goal = singleton.weeklyPhysicalExerciseGoal;
        if (goal <= 0) return const SizedBox.shrink();
        final done = singleton.weeklyPhysicalExerciseSessions;
        final progress = '$done of $goal sessions';
        final accent = context.isDarkMode
            ? colors.secondary
            : colors.secondaryDark;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.blend(colors.secondary, 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly movement goal', style: text.titleMedium),
              const SizedBox(height: 2),
              Text(progress, style: text.bodyMedium?.copyWith(color: accent)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (done / goal).clamp(0.0, 1.0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: colors.surface,
                color: accent,
                semanticsLabel: 'Weekly movement goal',
              ),
              const SizedBox(height: 8),
              Text(
                'Measured practice counts toward your Recovery goal.',
                style: text.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CameraNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 20, color: colors.navSelected),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Guided practice uses the camera on this device and saves only movement results. '
            'Manage account backup and AI summaries in Coaching settings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachSettingsScreen extends StatefulWidget {
  const _CoachSettingsScreen();

  @override
  State<_CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends State<_CoachSettingsScreen> {
  final MotionCoachPreferences _preferences = MotionCoachPreferences.shared;

  @override
  void initState() {
    super.initState();
    if (!_preferences.isLoaded) unawaited(_preferences.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coaching settings')),
      body: ListenableBuilder(
        listenable: _preferences,
        builder: (context, child) {
          final loaded = _preferences.isLoaded;
          return MotionScreenScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MotionSectionTitle(
                  title: 'Live feedback',
                  description: 'Coaching cues always appear on screen.',
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences.speechEnabled,
                  onChanged: loaded
                      ? (value) =>
                            unawaited(_preferences.setSpeechEnabled(value))
                      : null,
                  title: const Text('Spoken cues'),
                  subtitle: const Text('Hear short coaching cues as you move.'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences.hapticsEnabled,
                  onChanged: loaded
                      ? (value) =>
                            unawaited(_preferences.setHapticsEnabled(value))
                      : null,
                  title: const Text('Vibrate when a movement is counted'),
                ),
                const SizedBox(height: 26),
                const MotionSectionTitle(
                  title: 'Privacy and backup',
                  description: 'Your camera frames stay on this device.',
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences.syncResultsEnabled,
                  onChanged: loaded
                      ? (value) =>
                            unawaited(_preferences.setSyncResultsEnabled(value))
                      : null,
                  title: const Text('Back up results to my account'),
                  subtitle: const Text(
                    'Sync scores and movement counts when signed in.',
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences.aiSummaryEnabled,
                  onChanged: loaded && _preferences.syncResultsEnabled
                      ? (value) =>
                            unawaited(_preferences.setAiSummaryEnabled(value))
                      : null,
                  title: const Text('AI session summary'),
                  subtitle: const Text(
                    'Share session scores with a cloud AI service to create a summary. '
                    'Requires sign-in and account backup.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
