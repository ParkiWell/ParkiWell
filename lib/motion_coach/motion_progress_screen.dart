import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import 'motion_coach_layout.dart';
import 'motion_exercise_catalog.dart';
import 'motion_routine_results_screen.dart';
import 'motion_session_history.dart';

/// Trends across saved routine sessions.
///
/// Everything shown is a score the engine already produced; this screen only
/// orders and averages them. It also owns the delete control, because a
/// local record the person cannot remove is not really local-only.
class MotionProgressScreen extends StatefulWidget {
  const MotionProgressScreen({super.key, required this.history});

  final MotionSessionHistory history;

  @override
  State<MotionProgressScreen> createState() => _MotionProgressScreenState();
}

class _MotionProgressScreenState extends State<MotionProgressScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _clearing = false;
  final GlobalKey _actionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      await widget.history.load();
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    HapticUtils.lightImpact();
    try {
      final anchor = _actionsKey.currentContext?.findRenderObject();
      final origin = anchor is RenderBox && anchor.hasSize
          ? anchor.localToGlobal(Offset.zero) & anchor.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          text: widget.history.exportJson(),
          subject: 'ParkiWell movement history',
          sharePositionOrigin: origin,
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to export your history right now.'),
        ),
      );
    }
  }

  Future<void> _confirmClear() async {
    final bool? clear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete movement history?'),
        content: const Text(
          'Every saved score will be removed from this device and, if you '
          'use account backup, deleted from your account as well. This '
          'cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) return;
    setState(() => _clearing = true);
    HapticUtils.mediumImpact();
    try {
      await Singleton().deleteAllMotionSessions(history: widget.history);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete history. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.history.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement progress'),
        actions: [
          if (!_loading && !_loadFailed && entries.isNotEmpty)
            PopupMenuButton<bool>(
              key: _actionsKey,
              tooltip: 'Manage movement history',
              enabled: !_clearing,
              onSelected: (export) =>
                  unawaited(export ? _export() : _confirmClear()),
              itemBuilder: (context) => const [
                PopupMenuItem(value: true, child: Text('Export history')),
                PopupMenuItem(value: false, child: Text('Delete history')),
              ],
            ),
        ],
      ),
      body: _loading || _clearing
          ? Center(
              child: CircularProgressIndicator(
                semanticsLabel: _clearing
                    ? 'Deleting history'
                    : 'Loading history',
              ),
            )
          : _loadFailed
          ? MotionScreenScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MotionSectionTitle(
                    title: 'History could not be loaded',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => unawaited(_load()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            )
          : entries.isEmpty
          ? _buildEmpty(context)
          : _buildContent(context, entries),
      bottomNavigationBar:
          !_loading && !_clearing && !_loadFailed && entries.isEmpty
          ? MotionActionBar(
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                child: const Text('Back to Motion coach'),
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return MotionScreenScroll(
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_rounded, size: 42, color: colors.navSelected),
            const SizedBox(height: 14),
            const MotionSectionTitle(
              title: 'No sessions yet',
              description:
                  'Your movement results will appear here after your first '
                  'guided routine or single-exercise practice.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<MotionSessionRecord> entries,
  ) {
    final colors = context.colors;
    final double? recent = widget.history.recentAverageScore();
    final Set<String> practised = <String>{
      for (final MotionSessionRecord entry in entries)
        for (final MotionSessionStep step in entry.steps)
          if (step.overallScore != null) step.exerciseId,
    };

    final stats = [
      _Statistic(label: 'Sessions', value: '${entries.length}'),
      _Statistic(
        label: 'Recent average',
        value: recent == null ? '—' : '${recent.round()}',
      ),
      _Statistic(
        label: 'Day streak',
        value: '${widget.history.currentStreakDays()}',
      ),
      _Statistic(
        label: 'This week',
        value: '${widget.history.sessionsInLastWeek()}',
      ),
    ];

    return MotionScreenScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MotionSectionTitle(title: 'Your practice'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 14.0;
                  final scaled = MediaQuery.textScalerOf(context).scale(16);
                  final columns = constraints.maxWidth >= 450 && scaled <= 20
                      ? 4
                      : constraints.maxWidth < 170
                      ? 1
                      : 2;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final stat in stats)
                        SizedBox(width: width, child: stat),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const MotionSectionTitle(title: 'Sessions'),
          const SizedBox(height: 9),
          for (final entry in entries)
            _SessionRow(
              entry: entry,
              onTap: () {
                HapticUtils.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MotionRoutineResultsScreen(
                      title: entry.routineName,
                      record: entry,
                      history: widget.history,
                    ),
                  ),
                );
              },
            ),
          if (practised.isNotEmpty) ...[
            const SizedBox(height: 24),
            const MotionSectionTitle(
              title: 'By exercise',
              description: 'Latest score and changes over time.',
            ),
            const SizedBox(height: 9),
            for (final exerciseId in practised)
              _ExerciseTrendCard(
                exerciseId: exerciseId,
                scores: widget.history.scoreTrendFor(exerciseId),
              ),
          ],
        ],
      ),
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.navSelected,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _ExerciseTrendCard extends StatelessWidget {
  const _ExerciseTrendCard({required this.exerciseId, required this.scores});

  final String exerciseId;
  final List<double> scores;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (scores.isEmpty) return const SizedBox.shrink();
    final double latest = scores.first;
    final double? previous = scores.length > 1 ? scores[1] : null;
    final double? change = previous == null ? null : latest - previous;

    String title;
    try {
      title = motionExerciseById(exerciseId).title;
    } on ArgumentError {
      title = exerciseId;
    }

    final text = Theme.of(context).textTheme;
    final detail =
        '${scores.length} scored '
        '${scores.length == 1 ? 'session' : 'sessions'}';
    final difference = change == null || change.abs() < 1
        ? null
        : '${change > 0 ? '+' : '−'}${change.abs().round()} since last score';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                detail,
                style: text.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${latest.round()} out of 100',
                    style: text.titleSmall?.copyWith(color: colors.navSelected),
                  ),
                  if (difference != null)
                    Text(
                      difference,
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (scores.length >= 2)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 72,
                        height: 24,
                        child: CustomPaint(
                          painter: _SparklinePainter(
                            scores: scores.reversed.toList(growable: false),
                            color: colors.navSelected,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.entry, required this.onTap});

  final MotionSessionRecord entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(entry.completedAt.toLocal());
    final score = entry.overallScore;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: onTap,
      title: Text(entry.routineName, style: text.titleSmall),
      subtitle: Text(
        '$date · ${entry.completedRepetitions} movements'
        '${entry.endedEarly ? ' · Ended early' : ''}'
        '${score == null ? '' : ' · Score ${score.round()}'}',
        style: text.bodySmall?.copyWith(color: colors.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
    );
  }
}

/// Single-series score trend, oldest to newest, on the fixed 0-100 score
/// scale so identical shapes always mean identical score movements.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.scores, required this.color});

  final List<double> scores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;
    // Inset so the end-point dot is not clipped by the canvas edge.
    final double plotWidth = size.width - 6;
    final double plotHeight = size.height - 6;
    final Paint line = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path();
    for (int index = 0; index < scores.length; index += 1) {
      final double x = 3 + plotWidth * index / (scores.length - 1);
      final double y =
          3 + plotHeight * (1 - (scores[index] / 100).clamp(0.0, 1.0));
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
    final double lastY =
        3 + plotHeight * (1 - (scores.last / 100).clamp(0.0, 1.0));
    canvas.drawCircle(Offset(3 + plotWidth, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.color != color || !listEquals(oldDelegate.scores, scores);
}
