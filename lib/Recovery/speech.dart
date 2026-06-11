import 'package:flutter/material.dart';
import 'package:levio/singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/card_action_button.dart';
import '../widgets/guide_dialog.dart';
import '../widgets/session_count_button.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();
  late Map<String, List<String>> speeches;
  late List<String> videoIds;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    speeches = singleton.speeches;
    videoIds = singleton.speeches.keys.toList();
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

  void _showSpeechGuide() {
    showGuideDialog(
      context,
      icon: Icons.record_voice_over_rounded,
      title: 'Speech Guide',
      body:
          'Use these videos to practice speaking loudly and clearly. Pause and repeat sections as needed.\n\nTap Log on a lesson card each time you finish a session to track how many times you have done it.',
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

    return Scaffold(
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
        title: Text('Speech Therapy',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticUtils.lightImpact();
              _showSpeechGuide();
            },
            icon:
                Icon(Icons.menu_book_rounded, color: colors.primary, size: 18),
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
                      'Speech Exercises',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video-guided exercises from LSVT LOUD and speech therapists',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Speech video list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: speeches.length,
              itemBuilder: (BuildContext context, int index) {
                final videoId = videoIds[index];
                final speechData = singleton.speeches[videoId]!;
                return FadeTransition(
                  opacity: _animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.1 + (index / speeches.length) * 0.4,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    )),
                    child: _SpeechVideoCard(
                      title: speechData[0],
                      description: speechData[1],
                      duration: speechData.length > 2 ? speechData[2] : '',
                      source: speechData.length > 3 ? speechData[3] : '',
                      thumbnailUrl:
                          'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                      sessionCount:
                          singleton.speechSessionCountForVideo(videoId),
                      onLogSession: () {
                        HapticUtils.success();
                        final count =
                            singleton.recordSpeechExerciseSession(videoId);
                        setState(() {});
                        _showLoggedSnack(speechData[0], count);
                      },
                      onTap: () {
                        HapticUtils.cardTap();
                        singleton.setCurrentUrl(videoId);
                        Navigator.pushNamed(context, '/speechAudio');
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechVideoCard extends StatefulWidget {
  final String title;
  final String description;
  final String duration;
  final String source;
  final String thumbnailUrl;
  final int sessionCount;
  final VoidCallback onLogSession;
  final VoidCallback onTap;

  const _SpeechVideoCard({
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
  State<_SpeechVideoCard> createState() => _SpeechVideoCardState();
}

class _SpeechVideoCardState extends State<_SpeechVideoCard> {
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
          _isPressed ? 0.98 : 1.0,
          _isPressed ? 0.98 : 1.0,
          1.0,
        ),
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
                          color: colors.info.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              Icons.record_voice_over_rounded,
                              size: 48,
                              color: colors.info,
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
                              color: colors.info,
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
                            Colors.black.withValues(alpha: 0.4),
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
                        color: colors.info,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.info.withValues(alpha: 0.3),
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
                      accent: colors.info,
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
                        Icons.record_voice_over_rounded,
                        size: 16,
                        color: colors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Speech Therapy',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.info,
                              fontWeight: FontWeight.w600,
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
                            accent: colors.info,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CardActionButton(
                        label: 'Log',
                        icon: Icons.add_rounded,
                        accent: colors.info,
                        onTap: widget.onLogSession,
                      ),
                      const SizedBox(width: 8),
                      CardActionButton(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        accent: colors.info,
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
