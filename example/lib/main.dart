import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NextGenMediaExampleApp());
}

class NextGenMediaExampleApp extends StatefulWidget {
  const NextGenMediaExampleApp({super.key});

  @override
  State<NextGenMediaExampleApp> createState() => _NextGenMediaExampleAppState();
}

class _NextGenMediaExampleAppState extends State<NextGenMediaExampleApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextGen Media Studio Demo',
      debugShowCheckedModeBanner: false,
      theme: MediaTheme.lightTheme(),
      darkTheme: MediaTheme.darkTheme(),
      themeMode: _themeMode,
      home: MediaDemoHomeScreen(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MediaDemoHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MediaDemoHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<MediaDemoHomeScreen> createState() => _MediaDemoHomeScreenState();
}

class _MediaDemoHomeScreenState extends State<MediaDemoHomeScreen> {
  final List<MediaAssetModel> _mediaAssets = [];
  MediaLayoutMode _layoutMode = MediaLayoutMode.grid;
  String? _latestAudioPath;

  // -------------------------------------------------------------
  // 1. HARDWARE CAMERA CAPTURE
  // -------------------------------------------------------------
  Future<void> _openCamera() async {
    final result = await Navigator.push<CameraCaptureResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraCaptureScreen(allowVideo: true),
      ),
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    for (final xfile in result.files) {
      final file = File(xfile.path);
      final isVideo = xfile.path.toLowerCase().endsWith('.mp4');
      _addAsset(
        file,
        isVideo ? MediaType.video : MediaType.image,
        appliedFilter: result.filter,
        filterName: result.filterName,
      );
    }

