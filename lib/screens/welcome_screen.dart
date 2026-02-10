import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sequenceController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleReveal;
  late final Animation<double> _statsOpacity;
  late final Animation<double> _buttonOpacity;
  late final Animation<double> _buttonWidth;

  late final List<Animation<double>> _featureOpacities;
  late final List<Animation<double>> _featureReveal;

  bool _buttonEnabled = false;

  @override
  void initState() {
    super.initState();

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);

    _logoOpacity = _anim(0, 1, 0.03, 0.16);
    _logoScale = _anim(0.82, 1, 0.03, 0.18, curve: Curves.easeOutBack);
    _titleOpacity = _anim(0, 1, 0.13, 0.27);
    _titleSlide = _anim(20, 0, 0.13, 0.27, curve: Curves.easeOutCubic);
    _subtitleOpacity = _anim(0, 1, 0.24, 0.36);
    _subtitleReveal = _anim(0, 1, 0.24, 0.41, curve: Curves.easeOutCubic);
    _statsOpacity = _anim(0, 1, 0.58, 0.72);
    _buttonWidth = _anim(0.1, 1, 0.74, 0.87, curve: Curves.easeOutCubic);
    _buttonOpacity = _anim(0, 1, 0.80, 0.92);

    _featureOpacities = <Animation<double>>[
      _anim(0, 1, 0.40, 0.50),
      _anim(0, 1, 0.47, 0.58),
      _anim(0, 1, 0.54, 0.66),
    ];
    _featureReveal = <Animation<double>>[
      _anim(0, 1, 0.40, 0.54),
      _anim(0, 1, 0.47, 0.62),
      _anim(0, 1, 0.54, 0.70),
    ];

    _setupHaptics();
    _runSequence();
  }

  Animation<double> _anim(
    double begin,
    double end,
    double start,
    double endInterval, {
    Curve curve = Curves.easeOut,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: Interval(start, endInterval, curve: curve),
      ),
    );
  }

  void _setupHaptics() {
    final checkpoints = <double>[0.08, 0.24, 0.42, 0.52, 0.61, 0.82];
    final triggered = <int>{};
    _sequenceController.addListener(() {
      for (var i = 0; i < checkpoints.length; i++) {
        if (_sequenceController.value >= checkpoints[i] && triggered.add(i)) {
          HapticUtils.selectionClick();
        }
      }
    });
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _sequenceController.forward();
    if (!mounted) return;
    setState(() => _buttonEnabled = true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_buttonEnabled) return;
    HapticUtils.mediumImpact();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_sequenceController, _ambientController]),
        builder: (context, _) {
          final glowMovement = math.sin(_ambientController.value * math.pi * 2);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(colors.background, colors.primaryLight, 0.14)!,
                  colors.background,
                  Color.lerp(colors.background, colors.secondary, 0.08)!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(-0.95, -0.72 + (glowMovement * 0.05)),
                  child:
                      _GlowBlob(color: colors.primary.withValues(alpha: 0.14)),
                ),
                Align(
                  alignment: Alignment(0.88, -0.02 - (glowMovement * 0.03)),
                  child: _GlowBlob(
                    color: colors.secondary.withValues(alpha: 0.12),
                    size: 320,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _buildLogo(colors, isDark),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Opacity(
                          opacity: _titleOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlide.value),
                            child: Text(
                              'Levio',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.2,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.center,
                              widthFactor: _subtitleReveal.value,
                              child: Text(
                                'Personalized Parkinson\'s care, organized every day.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colors.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureRow(
                          icon: Icons.insights_outlined,
                          title: 'Track patterns',
                          subtitle: 'Daily symptom and medication trends',
                          opacity: _featureOpacities[0].value,
                          reveal: _featureReveal[0].value,
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          icon: Icons.favorite_border_rounded,
                          title: 'Guided recovery',
                          subtitle: 'Voice and movement sessions',
                          opacity: _featureOpacities[1].value,
                          reveal: _featureReveal[1].value,
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          icon: Icons.cloud_done_outlined,
                          title: 'Secure cloud sync',
                          subtitle: 'Google sign-in with synced profile',
                          opacity: _featureOpacities[2].value,
                          reveal: _featureReveal[2].value,
                        ),
                        const SizedBox(height: 24),
                        Opacity(
                          opacity: _statsOpacity.value,
                          child: _buildStats(colors),
                        ),
                        const Spacer(flex: 3),
                        Opacity(
                          opacity: _buttonOpacity.value,
                          child: SizedBox(
                            height: 52,
                            width: MediaQuery.of(context).size.width *
                                0.86 *
                                _buttonWidth.value,
                            child: ElevatedButton(
                              onPressed:
                                  _buttonEnabled ? _handleContinue : null,
                              child: Text(
                                'Start Onboarding',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _buttonEnabled ? _handleContinue : null,
                          child: Text(
                            'Skip intro',
                            style: TextStyle(color: colors.textTertiary),
                          ),
                        ),
                        const SizedBox(height: 14),
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

  Widget _buildLogo(AppColors colors, bool isDark) {
    final logo = isDark ? 'images/app_icon.png' : 'images/logo.png';
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.surface,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.32 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Image.asset(
        logo,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required double opacity,
    required double reveal,
  }) {
    final colors = context.colors;

    return Opacity(
      opacity: opacity,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: reveal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 1),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStats(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _WelcomeStat(value: '24/7', label: 'Support'),
          _WelcomeDivider(),
          _WelcomeStat(value: 'Cloud', label: 'Sync'),
          _WelcomeDivider(),
          _WelcomeStat(value: 'Guided', label: 'Recovery'),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({
    required this.color,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStat extends StatelessWidget {
  final String value;
  final String label;

  const _WelcomeStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
        ),
      ],
    );
  }
}

class _WelcomeDivider extends StatelessWidget {
  const _WelcomeDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 1,
      height: 26,
      color: colors.border,
    );
  }
}
