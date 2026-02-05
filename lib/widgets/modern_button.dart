import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// Professional primary button
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final EdgeInsets? padding;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.padding,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final backgroundColor = widget.backgroundColor ?? colors.primary;
    final textColor = widget.textColor ?? colors.textOnPrimary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading
          ? null
          : () {
              HapticUtils.lightImpact();
              widget.onPressed();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isOutlined
              ? (_isPressed ? colors.surfaceVariant : Colors.transparent)
              : (_isPressed
                  ? backgroundColor.withValues(alpha: 0.9)
                  : backgroundColor),
          borderRadius: BorderRadius.circular(6),
          border: widget.isOutlined
              ? Border.all(color: colors.border, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    widget.isOutlined ? colors.textSecondary : textColor,
                  ),
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isOutlined ? colors.textPrimary : textColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.isOutlined ? colors.textPrimary : textColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon button with professional styling
class ModernIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool isCircle;

  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.isCircle = false,
  });

  @override
  State<ModernIconButton> createState() => _ModernIconButtonState();
}

class _ModernIconButtonState extends State<ModernIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticUtils.lightImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed 
              ? (widget.backgroundColor ?? colors.primary).withValues(alpha: 0.9)
              : widget.backgroundColor ?? colors.primary,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(6),
        ),
        child: Icon(
          widget.icon,
          color: widget.iconColor ?? colors.textOnPrimary,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

/// Floating action button with professional styling
class ModernFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? label;
  final bool extended;

  const ModernFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.label,
    this.extended = false,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticUtils.lightImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.symmetric(
          horizontal: widget.extended ? 16 : 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: _isPressed
              ? (widget.backgroundColor ?? colors.primary).withValues(alpha: 0.9)
              : widget.backgroundColor ?? colors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: widget.iconColor ?? colors.textOnPrimary,
              size: 20,
            ),
            if (widget.extended && widget.label != null) ...[
              const SizedBox(width: 10),
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.iconColor ?? colors.textOnPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
