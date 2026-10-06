// ============================================================
// FILE: lib/media_utility/media_editor_suite_screen.dart
// Enhanced Media Editor with All Fixes - UPDATED
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crop_your_image/crop_your_image.dart';

import '../core/media_loading_indicator.dart';
import '../core/media_asset_model.dart';
import '../core/media_snackbar.dart';
import '../core/media_logger.dart';
import 'drawing_painter.dart';
import 'color_filters.dart';
import 'image_rotation_fixer.dart';

enum EditorMode { none, draw, filter, adjust }

class MediaEditorScreen extends StatefulWidget {
  final List<MediaAssetModel> mediaAssets;

  const MediaEditorScreen({super.key, required this.mediaAssets});

  @override
  State<MediaEditorScreen> createState() => _MediaEditorScreenState();
}

class _MediaEditorScreenState extends State<MediaEditorScreen>
    with TickerProviderStateMixin {
  PageController? _pageController;
  int _currentIndex = 0;
  EditorMode _currentMode = EditorMode.none;
  bool _isProcessing = false;

  late AnimationController _modeTransitionController;
  late AnimationController _filterSelectorController;
  late AnimationController _adjustmentController;
  late AnimationController _floatingButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final CropController _cropController = CropController();
  Uint8List? _imageDataForCrop;
  bool _isCropping = false;
  double? _currentAspectRatio;

  bool _isCollageMode = false;
  final GlobalKey _collageKey = GlobalKey();
  List<GlobalKey> _previewKeys = [];
  List<CollageItem> _collageItems = [];

  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  final ValueNotifier<List<Offset>> _currentStrokeNotifier =
      ValueNotifier<List<Offset>>([]);
  final List<Color> _drawingColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.white,
    Colors.black,
  ];

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  late List<Map<String, dynamic>> _filters;
  final ScrollController _filterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initPreviewKeys();
    _pageController = PageController();
    _filters = ColorFilters.getAllFilters();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCollageItems();
      if (widget.mediaAssets.isNotEmpty &&
          widget.mediaAssets[0].type == MediaType.video) {
        _initializeVideo(widget.mediaAssets[0]);
      }
      _modeTransitionController.forward();
    });
  }

  void _initPreviewKeys() {
    if (_previewKeys.length != widget.mediaAssets.length) {
      _previewKeys = List.generate(
        widget.mediaAssets.length,
        (index) => GlobalKey(),
      );
    }
  }

  @override
  void didUpdateWidget(MediaEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initPreviewKeys();
  }

  void _initAnimations() {
    _modeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterSelectorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _adjustmentController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _modeTransitionController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _modeTransitionController,
        curve: Curves.easeOutCubic,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _modeTransitionController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _initializeCollageItems() {
    final size = MediaQuery.sizeOf(context);
    _collageItems = widget.mediaAssets.asMap().entries.map((entry) {
      final index = entry.key;
      final cols = 2;
      final rows = (widget.mediaAssets.length / cols).ceil();
      final itemWidth = size.width / cols - 20;
      final itemHeight = (size.height - 200) / rows;
      final col = index % cols;
      final row = index ~/ cols;

      return CollageItem(
        asset: entry.value,
        position: Offset(
          col * (itemWidth + 10) + 10,
          row * (itemHeight + 10) + 100,
        ),
        scale: 0.8,
        rotation: 0.0,
      );
    }).toList();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _videoController?.dispose();
    _currentStrokeNotifier.dispose();
    _modeTransitionController.dispose();
    _filterSelectorController.dispose();
    _adjustmentController.dispose();
    _floatingButtonController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(MediaAssetModel asset) async {
    if (asset.type != MediaType.video) return;
    final file = asset.editedFile ?? asset.file;
    if (!await file.exists() || await file.length() == 0) {
      logW('⚠️ Video file is empty or does not exist: ${file.path}');
      if (mounted) setState(() => _isVideoInitialized = false);
      return;
    }
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      if (_videoController!.value.isInitialized &&
          _videoController!.value.aspectRatio != 0) {
        await _videoController!.setLooping(true);
        await _videoController!.play();
        if (mounted) setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      logE('Error initializing video: $e');
      if (mounted) setState(() => _isVideoInitialized = false);
    }
  }

  void _switchMode(EditorMode mode) {
    if (_currentMode == mode) {
      setState(() => _currentMode = EditorMode.none);
      _animateModePanels(show: false);
    } else {
      setState(() => _currentMode = mode);
      _animateModePanels(show: true);
      HapticFeedback.selectionClick();
    }
  }

  void _animateModePanels({required bool show}) {
    if (show) {
      switch (_currentMode) {
        case EditorMode.filter:
          _filterSelectorController.forward();
          _adjustmentController.reverse();
          break;
        case EditorMode.adjust:
          _adjustmentController.forward();
          _filterSelectorController.reverse();
          break;
        case EditorMode.draw:
          _filterSelectorController.reverse();
          _adjustmentController.reverse();
          break;
        case EditorMode.none:
          _filterSelectorController.reverse();
          _adjustmentController.reverse();
          break;
      }
    } else {
      _filterSelectorController.reverse();
      _adjustmentController.reverse();
    }
  }

  MediaAssetModel get _currentAsset => widget.mediaAssets[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _modeTransitionController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            _buildMainContent(),
            _buildTopBar(isDark),
            _buildBottomControls(theme, isDark),
            if (_currentMode == EditorMode.draw)
              _buildFloatingDrawingControls(),
            if (_isProcessing) _buildProcessingOverlay(),
            if (_isCropping) _buildCropScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isCollageMode) return _buildCollageView();

    return PageView.builder(
      physics: _currentMode == EditorMode.draw
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      controller: _pageController,
      itemCount: widget.mediaAssets.length,
      onPageChanged: (index) async {
        setState(() {
          _currentIndex = index;
          _currentMode = EditorMode.none;
        });
        await _initializeVideo(_currentAsset);
      },
      itemBuilder: (context, index) {
        _initPreviewKeys();
        return _buildMediaPreview(index);
      },
    );
  }

  void _endDrawing() {
    if (_currentStrokeNotifier.value.isNotEmpty) {
      setState(() {
        _currentAsset.drawingPaths.add(
          DrawStroke(
            points: List.from(_currentStrokeNotifier.value),
            color: _selectedColor,
            strokeWidth: _strokeWidth,
          ),
        );
        _currentStrokeNotifier.value = [];
      });
    }
  }

  Widget _buildMediaPreview(int index) {
    final asset = widget.mediaAssets[index];
    return RepaintBoundary(
      key: _previewKeys[index],
      child: GestureDetector(
        onPanStart: _currentMode == EditorMode.draw && index == _currentIndex
            ? (details) =>
                  _currentStrokeNotifier.value = [details.localPosition]
            : null,
        onPanUpdate: _currentMode == EditorMode.draw && index == _currentIndex
            ? (details) {
                final List<Offset> newList = List.from(
                  _currentStrokeNotifier.value,
                );
                newList.add(details.localPosition);
                _currentStrokeNotifier.value = newList;
              }
            : null,
        onPanEnd: _currentMode == EditorMode.draw && index == _currentIndex
            ? (details) => _endDrawing()
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildFilterStack(
              asset: asset,
              child: asset.type == MediaType.image
                  ? Image.file(
                      asset.editedFile ?? asset.file,
                      fit: BoxFit.contain,
                    )
                  : _buildVideoPlayer(),
            ),
            if (asset.drawingPaths.isNotEmpty ||
                (_currentMode == EditorMode.draw && index == _currentIndex))
              IgnorePointer(
                ignoring: true, // GestureDetector handles input
                child: ValueListenableBuilder<List<Offset>>(
                  valueListenable: _currentStrokeNotifier,
                  builder: (context, currentStroke, child) {
                    return CustomPaint(
                      painter: MediaDrawingPainter(
                        strokes: asset.drawingPaths,
                        currentStroke: index == _currentIndex
                            ? currentStroke
                            : [],
                        currentColor: _selectedColor,
                        strokeWidth: _strokeWidth,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return const Center(
        child: FuturisticLoadingIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildFilterStack({
    required Widget child,
    required MediaAssetModel asset,
  }) {
    Widget result = child;

    if (asset.brightness != 0) {
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorFilters.brightnessAdjust(asset.brightness),
        ),
        child: result,
      );
    }
    if (asset.contrast != 0) {
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorFilters.contrastAdjust(asset.contrast),
        ),
        child: result,
      );
    }
    if (asset.saturation != 0) {
      result = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorFilters.saturationAdjust(asset.saturation),
        ),
        child: result,
      );
    }
    if (asset.appliedFilter != null) {
      result = ColorFiltered(colorFilter: asset.appliedFilter!, child: result);
    }

    return result;
  }

  Widget _buildTopBar(bool isDark) {
    return AnimatedBuilder(
      animation: _floatingButtonController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _floatingButtonController.value)),
          child: Opacity(
            opacity: _floatingButtonController.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedIconButton(
              icon: Icons.close_rounded,
              onPressed: () => _showExitDialog(),
              color: Colors.white,
            ),
            Row(
              children: [
                const SizedBox(width: 8),
                AnimatedIconButton(
                  icon: Icons.brush_rounded,
                  isActive: _currentMode == EditorMode.draw,
                  onPressed: () => _switchMode(EditorMode.draw),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                AnimatedIconButton(
                  icon: Icons.filter_vintage_rounded,
                  isActive: _currentMode == EditorMode.filter,
                  onPressed: () => _switchMode(EditorMode.filter),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildModeControls(),
              ),
              const SizedBox(height: 16),
              _buildBottomActionBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeControls() {
    switch (_currentMode) {
      case EditorMode.filter:
        return _buildFilterSelector();
      case EditorMode.adjust:
        return _buildAdjustmentControls();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFilterSelector() {
    return AnimatedBuilder(
      animation: _filterSelectorController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _filterSelectorController.value)),
          child: Opacity(
            opacity: _filterSelectorController.value,
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          controller: _filterScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _currentAsset.filterName == filter['name'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentAsset.appliedFilter =
                      filter['filter'] as ColorFilter?;
                  _currentAsset.filterName = filter['name'] as String?;
                });
              },
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
                          color: isSelected ? Colors.white : Colors.white38,
                          width: isSelected ? 3 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColorFiltered(
                              colorFilter:
                                  filter['filter'] as ColorFilter? ??
                                  const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  ),
                              child: Image.file(
                                _currentAsset.file,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.white.withValues(alpha: 0.1),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      filter['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdjustmentControls() {
    return AnimatedBuilder(
      animation: _adjustmentController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 150 * (1 - _adjustmentController.value)),
          child: Opacity(opacity: _adjustmentController.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildAdjustmentSlider(
              label: 'Brightness',
              icon: Icons.brightness_6_rounded,
              value: _currentAsset.brightness,
              onChanged: (v) => setState(() => _currentAsset.brightness = v),
            ),
            const SizedBox(height: 8),
            _buildAdjustmentSlider(
              label: 'Contrast',
              icon: Icons.contrast_rounded,
              value: _currentAsset.contrast,
              onChanged: (v) => setState(() => _currentAsset.contrast = v),
            ),
            const SizedBox(height: 8),
            _buildAdjustmentSlider(
              label: 'Saturation',
              icon: Icons.water_drop_rounded,
              value: _currentAsset.saturation,
              onChanged: (v) => setState(() => _currentAsset.saturation = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSlider({
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: -1.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            (value * 100).toInt().toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Filters',
                  isActive: _currentMode == EditorMode.filter,
                  onPressed: () => _switchMode(EditorMode.filter),
                ),
                const SizedBox(width: 8),
                AnimatedActionButton(
                  icon: Icons.tune_rounded,
                  label: 'Adjust',
                  isActive: _currentMode == EditorMode.adjust,
                  onPressed: () => _switchMode(EditorMode.adjust),
                ),
                const SizedBox(width: 8),
                if (_currentAsset.type == MediaType.image) ...[
                  AnimatedActionButton(
                    icon: Icons.brush_rounded,
                    label: 'Draw',
                    isActive: _currentMode == EditorMode.draw,
                    onPressed: () => _switchMode(EditorMode.draw),
                  ),
                  const SizedBox(width: 8),
                  AnimatedActionButton(
                    icon: Icons.crop_rounded,
                    label: 'Crop',
                    onPressed: _showCropScreen,
                  ),
                  const SizedBox(width: 8),
                ],
                if (_currentAsset.type == MediaType.video) ...[
                  AnimatedActionButton(
                    icon: Icons.content_cut_rounded,
                    label: 'Trim',
                    onPressed: _showTrimScreen,
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.mediaAssets.length > 1)
                  AnimatedActionButton(
                    icon: _isCollageMode
                        ? Icons.view_carousel_rounded
                        : Icons.dashboard_rounded,
                    label: _isCollageMode ? 'Single' : 'Collage',
                    onPressed: () {
                      setState(() {
                        _isCollageMode = !_isCollageMode;
                        _currentMode = EditorMode.none;
                      });
                      HapticFeedback.mediumImpact();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: FuturisticLoadingIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDrawingControls() {
    return Positioned(
      top: MediaQuery.sizeOf(context).height * 0.5 - 150,
      right: 16,
      child: AnimatedBuilder(
        animation: _floatingButtonController,
        builder: (context, child) {
          return Transform.scale(
            scale: _floatingButtonController.value,
            child: Opacity(
              opacity: _floatingButtonController.value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 240,
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  itemCount: _drawingColors.length,
                  itemBuilder: (context, index) {
                    final color = _drawingColors[index];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: isSelected ? 36 : 30,
                        height: isSelected ? 36 : 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white54,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(
                      Icons.brush_rounded,
                      color: Colors.white,
                      size: _strokeWidth.clamp(16.0, 24.0),
                    ),
                    const SizedBox(height: 8),
                    RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 20.0,
                          onChanged: (v) => setState(() => _strokeWidth = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: Colors.white),
                tooltip: 'Undo stroke',
                onPressed: _currentAsset.drawingPaths.isNotEmpty
                    ? () {
                        setState(() {
                          _currentAsset.drawingPaths.removeLast();
                        });
                        HapticFeedback.lightImpact();
                      }
                    : null,
              ),
              if (_currentAsset.drawingPaths.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                  tooltip: 'Clear all drawings',
                  onPressed: () {
                    setState(() {
                      _currentAsset.drawingPaths.clear();
                    });
                    HapticFeedback.mediumImpact();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FuturisticLoadingIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropScreen() {
    if (_imageDataForCrop == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCropping = false;
                        _imageDataForCrop = null;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const Text(
                    'Crop Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _cropController.crop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Crop(
                image: _imageDataForCrop!,
                controller: _cropController,
                onCropped: (cropResult) {
                  if (cropResult is CropSuccess) {
                    _handleCroppedImage(cropResult.croppedImage);
                  }
                },
                aspectRatio: _currentAspectRatio,
                withCircleUi: false,
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.7),
                radius: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollageView() {
    return RepaintBoundary(
      key: _collageKey,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: _collageItems.map((item) {
            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    item.position += details.focalPointDelta;
                    item.scale = (item.scale * details.scale).clamp(0.5, 3.0);
                    item.rotation += details.rotation;
                  });
                },
                child: Transform(
                  transform: Matrix4.diagonal3Values(item.scale, item.scale, 1.0)
                    ..rotateZ(item.rotation),
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        item.asset.editedFile ?? item.asset.file,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExitDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Edits?'),
        content: const Text('All your edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCropScreen() async {
    if (_currentAsset.type != MediaType.image) return;
    try {
      setState(() => _isProcessing = true);
      final sourcePath =
          _currentAsset.editedFile?.path ?? _currentAsset.file.path;
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        if (mounted) snackbarService.showError('Image file not found');
        return;
      }
      final fixedFile = await ImageRotationFixer.fixRotation(sourceFile);
      final imageData = await fixedFile.readAsBytes();
      setState(() {
        _imageDataForCrop = imageData;
        _isCropping = true;
        _currentAspectRatio = null;
        _isProcessing = false;
      });
    } catch (e) {
      logE('Error preparing crop screen: $e');
      if (mounted) {
        snackbarService.showError('Failed to prepare image for cropping');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCroppedImage(Uint8List croppedData) async {
    try {
      setState(() => _isProcessing = true);
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await croppedFile.writeAsBytes(croppedData);
      setState(() {
        _currentAsset.editedFile = croppedFile;
        _isCropping = false;
        _imageDataForCrop = null;
        _currentAspectRatio = null;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      logE('Error saving cropped image: $e');
      if (mounted) snackbarService.showError('Failed to save cropped image');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showTrimScreen() {
    HapticFeedback.selectionClick();
    snackbarService.showInfo('Video trim feature coming soon!');
  }

  Future<void> _handleDone() async {
    setState(() => _isProcessing = true);
    try {
      if (_isCollageMode) {
        await _saveCollage();
      } else {
        await _saveEditedAssets();
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, widget.mediaAssets);
      }
    } catch (e) {
      logE('Error saving edits: $e');
      if (mounted) snackbarService.showError('Failed to save edits');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveEditedAssets() async {
    for (final asset in widget.mediaAssets) {
      if (asset.type == MediaType.image && asset.hasEdits) {
        await _captureEditedImage(asset);
      }
    }
  }

  Future<void> _saveCollage() async {
    try {
      final boundary =
          _collageKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/collage_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      final collageAsset = MediaAssetModel(
        id: 'collage_${DateTime.now().millisecondsSinceEpoch}',
        file: file,
        type: MediaType.image,
      );
      widget.mediaAssets.clear();
      widget.mediaAssets.add(collageAsset);
    } catch (e) {
      logE('Error saving collage: $e');
      rethrow;
    }
  }

  Future<void> _captureEditedImage(MediaAssetModel asset) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final index = widget.mediaAssets.indexOf(asset);
      if (index == -1) return;
      final boundary =
          _previewKeys[index].currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        logW('Boundary not found for asset ${asset.id}');
        return;
      }
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      asset.editedFile = file;
    } catch (e) {
      logE('Error capturing edited image: $e');
      rethrow;
    }
  }
}

class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isActive;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.isActive = false,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isActive ? Colors.white : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const AnimatedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollageItem {
  final MediaAssetModel asset;
  Offset position;
  double scale;
  double rotation;

  CollageItem({
    required this.asset,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

