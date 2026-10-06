import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../core/media_logger.dart';
import '../display/media_display.dart' show UniversalMediaService;

enum AudioPlayerStyle { bubble, card }

class AnimatedAudioPlayer extends StatefulWidget {
  final String url;
  final bool isLocal;
  final String? title;
  final String? subtitle;
  final double? height;
  final Color? primaryColor;
  final Color? accentColor;
  final AudioPlayerStyle style;
  final bool isMe;
  final double borderRadius;
  final bool showDetails;
  final bool transparentBackground;
  final DateTime? timestamp;
  final bool autoPlay;
  final bool showWaveform;

  const AnimatedAudioPlayer({
    super.key,
    required this.url,
    this.isLocal = false,
    this.title = 'Audio Message',
    this.subtitle,
    this.height,
    this.primaryColor,
    this.accentColor,
    this.style = AudioPlayerStyle.bubble,
    this.isMe = false,
    this.borderRadius = 16.0,
    this.showDetails = true,
    this.transparentBackground = false,
    this.timestamp,
    this.autoPlay = false,
    this.showWaveform = true,
  });

  @override
  State<AnimatedAudioPlayer> createState() => _AnimatedAudioPlayerState();
}

class _AnimatedAudioPlayerState extends State<AnimatedAudioPlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  bool _isLoaded = false;
  bool _hasError = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAudio();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initAudio() async {
    try {
      _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
            _isLoaded = true;
          });
        }
      });

      _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((
        event,
      ) {
        if (mounted) {
          setState(() {
            _playerState = PlayerState.stopped;
            _position = Duration.zero;
          });
          _pulseController.stop();
          _pulseController.reset();
        }
      });

      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() => _playerState = state);
          if (state == PlayerState.playing) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
            _pulseController.reset();
          }
        }
      });

      String finalUrl = widget.url;
      if (!widget.isLocal) {
        final resolved = await UniversalMediaService().getValidSignedUrl(
          widget.url,
        );
        if (resolved != null) {
          finalUrl = resolved;
        }
      }

      final source = widget.isLocal
          ? DeviceFileSource(finalUrl)
          : UrlSource(finalUrl);
      await _audioPlayer.setSource(source);

      if (widget.autoPlay) {
        await _audioPlayer.play(source);
      }
    } catch (e, s) {
      logE('Error loading audio: $e', e, s);
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_hasError) return;
    HapticFeedback.lightImpact();
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      if (!_isLoaded) {
        final source = widget.isLocal
            ? DeviceFileSource(widget.url)
            : UrlSource(widget.url);
        await _audioPlayer.play(source);
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAudioIcon(ThemeData theme, Color primaryColor) {
    final isPlaying = _playerState == PlayerState.playing;
    return ScaleTransition(
      scale: isPlaying ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: isPlaying ? 0.8 : 0.2),
              primaryColor.withValues(alpha: isPlaying ? 1.0 : 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.music_note_rounded : Icons.audiotrack_rounded,
            color: isPlaying ? Colors.white : primaryColor,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color primaryColor) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
        thumbColor: primaryColor,
      ),
      child: Slider(
        value: _position.inMilliseconds.toDouble(),
        min: 0.0,
        max: _duration.inMilliseconds > 0
            ? _duration.inMilliseconds.toDouble()
            : 1.0,
        onChanged: (val) {
          _audioPlayer.seek(Duration(milliseconds: val.toInt()));
        },
      ),
    );
  }

  Widget _buildCardPlayer(ThemeData theme, Color primaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.transparentBackground
        ? Colors.transparent
        : (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white);

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: 320, // Give it a fixed width so scaleDown works correctly
            height: 320, // Forced 320 height for full screen as requested
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.transparentBackground
                  ? null
                  : Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
              boxShadow: widget.transparentBackground
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Idle Icon or Pulsing Animation
                _buildAudioIcon(theme, primaryColor),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title ?? 'Audio Message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Progress & Times
                _buildProgressBar(primaryColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      // Force a reasonable width so spaceBetween works correctly inside FittedBox
                      width: 250,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Play Controls
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        onPressed: () {
                          final newPos =
                              _position - const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos < Duration.zero ? Duration.zero : newPos,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _playPause,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _playerState == PlayerState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        onPressed: () {
                          final newPos =
                              _position + const Duration(seconds: 10);
                          _audioPlayer.seek(
                            newPos > _duration ? _duration : newPos,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubblePlayer(ThemeData theme, Color primaryColor) {
    // For smaller bubble or grid contexts, return a very simple representation
    final isDark = theme.brightness == Brightness.dark;
    final onBubbleColor = widget.isMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final bgColor = widget.transparentBackground
        ? Colors.transparent
        : (widget.isMe
              ? primaryColor
              : (isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey.shade100));

    // If it's just meant as a thumbnail (showDetails == false), show just the icon
    if (!widget.showDetails) {
      return Center(child: _buildAudioIcon(theme, primaryColor));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playerState == PlayerState.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title ?? 'Audio Message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onBubbleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                _buildProgressBar(widget.isMe ? Colors.white : primaryColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: onBubbleColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: onBubbleColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    if (_hasError) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(height: 8),
              Text('Failed to load audio', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (widget.style == AudioPlayerStyle.card) {
      return _buildCardPlayer(theme, primaryColor);
    } else {
      return _buildBubblePlayer(theme, primaryColor);
    }
  }
}
