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

class _ManageScreenState extends State<ManageScreen>
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
                    'Manage Your Health',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track symptoms and manage your medications',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Symptom Log Card
          _buildAnimatedCard(
            delay: 0.1,
            child: _ManageFeatureCard(
              icon: Icons.favorite_rounded,
              iconColor: colors.primary,
              title: 'Symptom Log',
              subtitle: 'Track and monitor your daily symptoms',
              statValue: '${singleton.log.length}',
              statLabel: 'entries logged',
              gradientColors: [
                colors.primary.withValues(alpha: 0.1),
                colors.primary.withValues(alpha: 0.05),
              ],
              onTap: () {
                HapticUtils.cardTap();
                Navigator.pushNamed(context, '/logScreen');
              },
            ),
          ),
          const SizedBox(height: 16),

          // Medication Card
          _buildAnimatedCard(
            delay: 0.2,
            child: _ManageFeatureCard(
              icon: Icons.medication_rounded,
              iconColor: colors.secondary,
              title: 'Medications',
              subtitle: 'Set reminders and track your medications',
              statValue: '${singleton.schedule.length}',
              statLabel: 'medications scheduled',
              gradientColors: [
                colors.secondary.withValues(alpha: 0.1),
                colors.secondary.withValues(alpha: 0.05),
              ],
              onTap: () {
                HapticUtils.cardTap();
                Navigator.pushNamed(context, '/scheduleScreen');
              },
            ),
          ),
          const SizedBox(height: 32),

          // Tips section
          FadeTransition(
            opacity: _animation,
            child: Text(
              'Health Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          _buildAnimatedCard(
            delay: 0.3,
            child: _TipCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Regular Tracking',
              description:
                  'Log symptoms at the same time each day for more accurate tracking.',
              color: colors.warning,
            ),
          ),
          const SizedBox(height: 12),

          _buildAnimatedCard(
            delay: 0.4,
            child: _TipCard(
              icon: Icons.alarm_rounded,
              title: 'Medication Reminders',
              description:
                  'Set up your medication schedule to never miss a dose.',
              color: colors.info,
            ),
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

class _ManageFeatureCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String statValue;
  final String statLabel;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ManageFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.statValue,
    required this.statLabel,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ManageFeatureCard> createState() => _ManageFeatureCardState();
}

class _ManageFeatureCardState extends State<_ManageFeatureCard> {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.statValue,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.iconColor,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.statLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
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
            Row(
              children: [
                Text(
                  'View Details',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.iconColor,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
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
      ),
    );
  }
}
