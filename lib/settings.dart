import 'package:flutter/material.dart';
import 'package:levio/main.dart';
import 'package:restart_app/restart_app.dart';

import 'singleton.dart';
import 'theme/app_theme.dart';
import 'utils/haptic_utils.dart';
import 'widgets/modern_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  bool theme = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    theme = singleton.colorMode == 1;

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

  void _showDeleteAccountDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: colors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
            style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticUtils.heavyImpact();
                Navigator.pop(c);
                _showDeletingDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletingDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        // Perform deletion
        Future.delayed(const Duration(seconds: 2), () async {
          await singleton.deleteAccount();
          if (mounted) {
            Navigator.pop(c);
            HapticUtils.success();
            Restart.restartApp();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: colors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Deleting Account...',
                style: Theme.of(c).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we remove your data',
                style: Theme.of(c).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MyApp()),
              (r) => false,
            );
          },
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            _buildAnimatedCard(
              delay: 0.1,
              child: _SettingsTile(
                icon: theme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: theme ? colors.primaryLight : colors.warning,
                title: 'Theme',
                subtitle: theme ? 'Dark mode' : 'Light mode',
                trailing: _buildThemeSwitch(colors),
              ),
            ),
            const SizedBox(height: 24),

            // About section
            FadeTransition(
              opacity: _animation,
              child: Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            _buildAnimatedCard(
              delay: 0.2,
              child: _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: colors.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
            ),
            const SizedBox(height: 12),

            _buildAnimatedCard(
              delay: 0.25,
              child: _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: colors.secondary,
                title: 'Terms of Service',
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.textTertiary,
                ),
                onTap: () {
                  HapticUtils.lightImpact();
                  // Navigate to terms
                },
              ),
            ),
            const SizedBox(height: 12),

            _buildAnimatedCard(
              delay: 0.3,
              child: _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: colors.success,
                title: 'Privacy Policy',
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.textTertiary,
                ),
                onTap: () {
                  HapticUtils.lightImpact();
                  // Navigate to privacy
                },
              ),
            ),
            const SizedBox(height: 32),

            // Danger zone
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            _buildAnimatedCard(
              delay: 0.4,
              child: _SettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: colors.error,
                title: 'Delete Account',
                subtitle: 'Permanently delete all your data',
                backgroundColor: colors.error.withOpacity(0.05),
                onTap: _showDeleteAccountDialog,
              ),
            ),
            const SizedBox(height: 48),

            // Footer
            FadeTransition(
              opacity: _animation,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: colors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Levio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your health companion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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

  Widget _buildThemeSwitch(AppColors colors) {
    return GestureDetector(
      onTap: () {
        HapticUtils.selectionClick();
        setState(() {
          theme = !theme;
          singleton.switchColorTheme(theme);
        });
        // Delay navigation to show animation
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (r) => false,
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: theme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              theme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 14,
              color: theme ? colors.primary : colors.warning,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      backgroundColor: backgroundColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
