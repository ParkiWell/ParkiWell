import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../Recovery/exercise.dart';
import '../Recovery/speech.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/app_routes.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';
import '../widgets/pressable_scale.dart';

enum _RecoveryChartPeriod { week, month, year }

extension _RecoveryChartPeriodLabel on _RecoveryChartPeriod {
  String get label {
    switch (this) {
      case _RecoveryChartPeriod.week:
        return 'Week';
      case _RecoveryChartPeriod.month:
        return 'Month';
      case _RecoveryChartPeriod.year:
        return 'Year';
    }
  }
}

class RecoveryScreen extends StatefulWidget {
  final GlobalKey? exerciseCardKey;

  const RecoveryScreen({super.key, this.exerciseCardKey});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final singleton = Singleton();
  _RecoveryChartPeriod _selectedPeriod = _RecoveryChartPeriod.week;

  // Snapshot the least-practiced picks once per visit; recomputing on every
  // logged session would reshuffle the rows mid-interaction.
  late final List<({String videoId, String type})> _recommendedWorkouts = [
    ...singleton.recommendedPhysicalExerciseIds(limit: 2).map(
          (id) => (videoId: id, type: Singleton.recoveryTypePhysical),
        ),
    ...singleton.recommendedSpeechExerciseIds(limit: 1).map(
          (id) => (videoId: id, type: Singleton.recoveryTypeSpeech),
        ),
  ];

  @override
  void initState() {
    super.initState();
    singleton.addListener(_onSingletonUpdate);
  }

  @override
  void dispose() {
    singleton.removeListener(_onSingletonUpdate);
    super.dispose();
  }

