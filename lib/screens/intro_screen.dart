import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroScreen({super.key, required this.onComplete});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _ambientController;
  late final AnimationController _contentController;

  int _currentPage = 0;

  final List<_IntroPage> _pages = const <_IntroPage>[
    _IntroPage(
      icon: Icons.monitor_heart_outlined,
      title: 'Track Daily Patterns',
      description:
          'Capture symptoms, medication timing, and streaks in one clear timeline.',
      bullets: <String>[
        'Simple daily logging flow',
        'Structured entries for trend clarity',
      ],
      phase: 0.0,
    ),
    _IntroPage(
      icon: Icons.record_voice_over_outlined,
      title: 'Guided Recovery Sessions',
      description:
          'Follow curated speech and movement sessions designed for Parkinson support.',
      bullets: <String>[
        'Evidence-based guided content',
        'Built for consistency and calm routines',
      ],
      phase: 1.3,
    ),
    _IntroPage(
      icon: Icons.cloud_done_outlined,
      title: 'Secure Sync Ready',
      description:
          'Sign in, keep your identity linked, and sync profile data with secure backend sessions.',
      bullets: <String>[
        'Google sign-in supported',
        'UUID, name, and email are persisted',
      ],
      phase: 2.4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ambientController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticUtils.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    HapticUtils.lightImpact();
    widget.onComplete();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(
                    colors.background,
                    colors.primaryLight,
                    isDark ? 0.22 : 0.1,
                  )!,
                  Color.lerp(
                    colors.background,
                    colors.secondaryLight,
                    isDark ? 0.14 : 0.06,
                  )!,
                  colors.background,
                ],
                stops: const <double>[0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                _buildGlow(
                  colors,
                  diameter: 280,
                  alignment: Alignment(
                    -0.92,
                    -0.9 +
                        math.sin(_ambientController.value * 2 * math.pi) * 0.05,
                  ),
                ),
                _buildGlow(
                  colors,
                  diameter: 340,
                  alignment: Alignment(
                    0.95,
                    -0.15 +
                        math.cos(_ambientController.value * 2 * math.pi) * 0.04,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                        child: Row(
                          children: [
                            Text(
                              'Welcome to Levio',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _skip,
                              child: Text(
                                'Skip',
                                style: GoogleFonts.plusJakartaSans(
                                  color: colors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return _buildPage(_pages[index], colors);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: _buildIndicator(colors),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Continue to Sign In'
                                  : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlow(
    AppColors colors, {
    required double diameter,
    required Alignment alignment,
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
              colors: <Color>[
                colors.primary.withValues(alpha: 0.12),
                colors.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_IntroPage page, AppColors colors) {
    final fade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildFeatureVisual(page, colors),
              const SizedBox(height: 24),
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                page.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 16),
              ...page.bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bullet,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                        ),
                      ),
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

  Widget _buildFeatureVisual(_IntroPage page, AppColors colors) {
    final time = _ambientController.value * 2 * math.pi;
    final yDrift = math.sin(time + page.phase) * 6;
    final xDrift = math.cos(time + page.phase) * 5;

    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, yDrift * 0.35),
            child: Container(
              width: double.infinity,
              height: 192,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    colors.surface.withValues(alpha: 0.9),
                    colors.surfaceVariant.withValues(alpha: 0.75),
                  ],
                ),
                border:
                    Border.all(color: colors.border.withValues(alpha: 0.75)),
              ),
              child: Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    page.icon,
                    size: 42,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18 + xDrift,
            top: 20,
            child: _MetricPill(
              label: _currentPage == 2 ? 'Google' : 'Daily',
              value: _currentPage == 2 ? 'Auth' : 'Logs',
            ),
          ),
          Positioned(
            left: 16 - xDrift,
            bottom: 6,
            child: _MetricPill(
              label: _currentPage == 1 ? 'Guided' : 'Secure',
              value: _currentPage == 1 ? 'Sessions' : 'Sync',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(AppColors colors) {
    return Row(
      children: List<Widget>.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 6,
            margin: EdgeInsets.only(right: index == _pages.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive
                  ? colors.primary
                  : colors.border.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage {
  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
  final double phase;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    required this.phase,
  });
}
