import 'package:flutter/material.dart';
import 'package:levio/singleton.dart';
import '../services/tutorial_targets.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/card_action_button.dart';
import '../widgets/guide_dialog.dart';
import '../widgets/session_count_button.dart';
import '../widgets/tutorial_overlay.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  late Map<String, List<String>> exercises;
  late List<String> urls;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    exercises = singleton.exercises;
    urls = singleton.exercises.keys.toList();
    singleton.addListener(_onSingletonUpdate);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    singleton.removeListener(_onSingletonUpdate);
    _animationController.dispose();
    super.dispose();
  }

  void _onSingletonUpdate() {
    if (mounted) setState(() {});
  }

  void _showExerciseGuide() {
    showGuideDialog(
      context,
      icon: Icons.fitness_center_rounded,
      title: 'Exercise Guide',
      body:
          'Follow each session at your own pace. Stop if you feel pain, dizziness, or shortness of breath.\n\nTap Log on a lesson card each time you finish a session to track how many times you have done it.',
      footnote:
          'Sources: Official YouTube channels listed on each lesson card.',
    );
  }

  void _showLoggedSnack(String title, int count) {
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: colors.surface.blend(colors.success, 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border.blend(colors.success, 0.45)),
          ),
          content: Text(
            '$title logged. Completed $count time${count == 1 ? '' : 's'}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TutorialOverlay(
      steps: const [],
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {
              HapticUtils.lightImpact();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text('Exercises',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600)),
          actions: [
            TextButton.icon(
              onPressed: () {
                HapticUtils.lightImpact();
                _showExerciseGuide();
              },
              icon: Icon(Icons.menu_book_rounded,
                  color: colors.primary, size: 18),
              label: Text(
                'Guide',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Physical Exercises',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Video-guided exercises to help with mobility and strength',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                itemBuilder: (BuildContext context, int index) {
                  return FadeTransition(
                    opacity: _animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          0.1 + (index / exercises.length) * 0.4,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      )),
                      child: Container(
                        key: index == 0
                            ? TutorialTargets.firstExerciseCardKey
                            : null,
                        child: _ExerciseCard(
                          title: singleton.exercises[urls[index]]![0],
                          description: singleton.exercises[urls[index]]![1],
                          duration: singleton.exercises[urls[index]]!.length > 2
                              ? singleton.exercises[urls[index]]![2]
                              : '',
                          source: singleton.exercises[urls[index]]!.length > 3
                              ? singleton.exercises[urls[index]]![3]
                              : '',
                          thumbnailUrl:
                              'https://img.youtube.com/vi/${urls[index]}/hqdefault.jpg',
                          sessionCount: singleton
                              .exerciseSessionCountForVideo(urls[index]),
                          onLogSession: () {
                            HapticUtils.success();
                            final count = singleton
                                .recordPhysicalExerciseSession(urls[index]);
                            setState(() {});
                            _showLoggedSnack(
                              singleton.exercises[urls[index]]![0],
                              count,
                            );
                          },
                          onTap: () {
                            HapticUtils.cardTap();
                            singleton.setCurrentUrl(urls[index]);
                            Navigator.pushNamed(
                                context, '/exerciseVideoScreen');
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final String title;
  final String description;
  final String duration;
  final String source;
  final String thumbnailUrl;
  final int sessionCount;
  final VoidCallback onLogSession;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.title,
    required this.description,
    required this.duration,
    required this.source,
    required this.thumbnailUrl,
    required this.sessionCount,
    required this.onLogSession,
    required this.onTap,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _isPressed = false;
  bool _useFallbackThumbnail = false;
  static final RegExp _durationPattern = RegExp(r'^(\d{1,2}:)?\d{1,2}:\d{2}$');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.diagonal3Values(
            _isPressed ? 0.98 : 1.0, _isPressed ? 0.98 : 1.0, 1.0),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: _isPressed ? 0.05 : 0.1),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _useFallbackThumbnail
                          ? widget.thumbnailUrl.replaceFirst(
                              '/hqdefault.jpg',
                              '/mqdefault.jpg',
                            )
                          : widget.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        if (!_useFallbackThumbnail) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _useFallbackThumbnail = true);
                            }
                          });
                        }
                        return Container(
                          color: colors.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.play_circle_filled_rounded,
                              size: 48,
                              color: colors.textTertiary,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colors.surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  if (widget.duration.isNotEmpty &&
                      _durationPattern.hasMatch(widget.duration))
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  // Play button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: colors.textOnPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Session counter
                  Positioned(
                    top: 12,
                    right: 12,
                    child: SessionCountBadge(
                      count: widget.sessionCount,
                      accent: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Physical exercise',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What you will practice',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    height: 1.35,
                                  ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.source.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        widget.source,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SessionCountChip(
                            count: widget.sessionCount,
                            accent: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CardActionButton(
                        label: 'Log',
                        icon: Icons.add_rounded,
                        accent: colors.primary,
                        onTap: widget.onLogSession,
                      ),
                      const SizedBox(width: 8),
                      CardActionButton(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        accent: colors.primary,
                        filled: true,
                        onTap: widget.onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
