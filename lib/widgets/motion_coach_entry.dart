import 'package:flutter/material.dart';

import '../motion_coach/motion_analysis.dart' show motionCoachAvailable;
import '../motion_coach/motion_coach_home_screen.dart';
import '../services/feature_flags.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class MotionCoachEntry extends StatelessWidget {
  const MotionCoachEntry({
    super.key,
    required this.description,
    this.margin = EdgeInsets.zero,
  });

  final String description;
  final EdgeInsetsGeometry margin;

  void _open(BuildContext context) {
    if (!motionCoachAvailable) return;
    HapticUtils.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MotionCoachHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: FeatureFlags.shared,
    builder: (context, _) => motionCoachAvailable
        ? Padding(padding: margin, child: _buildEntry(context))
        : const SizedBox.shrink(),
  );

  Widget _buildEntry(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final accent = context.isDarkMode
        ? colors.secondaryLight
        : const Color(0xFF096665);
    final background = colors.surface.blend(colors.secondary, 0.09);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: accent.blend(background, 0.32)),
    );

    return Semantics(
      button: true,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          focusColor: accent.withValues(alpha: 0.17),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useIcon =
                    constraints.maxWidth >= 224 &&
                    MediaQuery.textScalerOf(context).scale(20) <= 31;
                return Row(
                  children: [
                    if (useIcon) ...[
                      Icon(
                        Icons.center_focus_weak_rounded,
                        color: accent,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Motion coach',
                            style: textTheme.titleLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
