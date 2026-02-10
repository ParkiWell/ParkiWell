import 'package:flutter/material.dart';

import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  final singleton = Singleton();

  int _medicationsDueToday() {
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final today = weekdays[DateTime.now().weekday - 1];
    var count = 0;
    for (final entry in singleton.schedule) {
      if (entry.length < 3) continue;
      final scheduleText = entry[2];
      if (scheduleText == 'Everyday' || scheduleText.contains(today)) {
        count += 1;
      }
    }
    return count;
  }

  int _currentLogStreak() {
    if (singleton.log.isEmpty) return 0;

    final dateKeys = singleton.log
        .map((entry) => entry.isNotEmpty ? _extractDateKey(entry[0]) : null)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (dateKeys.isEmpty) return 0;

    var cursor = DateTime.now();
    if (!dateKeys.contains(_toDateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (dateKeys.contains(_toDateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _extractDateKey(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return _toDateKey(DateTime.now());
    final date = parts.last.trim().split(' ');
    if (date.length != 3) return _toDateKey(DateTime.now());

    const months = <String, int>{
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    final day = int.tryParse(date[0]);
    final month = months[date[1]];
    final year = int.tryParse(date[2]);
    if (day == null || month == null || year == null) {
      return _toDateKey(DateTime.now());
    }

    return _toDateKey(DateTime(year, month, day));
  }

  String _toDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dueToday = _medicationsDueToday();
    final streak = _currentLogStreak();
    final totalLogs = singleton.log.length;
    final totalMeds = singleton.schedule.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track symptoms and manage medications',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          ModernCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today at a glance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InsightChip(
                        label: 'Symptom logs',
                        value: '$totalLogs',
                        icon: Icons.favorite_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightChip(
                        label: 'Meds today',
                        value: '$dueToday',
                        icon: Icons.medication_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InsightChip(
                        label: 'Streak',
                        value: '${streak}d',
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.insights_outlined, color: colors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    totalLogs == 0
                        ? 'Start with your first symptom log to unlock trend insights.'
                        : 'Great consistency. Keep logging symptoms and medication timing for clearer trend analysis.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_chart_rounded,
                  label: 'Log Symptom',
                  onTap: () {
                    HapticUtils.lightImpact();
                    Navigator.pushNamed(context, '/editLogScreen');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_alarm_rounded,
                  label: 'Add Med',
                  onTap: () {
                    HapticUtils.lightImpact();
                    Navigator.pushNamed(context, '/editScheduleScreen');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'View Trends',
                  onTap: () {
                    HapticUtils.lightImpact();
                    Navigator.pushNamed(context, '/');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ManageFeatureCard(
            icon: Icons.favorite_outline,
            title: 'Symptom Log',
            subtitle: 'Track and monitor your daily symptoms',
            statValue: '$totalLogs',
            statLabel: 'entries',
            onTap: () {
              HapticUtils.lightImpact();
              Navigator.pushNamed(context, '/logScreen');
            },
          ),
          const SizedBox(height: 12),
          _ManageFeatureCard(
            icon: Icons.medication_outlined,
            title: 'Medications',
            subtitle: 'Set reminders and track your medications',
            statValue: '$totalMeds',
            statLabel: 'scheduled',
            onTap: () {
              HapticUtils.lightImpact();
              Navigator.pushNamed(context, '/scheduleScreen');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textSecondary, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ManageFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statValue;
  final String statLabel;
  final VoidCallback onTap;

  const _ManageFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statValue,
    required this.statLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.textSecondary,
            size: 22,
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
                        color: colors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$statValue $statLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
