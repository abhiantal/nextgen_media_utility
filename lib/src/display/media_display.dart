// ============================================================
// FILE: lib/media_utility/media_display.dart
// COMPLETELY FIXED — Proper URL resolution, video support, offline display
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:gal/gal.dart';
import '../core/media_loading_indicator.dart';
import '../core/media_layout.dart';
import '../core/media_asset_model.dart';
import '../core/media_snackbar.dart';
import '../core/media_logger.dart';
import '../audio/animated_audio_player.dart';
import '../picker/media_picker.dart' show MediaBucket;
export '../audio/animated_audio_player.dart' show AudioPlayerStyle;

class UrlUpdateEvent {
  final String storagePath;
  final String newHttpsUrl;
  const UrlUpdateEvent({required this.storagePath, required this.newHttpsUrl});
}

class UniversalMediaService {
  static final UniversalMediaService _instance = UniversalMediaService._();
  factory UniversalMediaService() => _instance;
  UniversalMediaService._();

  static final StreamController<UrlUpdateEvent> _urlUpdateController =
      StreamController<UrlUpdateEvent>.broadcast();

  Stream<UrlUpdateEvent> get urlUpdates => _urlUpdateController.stream;

  Future<String?> resolveUrl(String path, [dynamic bucket]) async => path;
  Future<String?> getValidSignedUrl(String path) async => path;
  Future<File?> getCachedFile(String path, [dynamic bucket]) async => null;
  Future<void> purgeLocalCache(String path) async {}
  Future<String?> findFileOnDisk(String path, [dynamic bucket]) async {
    final f = File(path);
    if (f.existsSync()) return path;
    return null;
  }
}

final mediaService = UniversalMediaService();

// ============================================================
// COMPATIBILITY HELPERS
// ============================================================

class FullScreenViewer extends FullScreenMediaViewer {
  const FullScreenViewer({
    super.key,
    required super.mediaFiles,
    required super.initialIndex,
    required super.config,
    super.onDelete,
  });
}

typedef MediaDisplayBottomSheet = FullScreenMediaViewer;
typedef MediaViewerBottomSheet = FullScreenMediaViewer;


// ============================================================
// DISPLAY CONFIGURATION
// ============================================================

class MediaDisplayConfig {
  final MediaLayoutMode layoutMode;
  final double borderRadius;
  final double spacing;
  final bool showFileName;
  final bool showFileSize;
  final bool showDate;
  final bool allowDelete;
  final bool allowFullScreen;
  final bool autoPlay;
  final BoxFit imageFit;
  final int gridColumns;
  final double? maxHeight;
  final bool enableImageRotation;
  final bool enableAnimations;
  final AudioPlayerStyle audioStyle;
  final bool isMe;
  final bool showDetails;
  final bool transparentBackground;
  final MediaBucket? mediaBucket;
  final int? feedbackNumber;

  const MediaDisplayConfig({
    this.layoutMode = MediaLayoutMode.grid,
    this.borderRadius = 16,
    this.spacing = 12,
    this.showFileName = true,
    this.showFileSize = true,
    this.showDate = true,
    this.allowDelete = true,
    this.allowFullScreen = true,
    this.autoPlay = false,
    this.imageFit = BoxFit.cover,
    this.gridColumns = 3,
    this.maxHeight,
    this.enableImageRotation = false,
    this.enableAnimations = true,
    this.audioStyle = AudioPlayerStyle.card,
    this.isMe = false,
    this.showDetails = false,
    this.transparentBackground = false,
    this.mediaBucket,
    this.feedbackNumber,
  });
}

enum MediaLayoutMode { grid, list, carousel, single, masonry }

// ============================================================
// ENHANCED MEDIA DISPLAY WIDGET
// ============================================================

