import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Main/editProfile.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// Single onboarding screen: logo, message, loading animation, then continue to sign-in.
class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlowScreen({super.key, required this.onComplete});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadController;
  late AnimationController _pulseController;
  bool _showSignIn = false;
  bool _loadingDone = false;

  @override
  void initState() {
    super.initState();
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _loadController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _loadingDone = true);
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.lightColors.background,
      ),
    );
  }

  @override
  void dispose() {
    _loadController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _continueToSignIn() {
    HapticUtils.selectionClick();
    setState(() => _showSignIn = true);
  }

  void _skipToSignIn() {
    HapticUtils.lightImpact();
    setState(() => _showSignIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSignIn) {
      return EditProfileScreen(onComplete: widget.onComplete);
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                colors.background,
                colors.primaryLight,
                isDark ? 0.2 : 0.1,
              )!,
              Color.lerp(
                colors.background,
                colors.secondary.withValues(alpha: 0.08),
                isDark ? 0.12 : 0.05,
              )!,
              colors.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Levio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _skipToSignIn,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final t = _pulseController.value;
                          final scale = 0.96 + 0.08 * (1 - (t - 0.5).abs() * 2);
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            isDark ? 'images/app_icon.png' : 'images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.health_and_safety_rounded,
                              size: 56,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Personalized Parkinson\'s care,\norganized every day.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Track symptoms, guided recovery, and community—all in one place.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(flex: 2),
                      // Loading bar or Continue button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _loadingDone
                            ? Padding(
                                key: const ValueKey('button'),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _continueToSignIn,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.textOnPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Continue to Sign In',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                key: const ValueKey('loading'),
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _loadController,
                                      builder: (context, _) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: Curves.easeInOutCubic.transform(_loadController.value),
                                            minHeight: 4,
                                            backgroundColor: colors.border.withValues(alpha: 0.5),
                                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Getting ready…',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

