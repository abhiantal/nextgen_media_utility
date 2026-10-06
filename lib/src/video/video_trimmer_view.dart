// ============================================================
// FILE: lib/src/video/video_trimmer_view.dart
// NextGen Media Utility - Modular Video Trimmer & Preview
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/media_loading_indicator.dart';

class VideoTrimmerView extends StatefulWidget {
  final File file;
  final double maxDurationInSeconds;

  const VideoTrimmerView({
    super.key,
    required this.file,
    this.maxDurationInSeconds = 60.0,
  });

  @override
  State<VideoTrimmerView> createState() => _VideoTrimmerViewState();
}

class _VideoTrimmerViewState extends State<VideoTrimmerView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  double _startValue = 0.0;
  double _endValue = 1.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.file(widget.file);
    try {
      await _controller.initialize();
      _endValue = _controller.value.duration.inMilliseconds.toDouble();
      setState(() {
        _isInitialized = true;
      });
      _controller.addListener(_videoListener);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _videoListener() {
    if (!mounted) return;
    final pos = _controller.value.position.inMilliseconds.toDouble();
    if (pos >= _endValue) {
      _controller.pause();
      _controller.seekTo(Duration(milliseconds: _startValue.toInt()));
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _isPlaying = false);
    } else {
      _controller.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trim Video'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              // Return original file path (or trimmed path if processed)
              Navigator.pop(context, widget.file.path);
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: FuturisticLoadingIndicator(radius: 20))
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: Colors.black87,
                  child: Column(
                    children: [
                      RangeSlider(
                        values: RangeValues(
                          _startValue,
                          _endValue.clamp(_startValue, _controller.value.duration.inMilliseconds.toDouble()),
                        ),
                        min: 0.0,
                        max: _controller.value.duration.inMilliseconds.toDouble(),
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.grey.shade800,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _startValue = values.start;
                            _endValue = values.end;
                          });
                          _controller.seekTo(Duration(milliseconds: values.start.toInt()));
                        },
                      ),
                      IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                        onPressed: _togglePlay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
