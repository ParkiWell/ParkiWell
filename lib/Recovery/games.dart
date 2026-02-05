import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pushNamed(context, '/');
          },
        ),
        title: const Text('Games'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  size: 64,
                  color: colors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Fun cognitive games to help keep your mind sharp.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _GamePreviewItem(
                      icon: Icons.psychology_rounded,
                      title: 'Memory Match',
                      description: 'Train your memory with fun card games',
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    _GamePreviewItem(
                      icon: Icons.calculate_rounded,
                      title: 'Number Puzzles',
                      description: 'Challenge yourself with math puzzles',
                      color: colors.success,
                    ),
                    const SizedBox(height: 12),
                    _GamePreviewItem(
                      icon: Icons.pattern_rounded,
                      title: 'Pattern Recognition',
                      description: 'Spot the patterns and sequences',
                      color: colors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GamePreviewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _GamePreviewItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
