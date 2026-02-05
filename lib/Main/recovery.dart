import 'package:flutter/material.dart';

import '../Recovery/exercise.dart';
import '../Recovery/speech.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_animation),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recovery Journey',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exercise and therapy to support your health',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Progress stats
          _buildAnimatedCard(
            delay: 0.1,
            child: _ProgressCard(
              exercises: singleton.exerNum,
              colors: colors,
            ),
          ),
          const SizedBox(height: 24),

          // Speech Therapy Card
          _buildAnimatedCard(
            delay: 0.2,
            child: _RecoveryFeatureCard(
              icon: Icons.record_voice_over_rounded,
              iconColor: colors.info,
              title: 'Speech Therapy',
              subtitle: 'Audio exercises to improve speech clarity and strength',
              features: const [
                'Voice exercises',
                'Pronunciation practice',
                'Breathing techniques',
              ],
              gradientColors: [
                colors.info.withValues(alpha: 0.15),
                colors.info.withValues(alpha: 0.05),
              ],
              onTap: () {
                HapticUtils.cardTap();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SpeechScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Exercise Card
          _buildAnimatedCard(
            delay: 0.3,
            child: _RecoveryFeatureCard(
              icon: Icons.fitness_center_rounded,
              iconColor: colors.success,
              title: 'Physical Exercises',
              subtitle: 'Video-guided exercises for mobility and strength',
              features: const [
                'Stretching routines',
                'Balance training',
                'Strength exercises',
              ],
              gradientColors: [
                colors.success.withValues(alpha: 0.15),
                colors.success.withValues(alpha: 0.05),
              ],
              onTap: () {
                HapticUtils.cardTap();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ExerciseScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Motivation section
          FadeTransition(
            opacity: _animation,
            child: Text(
              'Daily Motivation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          _buildAnimatedCard(
            delay: 0.4,
            child: _MotivationCard(colors: colors),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        )),
        child: child,
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
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primary,
          colors.primaryDark,
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Going!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve completed $exercises exercises',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: exercises > 0 ? (exercises / 10).clamp(0.0, 1.0) : 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '$exercises',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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

class _RecoveryFeatureCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> features;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RecoveryFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_RecoveryFeatureCard> createState() => _RecoveryFeatureCardState();
}

class _RecoveryFeatureCardState extends State<_RecoveryFeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0, _isPressed ? 0.98 : 1.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.iconColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.iconColor.withValues(alpha: _isPressed ? 0.05 : 0.1),
              blurRadius: _isPressed ? 8 : 20,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.textTertiary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.iconColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: widget.iconColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        feature,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final AppColors colors;

  const _MotivationCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: colors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Small steps every day lead to big results."',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep pushing forward!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
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
