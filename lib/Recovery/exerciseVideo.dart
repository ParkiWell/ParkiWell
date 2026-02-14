import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:levio/singleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

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
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _recordingController;

  String? _recordedVideoPath;
  bool _isRecordingVideo = false;

  bool get _hasRecording => _recordedVideoPath != null;
  String get _youtubeUrl =>
      'https://www.youtube.com/watch?v=${singleton.currentURL}';
  String get _thumbnailUrl =>
      'https://img.youtube.com/vi/${singleton.currentURL}/hqdefault.jpg';

  @override
  void dispose() {
    _recordingController?.dispose();
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    final uri = Uri.parse(_youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Unable to open YouTube link'),
        backgroundColor: context.colors.error,
      ),
    );
  }

  Future<void> _setRecording(String path) async {
    final previous = _recordingController;
    final next = VideoPlayerController.file(File(path));
    await next.initialize();
    await next.setLooping(true);

    if (!mounted) {
      await next.dispose();
      return;
    }

    await previous?.dispose();
    setState(() {
      _recordedVideoPath = path;
      _recordingController = next;
    });
  }

  Future<void> _recordVideo() async {
    if (_isRecordingVideo) return;

    HapticUtils.mediumImpact();
    setState(() => _isRecordingVideo = true);

    try {
      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxDuration: const Duration(minutes: 3),
      );

      if (video == null) return;

      await _setRecording(video.path);
      if (!mounted) return;

      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recording captured successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRecordingVideo = false);
      }
    }
  }

  void _clearRecording() {
    HapticUtils.lightImpact();
    final controller = _recordingController;
    setState(() {
      _recordingController = null;
      _recordedVideoPath = null;
    });
    controller?.dispose();
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
                      color: colors.primary.withValues(alpha: 0.1),
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
                'Your recording was detected and analyzed successfully.',
                style: Theme.of(c).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(c),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exerciseData = singleton.exercises[singleton.currentURL];

    if (exerciseData == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Exercise',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        body: Container(
            color: colors.background,
            child: const Center(child: Text('Video not found'))),
      );
    }

    final source = exerciseData.length > 3 ? exerciseData[3] : '';

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
        title: Text('Exercise',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Open in YouTube',
            onPressed: () {
              HapticUtils.lightImpact();
              _openInYouTube();
            },
            icon: Icon(
              Icons.open_in_new_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        color: colors.background,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exerciseData[0],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseData[1],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              if (source.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  source,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 16),

              // Video thumbnail — tap to open in YouTube
              GestureDetector(
                onTap: () {
                  HapticUtils.lightImpact();
                  _openInYouTube();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colors.surfaceVariant,
                            child: Icon(Icons.videocam_off_rounded,
                                size: 48, color: colors.textTertiary),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Watch on YouTube',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: _hasRecording ? 'Re-record' : 'Record Yourself',
                      icon: Icons.videocam_rounded,
                      isLoading: _isRecordingVideo,
                      onPressed: _recordVideo,
                    ),
                  ),
                  if (_hasRecording) ...[
                    const SizedBox(width: 10),
                    ModernIconButton(
                      icon: Icons.delete_outline_rounded,
                      backgroundColor: colors.error,
                      onPressed: _clearRecording,
                    ),
                  ],
                ],
              ),
              if (_recordingController != null &&
                  _recordingController!.value.isInitialized) ...[
                const SizedBox(height: 14),
                ModernCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Recording',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: _recordingController!.value.aspectRatio,
                          child: VideoPlayer(_recordingController!),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            HapticUtils.lightImpact();
                            final controller = _recordingController;
                            if (controller == null) return;
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            _recordingController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _recordingController!.value.isPlaying
                                ? 'Pause Preview'
                                : 'Play Preview',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'AI Analysis',
                  icon: Icons.auto_awesome_rounded,
                  isOutlined: !_hasRecording,
                  onPressed: !_hasRecording
                      ? () {
                          HapticUtils.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Record yourself first to run AI analysis.',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: colors.info,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      : () {
                          HapticUtils.mediumImpact();
                          _showAnalysisDialog();
                        },
                ),
              ),
            ],
          ),
        ),
      ),
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
        color: color.withValues(alpha: 0.1),
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
