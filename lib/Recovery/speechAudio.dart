import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:levio/singleton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class SpeechAudio extends StatefulWidget {
  const SpeechAudio({super.key});

  @override
  State<SpeechAudio> createState() => _SpeechAudioState();
}

class _SpeechAudioState extends State<SpeechAudio> {
  final singleton = Singleton();
  late YoutubePlayerController _controller;
  String get _youtubeUrl =>
      'https://www.youtube.com/watch?v=${singleton.currentURL}';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: singleton.currentURL,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
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

  void _showSpeechText() {
    final colors = context.colors;
    final speechData = singleton.speeches[singleton.currentURL];
    final title = speechData != null ? speechData[0] : 'Speech Exercise';
    final description = speechData != null ? speechData[1] : '';
    final source =
        speechData != null && speechData.length > 3 ? speechData[3] : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speech Text',
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(c).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(c).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                ),
                if (source.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    source,
                    style: Theme.of(c).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final speechData = singleton.speeches[singleton.currentURL];
    final source =
        speechData != null && speechData.length > 3 ? speechData[3] : '';

    if (speechData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Speech Therapy')),
        body: const Center(child: Text('Video not found')),
      );
    }

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
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: const Text('Speech Therapy'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  HapticUtils.lightImpact();
                  _showSpeechText();
                },
                icon:
                    Icon(Icons.notes_rounded, color: colors.primary, size: 18),
                label: Text(
                  'Text',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
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
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  speechData[0],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  speechData[1],
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
                const SizedBox(height: 24),

                // Video player
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: player,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
