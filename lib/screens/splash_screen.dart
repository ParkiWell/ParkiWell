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
  late final AnimationController _mainController;
  late final AnimationController _floatController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _logoScale;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _progress = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 140));
    await _mainController.forward();
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(colors.background, colors.primaryLight,
                  isDark ? 0.22 : 0.09)!,
              colors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogo(colors),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Text(
                        'Levio',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Personalized Parkinson\'s care,\norganized every day.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    children: [
                      Text(
                        'Preparing your care workspace',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              minHeight: 6,
                              value: _progress.value,
                              backgroundColor:
                                  colors.border.withValues(alpha: 0.45),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(colors.primary),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(AppColors colors) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin(_floatController.value * 2 * math.pi) * 4;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 124,
            height: 124,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: colors.surface.withValues(alpha: 0.92),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.health_and_safety_rounded,
                  color: colors.primary,
                  size: 44,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
