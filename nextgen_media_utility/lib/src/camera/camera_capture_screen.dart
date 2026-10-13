// ============================================================
// FILE: lib/media_utility/camera_capture_screen.dart
// ✅ FIXED: Filter circles now use static gradients to prevent extreme GPU lag
// ✅ FIXED: Buttons with spring animations + haptic + glow effects
// ✅ All original features preserved
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

import '../core/media_loading_indicator.dart';
import '../core/media_asset_model.dart';
import '../core/media_logger.dart';
import '../core/media_snackbar.dart';
import '../picker/gallery_picker_screen.dart';
import '../editor/color_filters.dart';

class CameraCaptureResult {
  final List<XFile> files;
  final ColorFilter? filter;
  final String? filterName;

  CameraCaptureResult({required this.files, this.filter, this.filterName});
}

class CameraCaptureScreen extends StatefulWidget {
  final bool allowVideo;

  const CameraCaptureScreen({super.key, this.allowVideo = true});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static bool _isIdentityMatrix(List<double>? m) {
    if (m == null || m.length != 20) return true;
    return m[0] == 1.0 && m[1] == 0.0 && m[2] == 0.0 && m[3] == 0.0 && m[4] == 0.0 &&
           m[5] == 0.0 && m[6] == 1.0 && m[7] == 0.0 && m[8] == 0.0 && m[9] == 0.0 &&
           m[10] == 0.0 && m[11] == 0.0 && m[12] == 1.0 && m[13] == 0.0 && m[14] == 0.0 &&
           m[15] == 0.0 && m[16] == 0.0 && m[17] == 0.0 && m[18] == 1.0 && m[19] == 0.0;
  }

