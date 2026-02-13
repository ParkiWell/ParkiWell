import 'package:flutter/material.dart';
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
  String get _youtubeUrl =>
      'https://www.youtube.com/watch?v=${singleton.currentURL}';
  String get _thumbnailUrl =>
      'https://img.youtube.com/vi/${singleton.currentURL}/hqdefault.jpg';

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
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Speech Therapy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        body: Container(color: colors.background, child: const Center(child: Text('Video not found'))),
      );
    }

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
        title: Text('Speech Therapy', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                            child: Icon(Icons.videocam_off_rounded, size: 48, color: colors.textTertiary),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Watch on YouTube',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
            ],
          ),
        ),
      ),
    );
  }
}
