import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
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
                    'Community',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with others on similar journeys',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Coming soon illustration
          FadeTransition(
            opacity: _animation,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_rounded,
                      size: 64,
                      color: colors.primary,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'We\'re building a supportive community where you can share experiences, ask questions, and connect with others.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Feature preview cards
          FadeTransition(
            opacity: _animation,
            child: Text(
              'What\'s Coming',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          _buildFeaturePreview(
            colors,
            Icons.forum_rounded,
            'Discussion Forums',
            'Share experiences and get advice from the community',
            colors.info,
          ),
          const SizedBox(height: 12),

          _buildFeaturePreview(
            colors,
            Icons.group_rounded,
            'Support Groups',
            'Join groups based on your specific needs',
            colors.success,
          ),
          const SizedBox(height: 12),

          _buildFeaturePreview(
            colors,
            Icons.event_rounded,
            'Events & Meetups',
            'Find local and virtual events to participate in',
            colors.warning,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview(
    AppColors colors,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
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
