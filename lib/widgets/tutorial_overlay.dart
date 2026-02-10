import 'package:flutter/material.dart';

import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import 'tutorial_tooltip.dart';

class TutorialOverlay extends StatefulWidget {
  final Widget child;
  final List<TutorialStep> steps;
  final bool enabled;

  const TutorialOverlay({
    super.key,
    required this.child,
    required this.steps,
    this.enabled = true,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final TutorialService _service = TutorialService();
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onTutorialChanged);
    _startIfNeeded();
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.steps != widget.steps) {
      _startIfNeeded();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onTutorialChanged);
    super.dispose();
  }

  Future<void> _startIfNeeded() async {
    if (!widget.enabled) return;
    if (widget.steps.isEmpty) return;
    if (_service.isActive) return;

    final shouldShow = await _service.shouldShowTutorial();
    if (!mounted || !shouldShow) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _service.start(widget.steps);
      _refreshTargetRect();
    });
  }

  void _onTutorialChanged() {
    if (!mounted) return;
    _refreshTargetRect();
  }

  void _refreshTargetRect() {
    final step = _service.currentStep;
    if (step == null) {
      setState(() => _targetRect = null);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rect = _findTargetRect(step);
      if (rect == null) return;
      setState(() => _targetRect = rect);
    });
  }

  Rect? _findTargetRect(TutorialStep step) {
    final context = step.targetKey.currentContext;
    if (context == null) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final padding = step.spotlightPadding;

    return Rect.fromLTWH(
      position.dx - padding.left,
      position.dy - padding.top,
      size.width + padding.horizontal,
      size.height + padding.vertical,
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _service.currentStep;
    if (_service.isActive && step != null && _targetRect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshTargetRect();
      });
    }
    return Stack(
      children: [
        widget.child,
        if (_service.isActive && step != null && _targetRect != null)
          _buildOverlay(context, step, _targetRect!),
      ],
    );
  }

  Widget _buildOverlay(
      BuildContext context, TutorialStep step, Rect targetRect) {
    final colors = context.colors;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const tooltipWidth = 292.0;
    const tooltipHeight = 190.0;
    const horizontalInset = 16.0;
    const bubbleGap = 10.0;

    double left = targetRect.center.dx - (tooltipWidth / 2);
    left = left.clamp(
        horizontalInset, size.width - tooltipWidth - horizontalInset);

    final showAbove = step.tooltipPosition == TutorialTooltipPosition.above;
    final topIfAbove = targetRect.top - tooltipHeight - bubbleGap;
    final topIfBelow = targetRect.bottom + bubbleGap;
    final minTop = padding.top + 10;
    final maxTop = size.height - padding.bottom - tooltipHeight - 10;

    double top;
    if (showAbove) {
      if (topIfAbove >= minTop) {
        top = topIfAbove;
      } else {
        top = topIfBelow.clamp(minTop, maxTop);
      }
    } else {
      if (topIfBelow <= maxTop) {
        top = topIfBelow;
      } else {
        top = topIfAbove.clamp(minTop, maxTop);
      }
    }

    final isLast = _service.currentStepIndex == _service.totalSteps - 1;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: targetRect,
                    overlayColor: colors.textPrimary.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: tooltipWidth,
              child: TutorialTooltip(
                title: step.title,
                description: step.description,
                actionLabel: step.actionLabel ?? (isLast ? 'Done' : 'Next'),
                currentStep: _service.currentStepIndex + 1,
                totalSteps: _service.totalSteps,
                onNext: () async => _service.next(),
                onSkip: () async => _service.skip(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final spotlight =
        RRect.fromRectAndRadius(targetRect, const Radius.circular(14));
    final spotlightPath = Path()..addRRect(spotlight);

    final diffPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      spotlightPath,
    );

    canvas.drawPath(
      diffPath,
      Paint()..color = overlayColor,
    );

    canvas.drawRRect(
      spotlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