  void _onSingletonUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox.expand(
      child: Container(
        color: colors.background,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Therapy',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              _RecoveryFeatureCard(
                icon: Icons.record_voice_over_rounded,
                accent: colors.primary,
                title: 'Speech Therapy',
                subtitle:
                    'Video exercises to improve speech clarity and strength',
                onTap: () {
                  HapticUtils.lightImpact();
                  Navigator.of(context).push(
                    buildSubtleFadeRoute(page: const SpeechScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              _RecoveryFeatureCard(
                cardKey: widget.exerciseCardKey,
                icon: Icons.fitness_center_rounded,
                accent: colors.secondary,
                title: 'Physical Exercises',
                subtitle: 'Video-guided exercises for mobility and strength',
                onTap: () {
                  HapticUtils.lightImpact();
                  Navigator.of(context).push(
                    buildSubtleFadeRoute(page: const ExerciseScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Exercise and therapy to support your health',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              _GoalProgressCard(
                singleton: singleton,
                colors: colors,
                onGoalChanged: (speechGoal, physicalGoal) {
                  singleton.setTherapyGoals(
                    weeklySpeech: speechGoal,
                    weeklyPhysical: physicalGoal,
                  );
                },
              ),
              const SizedBox(height: 18),
              _TherapyTrackingChart(
                singleton: singleton,
                period: _selectedPeriod,
                onPeriodChanged: (period) {
                  HapticUtils.selectionClick();
                  setState(() => _selectedPeriod = period);
                },
              ),
              const SizedBox(height: 18),
              _RecommendedWorkoutsCard(
                singleton: singleton,
                picks: _recommendedWorkouts,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final Singleton singleton;
  final AppColors colors;
  final void Function(int speechGoal, int physicalGoal) onGoalChanged;

  const _GoalProgressCard({
    required this.singleton,
    required this.colors,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final speechGoal = singleton.weeklySpeechExerciseGoal;
    final physicalGoal = singleton.weeklyPhysicalExerciseGoal;
    final weeklySpeech = singleton.weeklySpeechExerciseSessions;
    final weeklyPhysical = singleton.weeklyPhysicalExerciseSessions;
    final totalGoal = speechGoal + physicalGoal;
    final totalDone = weeklySpeech + weeklyPhysical;
    final progress =
        totalGoal == 0 ? 0.0 : (totalDone / totalGoal).clamp(0, 1).toDouble();

    return ModernCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Goals',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalGoal == 0
                          ? 'Set a weekly target for speech and movement.'
                          : '$totalDone of $totalGoal sessions this week',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface.blend(colors.primary, 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.border.blend(colors.primary, 0.4),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    '${(progress * 100).round()}%',
                    key: ValueKey<int>((progress * 100).round()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalRow(
            colors: colors,
            icon: Icons.record_voice_over_rounded,
            title: 'Speech',
            accent: colors.primary,
            completed: weeklySpeech,
            goal: speechGoal,
            onDecrease: () => onGoalChanged(
              math.max(0, speechGoal - 1),
              physicalGoal,
            ),
            onIncrease: () => onGoalChanged(speechGoal + 1, physicalGoal),
          ),
          const SizedBox(height: 14),
          _GoalRow(
            colors: colors,
            icon: Icons.fitness_center_rounded,
            title: 'Physical',
            accent: colors.secondary,
            completed: weeklyPhysical,
            goal: physicalGoal,
            onDecrease: () => onGoalChanged(
              speechGoal,
              math.max(0, physicalGoal - 1),
            ),
            onIncrease: () => onGoalChanged(speechGoal, physicalGoal + 1),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String title;
  final Color accent;
  final int completed;
  final int goal;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _GoalRow({
    required this.colors,
    required this.icon,
    required this.title,
    required this.accent,
    required this.completed,
    required this.goal,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        goal == 0 ? 0.0 : (completed / goal).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal == 0
                        ? '$completed sessions this week'
                        : '$completed of $goal this week',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            _GoalStepperButton(
              icon: Icons.remove_rounded,
              colors: colors,
              onTap: onDecrease,
            ),
            SizedBox(
              width: 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Text(
                  '$goal',
                  key: ValueKey<int>(goal),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            _GoalStepperButton(
              icon: Icons.add_rounded,
              colors: colors,
              onTap: onIncrease,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: child,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalStepperButton extends StatelessWidget {
  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  const _GoalStepperButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.86,
      onTap: () {
        HapticUtils.selectionClick();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }
}

class _TherapyTrackingChart extends StatelessWidget {
  final Singleton singleton;
  final _RecoveryChartPeriod period;
  final ValueChanged<_RecoveryChartPeriod> onPeriodChanged;

  const _TherapyTrackingChart({
    required this.singleton,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final data = _buildChartData();
    final hasData = data.physical.any((value) => value > 0) ||
        data.speech.any((value) => value > 0);

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.chartLine.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: colors.chartLine,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Therapy Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _RecoveryChartPeriod.values.map((option) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == _RecoveryChartPeriod.values.last ? 0 : 8,
                  ),
                  child: _PeriodChip(
                    label: option.label,
                    selected: option == period,
                    colors: colors,
                    onTap: () => onPeriodChanged(option),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _LegendItem(
                color: colors.secondary,
                label: 'Physical',
                colors: colors,
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: colors.primary,
                label: 'Speech',
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 18),
          hasData
              ? SizedBox(
                  height: 210,
                  child: LineChart(
                    _chartData(context, data),
                    duration: const Duration(milliseconds: 300),
                  ),
                )
              : Container(
                  height: 210,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 44,
                        color: colors.textTertiary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Log sessions to see therapy trends',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  _ChartData _buildChartData() {
    final now = DateTime.now();
    final labels = <String>[];
    final starts = <DateTime>[];
    final ends = <DateTime>[];

    switch (period) {
      case _RecoveryChartPeriod.week:
        final today = DateTime(now.year, now.month, now.day);
        final start =
            today.subtract(Duration(days: today.weekday - DateTime.monday));
        const dayLabels = <String>[
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun'
        ];
        for (var index = 0; index < 7; index += 1) {
          labels.add(dayLabels[index]);
          starts.add(start.add(Duration(days: index)));
          ends.add(start.add(Duration(days: index + 1)));
        }
        break;
      case _RecoveryChartPeriod.month:
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        for (var day = 1; day <= daysInMonth; day += 1) {
          labels.add(day.toString());
          starts.add(DateTime(now.year, now.month, day));
          ends.add(DateTime(now.year, now.month, day + 1));
        }
        break;
      case _RecoveryChartPeriod.year:
        const monthLabels = <String>[
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        for (var month = 1; month <= 12; month += 1) {
          labels.add(monthLabels[month - 1]);
          starts.add(DateTime(now.year, month));
          ends.add(DateTime(now.year, month + 1));
        }
        break;
    }

    final physical = List<double>.filled(labels.length, 0);
    final speech = List<double>.filled(labels.length, 0);

    for (final session in singleton.recoverySessions) {
      final type = session['type']?.toString();
      final completedAt =
          DateTime.tryParse(session['completed_at']?.toString() ?? '')
              ?.toLocal();
      if (completedAt == null) continue;

      for (var index = 0; index < starts.length; index += 1) {
        if (completedAt.isBefore(starts[index]) ||
            !completedAt.isBefore(ends[index])) {
          continue;
        }
        if (type == Singleton.recoveryTypePhysical) {
          physical[index] += 1;
        } else if (type == Singleton.recoveryTypeSpeech) {
          speech[index] += 1;
        }
        break;
      }
    }

    return _ChartData(labels: labels, physical: physical, speech: speech);
  }

  LineChartData _chartData(BuildContext context, _ChartData data) {
    final colors = context.colors;
    final allValues = <double>[...data.physical, ...data.speech];
    final maxValue = allValues.isEmpty ? 0.0 : allValues.reduce(math.max);
    final maxY = maxValue > 0 ? maxValue + 1 : 4.0;
    final yInterval = math.max(1, (maxY / 5).ceil()).toDouble();

    return LineChartData(
      minX: 0,
      maxX: (data.labels.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: colors.divider.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 1),
          left: BorderSide(color: colors.divider, width: 1),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.labels.length) {
                return const SizedBox.shrink();
              }
              if (!_shouldShowBottomLabel(index, data.labels.length)) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 10,
                child: Text(
                  data.labels[index],
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchSpotThreshold: 24,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: barData.color!.withValues(alpha: 0.35),
                strokeWidth: 2,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, i) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: bar.color!,
                    strokeWidth: 2.5,
                    strokeColor: colors.surface,
                  );
                },
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => colors.surface,
          tooltipRoundedRadius: 12,
          tooltipPadding: const EdgeInsets.all(12),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final label = spot.barIndex == 0 ? 'Physical' : 'Speech';
              final color =
                  spot.barIndex == 0 ? colors.secondary : colors.primary;
              return LineTooltipItem(
                '${spot.y.toInt()} $label',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        _lineBar(colors.secondary, data.physical, colors.surface),
        _lineBar(colors.primary, data.speech, colors.surface),
      ],
    );
  }

  bool _shouldShowBottomLabel(int index, int count) {
    switch (period) {
      case _RecoveryChartPeriod.week:
        return true;
      case _RecoveryChartPeriod.month:
        return index == 0 ||
            index == 7 ||
            index == 14 ||
            index == 21 ||
            index == count - 1;
      case _RecoveryChartPeriod.year:
        return index == 0 ||
            index == 3 ||
            index == 6 ||
            index == 9 ||
            index == 11;
    }
  }

  LineChartBarData _lineBar(
    Color color,
    List<double> values,
    Color strokeColor,
  ) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      // Dots stay hidden until the user slides over the chart; the touch
      // indicator then draws the dot and the tooltip shows its value.
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
    );
  }
}

class _ChartData {
  final List<String> labels;
  final List<double> physical;
  final List<double> speech;

  const _ChartData({
    required this.labels,
    required this.physical,
    required this.speech,
  });
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.textOnPrimary : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final AppColors colors;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _RecommendedWorkoutsCard extends StatelessWidget {
  final Singleton singleton;
  final List<({String videoId, String type})> picks;

  const _RecommendedWorkoutsCard({
    required this.singleton,
    required this.picks,
  });

  void _showLoggedSnack(
    BuildContext context,
    AppColors colors,
    String title,
    int count,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: colors.surface.blend(colors.success, 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border.blend(colors.success, 0.45)),
          ),
          content: Text(
            '$title logged. Completed $count time${count == 1 ? '' : 's'}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recommendations = picks.map((pick) {
      final isPhysical = pick.type == Singleton.recoveryTypePhysical;
      final data = isPhysical
          ? singleton.exercises[pick.videoId]!
          : singleton.speeches[pick.videoId]!;
      return _RecommendationItem(
        videoId: pick.videoId,
        type: pick.type,
        title: data[0],
        detail: data.length > 2 ? data[2] : (isPhysical ? 'Exercise' : 'Speech'),
        icon: isPhysical
            ? Icons.fitness_center_rounded
            : Icons.record_voice_over_rounded,
        accent: isPhysical ? colors.secondary : colors.primary,
        count: isPhysical
            ? singleton.exerciseSessionCountForVideo(pick.videoId)
            : singleton.speechSessionCountForVideo(pick.videoId),
      );
    }).toList();

    return ModernCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended Workouts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suggested from sessions you have practiced least.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < recommendations.length; index += 1) ...[
            _RecommendedWorkoutRow(
              item: recommendations[index],
              colors: colors,
              onStart: () {
                HapticUtils.cardTap();
                singleton.setCurrentUrl(recommendations[index].videoId);
                Navigator.of(context).pushNamed(
                  recommendations[index].type == Singleton.recoveryTypePhysical
                      ? '/exerciseVideoScreen'
                      : '/speechAudio',
                );
              },
              onLog: () {
                HapticUtils.success();
                final int count;
                if (recommendations[index].type ==
                    Singleton.recoveryTypePhysical) {
                  count = singleton.recordPhysicalExerciseSession(
                    recommendations[index].videoId,
                  );
                } else {
                  count = singleton.recordSpeechExerciseSession(
                    recommendations[index].videoId,
                  );
                }
                _showLoggedSnack(
                  context,
                  colors,
                  recommendations[index].title,
                  count,
                );
              },
            ),
            if (index != recommendations.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RecommendationItem {
  final String videoId;
  final String type;
  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final int count;

  const _RecommendationItem({
    required this.videoId,
    required this.type,
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.count,
  });
}

class _RecommendedWorkoutRow extends StatelessWidget {
  final _RecommendationItem item;
  final AppColors colors;
  final VoidCallback onStart;
  final VoidCallback onLog;

  const _RecommendedWorkoutRow({
    required this.item,
    required this.colors,
    required this.onStart,
    required this.onLog,
  });

  String get _typeLabel =>
      item.type == Singleton.recoveryTypePhysical ? 'Physical' : 'Speech';

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.975,
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            _WorkoutThumbnail(item: item, colors: colors),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(item.icon, size: 13, color: item.accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$_typeLabel - ${item.detail}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      item.count == 0
                          ? 'Not logged yet'
                          : '${item.count}x logged',
                      key: ValueKey<int>(item.count),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: item.count == 0
                                ? colors.textTertiary
                                : item.accent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuickLogButton(
              accent: item.accent,
              colors: colors,
              onLog: onLog,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutThumbnail extends StatelessWidget {
  final _RecommendationItem item;
  final AppColors colors;

  const _WorkoutThumbnail({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 60,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/${item.videoId}/mqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: item.accent.withValues(alpha: 0.12),
                child: Icon(item.icon, color: item.accent, size: 24),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: colors.surfaceVariant);
              },
            ),
            Container(color: Colors.black.withValues(alpha: 0.16)),
            Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular quick-log button that flashes a checkmark after each tap.
class _QuickLogButton extends StatefulWidget {
  final Color accent;
  final AppColors colors;
  final VoidCallback onLog;

  const _QuickLogButton({
    required this.accent,
    required this.colors,
    required this.onLog,
  });

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton> {
  bool _flash = false;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    widget.onLog();
    setState(() => _flash = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log a session',
      child: PressableScale(
        pressedScale: 0.8,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _flash ? widget.colors.success : widget.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _flash
                  ? widget.colors.success
                  : widget.colors.border.blend(widget.accent, 0.45),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              _flash ? Icons.check_rounded : Icons.add_rounded,
              key: ValueKey<bool>(_flash),
              color: _flash ? Colors.white : widget.accent,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final GlobalKey? cardKey;

  const _RecoveryFeatureCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      key: cardKey,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
