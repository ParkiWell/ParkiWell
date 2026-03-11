import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Main/editProfile.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlowScreen({super.key, required this.onComplete});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late AnimationController _exitController;

  late Animation<double> _logoFade;
  late Animation<double> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _subtitleSlide;
  late Animation<double> _featuresFade;
  late Animation<double> _featuresSlide;

  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  bool _showSignIn = false;

  static const _features = [
    (Icons.show_chart_rounded, 'Track symptoms & patterns'),
    (Icons.medication_rounded, 'Medication scheduling'),
    (Icons.play_circle_outline_rounded, 'Guided recovery videos'),
    (Icons.people_outline_rounded, 'Supportive community'),
  ];

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _titleSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _featuresFade = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
    );
    _featuresSlide = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.lightColors.background,
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _staggerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _transitionToSignIn() async {
    await _exitController.forward();
    if (mounted) setState(() => _showSignIn = true);
  }

  void _continueToSignIn() {
    HapticUtils.selectionClick();
    _transitionToSignIn();
  }

  void _skipToSignIn() {
    HapticUtils.lightImpact();
    _transitionToSignIn();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSignIn) {
      return EditProfileScreen(onComplete: widget.onComplete);
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _exitFade,
        child: ScaleTransition(
          scale: _exitScale,
          child: Container(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Step 1 of 3',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                      child: AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, _) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),

                            // Logo with pulse + stagger
                            FadeTransition(
                              opacity: _logoFade,
                              child: Transform.translate(
                                offset: Offset(0, _logoSlide.value),
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final t = _pulseController.value;
                                    final scale = 0.985 +
                                        0.03 * (1 - (t - 0.5).abs() * 2);
                                    return Transform.scale(
                                        scale: scale, child: child);
                                  },
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    padding: const EdgeInsets.all(16),
                                    child: Image.asset(
                                      isDark
                                          ? 'images/app_icon.png'
                                          : 'images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.health_and_safety_rounded,
                                        size: 56,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Title
                            FadeTransition(
                              opacity: _titleFade,
                              child: Transform.translate(
                                offset: Offset(0, _titleSlide.value),
                                child: Text(
                                  'Personalized Parkinson\'s care,\norganized every day.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Subtitle
                            FadeTransition(
                              opacity: _subtitleFade,
                              child: Transform.translate(
                                offset: Offset(0, _subtitleSlide.value),
                                child: Text(
                                  'Track symptoms, guided recovery, and community\u2014all in one place.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Feature highlights
                            FadeTransition(
                              opacity: _featuresFade,
                              child: Transform.translate(
                                offset: Offset(0, _featuresSlide.value),
                                child: _buildFeatureChips(colors),
                              ),
                            ),

                            const Spacer(flex: 2),

                            _buildContinueButton(colors),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChips(AppColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                f.$2,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(AppColors colors) {
    return Padding(
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
            'Continue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
