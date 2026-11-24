import 'package:flutter/material.dart';

import '../services/cloud_backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import 'motion_coach_layout.dart';
import 'motion_exercise_catalog.dart';
import 'motion_coach_preferences.dart';
import 'motion_feedback_copy.dart';
import 'motion_session_history.dart';

/// Renders a completed `session-evaluation.v1` document.
///
/// Renders the engine's measurements and reviewed feedback sentences.
/// Saved sessions may also have an optional account summary.
class MotionRoutineResultsScreen extends StatelessWidget {
  /// Takes an already-parsed record on purpose: parsing the raw evaluation
  /// here would repeat, unguarded, exactly the parse the caller just
  /// protected with a try/catch, and crash the results route on the one
  /// input that protection exists for.
  const MotionRoutineResultsScreen({
    super.key,
    required this.title,
    required this.record,
    this.saved = true,
    MotionSessionHistory? history,
  }) : _history = history;

  /// Heading shown above the score; the record's routine name in every
  /// current flow. Only presentation, so a full routine description object
  /// is deliberately not required (history entries may outlive the catalog).
  final String title;
  final MotionSessionRecord record;

  /// False when the session finished but could not be written to history.
  final bool saved;

  final MotionSessionHistory? _history;

  /// Signed difference between this session's score and the mean of the
  /// most recent previous scored sessions, or null when this is the first.
  double? get _trendDelta {
    final double? score = record.overallScore;
    if (score == null || record.endedEarly) return null;
    final MotionSessionHistory history =
        _history ?? MotionSessionHistory.shared;
    final List<double> previous = <double>[
      for (final MotionSessionRecord entry in history.entries)
        if (entry.routineId == record.routineId &&
            entry.completedAt.isBefore(record.completedAt) &&
            !entry.endedEarly &&
            entry.overallScore != null)
          entry.overallScore!,
    ];
    if (previous.isEmpty) return null;
    final List<double> window = previous.take(5).toList(growable: false);
    final double mean =
        window.reduce((double a, double b) => a + b) / window.length;
    return score - mean;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final score = record.overallScore;
    final bool assessed = score != null;
    final bool measuredUnscored = !assessed && record.assessedSteps > 0;
    final delta = _trendDelta;
    final coachingAccent = context.isDarkMode
        ? colors.secondary
        : colors.secondaryDark;
    final summary = assessed
        ? 'Movement score out of 100'
        : measuredUnscored
        ? 'Measured without a score. Motion checks report evidence only.'
        : 'Not enough was visible to score this session';
    final statusColor = assessed ? coachingAccent : colors.navSelected;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          record.routineId.startsWith('check:')
              ? 'Motion check'
              : 'Routine summary',
        ),
      ),
      body: MotionScreenScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            if (record.endedEarly) ...[
              const SizedBox(height: 6),
              Text(
                'Ended early. This summary reflects the movements you did.',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceVariant.blend(statusColor, 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessed ? '${score.round()}' : '—',
                      style: text.displayMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(summary, style: text.titleSmall),
                    const SizedBox(height: 10),
                    Text(
                      '${record.assessedSteps} of ${record.totalSteps} '
                      'exercises measured · ${record.completedRepetitions} '
                      'movements counted',
                      style: text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        delta.abs() < 1
                            ? 'Close to your recent average for this routine.'
                            : '${delta.abs().round()} points ${delta > 0 ? 'above' : 'below'} '
                                  'your recent average for this routine.',
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (record.strengths.isNotEmpty) ...[
              const SizedBox(height: 24),
              const MotionSectionTitle(title: 'What went well'),
              const SizedBox(height: 9),
              for (final line in record.strengths)
                _FeedbackLine(
                  icon: Icons.check_circle_outline_rounded,
                  color: coachingAccent,
                  text: line,
                ),
            ],
            if (record.focusAreas.isNotEmpty) ...[
              const SizedBox(height: 24),
              const MotionSectionTitle(title: 'What to focus on next time'),
              const SizedBox(height: 9),
              for (final line in record.focusAreas)
                _FeedbackLine(
                  icon: Icons.flag_outlined,
                  color: colors.navSelected,
                  text: line,
                ),
            ],
            if (record.steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              const MotionSectionTitle(title: 'By exercise'),
              const SizedBox(height: 9),
              for (final step in record.steps) _StepCard(step: step),
            ],
            if (saved &&
                MotionCoachPreferences.shared.aiSummaryEnabled &&
                MotionCoachPreferences.shared.syncResultsEnabled &&
                CloudBackendService().hasFullAccount) ...[
              const SizedBox(height: 18),
              _AiSummaryCard(sessionId: record.id),
            ],
            const SizedBox(height: 24),
            Text(
              saved ? 'Saved on this device' : 'Not saved',
              style: text.titleSmall,
            ),
            const SizedBox(height: 5),
            Text(
              saved
                  ? 'Your movement results are stored on this device. '
                        'Account backup syncs your results when enabled and signed in.'
                  : 'This summary could not be written to your history. '
                        'It will be gone when you leave this screen.',
              style: text.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use these camera measurements as movement feedback. A score is '
              'not a diagnosis. Stay within a comfortable range and stop if '
              'you feel pain, dizziness, or discomfort.',
              style: text.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MotionActionBar(
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
          child: const Text('Done'),
        ),
      ),
    );
  }
}

/// Optional cloud-generated narrative, layered strictly on top of the
/// deterministic feedback above it. Requested lazily, cached server-side,
/// and simply absent on any failure — offline sessions never miss anything
/// they need.
class _AiSummaryCard extends StatefulWidget {
  const _AiSummaryCard({required this.sessionId});

  final String sessionId;

  @override
  State<_AiSummaryCard> createState() => _AiSummaryCardState();
}

class _AiSummaryCardState extends State<_AiSummaryCard> {
  late final Future<String?> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _fetchWithRetry();
  }

  /// The session row reaches the backend through the async sync journal, so
  /// the very first request usually races it. A few spaced retries cover
  /// the normal sync latency; after that the card simply stays hidden.
  Future<String?> _fetchWithRetry() async {
    final CloudBackendService cloud = CloudBackendService();
    for (int attempt = 0; attempt < 3; attempt += 1) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: 3 * attempt));
        if (!mounted) return null;
      }
      final String? summary = await cloud.getMotionSessionSummary(
        widget.sessionId,
      );
      if (summary != null && summary.isNotEmpty) return summary;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FutureBuilder<String?>(
      future: _summary,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final String? summary = snapshot.data;
        if (summary == null || summary.isEmpty) {
          return const SizedBox.shrink();
        }
        return ModernCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI summary',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Written by an AI service from the measurements above. Not '
                'medical advice.',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final MotionSessionStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String title = _titleFor(step.exerciseId);
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            step.overallScore == null
                ? step.assessed
                      ? 'Evidence measured'
                      : 'Not measured'
                : '${step.overallScore!.round()} out of 100',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: step.overallScore == null
                  ? colors.textSecondary
                  : colors.navSelected,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${step.completedRepetitions} of ${step.targetRepetitions} '
            'movements completed',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          if (!step.assessed)
            for (final String sentence in <String>[
              for (final String code in step.reasonCodes)
                if (reasonCodeLabel(code) != null) reasonCodeLabel(code)!,
            ]) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sentence,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          if (step.assessed) ...[
            const SizedBox(height: 12),
            _ComponentBar(label: 'Movement size', value: step.rangeScore),
            _ComponentBar(label: 'Pace', value: step.tempoScore),
            _ComponentBar(label: 'Smoothness', value: step.smoothnessScore),
            if (step.symmetryScore != null)
              _ComponentBar(label: 'Evenness', value: step.symmetryScore),
            if (_cueInsight() case final String insight) ...[
              const SizedBox(height: 4),
              Text(
                insight,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (step.repetitions.isNotEmpty) _StepEvidence(step: step),
          ],
        ],
      ),
    );
  }

  /// The most frequent corrective live cue, when it fired at least twice.
  /// Repeated guidance is evidence about the session, not a judgment made
  /// here: both the code and its count come from the engine.
  String? _cueInsight() {
    String? topCode;
    int topCount = 0;
    for (final MapEntry<String, int> entry in step.cueCounts.entries) {
      if (entry.key == 'positive') continue;
      if (entry.value > topCount) {
        topCode = entry.key;
        topCount = entry.value;
      }
    }
    if (topCode == null || topCount < 2) return null;
    final String? label = cueLabel(topCode);
    if (label == null) return null;
    final String times = topCount == 2 ? 'twice' : '$topCount times';
    return 'Live guidance to $label came up $times.';
  }

  static String _titleFor(String exerciseId) {
    try {
      return motionExerciseById(exerciseId).title;
    } on ArgumentError {
      // A history entry written by a newer build may name an exercise this
      // one does not ship; the id is still better than an empty row.
      return exerciseId;
    }
  }
}

/// Per-repetition evidence: what was measured, movement by movement.
///
/// This is the detailed-feedback half of the coach's purpose. Every chip and
/// sentence is an engine measurement or a deterministic restatement of one;
/// nothing is generated or judged in the UI.
class _StepEvidence extends StatelessWidget {
  const _StepEvidence({required this.step});

  final MotionSessionStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool alternating = step.repetitions.any(
      (MotionSessionRep rep) => rep.side != 'both',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 6),
        Text(
          'Movement by movement',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final MotionSessionRep rep in step.repetitions)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rep.index}'
                  '${alternating ? (rep.side == 'left' ? ' L' : ' R') : ''}'
                  ' · ${rep.romPctOfReference.round()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Each chip is one complete movement and its measured size as a '
          'percentage of the exercise reference.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        for (final String statement in step.evidenceStatements)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.straighten_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statement,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ComponentBar extends StatelessWidget {
  const _ComponentBar({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final rounded = '${value!.round()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Semantics(
        label: '$label, $rounded out of 100',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  rounded,
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (value! / 100).clamp(0.0, 1.0),
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: colors.surfaceVariant,
              color: colors.navSelected,
            ),
          ],
        ),
      ),
    );
  }
}
