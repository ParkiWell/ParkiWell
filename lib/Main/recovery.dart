import 'package:flutter/material.dart';

import '../Recovery/exercise.dart';
import '../Recovery/speech.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/app_routes.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class RecoveryScreen extends StatefulWidget {
  final GlobalKey? exerciseCardKey;

  const RecoveryScreen({super.key, this.exerciseCardKey});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final singleton = Singleton();

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
              Text(
                'Exercise and therapy to support your health',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),

              // Progress stats
              _ProgressCard(
                exercises: singleton.exerNum,
                colors: colors,
              ),
              const SizedBox(height: 24),

              // Therapy options
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Therapy',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              // Speech Therapy Card
              _RecoveryFeatureCard(
                icon: Icons.mic_outlined,
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
              const SizedBox(height: 8),

              // Exercise Card
              _RecoveryFeatureCard(
                key: widget.exerciseCardKey,
                icon: Icons.fitness_center_outlined,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int exercises;
  final AppColors colors;

  const _ProgressCard({
    required this.exercises,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$exercises exercises completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecoveryFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
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
