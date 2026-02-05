import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:levio/singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class ExerciseVideo extends StatefulWidget {
  const ExerciseVideo({super.key});

  @override
  State<ExerciseVideo> createState() => _ExerciseVideoState();
}

class _ExerciseVideoState extends State<ExerciseVideo> {
  final singleton = Singleton();
  late YoutubePlayerController _controller;
  bool recording = false;
  bool isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: singleton.currentURL,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
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
                _controller.close();
                Navigator.pushNamed(context, '/exerciseScreen');
              },
            ),
            title: const Text('Exercise'),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  singleton.exercises[singleton.currentURL]![0],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  singleton.exercises[singleton.currentURL]![1],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                // Video player
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: player,
                ),
                const SizedBox(height: 24),

                // Action buttons
                if (!recording) ...[
                  ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tips_and_updates_rounded,
                                color: colors.info,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Watch the video and follow along at your own pace.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Record button
                  SizedBox(
                    width: double.infinity,
                    child: ModernButton(
                      text: 'Record Yourself',
                      icon: Icons.videocam_rounded,
                      onPressed: () {
                        HapticUtils.mediumImpact();
                        setState(() => recording = true);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI Analysis button
                  SizedBox(
                    width: double.infinity,
                    child: ModernButton(
                      text: 'AI Analysis',
                      icon: Icons.auto_awesome_rounded,
                      isOutlined: true,
                      backgroundColor: isButtonDisabled
                          ? colors.textTertiary
                          : colors.primary,
                      onPressed: isButtonDisabled
                          ? () {
                              HapticUtils.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Record yourself first to get AI analysis'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: colors.info,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          : () {
                              HapticUtils.mediumImpact();
                              _showAnalysisDialog();
                            },
                    ),
                  ),
                ] else ...[
                  // Recording UI
                  ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.videocam_rounded,
                                  color: colors.error,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recording...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ModernButton(
                                text: 'Cancel',
                                isOutlined: true,
                                onPressed: () {
                                  HapticUtils.lightImpact();
                                  setState(() => recording = false);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernButton(
                                text: 'Save',
                                icon: Icons.check_rounded,
                                backgroundColor: colors.success,
                                onPressed: () {
                                  HapticUtils.success();
                                  _showSaveDialog();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Video Saved',
                style: Theme.of(c).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your recording has been saved. You can now get AI analysis.',
                style: Theme.of(c).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Continue',
                  onPressed: () {
                    setState(() {
                      isButtonDisabled = false;
                      recording = false;
                    });
                    Navigator.pop(c);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAnalysisDialog() {
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'AI Analysis',
                    style: Theme.of(c).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _AnalysisItem(
                label: 'Score',
                value: '85%',
                color: colors.success,
              ),
              const SizedBox(height: 16),
              Text(
                'Tips for Improvement',
                style: Theme.of(c).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _TipItem(text: 'Keep your movements slow and controlled'),
              _TipItem(text: 'Focus on full range of motion'),
              _TipItem(text: 'Remember to breathe steadily'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Got It',
                  onPressed: () => Navigator.pop(c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalysisItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
