import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late AnimationController _staggerController;
  late AnimationController _ambientController;
  late AnimationController _exitController;

  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _titleScale;
  late Animation<double> _subtitleFade;
  late Animation<double> _subtitleSlide;
  late Animation<double> _featuresFade;
  late Animation<double> _featuresSlide;
  late Animation<double> _manageFade;
  late Animation<double> _manageSlide;
  late Animation<double> _manageScale;
  late Animation<double> _manageRotate;
  late Animation<double> _manageAccent;
  late Animation<double> _recoveryFade;
  late Animation<double> _recoverySlide;
  late Animation<double> _recoveryScale;
  late Animation<double> _recoveryRotate;
  late Animation<double> _communityFade;
  late Animation<double> _communitySlide;
  late Animation<double> _communityScale;
  late Animation<double> _communityRotate;
  late Animation<double> _primaryActionFade;
  late Animation<double> _primaryActionSlide;
  late Animation<double> _primaryActionScale;
  late Animation<double> _secondaryActionFade;
  late Animation<double> _secondaryActionSlide;
  late Animation<double> _secondaryActionScale;

  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  bool _showSignIn = false;
  bool _launchSignInMode = false;

  static const List<_Specialty> _specialties = <_Specialty>[
    _Specialty(
      icon: Icons.monitor_heart_outlined,
      sectionLabel: 'Manage',
      title: 'Symptoms + medication together',
      subtitle: 'Log symptoms and medication schedules in one daily care view.',
      chips: <String>['Symptom log', 'Medication plans'],
    ),
    _Specialty(
      icon: Icons.record_voice_over_outlined,
      sectionLabel: 'Recovery',
      title: 'Guided speech + movement',
      subtitle: 'Follow recovery sessions for speech and movement in the app.',
      chips: <String>['Speech therapy', 'Exercise videos'],
    ),
    _Specialty(
      icon: Icons.people_outline_rounded,
      sectionLabel: 'Community',
      title: 'Parkinson\'s community',
      subtitle:
          'Ask questions, share routines, and learn from people who get it.',
      chips: <String>['Discussion feed', 'Support groups'],
    ),
  ];

  Animation<double> _curve(
    double begin,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: curve),
    );
  }

  Animation<double> _offset(
    double begin,
    double end,
    double startOffset,
  ) {
    return Tween<double>(
      begin: startOffset,
      end: 0,
    ).animate(_curve(begin, end));
  }

  Animation<double> _scale(
    double begin,
    double end, {
    double start = 0.97,
  }) {
    return Tween<double>(
      begin: start,
      end: 1,
    ).animate(_curve(begin, end, curve: Curves.easeOutBack));
  }

  Animation<double> _rotation(
    double begin,
    double end, {
    required double start,
  }) {
    return Tween<double>(
      begin: start,
      end: 0,
    ).animate(_curve(begin, end, curve: Curves.easeOutCubic));
  }

  void _disposeControllerIfReady(AnimationController? controller) {
    if (controller == null) return;
    controller.dispose();
  }

  void _configureAnimations({bool disposeExisting = false}) {
    if (disposeExisting) {
      try {
        _disposeControllerIfReady(_staggerController);
      } catch (_) {}
      try {
        _disposeControllerIfReady(_ambientController);
      } catch (_) {}
      try {
        _disposeControllerIfReady(_exitController);
      } catch (_) {}
    }

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1880),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    );

    _titleFade = _curve(0.02, 0.24, curve: Curves.easeOut);
    _titleSlide = _offset(0.02, 0.24, 26);
    _titleScale = _scale(0.02, 0.3, start: 0.92);

    _subtitleFade = _curve(0.12, 0.36, curve: Curves.easeOut);
    _subtitleSlide = _offset(0.12, 0.36, 20);

    _featuresFade = _curve(0.18, 0.44, curve: Curves.easeOut);
    _featuresSlide = _offset(0.18, 0.44, 0);

    _manageFade = _curve(0.26, 0.56, curve: Curves.easeOut);
    _manageSlide = _offset(0.26, 0.56, 0);
    _manageScale = _scale(0.26, 0.6, start: 1);
    _manageRotate = _rotation(0.26, 0.6, start: 0);
    _manageAccent = _curve(0.42, 0.72, curve: Curves.easeOutCubic);

    _recoveryFade = _curve(0.46, 0.74, curve: Curves.easeOut);
    _recoverySlide = _offset(0.46, 0.74, 0);
    _recoveryScale = _scale(0.46, 0.78, start: 1);
    _recoveryRotate = _rotation(0.46, 0.78, start: 0);

    _communityFade = _curve(0.54, 0.82, curve: Curves.easeOut);
    _communitySlide = _offset(0.54, 0.82, 0);
    _communityScale = _scale(0.54, 0.86, start: 1);
    _communityRotate = _rotation(0.54, 0.86, start: 0);

    _primaryActionFade = _curve(0.7, 0.94, curve: Curves.easeOut);
    _primaryActionSlide = _offset(0.7, 0.94, 0);
    _primaryActionScale = _scale(0.7, 0.96, start: 1);

    _secondaryActionFade = _curve(0.8, 1.0, curve: Curves.easeOut);
    _secondaryActionSlide = _offset(0.8, 1.0, 0);
    _secondaryActionScale = _scale(0.8, 1.0, start: 1);

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _staggerController.forward();
    _ambientController.repeat(reverse: true);
  }

  @override
  void initState() {
    super.initState();
    _configureAnimations();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppTheme.lightColors.background,
        systemNavigationBarColor: AppTheme.lightColors.background,
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _configureAnimations(disposeExisting: true);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _ambientController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _transitionToSignIn() async {
    await _exitController.forward();
    if (mounted) setState(() => _showSignIn = true);
  }

  void _continueToSignUp() {
    HapticUtils.selectionClick();
    _launchSignInMode = false;
    _transitionToSignIn();
  }

  void _continueToSignIn() {
    HapticUtils.lightImpact();
    _launchSignInMode = true;
    _transitionToSignIn();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSignIn) {
      return EditProfileScreen(
        onComplete: widget.onComplete,
        startInSignIn: _launchSignInMode,
        onBack: () {
          setState(() {
            _showSignIn = false;
            _exitController.value = 0;
          });
        },
      );
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final extraCompact =
            constraints.maxHeight < 820 || constraints.maxWidth < 380;
        final compact = extraCompact ||
            constraints.maxHeight < 900 ||
            constraints.maxWidth < 400;

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
                      colors.background.blend(colors.primaryLight, 0.12),
                      colors.background.blend(colors.secondaryLight, 0.07),
                      colors.background,
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    _buildBackdrop(colors, isDark),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          extraCompact ? 8 : (compact ? 10 : 18),
                          24,
                          extraCompact ? 10 : (compact ? 12 : 20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(
                              colors,
                              compact,
                              extraCompact,
                            ),
                            SizedBox(
                                height:
                                    extraCompact ? 10 : (compact ? 12 : 18)),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: LayoutBuilder(
                                  builder: (context, viewport) {
                                    final showcaseWidth = math.min(
                                      viewport.maxWidth,
                                      460.0,
                                    );
                                    return _buildAnimatedReveal(
                                      fade: _featuresFade,
                                      slide: _featuresSlide,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.topCenter,
                                        child: SizedBox(
                                          width: showcaseWidth,
                                          child: _buildShowcase(
                                            colors,
                                            compact,
                                            extraCompact,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                                height: extraCompact ? 4 : (compact ? 6 : 10)),
                            _buildBottomActions(colors, compact, extraCompact),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackdrop(AppColors colors, bool isDark) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final phase = _ambientController.value * math.pi * 2;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -70 + math.sin(phase) * 2.5,
                left: -90 + math.cos(phase * 0.8) * 2.0,
                child: _BackdropShape(
                  size: 240,
                  color: colors.background
                      .blend(colors.primary, isDark ? 0.18 : 0.1),
                  rotation: -0.18 + math.sin(phase * 0.55) * 0.01,
                  radius: 80,
                ),
              ),
              Positioned(
                top: 170 + math.cos(phase * 0.75) * 2.5,
                right: -70 + math.sin(phase * 0.9) * 2.5,
                child: _BackdropShape(
                  size: 190,
                  color: colors.background
                      .blend(colors.secondary, isDark ? 0.18 : 0.1),
                  rotation: 0.28 + math.cos(phase * 0.6) * 0.01,
                  radius: 58,
                ),
              ),
              Positioned(
                bottom: 120 + math.sin(phase * 0.7) * 3.0,
                left: -30 + math.cos(phase * 0.65) * 2.0,
                child: _BackdropShape(
                  size: 150,
                  color: colors.background
                      .blend(colors.primaryDark, isDark ? 0.16 : 0.08),
                  rotation: 0.56 + math.sin(phase * 0.5) * 0.01,
                  radius: 42,
                ),
              ),
              Positioned(
                top: 108 + math.sin(phase * 0.55) * 2.5,
                left: 34 + math.cos(phase * 0.62) * 2.5,
                child: _BackdropPill(
                  width: 118,
                  height: 20,
                  color: colors.background
                      .blend(colors.primaryLight, isDark ? 0.22 : 0.14),
                  rotation: 0.22 + math.cos(phase * 0.42) * 0.015,
                ),
              ),
              Positioned(
                top: 348 + math.cos(phase * 0.48) * 3.0,
                right: 22 + math.sin(phase * 0.66) * 3.0,
                child: _BackdropPill(
                  width: 96,
                  height: 18,
                  color: colors.background
                      .blend(colors.secondaryLight, isDark ? 0.22 : 0.12),
                  rotation: -0.3 + math.sin(phase * 0.38) * 0.015,
                ),
              ),
              Positioned(
                bottom: 210 + math.sin(phase * 0.52) * 3.5,
                right: -12 + math.cos(phase * 0.44) * 3.0,
                child: _BackdropPill(
                  width: 160,
                  height: 24,
                  color: colors.background
                      .blend(colors.primary, isDark ? 0.2 : 0.11),
                  rotation: -1.14 + math.sin(phase * 0.34) * 0.01,
                ),
              ),
              Positioned(
                bottom: 94 + math.cos(phase * 0.58) * 2.5,
                left: 42 + math.sin(phase * 0.5) * 2.0,
                child: _BackdropPill(
                  width: 72,
                  height: 14,
                  color: colors.background
                      .blend(colors.secondary, isDark ? 0.16 : 0.09),
                  rotation: 0.12 + math.cos(phase * 0.4) * 0.008,
                ),
              ),
              Positioned(
                top: 62 + math.sin(phase * 0.44) * 2.0,
                right: 44 + math.cos(phase * 0.31) * 2.0,
                child: _BackdropPill(
                  width: 88,
                  height: 16,
                  color: colors.background
                      .blend(colors.primaryDark, isDark ? 0.18 : 0.09),
                  rotation: -0.24 + math.sin(phase * 0.27) * 0.01,
                ),
              ),
              Positioned(
                top: 278 + math.cos(phase * 0.36) * 2.5,
                left: -18 + math.sin(phase * 0.57) * 2.0,
                child: _BackdropPill(
                  width: 74,
                  height: 14,
                  color: colors.background
                      .blend(colors.secondary, isDark ? 0.14 : 0.08),
                  rotation: 0.48 + math.cos(phase * 0.32) * 0.01,
                ),
              ),
              Positioned(
                bottom: 306 + math.sin(phase * 0.41) * 2.5,
                left: 116 + math.cos(phase * 0.29) * 2.0,
                child: _BackdropShape(
                  size: 76,
                  color: colors.background
                      .blend(colors.primaryLight, isDark ? 0.16 : 0.08),
                  rotation: 0.18 + math.sin(phase * 0.22) * 0.008,
                  radius: 28,
                ),
              ),
              Positioned(
                bottom: 42 + math.cos(phase * 0.46) * 2.5,
                right: 118 + math.sin(phase * 0.36) * 2.0,
                child: _BackdropPill(
                  width: 98,
                  height: 16,
                  color: colors.background
                      .blend(colors.secondaryLight, isDark ? 0.16 : 0.08),
                  rotation: -0.92 + math.sin(phase * 0.28) * 0.01,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(
    AppColors colors,
    bool compact,
    bool extraCompact,
  ) {
    final theme = Theme.of(context).textTheme;
    final brandStyle = theme.displaySmall?.copyWith(
      fontSize: extraCompact ? 38 : (compact ? 40 : 54),
      fontWeight: FontWeight.w800,
      letterSpacing: extraCompact ? -1.7 : -2.1,
      height: 0.95,
    );

    return Column(
      children: [
        _buildAnimatedReveal(
          fade: _titleFade,
          slide: _titleSlide,
          scale: _titleScale,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'L',
                  style: brandStyle?.copyWith(color: colors.primary),
                ),
                TextSpan(
                  text: 'evio',
                  style: brandStyle?.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: extraCompact ? 6 : (compact ? 8 : 10)),
        _buildAnimatedReveal(
          fade: _subtitleFade,
          slide: _subtitleSlide,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: extraCompact ? 340 : 390),
            child: Text(
              'Track symptoms, follow guided recovery, and stay connected, all in one place.',
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(
                color: colors.textSecondary,
                height: 1.28,
                fontWeight: FontWeight.w600,
                fontSize: extraCompact ? 15.5 : (compact ? 16.5 : null),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowcase(
    AppColors colors,
    bool compact,
    bool extraCompact,
  ) {
    final primary = _specialties[0];
    final recovery = _specialties[1];
    final community = _specialties[2];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnimatedReveal(
          fade: _manageFade,
          slide: _manageSlide,
          scale: _manageScale,
          rotate: _manageRotate,
          child: _buildPrimarySpecialtyCard(
            colors: colors,
            specialty: primary,
            accent: colors.primary,
            compact: compact,
            extraCompact: extraCompact,
          ),
        ),
        SizedBox(height: extraCompact ? 8 : (compact ? 10 : 14)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAnimatedReveal(
                fade: _recoveryFade,
                slide: _recoverySlide,
                scale: _recoveryScale,
                rotate: _recoveryRotate,
                child: _buildSecondarySpecialtyCard(
                  colors: colors,
                  specialty: recovery,
                  accent: colors.secondary,
                  compact: compact,
                  extraCompact: extraCompact,
                ),
              ),
            ),
            SizedBox(width: extraCompact ? 8 : 10),
            Expanded(
              child: _buildAnimatedReveal(
                fade: _communityFade,
                slide: _communitySlide,
                scale: _communityScale,
                rotate: _communityRotate,
                child: _buildSecondarySpecialtyCard(
                  colors: colors,
                  specialty: community,
                  accent: colors.primaryDark,
                  compact: compact,
                  extraCompact: extraCompact,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimarySpecialtyCard({
    required AppColors colors,
    required _Specialty specialty,
    required Color accent,
    required bool compact,
    required bool extraCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(extraCompact ? 14 : (compact ? 16 : 20)),
      decoration: BoxDecoration(
        color: colors.surface.blend(accent, 0.14),
        borderRadius: BorderRadius.circular(compact ? 28 : 30),
        border: Border.all(color: colors.border.blend(accent, 0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: extraCompact ? 34 : (compact ? 38 : 42),
                height: extraCompact ? 34 : (compact ? 38 : 42),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  specialty.icon,
                  size: extraCompact ? 18 : (compact ? 20 : 22),
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                specialty.sectionLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: extraCompact ? 16 : null,
                    ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: extraCompact ? 8 : (compact ? 10 : 12),
                  vertical: extraCompact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'All in one',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: extraCompact ? 10.5 : null,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: extraCompact ? 10 : (compact ? 12 : 16)),
          Text(
            specialty.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: extraCompact ? 21 : (compact ? 24 : 28),
                  height: 1.04,
                ),
          ),
          SizedBox(height: extraCompact ? 7 : (compact ? 8 : 10)),
          Text(
            specialty.subtitle,
            maxLines: extraCompact ? 2 : null,
            overflow: extraCompact ? TextOverflow.ellipsis : null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.28,
                  fontSize: extraCompact ? 14 : (compact ? 15 : 16),
                ),
          ),
          SizedBox(height: extraCompact ? 10 : (compact ? 12 : 14)),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _manageAccent,
              child: Container(
                width: extraCompact ? 64 : (compact ? 74 : 86),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      colors.surface.blend(accent, 0.45),
                    ],
                  ),
                ),
              ),
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _manageAccent.value,
                    child: child,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: extraCompact ? 12 : (compact ? 14 : 16)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: specialty.chips
                .map(
                  (chip) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: extraCompact ? 9 : (compact ? 10 : 12),
                      vertical: extraCompact ? 6 : (compact ? 7 : 8),
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      chip,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: extraCompact ? 11.5 : null,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondarySpecialtyCard({
    required AppColors colors,
    required _Specialty specialty,
    required Color accent,
    required bool compact,
    required bool extraCompact,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: extraCompact ? 232 : (compact ? 264 : 286),
      ),
      padding: EdgeInsets.all(extraCompact ? 12 : (compact ? 14 : 16)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: extraCompact ? 34 : (compact ? 38 : 40),
            height: extraCompact ? 34 : (compact ? 38 : 40),
            decoration: BoxDecoration(
              color: colors.surface.blend(accent, 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              specialty.icon,
              size: extraCompact ? 18 : (compact ? 20 : 22),
              color: accent,
            ),
          ),
          SizedBox(height: extraCompact ? 8 : (compact ? 10 : 12)),
          Text(
            specialty.sectionLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: extraCompact ? 11.5 : null,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            specialty.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                  fontSize: extraCompact ? 15 : (compact ? 17 : 18),
                ),
          ),
          const SizedBox(height: 5),
          Text(
            specialty.subtitle,
            maxLines: extraCompact ? 4 : null,
            overflow: extraCompact ? TextOverflow.ellipsis : null,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.24,
                  fontSize: extraCompact ? 12 : (compact ? 13 : 14),
                ),
          ),
          SizedBox(height: extraCompact ? 10 : (compact ? 12 : 14)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: extraCompact ? 8 : (compact ? 10 : 12),
              vertical: extraCompact ? 6 : (compact ? 7 : 8),
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              specialty.chips.first,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: extraCompact ? 10.5 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    AppColors colors,
    bool compact,
    bool extraCompact,
  ) {
    return Column(
      children: [
        _buildAnimatedReveal(
          fade: _primaryActionFade,
          slide: _primaryActionSlide,
          scale: _primaryActionScale,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: extraCompact ? 300 : (compact ? 320 : 336),
              ),
              child: SizedBox(
                width: double.infinity,
                height: extraCompact ? 42 : (compact ? 46 : 50),
                child: FilledButton(
                  onPressed: _continueToSignUp,
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        colors.primaryDark.blend(colors.primary, 0.18),
                    foregroundColor: colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Start Strong with Levio',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textOnPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: extraCompact ? 15.5 : null,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: extraCompact ? 8 : (compact ? 10 : 12)),
        _buildAnimatedReveal(
          fade: _secondaryActionFade,
          slide: _secondaryActionSlide,
          scale: _secondaryActionScale,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: extraCompact ? 300 : (compact ? 320 : 336),
              ),
              child: SizedBox(
                width: double.infinity,
                height: extraCompact ? 36 : (compact ? 40 : 42),
                child: OutlinedButton(
                  onPressed: _continueToSignIn,
                  style: OutlinedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: colors.surface,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: extraCompact ? 15 : null,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedReveal({
    required Widget child,
    required Animation<double> fade,
    required Animation<double> slide,
    Animation<double>? scale,
    Animation<double>? rotate,
    double baseOffsetY = 0,
  }) {
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: Listenable.merge(
          <Listenable>[
            slide,
            if (scale != null) scale,
            if (rotate != null) rotate,
          ],
        ),
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, slide.value + baseOffsetY),
            child: Transform.rotate(
              angle: rotate?.value ?? 0,
              child: Transform.scale(
                alignment: Alignment.topCenter,
                scale: scale?.value ?? 1,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Specialty {
  final IconData icon;
  final String sectionLabel;
  final String title;
  final String subtitle;
  final List<String> chips;

  const _Specialty({
    required this.icon,
    required this.sectionLabel,
    required this.title,
    required this.subtitle,
    required this.chips,
  });
}

class _BackdropShape extends StatelessWidget {
  final double size;
  final double radius;
  final double rotation;
  final Color color;

  const _BackdropShape({
    required this.size,
    required this.radius,
    required this.rotation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _BackdropPill extends StatelessWidget {
  final double width;
  final double height;
  final double rotation;
  final Color color;

  const _BackdropPill({
    required this.width,
    required this.height,
    required this.rotation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
