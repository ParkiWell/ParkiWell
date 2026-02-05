import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// Modern primary button with animations
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

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
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
              HapticUtils.buttonTap();
              widget.onPressed();
            },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (widget.isLoading
                    ? backgroundColor.withOpacity(0.7)
                    : backgroundColor),
            borderRadius: BorderRadius.circular(12),
            border: widget.isOutlined
                ? Border.all(color: backgroundColor, width: 2)
                : null,
            boxShadow: widget.isOutlined || widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: backgroundColor.withOpacity(_isPressed ? 0.2 : 0.3),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      widget.isOutlined ? backgroundColor : textColor,
                    ),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: widget.isOutlined ? backgroundColor : textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.isOutlined ? backgroundColor : textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon button with modern styling
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
    this.size = 48,
    this.isCircle = true,
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
        HapticUtils.buttonTap();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.identity()..scale(_isPressed ? 0.9 : 1.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colors.primary,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle ? null : BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (widget.backgroundColor ?? colors.primary)
                  .withOpacity(_isPressed ? 0.2 : 0.3),
              blurRadius: _isPressed ? 4 : 8,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
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

/// Floating action button with modern styling
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
        HapticUtils.buttonTap();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: EdgeInsets.symmetric(
          horizontal: widget.extended ? 20 : 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (widget.backgroundColor ?? colors.primary)
                  .withOpacity(_isPressed ? 0.2 : 0.4),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: widget.iconColor ?? colors.textOnPrimary,
              size: 24,
            ),
            if (widget.extended && widget.label != null) ...[
              const SizedBox(width: 12),
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.iconColor ?? colors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
