import 'package:flutter/material.dart';
import 'package:levio/main.dart';
import 'package:terminate_restart/terminate_restart.dart';

import 'singleton.dart';
import 'theme/app_theme.dart';
import 'utils/haptic_utils.dart';
import 'widgets/modern_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final singleton = Singleton();
  bool theme = false;

  @override
  void initState() {
    super.initState();
    theme = singleton.colorMode == 1;
  }

  void _showDeleteAccountDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          title: const Text('Delete Account'),
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
                HapticUtils.lightImpact();
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
          if (mounted && c.mounted) {
            Navigator.pop(c);
            HapticUtils.lightImpact();
            await TerminateRestart.instance.restartApp(
              options: const TerminateRestartOptions(terminate: false),
            );
          }
        });

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              CircularProgressIndicator(
                color: colors.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 20),
              Text(
                'Deleting Account...',
                style: Theme.of(c).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
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
          icon: Icon(
            Icons.arrow_back,
            color: colors.textPrimary,
            size: 22,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: theme ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              title: 'Theme',
              subtitle: theme ? 'Dark mode' : 'Light mode',
              trailing: _buildThemeSwitch(colors),
            ),
            const SizedBox(height: 24),

            // About section
            Text(
              'About',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.info_outlined,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.textTertiary,
              ),
              onTap: () {
                HapticUtils.lightImpact();
                // Navigate to terms
              },
            ),
            const SizedBox(height: 8),

            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.textTertiary,
              ),
              onTap: () {
                HapticUtils.lightImpact();
                // Navigate to privacy
              },
            ),
            const SizedBox(height: 24),

            // Danger zone
            Text(
              'Danger Zone',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently delete all your data',
              iconColor: colors.error,
              onTap: _showDeleteAccountDialog,
            ),
            const SizedBox(height: 48),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Levio',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Parkinson\'s Care Management',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(AppColors colors) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          theme = !theme;
          singleton.switchColorTheme(theme);
        });
        // Delay navigation to show animation
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MyApp()),
              (r) => false,
            );
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme ? colors.primary : colors.border,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: theme ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? colors.textSecondary,
            size: 20,
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
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
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