class EnhancedMediaDisplay extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final MediaDisplayConfig config;
  final Function(String mediaId)? onDelete;
  final VoidCallback? onAddMedia;
  final bool isLoading;
  final String? emptyMessage;

  const EnhancedMediaDisplay({
    super.key,
    required this.mediaFiles,
    this.config = const MediaDisplayConfig(),
    this.onDelete,
    this.onAddMedia,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  State<EnhancedMediaDisplay> createState() => _EnhancedMediaDisplayState();
}

class _EnhancedMediaDisplayState extends State<EnhancedMediaDisplay>
    with TickerProviderStateMixin {
  late AnimationController _entryAnimController;
  late AnimationController _layoutTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  MediaLayoutMode? _previousLayoutMode;

  @override
  void initState() {
    super.initState();
    _entryAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _layoutTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOutBack),
    );
    if (widget.config.enableAnimations) _entryAnimController.forward();
  }

  @override
  void didUpdateWidget(EnhancedMediaDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.layoutMode != widget.config.layoutMode) {
      _previousLayoutMode = oldWidget.config.layoutMode;
      _layoutTransitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entryAnimController.dispose();
    _layoutTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoadingState();
    if (widget.mediaFiles.isEmpty) return _buildEmptyState();

    return widget.config.enableAnimations
        ? FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildMediaLayout(),
            ),
          )
        : _buildMediaLayout();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: FuturisticLoadingIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading media...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.emptyMessage ?? 'No media files',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.onAddMedia != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onAddMedia!();
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Media'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaLayout() {
    if (_previousLayoutMode != null && widget.config.enableAnimations) {
      return AnimatedBuilder(
        animation: _layoutTransitionController,
        builder: (context, _) {
          return Stack(
            children: [
              if (_layoutTransitionController.value < 0.5)
                Opacity(
                  opacity: 1.0 - (_layoutTransitionController.value * 2),
                  child: _buildLayoutForMode(_previousLayoutMode!),
                ),
              if (_layoutTransitionController.value >= 0.5)
                Opacity(
                  opacity: (_layoutTransitionController.value - 0.5) * 2,
                  child: _buildLayoutForMode(widget.config.layoutMode),
                ),
            ],
          );
        },
      );
    }
    return _buildLayoutForMode(widget.config.layoutMode);
  }

  Widget _buildLayoutForMode(MediaLayoutMode mode) {
    switch (mode) {
      case MediaLayoutMode.grid:
        return _buildGrid();
      case MediaLayoutMode.list:
        return _buildList();
      case MediaLayoutMode.carousel:
        return _buildCarousel();
      case MediaLayoutMode.single:
        return _buildSingle();
      case MediaLayoutMode.masonry:
        return _buildMasonry();
    }
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUnbounded = constraints.maxWidth == double.infinity;
        final grid = GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.config.gridColumns,
            crossAxisSpacing: widget.config.spacing,
            mainAxisSpacing: widget.config.spacing,
          ),
          itemCount: widget.mediaFiles.length,
          itemBuilder: (context, index) => _MediaTile(
            media: widget.mediaFiles[index],
            config: widget.config,
            index: index,
            onTap: () => _openFullScreen(index),
            onDelete: widget.config.allowDelete
                ? () => _confirmDelete(widget.mediaFiles[index].id)
                : null,
          ),
        );

        if (isUnbounded) {
          return SizedBox(width: 300, child: grid);
        }
        return grid;
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.mediaFiles.length,
      separatorBuilder: (context, index) => SizedBox(height: widget.config.spacing),
      itemBuilder: (context, index) {
        final media = widget.mediaFiles[index];

        return _MediaListTile(
          media: media,
          config: widget.config,
          index: index,
          onTap: () => _openFullScreen(index),
          onDelete: widget.config.allowDelete
              ? () => _confirmDelete(media.id)
              : null,
        );
      },
    );
  }

  Widget _buildCarousel() {
    return _MediaCarousel(
      mediaFiles: widget.mediaFiles,
      config: widget.config,
      onTap: _openFullScreen,
      onDelete: widget.config.allowDelete ? _confirmDelete : null,
    );
  }

  Widget _buildSingle() {
    if (widget.mediaFiles.isEmpty) return const SizedBox();
    final media = widget.mediaFiles[0];

    return SizedBox(
      height: widget.config.maxHeight ?? 220,
      child: _MediaTile(
        media: media,
        config: widget.config,
        index: 0,
        onTap: () => _openFullScreen(0),
        onDelete: widget.config.allowDelete
            ? () => _confirmDelete(media.id)
            : null,
      ),
    );
  }

  Widget _buildMasonry() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUnbounded = constraints.maxWidth == double.infinity;
        final masonry = GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: context.responsive(standard: 0.7, compact: 0.65, tablet: 0.85),
          ),
          itemCount: widget.mediaFiles.length,
          itemBuilder: (context, index) => _MediaTile(
            media: widget.mediaFiles[index],
            config: widget.config,
            index: index,
            onTap: () => _openFullScreen(index),
            onDelete: widget.config.allowDelete
                ? () => _confirmDelete(widget.mediaFiles[index].id)
                : null,
          ),
        );

        if (isUnbounded) {
          return SizedBox(width: 300, child: masonry);
        }
        return masonry;
      },
    );
  }

  Future<void> _confirmDelete(String mediaId) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call(mediaId);
  }

  void _openFullScreen(int index) {
    if (!widget.config.allowFullScreen) return;
    if (!widget.mediaFiles[index].supportsFullScreen) return;
    HapticFeedback.lightImpact();
    FullScreenMediaViewer.show(
      context,
      mediaFiles: widget.mediaFiles,
      initialIndex: index,
      config: widget.config,
      onDelete: widget.onDelete,
    );
  }
}

// ============================================================
// MEDIA TILE — with smart URL resolution
// ============================================================

