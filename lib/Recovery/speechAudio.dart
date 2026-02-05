import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:parkinson/singleton.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import '../widgets/modern_card.dart';

class SpeechAudio extends StatefulWidget {
  const SpeechAudio({super.key});

  @override
  State<SpeechAudio> createState() => _SpeechAudioState();
}

class _SpeechAudioState extends State<SpeechAudio>
    with SingleTickerProviderStateMixin {
  final singleton = Singleton();

  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;
  String get _durationText => _formatDuration(_duration);
  String get _positionText => _formatDuration(_position);

  final player = AudioPlayer();

  late AnimationController _animationController;
  late Animation<double> _animation;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _play() async {
    HapticUtils.mediumImpact();
    await player.play(UrlSource(singleton.currentURL));
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _resume() async {
    HapticUtils.lightImpact();
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    HapticUtils.lightImpact();
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    HapticUtils.lightImpact();
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  void checkPause() {
    if (_isPaused) {
      _resume();
    } else {
      _play();
    }
  }

  @override
  void initState() {
    super.initState();
    _playerState = player.state;
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    _animationController.dispose();
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
            player.stop();
            Navigator.pushNamed(context, '/speechScreen');
          },
        ),
        title: const Text('Speech Therapy'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Album art / visualization
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.info,
                      colors.info.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: colors.info.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated ring for playing state
                    if (_isPlaying)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.1),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    Icon(
                      Icons.headphones_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Title and description
              Text(
                singleton.speeches[singleton.currentURL]![0],
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                singleton.speeches[singleton.currentURL]![1],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Progress slider
              ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Time display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _positionText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                        Text(
                          _durationText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.info,
                        inactiveTrackColor: colors.info.withOpacity(0.2),
                        thumbColor: colors.info,
                        overlayColor: colors.info.withOpacity(0.1),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        onChanged: (value) {
                          final duration = _duration;
                          if (duration == null) return;
                          final position = value * duration.inMilliseconds;
                          player.seek(Duration(milliseconds: position.round()));
                        },
                        value: (_position != null &&
                                _duration != null &&
                                _position!.inMilliseconds > 0 &&
                                _position!.inMilliseconds <
                                    _duration!.inMilliseconds)
                            ? _position!.inMilliseconds /
                                _duration!.inMilliseconds
                            : 0.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stop button
                        _ControlButton(
                          icon: Icons.stop_rounded,
                          size: 48,
                          color: colors.textSecondary,
                          backgroundColor: colors.surfaceVariant,
                          onPressed:
                              _isPlaying || _isPaused ? _stop : () {},
                        ),
                        const SizedBox(width: 24),

                        // Play/Pause button
                        _ControlButton(
                          icon: _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 72,
                          color: Colors.white,
                          backgroundColor: colors.info,
                          onPressed: _isPlaying ? _pause : checkPause,
                          showShadow: true,
                        ),
                        const SizedBox(width: 24),

                        // Replay button
                        _ControlButton(
                          icon: Icons.replay_rounded,
                          size: 48,
                          color: colors.textSecondary,
                          backgroundColor: colors.surfaceVariant,
                          onPressed: () async {
                            HapticUtils.lightImpact();
                            await player.seek(Duration.zero);
                            if (!_isPlaying) {
                              _play();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tips
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tips_and_updates_rounded,
                        color: colors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Tip',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Repeat each exercise 3-5 times for best results.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
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

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final bool showShadow;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
    this.showShadow = false,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.identity()..scale(_isPressed ? 0.9 : 1.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.3),
                    blurRadius: _isPressed ? 8 : 16,
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
