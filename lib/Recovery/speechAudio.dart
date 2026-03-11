import 'package:flutter/material.dart';
import 'package:levio/singleton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

class SpeechAudio extends StatefulWidget {
  const SpeechAudio({super.key});

  @override
  State<SpeechAudio> createState() => _SpeechAudioState();
}

class _SpeechAudioState extends State<SpeechAudio> {
  final singleton = Singleton();
  WebViewController? _webViewController;
  String? _videoId;
  bool _isVideoLoading = true;

  String get _youtubeUrl =>
      'https://www.youtube.com/watch?v=${_videoId ?? singleton.currentURL}';

  @override
  void initState() {
    super.initState();
    _videoId = singleton.normalizeYouTubeVideoId(singleton.currentURL);
    if (_videoId != null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() => _isVideoLoading = true);
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() => _isVideoLoading = false);
            },
            onWebResourceError: (_) {
              if (!mounted) return;
              setState(() => _webViewController = null);
            },
          ),
        )
        ..loadRequest(Uri.parse('https://m.youtube.com/watch?v=$_videoId'));
    }
  }

  @override
  void dispose() => super.dispose();

  Future<void> _openInAppBrowser() async {
    if (_videoId == null) return;
    final uri = Uri.parse(_youtubeUrl);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _openInYouTube() async {
    if (_videoId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This video link appears invalid.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

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
          title: Text('Speech Therapy',
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        body: Container(
            color: colors.background,
            child: const Center(child: Text('Video not found'))),
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
        title: Text('Speech Therapy',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Official Speech Session',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              (_webViewController != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child:
                                WebViewWidget(controller: _webViewController!),
                          ),
                          if (_isVideoLoading)
                            Positioned.fill(
                              child: ColoredBox(
                                color: colors.surface.withValues(alpha: 0.92),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: colors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Loading video...',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unable to load video in-app',
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Open this speech session directly in YouTube.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _openInAppBrowser,
                                  icon:
                                      const Icon(Icons.ondemand_video_rounded),
                                  label: const Text('Play in App'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openInYouTube,
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('Open YouTube'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
