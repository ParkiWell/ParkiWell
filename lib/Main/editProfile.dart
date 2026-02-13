import 'package:flutter/material.dart';

import '../navbar.dart';
import '../singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const EditProfileScreen({super.key, this.onComplete});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final singleton = Singleton();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  String image = 'images/711128.png';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // From onboarding: go straight to sign-in (Google only).
    if (widget.onComplete != null) {
      _step = 1;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isLoading) return;

    if (!singleton.isCloudConfigured) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Google sign-in requires cloud backend configuration.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _isGoogleLoading = true);
    HapticUtils.mediumImpact();

    try {
      final profile = await singleton.signInWithGoogle();
      if (profile == null) {
        throw Exception('Google sign-in was cancelled or could not complete.');
      }

      final resolvedEmail =
          (profile.email != null && profile.email!.trim().isNotEmpty)
              ? profile.email!.trim()
              : null;
      if (resolvedEmail == null || !resolvedEmail.contains('@')) {
        throw Exception(
          'Please use a Google account with an email address to sign in.',
        );
      }

      final fallbackName = resolvedEmail.split('@').first;
      final resolvedName =
          (profile.fullName != null && profile.fullName!.trim().isNotEmpty)
              ? profile.fullName!.trim()
              : fallbackName;

      _nameController.text = resolvedName;
      _emailController.text = resolvedEmail;

      final synced = await singleton.createOrSyncAuthenticatedUser(
        displayName: resolvedName,
        userEmail: resolvedEmail,
        profileImage: image,
      );
      if (!synced) {
        throw Exception('Unable to complete account sync.');
      }

      singleton.setFirstTime(false);
      widget.onComplete?.call();

      if (!mounted) return;
      HapticUtils.success();

      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Navbar()),
        (route) => false,
      );
    } catch (e) {
      HapticUtils.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _goToForm() {
    HapticUtils.selectionClick();
    setState(() => _step = 1);
  }

  void _goBack() {
    HapticUtils.selectionClick();
    setState(() => _step = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(colors.background, colors.primaryLight, 0.1)!,
                colors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildTopBar(colors),
                  const SizedBox(height: 18),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.02, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _step == 0
                          ? _buildWelcomeStep(colors)
                          : _buildSignInStep(colors),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBottomActions(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppColors colors) {
    return Row(
      children: [
        if (_step == 1)
          IconButton(
            onPressed: _goBack,
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: colors.surface.withValues(alpha: 0.8),
            ),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                _step == 0 ? 'Welcome' : 'Sign In',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final isActive = index <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildWelcomeStep(AppColors colors) {
    return SingleChildScrollView(
      key: const ValueKey('welcome_step'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Sign in to Levio',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your care space in under a minute. Sign in with Google to sync your data to the cloud.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          ModernCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Image.asset(
                      'images/logo.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.health_and_safety_rounded,
                        color: colors.primary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personalized, calm, and consistent',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Levio organizes symptoms, meds, speech, and movement in one place.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBulletCard(
            colors,
            icon: Icons.shield_outlined,
            title: 'Secure in the cloud',
            subtitle:
                'Your profile and data sync with an authenticated Google account.',
          ),
          const SizedBox(height: 10),
          _buildBulletCard(
            colors,
            icon: Icons.track_changes_outlined,
            title: 'Actionable tracking',
            subtitle: 'Capture symptoms and routines for clearer patterns.',
          ),
          const SizedBox(height: 10),
          _buildBulletCard(
            colors,
            icon: Icons.favorite_outline,
            title: 'Supportive community',
            subtitle: 'Share safely with moderated posts and comments.',
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildBulletCard(
    AppColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  Widget _buildSignInStep(AppColors colors) {
    final cloudReady = singleton.isCloudConfigured;
    return SingleChildScrollView(
      key: const ValueKey('signin_step'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'Finish your account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your Google account to continue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: (cloudReady && !_isGoogleLoading && !_isLoading)
                  ? _signInWithGoogle
                  : null,
              icon: _isGoogleLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.textOnPrimary),
                      ),
                    )
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.textOnPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textOnPrimary,
                                  ),
                        ),
                      ),
                    ),
              label: Text(
                _isGoogleLoading
                    ? 'Connecting…'
                    : 'Continue with Google',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textOnPrimary,
                    ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (!cloudReady) ...[
            const SizedBox(height: 16),
            Text(
              'Cloud backend must be configured to sign in.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppColors colors) {
    if (_step == 0) {
      return SizedBox(
        width: double.infinity,
        child: ModernButton(
          text: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _goToForm,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ModernButton(
        text: 'Back',
        isOutlined: true,
        onPressed: _goBack,
      ),
    );
  }
}
