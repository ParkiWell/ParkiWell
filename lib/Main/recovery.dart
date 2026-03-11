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
                completed: singleton.completedRecoveryVideos,
                total: singleton.totalRecoveryVideos,
                progress: singleton.recoveryProgress,
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
                cardKey: widget.exerciseCardKey,
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
  final int completed;
  final int total;
  final double progress;
  final AppColors colors;

  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total < 0 ? 0 : total;
    final safeCompleted =
        safeTotal == 0 ? 0 : completed.clamp(0, safeTotal).toInt();
    final safeProgress = safeTotal == 0 ? 0.0 : progress.clamp(0.0, 1.0);
    final progressPercent = (safeProgress * 100).round();
    final remainingSessions = safeTotal - safeCompleted;

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
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$safeCompleted of $safeTotal sessions completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '$progressPercent%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: safeProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remainingSessions > 0
                ? '$remainingSessions session${remainingSessions == 1 ? '' : 's'} left in this set.'
                : 'All sessions completed. Keep your routine going.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
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
  final GlobalKey? cardKey;

  const _RecoveryFeatureCard({
    required this.icon,
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