  // Isolate processing params — optimized for ultra-fast response
  static Future<File> _processPhotoIsolate(Map<String, dynamic> params) async {
    try {
      final String path = params['path'];
      final bool isRearCamera = params['isRearCamera'];
      final List<double>? matrix = params['matrix'];
      final String tempDirPath = params['tempDirPath'];

      // 1. Fast native TurboJPEG compression (C++/NDK)
      final compressedPath =
          '$tempDirPath/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        path,
        compressedPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1920,
      );

      final fileToUse =
          compressedFile != null ? File(compressedFile.path) : File(path);

      final bool hasFilter =
          matrix != null && matrix.length == 20 && !_isIdentityMatrix(matrix);

      // Instant 0ms return for standard rear camera capture without color filter
      if (isRearCamera && !hasFilter) {
        return fileToUse;
      }

      // Fast image decode
      final bytes = await fileToUse.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return fileToUse;

      // Front selfie camera: flip horizontally
      if (!isRearCamera) {
        image = img.flipHorizontal(image);
      }

      // If no color filter, save flipped selfie and return
      if (!hasFilter) {
        final flippedPath =
            '$tempDirPath/flipped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final out = File(flippedPath);
        await out.writeAsBytes(img.encodeJpg(image, quality: 85));
        return out;
      }

      // 2. High-speed in-place matrix transformation
      final m0 = matrix[0], m1 = matrix[1], m2 = matrix[2], m4 = matrix[4];
      final m5 = matrix[5], m6 = matrix[6], m7 = matrix[7], m9 = matrix[9];
      final m10 = matrix[10], m11 = matrix[11], m12 = matrix[12], m14 = matrix[14];

      for (final pixel in image) {
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        final nr = (r * m0 + g * m1 + b * m2 + m4).clamp(0, 255).toInt();
        final ng = (r * m5 + g * m6 + b * m7 + m9).clamp(0, 255).toInt();
        final nb = (r * m10 + g * m11 + b * m12 + m14).clamp(0, 255).toInt();

        pixel.r = nr;
        pixel.g = ng;
        pixel.b = nb;
      }

      final outputBytes = img.encodeJpg(image, quality: 85);
      final outputPath =
          '$tempDirPath/captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);
      return outputFile;
    } catch (e) {
      return File(params['path']);
    }
  }

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isRecordingPending = false;
  bool _isRearCamera = true;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(1.0);

  final List<XFile> _recordedClips = [];
  Duration _totalRecordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // -- Animation controllers --
  late AnimationController _shutterAnimController;
  late AnimationController _recordPulseController;
  late AnimationController _captureButtonController;
  late AnimationController _switchButtonController;
  late AnimationController _galleryButtonController;
  late AnimationController _flashButtonController;
  late AnimationController _closeButtonController;
  late AnimationController _filterSwitchController;

  late Animation<double> _recordPulseAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _switchScaleAnimation;
  late Animation<double> _galleryScaleAnimation;
  late Animation<double> _flashScaleAnimation;
  late Animation<double> _closeScaleAnimation;

  late List<Map<String, dynamic>> _filters;
  int _selectedFilterIndex = 0;

  Uint8List? _latestMediaThumbnailBytes;

  // ✅ Scroll controller to snap filter to center
  final ScrollController _filterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filters = ColorFilters.getAllFilters();
    _initAnimations();
    _initializeCamera();
    _loadLatestMediaThumbnail();
  }

  Future<void> _loadLatestMediaThumbnail() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) return;

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      if (albums.isNotEmpty) {
        final List<AssetEntity> media = await albums.first.getAssetListPaged(
          page: 0,
          size: 1,
        );
        if (media.isNotEmpty) {
          final Uint8List? thumb = await media.first.thumbnailDataWithSize(
            const ThumbnailSize(140, 140),
            quality: 70,
          );
          if (thumb != null && mounted) {
            setState(() => _latestMediaThumbnailBytes = thumb);
          }
        }
      }
    } catch (e) {
      logW('Could not fetch latest media thumbnail: $e');
    }
  }

  void _initAnimations() {
    _shutterAnimController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    // Only pulsate during actual recording, not idle
    _recordPulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _recordPulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _recordPulseController, curve: Curves.easeInOut),
    );

    // -- Shutter button spring --
    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _captureButtonController, curve: Curves.easeOut),
    );

    // -- Switch camera spring --
    _switchButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _switchButtonController,
        curve: Curves.easeInBack,
      ),
    );

    // -- Gallery button spring --
    _galleryButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _galleryScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _galleryButtonController, curve: Curves.easeOut),
    );

    // -- Flash button spring --
    _flashButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _flashScaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _flashButtonController, curve: Curves.easeOut),
    );

    // -- Close button spring --
    _closeButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _closeScaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _closeButtonController, curve: Curves.easeOut),
    );

    // -- Filter strip slide in --
    _filterSwitchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _filterSwitchController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recordingTimer?.cancel();
    _filterToastTimer?.cancel();
    _shutterAnimController.dispose();
    _recordPulseController.dispose();
    _captureButtonController.dispose();
    _switchButtonController.dispose();
    _galleryButtonController.dispose();
    _flashButtonController.dispose();
    _closeButtonController.dispose();
    _filterSwitchController.dispose();
    _filterScrollController.dispose();
    _zoomNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        snackbarService.showWarning('No cameras available');
        return;
      }

      _cameras = cameras;
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _controller?.dispose();

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      logE('Camera initialization error: $e');
      if (mounted) snackbarService.showError('Failed to initialize camera');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    HapticFeedback.lightImpact();

    // ✅ Spin animation on switch
    _switchButtonController.forward().then((_) {
      _isRearCamera = !_isRearCamera;
      _switchButtonController.reverse();
    });

    try {
      setState(() => _isCameraInitialized = false);

      final newCamera = _cameras!.firstWhere(
        (cam) =>
            cam.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );

      await _controller?.dispose();

      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = 1.0;

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      logE('Camera switch error: $e');
      snackbarService.showError('Failed to switch camera');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    HapticFeedback.selectionClick();

    // Button tap animation
    _flashButtonController.forward().then(
      (_) => _flashButtonController.reverse(),
    );

    try {
      final nextMode = {
        FlashMode.off: FlashMode.always,
        FlashMode.always: FlashMode.torch,
        FlashMode.torch: FlashMode.auto,
        FlashMode.auto: FlashMode.off,
      }[_flashMode]!;

      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      logE('Flash toggle error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    try {
      setState(() => _isCapturing = true);
      HapticFeedback.mediumImpact();
      _shutterAnimController.forward().then(
        (_) => _shutterAnimController.reverse(),
      );

      final XFile photo = await _controller!.takePicture();
      final processedFile = await _processPhoto(photo);

      if (mounted) {
        Navigator.pop(context, [XFile(processedFile.path)]);
      }
    } catch (e) {
      logE('Photo capture error: $e');
      snackbarService.showError('Failed to capture photo');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<File> _processPhoto(XFile photo) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final matrix = _filters[_selectedFilterIndex]['matrix'] as List<double>?;

      final Map<String, dynamic> params = {
        'path': photo.path,
        'isRearCamera': _isRearCamera,
        'matrix': matrix,
        'tempDirPath': tempDir.path,
      };

      // Import flutter/foundation.dart to use compute
      return await compute(_processPhotoIsolate, params);
    } catch (e) {
      logE('Error processing photo in compute: $e');
      return File(photo.path);
    }
  }

  Future<void> _startRecording() async {
    if (!widget.allowVideo) {
      AppSnackbar.error('Video recording is not allowed here');
      return;
    }
    if (_controller == null || _isRecording || _isRecordingPending) return;

    try {
      setState(() => _isRecordingPending = true);
      HapticFeedback.heavyImpact();

      await _controller!.startVideoRecording();

      if (!_isRecordingPending) {
        await _controller!.stopVideoRecording();
        return;
      }

      setState(() {
        _isRecording = true;
        _isRecordingPending = false;
      });
      _recordPulseController.repeat(reverse: true);

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (mounted) {
          setState(
            () => _totalRecordingDuration += const Duration(milliseconds: 100),
          );
          if (_totalRecordingDuration.inSeconds >= 60) _stopRecording();
        }
      });
    } catch (e) {
      logE('Recording start error: $e');
      _recordPulseController.stop();
      _recordPulseController.reset();
      snackbarService.showError('Failed to start recording');
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null) return;
    if (_isRecordingPending && !_isRecording) {
      _recordPulseController.stop();
      _recordPulseController.reset();
      setState(() => _isRecordingPending = false);
      return;
    }
    if (!_isRecording) return;

    try {
      HapticFeedback.mediumImpact();
      _recordingTimer?.cancel();
      _recordPulseController.stop();
      _recordPulseController.reset();
      final XFile video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
        _recordedClips.add(video);
      });
      if (mounted) Navigator.pop(context, _recordedClips);
    } catch (e) {
      logE('Recording stop error: $e');
      _recordPulseController.stop();
      _recordPulseController.reset();
      snackbarService.showError('Failed to stop recording');
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: GestureDetector(
          onScaleStart: (_) {
            _baseZoom = _currentZoom;
          },
          onScaleUpdate: (details) {
            if (_controller == null) return;
            final newZoom = (_baseZoom * details.scale).clamp(
              _minZoom,
              _maxZoom,
            );
            if ((newZoom - _currentZoom).abs() > 0.05) {
              _currentZoom = newZoom;
              _controller!.setZoomLevel(newZoom);
              _zoomNotifier.value = newZoom;
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(),
              // Shutter flash overlay
              AnimatedBuilder(
                animation: _shutterAnimController,
                builder: (context, child) => IgnorePointer(
                  child: Opacity(
                    opacity: _shutterAnimController.value * 0.5,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              _buildTopControls(),
              _buildFilterToast(),
              _buildBottomControls(),
              _buildZoomIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAMERA PREVIEW — full screen with active filter
  // ============================================================
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FuturisticLoadingIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Wrap entire camera preview with selected color filter and live overlay
    final currentFilter =
        _filters[_selectedFilterIndex]['filter'] as ColorFilter?;
    final filterName = _filters[_selectedFilterIndex]['name'] as String;

    Widget preview = CameraPreview(
      _controller!,
      key: ValueKey('camera_preview_${_controller!.hashCode}'),
    );

    if (currentFilter != null) {
      preview = Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            key: ValueKey('filter_$_selectedFilterIndex'),
            colorFilter: currentFilter,
            child: preview,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColorFilters.buildLiveFilterOverlay(filterName),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onDoubleTap: _switchCamera,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -200) {
          // Swipe Left -> next filter
          if (_selectedFilterIndex < _filters.length - 1) {
            _selectFilter(_selectedFilterIndex + 1);
          }
        } else if (details.primaryVelocity! > 200) {
          // Swipe Right -> previous filter
          if (_selectedFilterIndex > 0) {
            _selectFilter(_selectedFilterIndex - 1);
          }
        }
      },
      child: preview,
    );
  }

  String? _activeFilterToastName;
  Timer? _filterToastTimer;

  void _selectFilter(int index) {
    HapticFeedback.selectionClick();
    final filterName = _filters[index]['name'] as String;
    setState(() {
      _selectedFilterIndex = index;
      _activeFilterToastName = filterName;
    });

    _filterToastTimer?.cancel();
    _filterToastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _activeFilterToastName = null);
    });

    const itemWidth = 76.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final offset = (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    if (_filterScrollController.hasClients) {
      _filterScrollController.animateTo(
        offset.clamp(0.0, _filterScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildFilterToast() {
    if (_activeFilterToastName == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 65,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00E5FF),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                _activeFilterToastName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP CONTROLS — close + flash + switch
  // ============================================================
  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // -- Close --
          _AnimatedControlButton(
            icon: Icons.close_rounded,
            controller: _closeButtonController,
            scaleAnimation: _closeScaleAnimation,
            onTap: () {
              _closeButtonController.forward().then(
                (_) => _closeButtonController.reverse(),
              );
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          Row(
            children: [
              // -- Flash --
              _AnimatedControlButton(
                icon: _getFlashIcon(),
                controller: _flashButtonController,
                scaleAnimation: _flashScaleAnimation,
                onTap: _toggleFlash,
                glowColor: _flashMode != FlashMode.off ? Colors.amber : null,
                badgeColor: _flashMode != FlashMode.off ? Colors.amber : null,
              ),
              const SizedBox(width: 12),
              // -- Switch camera (spin animation) --
              AnimatedBuilder(
                animation: _switchScaleAnimation,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 - _switchScaleAnimation.value,
                  child: child,
                ),
                child: _AnimatedControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  controller: _switchButtonController,
                  scaleAnimation: const AlwaysStoppedAnimation(1.0),
                  onTap: _switchCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() => switch (_flashMode) {
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always => Icons.flash_on_rounded,
    FlashMode.off => Icons.flash_off_rounded,
    FlashMode.torch => Icons.flashlight_on_rounded,
  };

  // ============================================================
  // BOTTOM CONTROLS
  // ============================================================
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) _buildRecordingIndicator(),
            if (!_isRecording) ...[
              _buildFilterSelector(),
              const SizedBox(height: 24),
            ],
            _buildMainControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _recordPulseAnimation,
      builder: (context, child) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(
                alpha: 0.5 * (_recordPulseAnimation.value - 1.0) / 0.25 + 0.3,
              ),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(_totalRecordingDuration),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ FILTER SELECTOR — horizontal filter carousel (Matched with Editor Suite)
  // ============================================================
  Widget _buildFilterSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          final filterName = _filters[index]['name'] as String;
          final colorFilter = _filters[index]['filter'] as ColorFilter?;

          return GestureDetector(
            onTap: () => _selectFilter(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 70 : 60,
                    height: isSelected ? 70 : 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E5FF) : Colors.white38,
                        width: isSelected ? 3 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildFilterThumbnail(colorFilter, filterName),
                          if (isSelected)
                            Container(
                              color: Colors.black.withValues(alpha: 0.2),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF00E5FF),
                                  size: 26,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: isSelected ? 12 : 11,
                      shadows: isSelected
                          ? [
                              const Shadow(
                                color: Color(0xFF00E5FF),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      filterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterThumbnail(ColorFilter? colorFilter, String filterName) {
    Widget baseThumbnail;
    if (_latestMediaThumbnailBytes != null) {
      baseThumbnail = Image.memory(
        _latestMediaThumbnailBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        cacheWidth: 140,
        cacheHeight: 140,
      );
    } else {
      baseThumbnail = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white38,
            size: 22,
          ),
        ),
      );
    }

    if (colorFilter != null) {
      baseThumbnail = ColorFiltered(
        colorFilter: colorFilter,
        child: baseThumbnail,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        baseThumbnail,
        if (colorFilter != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ColorFilters.buildLiveFilterOverlay(filterName),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // MAIN CONTROLS — gallery | shutter | switch
  // ============================================================
  Widget _buildMainControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // -- Gallery button --
              _buildGalleryButton(),

              // -- Shutter button --
              _buildShutterButton(),

              // -- Switch camera button --
              _buildSwitchButton(),
            ],
          ),
        ),
      ),
    );
  }

  // -- Gallery button with spring tap --
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTapDown: (_) => _galleryButtonController.forward(),
      onTapUp: (_) {
        _galleryButtonController.reverse();
        _openGallery();
      },
      onTapCancel: () => _galleryButtonController.reverse(),
      child: AnimatedBuilder(
        animation: _galleryScaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _galleryScaleAnimation.value, child: child),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _latestMediaThumbnailBytes != null
                ? Image.memory(
                    _latestMediaThumbnailBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                : const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }

  // -- Switch button with rotation --
  Widget _buildSwitchButton() {
    return GestureDetector(
      onTap: _switchCamera,
      child: AnimatedBuilder(
        animation: _switchButtonController,
        builder: (_, child) => Transform.rotate(
          angle: _switchButtonController.value * 3.14159,
          child: child,
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.cameraswitch_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // -- Shutter button with spring + glow --
  Widget _buildShutterButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isRecording && !_isCapturing) {
          _captureButtonController.forward();
        }
      },
      onTapUp: (_) {
        _captureButtonController.reverse();
        if (!_isRecording && !_isCapturing) _capturePhoto();
      },
      onTapCancel: () => _captureButtonController.reverse(),
      onLongPressStart: (_) {
        if (!_isRecording && !_isCapturing) _startRecording();
      },
      onLongPressEnd: (_) {
        if (_isRecording) _stopRecording();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _buttonScaleAnimation,
          _recordPulseAnimation,
        ]),
        builder: (context, child) {
          final scale = _isRecording
              ? _recordPulseAnimation.value
              : _buttonScaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ✅ Outer glow ring when recording
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 96 : 88,
                  height: _isRecording ? 96 : 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? Colors.red : Colors.white,
                      width: _isRecording ? 3 : 4,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                ),
                // Inner button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  width: _isRecording ? 46 : 70,
                  height: _isRecording ? 46 : 70,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.white,
                    // ✅ Morphs from circle to rounded square when recording
                    borderRadius: _isRecording
                        ? BorderRadius.circular(12)
                        : BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.white)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: FuturisticLoadingIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black45,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: _zoomNotifier,
      builder: (context, zoom, _) {
        if (zoom <= 1.01) return const SizedBox.shrink();
        return Positioned(
          top: MediaQuery.sizeOf(context).height / 2 - 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${zoom.toStringAsFixed(1)}×',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGallery() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GalleryPickerScreen(allowMultiple: true, maxSelection: 10),
      ),
    );

    if (result == 'camera_requested' || result == null || !mounted) return;

    List<XFile> xFiles = [];
    if (result is List<MediaAssetModel>) {
      xFiles = result.map((a) => XFile(a.file.path)).toList();
    } else if (result is List<XFile>) {
      xFiles = result;
    }

    if (xFiles.isNotEmpty) {
      Navigator.pop(
        context,
        CameraCaptureResult(
          files: xFiles,
          filter: _filters[_selectedFilterIndex]['filter'] as ColorFilter?,
          filterName: _filters[_selectedFilterIndex]['name'] as String?,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}

// ============================================================
// REUSABLE ANIMATED CONTROL BUTTON (top bar)
// ============================================================
class _AnimatedControlButton extends StatelessWidget {
  const _AnimatedControlButton({
    required this.icon,
    required this.controller,
    required this.scaleAnimation,
    required this.onTap,
    this.glowColor,
    this.badgeColor,
  });

  final IconData icon;
  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final Color? glowColor;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () => controller.reverse(),
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: scaleAnimation.value, child: child),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: glowColor != null
                  ? glowColor!.withValues(alpha: 0.6)
                  : Colors.white24,
              width: 1.5,
            ),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (badgeColor != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
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