    _showSuccess(
      'Captured ${result.files.length} item(s) from hardware camera!',
    );
  }

  // -------------------------------------------------------------
  // 2. ALBUM GALLERY PICKER (Multi-select)
  // -------------------------------------------------------------
  Future<void> _openGallery() async {
    final result = await Navigator.push<List<MediaAssetModel>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const GalleryPickerScreen(
          allowMultiple: true,
          maxSelection: 10,
        ),
      ),
    );

    if (!mounted || result == null || result.isEmpty) return;

    setState(() {
      _mediaAssets.addAll(result);
    });

    _showSuccess('Picked ${result.length} item(s) from Gallery!');
  }

  // -------------------------------------------------------------
  // 3. WHATSAPP-STYLE ATTACHMENT SHEET
  // -------------------------------------------------------------
  Future<void> _openQuickAttachmentSheet() async {
    final List<XFile> picked = await EnhancedMediaPicker.pickMultipleMedia(
      context,
      config: const MediaPickerConfig(
        allowCamera: true,
        allowGallery: true,
        allowVideo: true,
        allowAudio: true,
        allowDocument: true,
      ),
      maxFiles: 5,
    );

    if (!mounted || picked.isEmpty) return;

    for (final xf in picked) {
      final file = File(xf.path);
      final isVideo = xf.path.toLowerCase().endsWith('.mp4');
      final isAudio =
          xf.path.toLowerCase().endsWith('.m4a') ||
          xf.path.toLowerCase().endsWith('.mp3');
      _addAsset(
        file,
        isVideo
            ? MediaType.video
            : (isAudio ? MediaType.audio : MediaType.image),
      );
    }

    _showSuccess('Attached ${picked.length} item(s)!');
  }

  // -------------------------------------------------------------
  // 4. PHOTO STUDIO / EDITOR SUITE
  // -------------------------------------------------------------
  Future<void> _openPhotoEditor([MediaAssetModel? asset]) async {
    MediaAssetModel targetAsset;

    if (asset != null) {
      targetAsset = asset;
    } else {
      final imageAssets =
          _mediaAssets.where((a) => a.type == MediaType.image).toList();
      if (imageAssets.isEmpty) {
        final sample = await _createSampleImage();
        targetAsset = sample;
        setState(() => _mediaAssets.add(sample));
      } else {
        targetAsset = imageAssets.first;
      }
    }

    if (!mounted) return;

    final editedAssets = await Navigator.push<List<MediaAssetModel>?>(
      context,
      MaterialPageRoute(
        builder: (_) => MediaEditorScreen(mediaAssets: [targetAsset]),
      ),
    );

    if (!mounted || editedAssets == null || editedAssets.isEmpty) return;

    setState(() {
      final idx = _mediaAssets.indexWhere((a) => a.id == targetAsset.id);
      if (idx != -1) {
        _mediaAssets[idx] = editedAssets.first;
      }
    });

    _showSuccess('Image successfully edited in Photo Studio!');
  }

  // -------------------------------------------------------------
  // 5. CUSTOM MEDIA COMPRESSION MODAL
  // -------------------------------------------------------------
  Future<void> _openCompressor([MediaAssetModel? asset]) async {
    MediaAssetModel target;

    if (asset != null) {
      target = asset;
    } else {
      if (_mediaAssets.isEmpty) {
        final sample = await _createSampleImage();
        target = sample;
        setState(() => _mediaAssets.add(sample));
      } else {
        target = _mediaAssets.first;
      }
    }

    if (!mounted) return;

    final originalFile = target.editedFile ?? target.file;
    final originalBytes = await originalFile.length();
    if (!mounted) return;

    final compressed = await MediaCompressionSheet.show(
      context,
      file: originalFile,
      isVideo: target.type == MediaType.video,
    );

    if (!mounted || compressed == null) return;

    final compressedBytes = await compressed.length();
    final reduction =
        ((originalBytes - compressedBytes) / originalBytes * 100)
            .toStringAsFixed(1);

    setState(() {
      final idx = _mediaAssets.indexWhere((a) => a.id == target.id);
      if (idx != -1) {
        _mediaAssets[idx] = target.copyWith(file: compressed);
      }
    });

    _showSuccess(
      'Compressed successfully! Size reduced by $reduction% '
      '(${_formatSize(originalBytes)} → ${_formatSize(compressedBytes)})',
    );
  }

  // -------------------------------------------------------------
  // 6. PULSE AUDIO RECORDER
  // -------------------------------------------------------------
  void _openAudioRecorder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: EnhancedAudioRecorder(
          onCompleted: (xfile) {
            Navigator.pop(ctx);
            final file = File(xfile.path);
            setState(() {
              _latestAudioPath = file.path;
              _addAsset(file, MediaType.audio);
            });
            _showSuccess(
              'Voice note recorded: ${_formatSize(file.lengthSync())}',
            );
          },
          onCanceled: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. VIDEO TRIMMER
  // -------------------------------------------------------------
  Future<void> _openVideoTrimmer([MediaAssetModel? asset]) async {
    MediaAssetModel? target = asset;
    if (target == null) {
      final videos =
          _mediaAssets.where((a) => a.type == MediaType.video).toList();
      if (videos.isNotEmpty) {
        target = videos.first;
      }
    }

    if (target == null || target.type != MediaType.video) {
      _showWarning('Please capture or pick a video first to trim it!');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTrimmerView(file: target!.file),
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------
  void _addAsset(
    File file,
    MediaType type, {
    ColorFilter? appliedFilter,
    String? filterName,
  }) {
    final asset = MediaAssetModel(
      id: 'asset_${DateTime.now().microsecondsSinceEpoch}',
      file: file,
      type: type,
      appliedFilter: appliedFilter,
      filterName: filterName,
    );
    setState(() => _mediaAssets.insert(0, asset));
  }

  Future<MediaAssetModel> _createSampleImage() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/sample_demo_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    // 1x1 base PNG fallback or write solid dummy PNG
    final dummyPng = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 1, 0, 0, 0, 1, 0, 8, 2, 0, 0, 0, 144, 119, 83, 222, 0,
      0, 0, 12, 73, 68, 65, 84, 120, 156, 99, 248, 207, 192, 0, 0,
      3, 1, 1, 0, 24, 221, 141, 176, 0, 0, 0, 0, 73, 69, 78, 68, 174,
      66, 96, 130,
    ]);
    await file.writeAsBytes(dummyPng);

    return MediaAssetModel(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      file: file,
      type: MediaType.image,
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.amber.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 22),
            SizedBox(width: 8),
            Text(
              'NextGen Media Studio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E2E), Color(0xFF2A2D3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Full Feature Playground',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Chip(
                        backgroundColor: Color(0xFF00E676),
                        label: Text(
                          'v0.0.1',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hardware Camera • Multi-Album Gallery • Studio Filters & Drawing • '
                    'Waveform Audio • Interactive Compression • Video Trimmer • Pinch Zoom Grid',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Loaded Media: ${_mediaAssets.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.add_photo_alternate,
                          size: 16,
                          color: Color(0xFF00E676),
                        ),
                        label: const Text(
                          'Add Sample',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () async {
                          final sample = await _createSampleImage();
                          setState(() => _mediaAssets.insert(0, sample));
                          _showSuccess('Sample image created!');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 8 Action Feature Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildFeatureCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Hardware Camera',
                  subtitle: 'Photo & Video capture',
                  color: const Color(0xFF00E676),
                  onTap: _openCamera,
                ),
                _buildFeatureCard(
                  icon: Icons.photo_library_rounded,
                  title: 'Album Gallery',
                  subtitle: 'Multi-select albums',
                  color: const Color(0xFF2979FF),
                  onTap: _openGallery,
                ),
                _buildFeatureCard(
                  icon: Icons.attach_file_rounded,
                  title: 'Attachment Sheet',
                  subtitle: 'WhatsApp style menu',
                  color: const Color(0xFFFF9100),
                  onTap: _openQuickAttachmentSheet,
                ),
                _buildFeatureCard(
                  icon: Icons.auto_fix_high_rounded,
                  title: 'Photo Studio',
                  subtitle: 'Filters, brush & crop',
                  color: const Color(0xFFE040FB),
                  onTap: () => _openPhotoEditor(),
                ),
                _buildFeatureCard(
                  icon: Icons.compress_rounded,
                  title: 'Custom Compressor',
                  subtitle: 'Slider & presets',
                  color: const Color(0xFF00E5FF),
                  onTap: () => _openCompressor(),
                ),
                _buildFeatureCard(
                  icon: Icons.mic_rounded,
                  title: 'Voice Recorder',
                  subtitle: 'Pulsing waveforms',
                  color: const Color(0xFFFF1744),
                  onTap: _openAudioRecorder,
                ),
                _buildFeatureCard(
                  icon: Icons.content_cut_rounded,
                  title: 'Video Trimmer',
                  subtitle: 'Start/End clipping',
                  color: const Color(0xFFFFD600),
                  onTap: () => _openVideoTrimmer(),
                ),
                _buildFeatureCard(
                  icon: Icons.dashboard_customize_rounded,
                  title: 'Change Layout',
                  subtitle: 'Grid / Carousel / List',
                  color: const Color(0xFF76FF03),
                  onTap: () {
                    setState(() {
                      if (_layoutMode == MediaLayoutMode.grid) {
                        _layoutMode = MediaLayoutMode.carousel;
                      } else if (_layoutMode == MediaLayoutMode.carousel) {
                        _layoutMode = MediaLayoutMode.list;
                      } else {
                        _layoutMode = MediaLayoutMode.grid;
                      }
                    });
                    _showSuccess('Switched layout to ${_layoutMode.name}!');
                  },
                ),
              ],
            ),
          ),

          // Audio Player Section (if an audio note was recorded)
          if (_latestAudioPath != null) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF00E676),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Waveform Audio Player Demo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedAudioPlayer(
                      url: _latestAudioPath!,
                      isLocal: true,
                      style: AudioPlayerStyle.card,
                      accentColor: const Color(0xFF00E676),
                      showWaveform: true,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Media Tray / Showcase Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Interactive Media Showcase',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_mediaAssets.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete_sweep,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                      onPressed: () => setState(() => _mediaAssets.clear()),
                    ),
                ],
              ),
            ),
          ),

          if (_mediaAssets.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: EnhancedMediaDisplay(
                  mediaFiles: _mediaAssets
                      .map(
                        (a) => EnhancedMediaFile.fromFile(
                          file: a.editedFile ?? a.file,
                          id: a.id,
                        ),
                      )
                      .toList(),
                  config: MediaDisplayConfig(
                    layoutMode: _layoutMode,
                    borderRadius: 16,
                    allowFullScreen: true,
                    allowDelete: true,
                    showFileName: true,
                    showFileSize: true,
                  ),
                  onDelete: (id) {
                    setState(() {
                      _mediaAssets.removeWhere((a) => a.id == id);
                    });
                  },
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const FuturisticLoadingIndicator(radius: 20),
                    const SizedBox(height: 16),
                    const Text(
                      'No media loaded yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap any feature card above or "Add Sample" to test interactive media tools live on your mobile!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