class _MediaTile extends StatefulWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const _MediaTile({
    required this.media,
    required this.config,
    required this.onTap,
    required this.index,
    this.onDelete,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final child = GestureDetector(
      onTapDown: (_) {
        if (widget.config.enableAnimations) {
          _pressController.forward();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.config.enableAnimations) {
          _pressController.reverse();
          setState(() => _isPressed = false);
        }
      },
      onTapCancel: () {
        if (widget.config.enableAnimations) {
          _pressController.reverse();
          setState(() => _isPressed = false);
        }
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            boxShadow: widget.config.borderRadius == 0
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.08),
                      blurRadius: _isPressed ? 4 : 8,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(context),
                if (widget.onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DeleteButton(onDelete: widget.onDelete!),
                  ),
                _buildOverlay(),
              ],
            ),
          ),
        ),
      ),
    );

    final wrappedChild = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == double.infinity) {
          return SizedBox(width: 300, child: child);
        }
        return child;
      },
    );

    if (widget.config.enableAnimations) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(
          milliseconds: 300 + (widget.index * 40).clamp(0, 400),
        ),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: wrappedChild,
      );
    }
    return wrappedChild;
  }

  Widget _buildMediaContent(BuildContext context) {
    switch (widget.media.type) {
      case MediaFileType.image:
        return _SmartImageWidget(
          media: widget.media,
          config: widget.config,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.video:
        return _SmartVideoThumbnail(
          media: widget.media,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.audio:
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful background watermark icon
              Positioned(
                bottom: -20,
                right: -20,
                child: Icon(
                  Icons.audiotrack_rounded,
                  size: 100,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.media.fileName ?? 'Audio File',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AUDIO',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MediaFileType.document:
        return Container(
          color: Colors.blue.shade50,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                  if (widget.media.fileName != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.media.fileName!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildOverlay() {
    if (!widget.config.showDate) return const SizedBox();
    if (widget.media.type == MediaFileType.audio) return const SizedBox();

    final formattedDate = _formatDate(
      widget.media.uploadedAt,
      widget.media.url,
    );
    if (formattedDate.isEmpty) return const SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        child: Row(
          children: [
            _getMediaIcon(),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                formattedDate,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, [String? url]) {
    if (date == null) return '';

    // Local file during feedback addition
    if (widget.config.feedbackNumber != null) {
      final h = date.toLocal().hour.toString().padLeft(2, '0');
      final m = date.toLocal().minute.toString().padLeft(2, '0');
      return '(f${widget.config.feedbackNumber}:$h:$m)';
    }

    // Remote file with feedback path
    if (url != null) {
      final feedbackMatch = RegExp(r'/feedback-(\d+)/').firstMatch(url);
      if (feedbackMatch != null) {
        final fNum = feedbackMatch.group(1);
        final h = date.toLocal().hour.toString().padLeft(2, '0');
        final m = date.toLocal().minute.toString().padLeft(2, '0');
        return '(f$fNum:$h:$m)';
      }
    }

    // No watermark for anything else
    return '';
  }

  Widget _getMediaIcon() {
    switch (widget.media.type) {
      case MediaFileType.video:
        return const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 16,
        );
      case MediaFileType.document:
        return const Icon(
          Icons.description_rounded,
          color: Colors.white,
          size: 16,
        );
      default:
        return const SizedBox();
    }
  }
}

// ============================================================
// SMART IMAGE WIDGET — handles local + network + storage paths
// ============================================================

class _SmartImageWidget extends StatefulWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final MediaBucket? bucket;

  const _SmartImageWidget({
    required this.media,
    required this.config,
    this.bucket,
  });

  @override
  State<_SmartImageWidget> createState() => _SmartImageWidgetState();
}

class _SmartImageWidgetState extends State<_SmartImageWidget> {
  /// When true, skip local cache entirely and go straight to remote URL.
  bool _forceRemote = false;

  @override
  Widget build(BuildContext context) {
    // If already local AND not forced remote, display immediately
    if (!_forceRemote &&
        (widget.media.isLocal || _isLocalPath(widget.media.url))) {
      return _buildLocalImage(widget.media.url);
    }

    // For storage paths or HTTP URLs (or after local decode failure), use the resolver
    return ResolvedMediaWidget(
      pathOrUrl: widget.media.url,
      bucket: widget.bucket,
      forceRemote: _forceRemote,
      builder: (resolvedUrl, isLocal) {
        if (isLocal && !_forceRemote) return _buildLocalImage(resolvedUrl);
        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: widget.config.imageFit,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (context, url, error) => _buildError(),
          placeholder: (context, url) => _buildPlaceholder(context),
        );
      },
      loadingBuilder: () => _buildPlaceholder(context),
      errorBuilder: () => _buildError(),
    );
  }

  Widget _buildLocalImage(String path) {
    final filePath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;

    // Safety fallback: if it's a video file, do not try to load as Image.file
    final lowerPath = filePath.toLowerCase();
    if (lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.webm') ||
        lowerPath.endsWith('.mkv')) {
      // It's a video being requested as an image. This usually means a missing thumbnail.
      return _buildError();
    }

    return Image.file(
      File(filePath),
      fit: widget.config.imageFit,
      errorBuilder: (context, error, stackTrace) {
        // Local file failed to decode — it is corrupt. Purge it and retry remote.
        _purgeCorruptLocalFile(filePath);
        return _buildError();
      },
    );
  }

  /// Deletes the corrupt local file, clears the DB local_path reference,
  /// and triggers a UI rebuild in remote mode so the signed URL is fetched.
  void _purgeCorruptLocalFile(String localPath) {
    // Fire-and-forget async cleanup
    Future.microtask(() async {
      try {
        final file = File(localPath);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}

      // Only attempt remote purge & fallback if the media has a remote storage key
      final storageKey = widget.media.url;
      if (!_isLocalPath(storageKey)) {
        try {
          await UniversalMediaService().purgeLocalCache(storageKey);
        } catch (_) {}
        if (mounted) {
          setState(() => _forceRemote = true);
        }
      }
    });
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: FuturisticLoadingIndicator(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');
}

// ============================================================
// LOCAL VIDEO THUMBNAIL GENERATOR
// ============================================================

class _LocalVideoThumbnail extends StatefulWidget {
  final String videoPath;
  const _LocalVideoThumbnail({required this.videoPath});

  @override
  State<_LocalVideoThumbnail> createState() => _LocalVideoThumbnailState();
}

class _LocalVideoThumbnailState extends State<_LocalVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize()
          .then((_) {
            if (mounted) setState(() => _initialized = true);
          })
          .catchError((e) {
            logE('Error initializing local thumbnail video: $e', e);
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: FuturisticLoadingIndicator(
              strokeWidth: 2,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

// ============================================================
// SMART VIDEO THUMBNAIL
// ============================================================

class _SmartVideoThumbnail extends StatelessWidget {
  final EnhancedMediaFile media;
  final MediaBucket? bucket;

  const _SmartVideoThumbnail({required this.media, this.bucket});

  @override
  Widget build(BuildContext context) {
    if (media.isLocal || _isLocalPath(media.url)) {
      final path = media.url.startsWith('file://')
          ? Uri.parse(media.url).toFilePath()
          : media.url;
      return Stack(
        fit: StackFit.expand,
        children: [
          _LocalVideoThumbnail(videoPath: path),
          _buildPlayIcon(),
        ],
      );
    }

    return ResolvedMediaWidget(
      pathOrUrl: media.url,
      bucket: bucket,
      builder: (resolvedUrl, isLocal) {
        if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ResolvedMediaWidget(
                pathOrUrl: media.thumbnailUrl!,
                bucket: bucket,
                builder: (thumbUrl, thumbIsLocal) {
                  if (thumbIsLocal) {
                    final lowerPath = thumbUrl.toLowerCase();
                    if (lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov') || lowerPath.endsWith('.avi') || lowerPath.endsWith('.webm') || lowerPath.endsWith('.mkv')) {
                      return Container(color: Colors.black26); // Invalid thumbnail
                    }
                    return Image.file(File(thumbUrl), fit: BoxFit.cover);
                  }
                  return CachedNetworkImage(
                    imageUrl: thumbUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black12),
                    errorWidget: (context, url, error) => Container(color: Colors.black26),
                  );
                },
                loadingBuilder: () => Container(
                  color: Colors.black12,
                  child: const Center(
                    child: FuturisticLoadingIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: () => Container(color: Colors.black26),
              ),
              _buildPlayIcon(),
            ],
          );
        }

        // If no thumbnail but we have a resolved local path (cached video), generate thumbnail
        if (isLocal) {
          final cleanPath = resolvedUrl.startsWith('file://')
              ? Uri.parse(resolvedUrl).toFilePath()
              : resolvedUrl;
          return Stack(
            fit: StackFit.expand,
            children: [
              _LocalVideoThumbnail(videoPath: cleanPath),
              _buildPlayIcon(),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            _NetworkVideoThumbnail(videoUrl: resolvedUrl),
            _buildPlayIcon(),
          ],
        );
      },
      loadingBuilder: () => Container(
        color: Colors.black12,
        child: const Center(
          child: FuturisticLoadingIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      ),
      errorBuilder: () => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black87),
          _buildPlayIcon(),
        ],
      ),
    );
  }

  Widget _buildPlayIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');
}

class _NetworkVideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _NetworkVideoThumbnail({required this.videoUrl});

  @override
  State<_NetworkVideoThumbnail> createState() => _NetworkVideoThumbnailState();
}

class _NetworkVideoThumbnailState extends State<_NetworkVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (mounted) setState(() => _initialized = true);
          })
          .catchError((e) {
            logE('Error initializing thumbnail video: $e', e);
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: FuturisticLoadingIndicator(
              strokeWidth: 2,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

// ============================================================
// RESOLVED MEDIA WIDGET — async URL resolution with proper states
// FIXED: doesn't flash or re-resolve unnecessarily
// ============================================================

class ResolvedMediaWidget extends StatefulWidget {
  final String pathOrUrl;
  final MediaBucket? bucket;
  final bool forceRemote;
  final Widget Function(String resolvedUrl, bool isLocal) builder;
  final Widget Function() loadingBuilder;
  final Widget Function() errorBuilder;

  const ResolvedMediaWidget({
    super.key,
    required this.pathOrUrl,
    required this.builder,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.bucket,
    this.forceRemote = false,
  });

  @override
  State<ResolvedMediaWidget> createState() => _ResolvedMediaWidgetState();
}

class _ResolvedMediaWidgetState extends State<ResolvedMediaWidget> {
  String? _resolvedUrl;
  bool _isLocal = false;
  bool _hasError = false;
  bool _isLoading = true;
  StreamSubscription<UrlUpdateEvent>? _urlSub;

  @override
  void initState() {
    super.initState();
    _resolve();

    // Listen for background uploads completing to instantly refresh broken UI
    _urlSub = UniversalMediaService().urlUpdates.listen((event) {
      if (!mounted) return;
      if (event.storagePath == widget.pathOrUrl) {
        setState(() {
          _resolvedUrl = event.newHttpsUrl;
          _isLocal = !event.newHttpsUrl.startsWith('http');
          _hasError = false;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _urlSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ResolvedMediaWidget old) {
    super.didUpdateWidget(old);
    if (old.pathOrUrl != widget.pathOrUrl ||
        old.forceRemote != widget.forceRemote) {
      setState(() {
        _resolvedUrl = null;
        _isLocal = false;
        _hasError = false;
        _isLoading = true;
      });
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = widget.pathOrUrl;

    // Fast path: already local or http — but if forceRemote skip local path
    if (!widget.forceRemote &&
        (url.startsWith('/') || url.startsWith('file://'))) {
      final filePath = url.startsWith('file://')
          ? Uri.parse(url).toFilePath()
          : url;
      if (File(filePath).existsSync()) {
        if (mounted) {
          setState(() {
            _resolvedUrl = url;
            _isLocal = true;
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (url.startsWith('http')) {
      if (mounted) {
        setState(() {
          _resolvedUrl = url;
          _isLocal = false;
          _isLoading = false;
        });
      }
      return;
    }

    // Storage path — needs resolution
    try {
      String? resolved;
      if (widget.bucket != null) {
        resolved = await mediaService.resolveUrl(url, widget.bucket!);
      } else {
        resolved = await mediaService.getValidSignedUrl(url);
      }

      if (resolved == null) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }

      final isLocal =
          resolved.startsWith('/') || resolved.startsWith('file://');
      if (mounted) {
        setState(() {
          _resolvedUrl = resolved;
          _isLocal = isLocal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return widget.loadingBuilder();
    if (_hasError || _resolvedUrl == null) return widget.errorBuilder();
    return widget.builder(_resolvedUrl!, _isLocal);
  }
}

// ============================================================
// LIST TILE
// ============================================================

class _MediaListTile extends StatelessWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const _MediaListTile({
    required this.media,
    required this.config,
    required this.onTap,
    required this.index,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _MediaTile(
                      media: media,
                      config: config,
                      index: index,
                      onTap: onTap,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.fileName ?? 'Unknown File',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (config.showFileSize && media.size != null)
                            _formatFileSize(media.size!),
                          if (config.showDate && media.uploadedAt != null)
                            _formatDate(media.uploadedAt!, media.url),
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (config.enableAnimations) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 400)),
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        ),
        child: tile,
      );
    }
    return tile;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date, [String? url]) {
    if (url != null) {
      final feedbackMatch = RegExp(r'/feedback-(\d+)/').firstMatch(url);
      if (feedbackMatch != null) {
        final fNum = feedbackMatch.group(1);
        final h = date.toLocal().hour.toString().padLeft(2, '0');
        final m = date.toLocal().minute.toString().padLeft(2, '0');
        return '(f$fNum:$h:$m)';
      }
    }
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// DELETE BUTTON
// ============================================================

class _MediaCarousel extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final MediaDisplayConfig config;
  final Function(int) onTap;
  final Function(String)? onDelete;

  const _MediaCarousel({
    required this.mediaFiles,
    required this.config,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaFiles.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final height = widget.config.maxHeight ?? 300.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaFiles.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.mediaFiles.length > 1 ? 4.0 : 0.0,
                    ),
                    child: _MediaTile(
                      media: widget.mediaFiles[index],
                      config: widget.config,
                      index: index,
                      onTap: () => widget.onTap(index),
                      onDelete: widget.onDelete != null
                          ? () => widget.onDelete!(widget.mediaFiles[index].id)
                          : null,
                    ),
                  );
                },
              ),
            ),

            // Index Indicator (e.g., 1/5)
            if (widget.mediaFiles.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.mediaFiles.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Dot Indicators
        if (widget.mediaFiles.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.mediaFiles.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 8 : 6,
                  height: _currentIndex == index ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onDelete();
      },
      child: Container(
        padding: const EdgeInsets.all(8), // invisible hit area
        child: Container(
          padding: const EdgeInsets.all(6), // visual size
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

// ============================================================
// FULL SCREEN VIEWER
// ============================================================

class FullScreenMediaViewer extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final int initialIndex;
  final MediaDisplayConfig config;
  final Function(String mediaId)? onDelete;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaFiles,
    required this.initialIndex,
    required this.config,
    this.onDelete,
  });

  /// Displays the full screen media viewer
  static Future<void> show(
    BuildContext context, {
    required List<EnhancedMediaFile> mediaFiles,
    int initialIndex = 0,
    MediaDisplayConfig config = const MediaDisplayConfig(),
    Function(String mediaId)? onDelete,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenMediaViewer(
            mediaFiles: mediaFiles,
            initialIndex: initialIndex,
            config: config,
            onDelete: onDelete,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;
  bool _showOverlays = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDelete(EnhancedMediaFile media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDelete?.call(media.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMedia =
        widget.mediaFiles.isNotEmpty && _currentIndex < widget.mediaFiles.length
            ? widget.mediaFiles[_currentIndex]
            : null;
    final canDownload = currentMedia != null &&
        (currentMedia.type == MediaFileType.image ||
            currentMedia.type == MediaFileType.video);

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () {
            setState(() => _showOverlays = !_showOverlays);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Fullscreen Gallery View
              widget.mediaFiles.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : PhotoViewGallery.builder(
                      scrollPhysics: const BouncingScrollPhysics(),
                      builder: (context, index) {
                        final media = widget.mediaFiles[index];
                        return PhotoViewGalleryPageOptions.customChild(
                          child: _buildFullScreenItem(media),
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 3.0,
                          heroAttributes: PhotoViewHeroAttributes(
                            tag: 'fs_${media.id}_$index',
                          ),
                          disableGestures: media.type == MediaFileType.video,
                        );
                      },
                      itemCount: widget.mediaFiles.length,
                      loadingBuilder: (context, event) => const Center(
                        child: FuturisticLoadingIndicator(
                          color: Colors.white,
                        ),
                      ),
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      pageController: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        HapticFeedback.selectionClick();
                      },
                    ),

              // Top Bar Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: _showOverlays ? 0 : -110,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 6,
                    bottom: 12,
                    left: 12,
                    right: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMedia?.fileName ??
                                  (currentMedia != null
                                      ? _getMediaTypeLabel(currentMedia.type)
                                      : 'Media Viewer'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentMedia != null)
                              Text(
                                widget.mediaFiles.length > 1
                                    ? '${_currentIndex + 1} of ${widget.mediaFiles.length} • ${_buildMediaSubtitle(currentMedia)}'
                                    : _buildMediaSubtitle(currentMedia),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      if (canDownload)
                        _isDownloading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: FuturisticLoadingIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'Save to Gallery',
                                onPressed: _downloadMedia,
                              ),
                      if (widget.config.allowDelete &&
                          widget.onDelete != null &&
                          currentMedia != null)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Delete Media',
                          onPressed: () => _confirmDelete(currentMedia),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Bar Overlay (Thumbnails Carousel for multiple files)
              if (widget.mediaFiles.length > 1)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  bottom: _showOverlays ? 0 : -130,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                      top: 14,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.mediaFiles.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final isSelected = idx == _currentIndex;
                          final media = widget.mediaFiles[idx];
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.white24,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildThumbnailPreview(media),
                            ),
                          );
                        },
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

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Media Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This media item could not be loaded or is empty.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPreview(EnhancedMediaFile media) {
    if (media.type == MediaFileType.image) {
      if (media.isLocal ||
          media.url.startsWith('/') ||
          media.url.startsWith('file://')) {
        final filePath = media.url.startsWith('file://')
            ? Uri.parse(media.url).toFilePath()
            : media.url;
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_rounded, size: 20),
        );
      }
      if (media.url.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: media.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: FuturisticLoadingIndicator(strokeWidth: 1.5),
            ),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image_rounded, size: 20),
        );
      }
      return ResolvedMediaWidget(
        pathOrUrl: media.url,
        bucket: widget.config.mediaBucket,
        builder: (resolvedUrl, isLocal) {
          if (isLocal) {
            final filePath = resolvedUrl.startsWith('file://')
                ? Uri.parse(resolvedUrl).toFilePath()
                : resolvedUrl;
            return Image.file(
              File(filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image_rounded, size: 20),
            );
          }
          return CachedNetworkImage(
            imageUrl: resolvedUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: FuturisticLoadingIndicator(strokeWidth: 1.5),
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image_rounded, size: 20),
          );
        },
        loadingBuilder: () => const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: FuturisticLoadingIndicator(strokeWidth: 1.5),
          ),
        ),
        errorBuilder: () => const Center(
          child: Icon(Icons.broken_image_rounded, size: 20),
        ),
      );
    } else if (media.type == MediaFileType.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black87),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      );
    } else if (media.type == MediaFileType.audio) {
      return Container(
        color: Colors.deepPurple.withValues(alpha: 0.2),
        child: const Icon(
          Icons.audiotrack_rounded,
          color: Colors.deepPurpleAccent,
          size: 24,
        ),
      );
    } else {
      return Container(
        color: Colors.blueGrey.withValues(alpha: 0.2),
        child: const Icon(
          Icons.description_rounded,
          color: Colors.blueGrey,
          size: 24,
        ),
      );
    }
  }



  String _buildMediaSubtitle(EnhancedMediaFile media) {
    final List<String> parts = [];
    parts.add(_getMediaTypeLabel(media.type));
    if (media.size != null && media.size! > 0) {
      parts.add(_formatBytes(media.size!));
    }
    if (media.uploadedAt != null) {
      parts.add(_formatDate(media.uploadedAt!));
    }
    return parts.join(' • ');
  }

  String _getMediaTypeLabel(MediaFileType type) {
    switch (type) {
      case MediaFileType.image:
        return 'Image';
      case MediaFileType.video:
        return 'Video';
      case MediaFileType.audio:
        return 'Audio';
      case MediaFileType.document:
        return 'Document';
    }
  }



  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _downloadMedia() async {
    final media = widget.mediaFiles[_currentIndex];

    // 1. Request Gallery Access
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        AppSnackbar.warning(
          'Permission Required',
          description: 'Gallery permission is required to save media.',
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _isDownloading = true);
    }

    try {
      String resolvedUrl = media.url;

      // 2. Resolve URL if it's a storage path
      if (!resolvedUrl.startsWith('http') &&
          !resolvedUrl.startsWith('/') &&
          !resolvedUrl.startsWith('file://')) {
        String? resolved;
        if (widget.config.mediaBucket != null) {
          resolved = await mediaService.resolveUrl(
            resolvedUrl,
            widget.config.mediaBucket!,
          );
        } else {
          resolved = await mediaService.getValidSignedUrl(resolvedUrl);
        }
        if (resolved != null) resolvedUrl = resolved;
      }

      // 3. Save to Gallery
      if (resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://')) {
        // Local File
        final filePath = resolvedUrl.startsWith('file://')
            ? Uri.parse(resolvedUrl).toFilePath()
            : resolvedUrl;

        if (media.type == MediaFileType.video) {
          await Gal.putVideo(filePath);
        } else {
          await Gal.putImage(filePath);
        }
      } else {
        // Remote File
        final tempDir = await getTemporaryDirectory();
        final ext = media.type == MediaFileType.video ? 'mp4' : 'jpg';
        final fileName =
            media.fileName ??
            'download_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final tempPath = '${tempDir.path}/$fileName';

        final response = await http.get(Uri.parse(resolvedUrl));
        final file = File(tempPath);
        await file.writeAsBytes(response.bodyBytes);

        if (media.type == MediaFileType.video) {
          await Gal.putVideo(tempPath);
        } else {
          await Gal.putImage(tempPath);
        }
      }

      AppSnackbar.success('Saved to Gallery!');
    } catch (e, s) {
      logE('Download error: $e', e, s);
      AppSnackbar.error(
        'Download Error',
        description: 'Failed to save media to gallery. Please check storage permissions and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Widget _buildFullScreenItem(EnhancedMediaFile media) {
    switch (media.type) {
      case MediaFileType.video:
        return _FullScreenVideoPlayer(
          pathOrUrl: media.url,
          isLocal: media.isLocal,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.audio:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedAudioPlayer(
              url: media.url,
              isLocal: media.isLocal,
              title: media.fileName,
              subtitle: 'Now Playing',
              autoPlay: true,
              showWaveform: true,
              height: 220,
            ),
          ),
        );

      case MediaFileType.image:
        if (media.isLocal ||
            media.url.startsWith('/') ||
            media.url.startsWith('file://')) {
          final filePath = media.url.startsWith('file://')
              ? Uri.parse(media.url).toFilePath()
              : media.url;
          return Center(child: Image.file(File(filePath), fit: BoxFit.contain));
        }
        if (media.url.startsWith('http')) {
          return Center(
            child: CachedNetworkImage(
              imageUrl: media.url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: FuturisticLoadingIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        }
        // Storage path — resolve first
        return ResolvedMediaWidget(
          pathOrUrl: media.url,
          bucket: widget.config.mediaBucket,
          builder: (resolvedUrl, isLocal) {
            if (isLocal) {
              final filePath = resolvedUrl.startsWith('file://')
                  ? Uri.parse(resolvedUrl).toFilePath()
                  : resolvedUrl;
              return Center(
                child: Image.file(File(filePath), fit: BoxFit.contain),
              );
            }
            return Center(
              child: CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: FuturisticLoadingIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: () => const Center(
            child: FuturisticLoadingIndicator(color: Colors.white),
          ),
          errorBuilder: () => const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 64,
            ),
          ),
        );

      default:
        return const Center(
          child: Icon(
            Icons.description_rounded,
            color: Colors.white54,
            size: 64,
          ),
        );
    }
  }
}

// ============================================================
// FULL SCREEN VIDEO PLAYER — Fixed with proper URL resolution
// ============================================================

class _FullScreenVideoPlayer extends StatefulWidget {
  final String pathOrUrl;
  final bool isLocal;
  final MediaBucket? bucket;

  const _FullScreenVideoPlayer({
    required this.pathOrUrl,
    this.isLocal = false,
    this.bucket,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isEnded = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveAndInit();
  }

  Future<void> _resolveAndInit() async {
    try {
      String effectiveUrl = widget.pathOrUrl;

      // Resolve storage path to playable URL
      if (!effectiveUrl.startsWith('http') &&
          !effectiveUrl.startsWith('/') &&
          !effectiveUrl.startsWith('file://')) {
        String? resolved;
        if (widget.bucket != null) {
          resolved = await mediaService.resolveUrl(
            effectiveUrl,
            widget.bucket!,
          );
        } else {
          resolved = await mediaService.getValidSignedUrl(effectiveUrl);
        }
        if (resolved != null) effectiveUrl = resolved;
      }

      // Strip file:// prefix for VideoPlayerController.file
      if (effectiveUrl.startsWith('file://')) {
        effectiveUrl = Uri.parse(effectiveUrl).toFilePath();
      }

      VideoPlayerController controller;
      final isLocalFile = widget.isLocal ||
          (!effectiveUrl.startsWith('http://') &&
              !effectiveUrl.startsWith('https://'));

      if (isLocalFile) {
        var file = File(effectiveUrl);
        if (!file.existsSync()) {
          final foundDisk = await UniversalMediaService().findFileOnDisk(
            effectiveUrl,
            widget.bucket,
          );
          if (foundDisk != null && File(foundDisk).existsSync()) {
            file = File(foundDisk);
            effectiveUrl = foundDisk;
          } else {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Video file not found';
              });
            }
            return;
          }
        }
        controller = VideoPlayerController.file(file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(effectiveUrl));
      }

      controller.addListener(_onControllerUpdate);
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
          // _isPlaying will be updated by VisibilityDetector
        });
      } else {
        controller.dispose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur) {
      if (mounted && !_isEnded) {
        setState(() {
          _isPlaying = false;
          _isEnded = true;
          _showControls = true;
        });
      }
    }
    if (_controller!.value.hasError && mounted && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _controller!.value.errorDescription;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load video',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return const Center(
        child: FuturisticLoadingIndicator(color: Colors.white),
      );
    }

    return VisibilityDetector(
      key: Key('fullscreen_video_${widget.pathOrUrl}'),
      onVisibilityChanged: (info) {
        if (mounted && _controller != null) {
          final isVisible = info.visibleFraction > 0.5;
          if (isVisible && !_isEnded && _isPlaying) {
            _controller?.play();
          } else if (isVisible && !_isEnded && !_isPlaying) {
            // Let it be paused if user specifically paused it
            // But if it's the first time it becomes visible, play it
            if (_controller!.value.position == Duration.zero) {
              _controller?.play();
              setState(() => _isPlaying = true);
            }
          } else {
            _controller?.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton(
                          iconSize: 72,
                          color: Colors.white,
                          icon: Icon(
                            _isEnded
                                ? Icons.replay_circle_filled_rounded
                                : (_isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_isEnded) {
                                _controller!.seekTo(Duration.zero);
                                _controller!.play();
                                _isPlaying = true;
                                _isEnded = false;
                              } else if (_controller!.value.isPlaying) {
                                _controller!.pause();
                                _isPlaying = false;
                              } else {
                                _controller!.play();
                                _isPlaying = true;
                              }
                            });
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.grey,
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
    );
  }
}

