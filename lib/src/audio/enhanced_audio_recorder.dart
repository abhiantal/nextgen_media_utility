import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:camera/camera.dart';

class EnhancedAudioRecorder extends StatefulWidget {
  final Function(XFile file)? onCompleted;
  final VoidCallback? onCanceled;

  const EnhancedAudioRecorder({super.key, this.onCompleted, this.onCanceled});

  @override
  State<EnhancedAudioRecorder> createState() => _EnhancedAudioRecorderState();
}

class _EnhancedAudioRecorderState extends State<EnhancedAudioRecorder>
    with TickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;
  Duration _duration = Duration.zero;
  Timer? _timer;

  // Animations
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real-time waveform data
  final List<double> _amplitudes = List.filled(40, 0.05);
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      HapticFeedback.mediumImpact();
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      await _recorder.start(const RecordConfig(), path: path);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _hasRecording = false;
        _recordedPath = path;
        _duration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);
      _startTimer();
      _startAmplitudeTracking();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _duration += const Duration(seconds: 1));
    });
  }

  void _startAmplitudeTracking() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = Stream.periodic(const Duration(milliseconds: 100))
        .asyncMap((_) => _recorder.getAmplitude())
        .listen((amp) {
          if (mounted && _isRecording && !_isPaused) {
            setState(() {
              _amplitudes.removeAt(0);
              // Convert dB to 0.0 - 1.0 range
              double value = (amp.current + 40) / 40;
              _amplitudes.add(value.clamp(0.05, 1.0));
            });
          }
        });
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    _startTimer();
    _pulseController.repeat(reverse: true);
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (path != null) {
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordedPath = path;
      });
    }
  }

  void _save() {
    if (_recordedPath != null) {
      widget.onCompleted?.call(XFile(_recordedPath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording
                  ? (_isPaused ? 'Recording Paused' : 'Recording...')
                  : 'Ready to Record',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildWaveform(),
            const SizedBox(height: 24),
            Text(
              _formatDuration(_duration),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w300,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 40),
            _buildControls(theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CustomPaint(
        painter: _LiveWaveformPainter(
          amplitudes: _amplitudes,
          isRecording: _isRecording && !_isPaused,
          color: _isRecording ? Colors.redAccent : Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    if (!_isRecording && !_hasRecording) {
      return GestureDetector(
        onTap: _startRecording,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 40),
          ),
        ),
      );
    }

    if (_isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              _recorder.stop();
              widget.onCanceled?.call();
            },
            icon: const Icon(Icons.close, color: Colors.grey, size: 32),
          ),
          GestureDetector(
            onTap: _isPaused ? _resumeRecording : _pauseRecording,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.orange,
                size: 35,
              ),
            ),
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 35),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setState(() {
            _hasRecording = false;
            _duration = Duration.zero;
          }),
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
        ),
        GestureDetector(
          onTap: () async {
            if (_isPlaying) {
              await _player.stop();
            } else {
              await _player.play(DeviceFileSource(_recordedPath!));
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        IconButton(
          onPressed: _save,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _LiveWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final bool isRecording;
  final Color color;

  _LiveWaveformPainter({
    required this.amplitudes,
    required this.isRecording,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / amplitudes.length;
    final centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final h = amplitudes[i] * size.height;
      final x = i * spacing;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveWaveformPainter oldDelegate) => true;
}
