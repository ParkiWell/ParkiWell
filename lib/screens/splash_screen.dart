import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _ambientController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _brandLift;
  late final Animation<double> _logoScale;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    );

    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 5600),
      vsync: this,
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.08, 0.58, curve: Curves.easeOutBack),
      ),
    );

    _brandLift = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _progress = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 120));
    await _entryController.forward();
    await Future.delayed(const Duration(milliseconds: 220));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    colors.background,
                    colors.primaryLight,
                    isDark ? 0.26 : 0.12,
                  )!,
                  Color.lerp(
                    colors.background,
                    colors.secondary,
                    isDark ? 0.18 : 0.06,
                  )!,
                  colors.background,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: Stack(
              children: [
                _buildBackgroundGlow(
                  colors,
                  diameter: 260,
                  alignment: Alignment(
                    -0.85,
                    -0.92 +
                        (math.sin(_ambientController.value * 2 * math.pi) *
                            0.05),
                  ),
                  tint: colors.primary,
                ),
                _buildBackgroundGlow(
                  colors,
                  diameter: 340,
                  alignment: Alignment(
                    0.95,
                    -0.15 +
                        (math.cos(_ambientController.value * 2 * math.pi) *
                            0.04),
                  ),
                  tint: colors.secondary,
                ),
                _buildBackgroundGlow(
                  colors,
                  diameter: 300,
                  alignment: Alignment(
                    -0.3,
                    1.1 -
                        (math.sin(_ambientController.value * 2 * math.pi) *
                            0.03),
                  ),
                  tint: colors.primaryDark,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Transform.translate(
                            offset: Offset(0, _brandLift.value),
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _buildHeroLogo(
                                colors,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Transform.translate(
                            offset: Offset(0, _brandLift.value),
                            child: Column(
                              children: [
                                Text(
                                  'Levio',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.3,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Personalized Parkinson\'s care,\norganized every day.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 4),
                        FadeTransition(
                          opacity: _fadeIn,
                          child: _buildProgressSection(colors),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundGlow(
    AppColors colors, {
    required double diameter,
    required Alignment alignment,
    required Color tint,
  }) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLogo(
    AppColors colors, {
    required bool isDark,
  }) {
    final pulse = math.sin(_ambientController.value * 2 * math.pi);
    const logoPath = 'images/logo.png';

    return Transform.scale(
      scale: 1.0 + (pulse * 0.01),
      child: SizedBox(
        width: 132,
        height: 132,
        child: Image.asset(
          logoPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            Icons.health_and_safety_rounded,
            color: isDark ? colors.textPrimary : colors.primary,
            size: 44,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(AppColors colors) {
    return Column(
      children: [
        Text(
          'Preparing your care workspace',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textTertiary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, child) {
              return LinearProgressIndicator(
                minHeight: 7,
                value: _progress.value,
                backgroundColor: colors.border.withValues(alpha: 0.42),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              );
            },
          ),
        ),
      ],
    );
  }
}
