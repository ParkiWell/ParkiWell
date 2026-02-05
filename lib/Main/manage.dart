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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
          const SizedBox(height: 24),

          // Symptom Log Card
          _ManageFeatureCard(
            icon: Icons.favorite_outline,
            title: 'Symptom Log',
            subtitle: 'Track and monitor your daily symptoms',
            statValue: '${singleton.log.length}',
            statLabel: 'entries',
            onTap: () {
              HapticUtils.lightImpact();
              Navigator.pushNamed(context, '/logScreen');
            },
          ),
          const SizedBox(height: 12),

          // Medication Card
          _ManageFeatureCard(
            icon: Icons.medication_outlined,
            title: 'Medications',
            subtitle: 'Set reminders and track your medications',
            statValue: '${singleton.schedule.length}',
            statLabel: 'scheduled',
            onTap: () {
              HapticUtils.lightImpact();
              Navigator.pushNamed(context, '/scheduleScreen');
            },
          ),
          const SizedBox(height: 24),

          // Tips section
          Text(
            'Tips',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),

          _TipCard(
            icon: Icons.lightbulb_outline,
            title: 'Regular Tracking',
            description:
                'Log symptoms at the same time each day for more accurate tracking.',
          ),
          const SizedBox(height: 8),

          _TipCard(
            icon: Icons.alarm_outlined,
            title: 'Medication Reminders',
            description:
                'Set up your medication schedule to never miss a dose.',
          ),
          const SizedBox(height: 24),
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
                        fontWeight: FontWeight.w500,
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

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textTertiary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
}
