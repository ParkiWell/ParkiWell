import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// A modern card widget with hover effects and optional onTap
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showShadow;
  final Gradient? gradient;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.showShadow = true,
    this.gradient,
    this.border,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return GestureDetector(
      onTapDown: widget.onTap != null 
          ? (_) => setState(() => _isPressed = true) 
          : null,
      onTapUp: widget.onTap != null 
          ? (_) => setState(() => _isPressed = false) 
          : null,
      onTapCancel: widget.onTap != null 
          ? () => setState(() => _isPressed = false) 
          : null,
      onTap: widget.onTap != null
          ? () {
              HapticUtils.cardTap();
              widget.onTap!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: widget.gradient == null 
              ? (widget.backgroundColor ?? colors.cardBackground) 
              : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ?? Border.all(
            color: colors.border.withOpacity(0.3),
          ),
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: colors.shadow.withOpacity(_isPressed ? 0.05 : 0.1),
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ]
              : null,
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? colors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor ?? colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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
            Icons.arrow_forward_ios_rounded,
            size: 16,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
