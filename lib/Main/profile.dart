import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  String name = "[Name]";
  String email = "[Email]";
  String image = "images/711128.png";
  final picker = ImagePicker();
  String posts = "0";
  String exercises = "0";

  late AnimationController _animationController;
  late Animation<double> _animation;

  Future<void> updateImage() async {
    HapticUtils.lightImpact();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        image = pickedFile.path;
      });
      singleton.setImage(image);
      HapticUtils.success();
    }
  }

  @override
  void initState() {
    super.initState();
    image = singleton.image;
    name = singleton.name;
    email = singleton.email;
    posts = '${singleton.postNum}';
    exercises = '${singleton.exerNum}';

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

  Widget _buildProfileImage(AppColors colors) {
    if (image.startsWith('images/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        width: 112,
        height: 112,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(colors);
        },
      );
    } else {
      final file = File(image);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: 112,
          height: 112,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(colors);
          },
        );
      }
      return _buildDefaultAvatar(colors);
    }
  }

  Widget _buildDefaultAvatar(AppColors colors) {
    return Container(
      width: 112,
      height: 112,
      color: colors.surfaceVariant,
      child: Icon(
        Icons.person_rounded,
        size: 56,
        color: colors.textTertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_animation),
              child: _buildProfileHeader(colors),
            ),
          ),
          const SizedBox(height: 32),

          // Stats section
          _buildAnimatedCard(
            delay: 0.1,
            child: _buildStatsSection(colors),
          ),
          const SizedBox(height: 24),

          // Activity section
          FadeTransition(
            opacity: _animation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildAnimatedCard(
            delay: 0.2,
            child: _ActivityItem(
              icon: Icons.favorite_rounded,
              title: 'Symptoms Logged',
              value: '${singleton.log.length}',
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),

          _buildAnimatedCard(
            delay: 0.25,
            child: _ActivityItem(
              icon: Icons.medication_rounded,
              title: 'Medications Tracked',
              value: '${singleton.schedule.length}',
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 12),

          _buildAnimatedCard(
            delay: 0.3,
            child: _ActivityItem(
              icon: Icons.fitness_center_rounded,
              title: 'Exercises Completed',
              value: exercises,
              color: colors.success,
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

  Widget _buildProfileHeader(AppColors colors) {
    return Column(
      children: [
        // Profile image
        GestureDetector(
          onTap: updateImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primaryLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: Container(
                    width: 112,
                    height: 112,
                    color: colors.surface,
                    child: _buildProfileImage(colors),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.surface,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: colors.textOnPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Name
        Text(
          name == "[Name]" ? "Your Name" : name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 16,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(AppColors colors) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.messenger_rounded,
            value: posts,
            label: 'Posts',
            color: colors.info,
          ),
          Container(
            width: 1,
            height: 48,
            color: colors.divider,
          ),
          _StatItem(
            icon: Icons.directions_run_rounded,
            value: exercises,
            label: 'Exercises',
            color: colors.success,
          ),
          Container(
            width: 1,
            height: 48,
            color: colors.divider,
          ),
          _StatItem(
            icon: Icons.calendar_today_rounded,
            value: '${singleton.log.length + singleton.schedule.length}',
            label: 'Total Logs',
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
