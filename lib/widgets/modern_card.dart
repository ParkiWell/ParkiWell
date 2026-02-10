import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// A professional card widget with subtle interactions
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showBorder;
  final Gradient? gradient;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 8,
    this.showBorder = true,
    this.gradient,
    this.border,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isHovered = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isHovered = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isHovered = false)
          : null,
      onTap: widget.onTap != null
          ? () {
              HapticUtils.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (_isHovered
                  ? colors.surfaceVariant
                  : widget.backgroundColor ?? colors.cardBackground)
              : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ??
              (widget.showBorder ? Border.all(color: colors.border) : null),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A feature card with icon, title, and description
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Gradient? gradient;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.iconColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ModernCard(
      onTap: onTap,
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? colors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? colors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// A stat card for displaying metrics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cardColor = color ?? colors.primary;

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 20,
                color: cardColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cardColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
