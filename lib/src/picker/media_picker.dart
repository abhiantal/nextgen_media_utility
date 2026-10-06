// ============================================================
// FILE: lib/media_utility/media_picker.dart
// Enhanced Media Picker - Fixed Rotation & Improved UI
// ============================================================

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../core/media_loading_indicator.dart';
import '../core/media_layout.dart';
import '../core/media_snackbar.dart';
import '../core/media_logger.dart';
import '../core/media_asset_model.dart';
import '../camera/camera_capture_screen.dart';
import '../editor/image_rotation_fixer.dart';
import '../editor/media_editor_suite_screen.dart';
import '../audio/enhanced_audio_recorder.dart';
import '../video/video_trimmer_view.dart';
import 'gallery_picker_screen.dart';

enum MediaBucket {
  userAvatars('user-avatars', 15, 'Avatars'),
  bucketMedia('bucket-media', 50, 'Media'),
  general('general', 50, 'General');

  final String bucketId;
  final int maxSizeMB;
  final String displayName;

  const MediaBucket(this.bucketId, this.maxSizeMB, this.displayName);
}

class SecurityService {
  static final SecurityService _instance = SecurityService._();
  factory SecurityService() => _instance;
  SecurityService._();
  void ignoreNextLifecycle() {}
}

// ============================================================
// ENHANCED MEDIA COMPRESSOR - WITH ROTATION FIX
// ============================================================

class EnhancedMediaCompressor {
  /// Compress image with automatic rotation fix
  static Future<File?> compressImage(
    File file, {
    int quality = 50, // Ultra-aggressive: reduced from 75 to 50
    int minWidth = 800, // Reduced from 1080 to 800
    int minHeight = 800, // Reduced from 1080 to 800
    bool fixRotation = true,
  }) async {
    try {
      final dir = path.dirname(file.path);
      final filename = path.basenameWithoutExtension(file.path);
      final targetPath = path.join(dir, '${filename}_compressed.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: fixRotation,
      );

      if (result != null) {
        final originalSize = await file.length();
        final compressedSize = await result.length();
        final reduction = ((originalSize - compressedSize) / originalSize * 100)
            .toStringAsFixed(1);
        logD('Image compressed natively: $reduction% smaller');

        return File(result.path);
      }

      return file;
    } catch (e, stackTrace) {
      logE('Error compressing image: $e', e, stackTrace);
      return file;
    }
  }

  /// Process gallery image - always fix rotation natively (very fast)
  static Future<File> processGalleryImage(File file) async {
    try {
      final dir = path.dirname(file.path);
      final filename = path.basenameWithoutExtension(file.path);
      final targetPath = path.join(dir, '${filename}_fixed.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 95,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      logE('Error natively fixing rotation: $e');
      return file;
    }
  }

  static Future<File?> compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool force = false,
  }) async {
    try {
      if (!await file.exists()) return file;
      final size = await file.length();

      // Skip video compression for files <= 35 MB for lightning speed & instant uploads unless explicitly forced
      if (!force && size <= 35 * 1024 * 1024) {
        logD('⚡ [Fast Video] Video under 35MB (${(size / (1024 * 1024)).toStringAsFixed(1)}MB), skipping compression');
        return file;
      }

      // Prevent concurrent VideoCompress native calls which crash Android native memory
      if (VideoCompress.isCompressing) {
        logW('⚠️ VideoCompress busy, skipping duplicate compression');
        return file;
      }

      logD('⚡ Starting fast video compression: ${file.path}');
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          logW('⚠️ Video compression reached 25s limit, safely returning original file');
          try {
            VideoCompress.cancelCompression();
          } catch (_) {}
          return null;
        },
      );

      if (info != null && info.file != null && info.file!.existsSync()) {
        final originalSize = size;
        final compressedSize = await info.file!.length();
        final reduction =
            ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
        logD('⚡ Video compressed natively: $reduction% smaller');
        return info.file;
      }
      return file;
    } catch (e, stackTrace) {
      logE('Error compressing video, safely returning original file: $e', e, stackTrace);
      try {
        await VideoCompress.cancelCompression();
      } catch (_) {}
      return file;
    }
  }

  static Future<File?> compressMedia(
    File file, {
    bool fixRotation = true,
    VideoQuality videoQuality = VideoQuality.MediumQuality,
  }) async {
    final extension = path.extension(file.path).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(extension)) {
      return await compressImage(file, fixRotation: fixRotation);
    }

    if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
      return await compressVideo(file, quality: videoQuality);
    }

    return file;
  }

  /// Check if a file actually needs compression based on its size
  static Future<bool> shouldCompress(File file, String mediaType) async {
    try {
      final size = await file.length();
      if (mediaType == 'image') {
        // Skip compression for images already smaller than 1.5 MB for lightning speed
        return size > 1500 * 1024;
      } else if (mediaType == 'video') {
        // Skip compression for videos already smaller than 35 MB for instant uploads
        return size > 35 * 1024 * 1024;
      }
    } catch (_) {}
    return true;
  }

  static String detectMediaType(String filePath) {
    if (filePath.isEmpty) return 'image';

    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceAll('.', '');

    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'webm', 'm4v'];
    const imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
    ];
    const audioExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];
    const documentExtensions = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
    ];

    if (videoExtensions.contains(extension)) return 'video';
    if (imageExtensions.contains(extension)) return 'image';
    if (audioExtensions.contains(extension)) return 'audio';
    if (documentExtensions.contains(extension)) return 'document';

    return 'image';
  }

  static String getContentType(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceAll('.', '');

    const typeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'bmp': 'image/bmp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'flv': 'video/x-flv',
      'webm': 'video/webm',
      'm4v': 'video/x-m4v',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
    };

    return typeMap[extension] ?? 'application/octet-stream';
  }

  static void cancelCompression() {
    VideoCompress.cancelCompression();
  }

  static Subscription subscribeToProgress(Function(double) onProgress) {
    return VideoCompress.compressProgress$.subscribe(onProgress);
  }
}

// ============================================================
// MEDIA PICKER CONFIG
// ============================================================

class MediaPickerConfig {
  final MediaBucket? bucket;
  final bool allowCamera;
  final bool allowGallery;
  final bool allowImage;
  final bool allowVideo;
  final bool allowAudio;
  final bool allowDocument;
  final bool autoCompress;
  final bool fixRotation;
  final int imageQuality;
  final VideoQuality videoQuality;
  final Duration? maxVideoDuration;
  final int? maxFileSizeMB;

  const MediaPickerConfig({
    this.bucket,
    this.allowCamera = true,
    this.allowGallery = true,
    this.allowImage = true,
    this.allowVideo = true,
    this.allowAudio = true,
    this.allowDocument = true,
    this.autoCompress = true,
    this.fixRotation = true,
    this.imageQuality = 75,
    this.videoQuality = VideoQuality.MediumQuality,
    this.maxVideoDuration,
    this.maxFileSizeMB,
  });

  int get effectiveMaxFileSizeMB => maxFileSizeMB ?? bucket?.maxSizeMB ?? 50;
  int get effectiveMaxFileSizeBytes => effectiveMaxFileSizeMB * 1024 * 1024;
  String get bucketDisplayName => bucket != null ? bucket!.displayName : 'Media';

  MediaPickerConfig copyWith({
    MediaBucket? bucket,
    bool? allowCamera,
    bool? allowGallery,
    bool? allowImage,
    bool? allowVideo,
    bool? allowAudio,
    bool? allowDocument,
    bool? autoCompress,
    bool? fixRotation,
    int? imageQuality,
    VideoQuality? videoQuality,
    Duration? maxVideoDuration,
    int? maxFileSizeMB,
  }) {
    return MediaPickerConfig(
      bucket: bucket ?? this.bucket,
      allowCamera: allowCamera ?? this.allowCamera,
      allowGallery: allowGallery ?? this.allowGallery,
      allowImage: allowImage ?? this.allowImage,
      allowVideo: allowVideo ?? this.allowVideo,
      allowAudio: allowAudio ?? this.allowAudio,
      allowDocument: allowDocument ?? this.allowDocument,
      autoCompress: autoCompress ?? this.autoCompress,
      fixRotation: fixRotation ?? this.fixRotation,
      imageQuality: imageQuality ?? this.imageQuality,
      videoQuality: videoQuality ?? this.videoQuality,
      maxVideoDuration: maxVideoDuration ?? this.maxVideoDuration,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
    );
  }
}

// ============================================================
// ENHANCED MEDIA PICKER
// ============================================================

class EnhancedMediaPicker {
  static Future<XFile?> pickMedia(
    BuildContext context, {
    MediaPickerConfig? config,
  }) async {
    final cfg = config ?? const MediaPickerConfig();

    if (!context.mounted) return null;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => _EnhancedMediaPickerSheet(config: cfg),
    );

    XFile? pickedFile;

    if (result is Map<String, dynamic>) {
      final source = result['source'] as ImageSource;
      final mediaType = result['mediaType'] as String;
      if (!context.mounted) return null;
      pickedFile = await _pickSingleMedia(context, source, mediaType, cfg);
    } else if (result is XFile) {
      pickedFile = result;
    }

    if (pickedFile == null || !context.mounted) return null;

    // Validate file size limit immediately
    final file = File(pickedFile.path);
    if (file.existsSync() && file.lengthSync() > cfg.effectiveMaxFileSizeBytes) {
      final sizeMB = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
      final fileName = path.basename(pickedFile.path);
      logW(
        'Picked file "$fileName" ($sizeMB MB) exceeds limit of ${cfg.effectiveMaxFileSizeMB} MB for ${cfg.bucketDisplayName}',
      );
      AppSnackbar.warning(
        'File Exceeds Size Limit (${cfg.bucketDisplayName})',
        description:
            'Selected "$fileName" is $sizeMB MB. The maximum limit is ${cfg.effectiveMaxFileSizeMB} MB. Please choose a smaller file.',
      );
      return null;
    }

    final edited = await _routeThroughEditor(context, [pickedFile]);
    return edited.isNotEmpty ? edited.first : null;
  }

  static Future<List<XFile>> pickMultipleMedia(
    BuildContext context, {
    MediaPickerConfig? config,
    int maxFiles = 10,
  }) async {
    final cfg = config ?? const MediaPickerConfig();

    if (!context.mounted) return [];

    try {
      final result = await showModalBottomSheet<dynamic>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (ctx) => _EnhancedMediaPickerSheet(
          config: cfg,
          allowMultiple: true,
          maxFiles: maxFiles,
        ),
      );

      List<XFile> files = [];

      if (result is Map<String, dynamic>) {
        if (!context.mounted) return [];
        final source = result['source'] as ImageSource;
        final mediaType = result['mediaType'] as String;
        final allowMultiple = result['allowMultiple'] == true;

        if (source == ImageSource.gallery &&
            allowMultiple &&
            mediaType != 'document' &&
            !mediaType.startsWith('audio')) {
          final allowedTypes = <AssetType>[];
          if (cfg.allowImage) allowedTypes.add(AssetType.image);
          if (cfg.allowVideo) allowedTypes.add(AssetType.video);
          if (allowedTypes.isEmpty) allowedTypes.add(AssetType.image);

          final filesResult = await Navigator.push<List<MediaAssetModel>>(
            context,
            MaterialPageRoute(
              builder: (context) => GalleryPickerScreen(
                allowMultiple: true,
                maxSelection: maxFiles,
                allowedTypes: allowedTypes,
                maxFileSizeMB: cfg.effectiveMaxFileSizeMB,
              ),
            ),
          );
          if (filesResult != null) {
            files = filesResult.map((e) => XFile(e.file.path)).toList();
          }
        } else if (mediaType == 'document' && allowMultiple) {
          SecurityService().ignoreNextLifecycle();
          final pickerResult = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'pdf',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'ppt',
              'pptx',
            ],
          );
          if (pickerResult.isNotEmpty) {
            files = pickerResult
                .where((f) => f.path != null)
                .take(maxFiles)
                .map((f) => XFile(f.path!))
                .toList();
          }
        } else {
          final file = await _pickSingleMedia(context, source, mediaType, cfg);
          if (file != null) files = [file];
        }
      } else if (result is List<XFile>) {
        files = result;
      } else if (result is XFile) {
        files = [result];
      }

      // Check all picked files against max file size limit
      if (files.isNotEmpty) {
        final validFiles = <XFile>[];
        final rejectedNames = <String>[];

        for (final f in files) {
          final fileObj = File(f.path);
          if (fileObj.existsSync() &&
              fileObj.lengthSync() > cfg.effectiveMaxFileSizeBytes) {
            final sizeMB =
                (fileObj.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
            rejectedNames.add('${path.basename(f.path)} ($sizeMB MB)');
          } else {
            validFiles.add(f);
          }
        }

        if (rejectedNames.isNotEmpty) {
          AppSnackbar.warning(
            'File(s) Exceeded Limit (${cfg.bucketDisplayName})',
            description:
                '${rejectedNames.length} file(s) exceeded the ${cfg.effectiveMaxFileSizeMB} MB limit and were skipped.',
          );
        }

        files = validFiles;
      }

      if (files.isNotEmpty && context.mounted) {
        files = await _routeThroughEditor(context, files);
      }

      if (files.isNotEmpty && cfg.autoCompress && context.mounted) {
        return await _processMultipleFiles(context, files, cfg);
      }

      return files;
    } catch (e) {
      logE('Error picking multiple media: $e');
      if (context.mounted) {
        snackbarService.showError('Failed to pick media');
      }
      return [];
    }
  }

  static Future<XFile?> _pickSingleMedia(
    BuildContext context,
    ImageSource source,
    String mediaType,
    MediaPickerConfig config,
  ) async {
    // Camera
    if (source == ImageSource.camera &&
        (mediaType == 'image' ||
            mediaType == 'video' ||
            mediaType == 'media')) {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CameraCaptureScreen(allowVideo: config.allowVideo),
        ),
      );

      if (result is List<XFile> && result.isNotEmpty) {
        return result.first;
      } else if (result is CameraCaptureResult && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    }

    // Gallery
    if (source == ImageSource.gallery &&
        (mediaType == 'image' ||
            mediaType == 'video' ||
            mediaType == 'media')) {
      final allowedTypes = <AssetType>[];
      if (mediaType == 'image' || (mediaType == 'media' && config.allowImage)) {
        allowedTypes.add(AssetType.image);
      }
      if (mediaType == 'video' || (mediaType == 'media' && config.allowVideo)) {
        allowedTypes.add(AssetType.video);
      }

      if (allowedTypes.isEmpty) allowedTypes.add(AssetType.image);

      final result = await Navigator.push<List<MediaAssetModel>>(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryPickerScreen(
            allowMultiple: false,
            maxSelection: 1,
            allowedTypes: allowedTypes.isNotEmpty
                ? allowedTypes
                : [AssetType.image, AssetType.video],
            maxFileSizeMB: config.effectiveMaxFileSizeMB,
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        // Gallery picker already fixes rotation
        return XFile(result.first.file.path);
      }
      return null;
    }

    // Other types
    final picker = ImagePicker();

    try {
      XFile? file;

      switch (mediaType) {
        case 'audio_file':
          SecurityService().ignoreNextLifecycle();
          final result = await FilePicker.pickFile(type: FileType.audio);
          if (result != null && result.path != null) {
            file = XFile(result.path!);
          }
          break;

        case 'audio_record':
          if (!context.mounted) return null;
          file = await _showAudioRecorder(context);
          break;

        case 'document':
          SecurityService().ignoreNextLifecycle();
          final result = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: [
              'pdf',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'ppt',
              'pptx',
            ],
          );
          if (result != null && result.path != null) {
            file = XFile(result.path!);
          }
          break;

        case 'image':
        case 'media':
          if (source == ImageSource.gallery) {
            // Force-route system intent to our local RAM-safe picker
            final result = await Navigator.push<List<MediaAssetModel>>(
              context,
              MaterialPageRoute(
                builder: (context) => GalleryPickerScreen(
                  allowMultiple: false,
                  maxSelection: 1,
                  allowedTypes: mediaType == 'image'
                      ? [AssetType.image]
                      : [AssetType.image, AssetType.video],
                  maxFileSizeMB: config.effectiveMaxFileSizeMB,
                ),
              ),
            );

            if (result != null && result.isNotEmpty) {
              file = XFile(result.first.file.path);
            }
          } else {
            SecurityService().ignoreNextLifecycle();
            file = await picker.pickImage(
              source: source,
              imageQuality: config.imageQuality,
            );
            // Fix rotation for system camera capture
            if (file != null && config.fixRotation) {
              final fixed = await ImageRotationFixer.fixRotation(
                File(file.path),
              );
              file = XFile(fixed.path);
            }
          }
          break;

        case 'video':
          if (source == ImageSource.gallery) {
            final result = await Navigator.push<List<MediaAssetModel>>(
              context,
              MaterialPageRoute(
                builder: (context) => GalleryPickerScreen(
                  allowMultiple: false,
                  maxSelection: 1,
                  allowedTypes: [AssetType.video],
                ),
              ),
            );
            if (result != null && result.isNotEmpty) {
              file = XFile(result.first.file.path);
            }
          } else {
            SecurityService().ignoreNextLifecycle();
            file = await picker.pickVideo(
              source: source,
              maxDuration: config.maxVideoDuration,
            );
          }
          break;
      }

      if (file == null) return null;

      // Trimming for video files
      final lowerPath = file.path.toLowerCase();
      if (lowerPath.endsWith('.mp4') ||
          lowerPath.endsWith('.mov') ||
          lowerPath.endsWith('.avi') ||
          lowerPath.endsWith('.mkv')) {
        if (context.mounted) {
          final trimmedPath = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => VideoTrimmerView(
                file: File(file!.path),
                maxDurationInSeconds: 60.0,
              ),
            ),
          );
          if (trimmedPath != null) {
            file = XFile(trimmedPath);
          } else {
            // User cancelled trimming
            return null;
          }
        }
      }

      // Size validation
      if (config.maxFileSizeMB != null) {
        final fileSize = await File(file.path).length();
        final sizeMB = fileSize / (1024 * 1024);
        if (sizeMB > config.maxFileSizeMB!) {
          if (context.mounted) {
            snackbarService.showError(
              'File too large',
              description: 'Max size: ${config.maxFileSizeMB}MB',
            );
          }
          return null;
        }
      }

      // Compression
      if (config.autoCompress &&
          (mediaType == 'image' || mediaType == 'video')) {
        if (context.mounted) {
          final fileToCompress = File(file.path);
          final needsComp = await EnhancedMediaCompressor.shouldCompress(
            fileToCompress,
            mediaType,
          );
          if (!context.mounted) return file;
          if (needsComp) {
            return await _compressWithAnimation(
              context,
              file,
              mediaType,
              config,
            );
          }
        }
      }

      return file;
    } catch (e) {
      logE('Error picking media: $e');
      if (context.mounted) {
        snackbarService.showError('Failed to pick media');
      }
      return null;
    }
  }

  static Future<XFile?> _showAudioRecorder(BuildContext context) async {
    if (!context.mounted) return null;

    return await showModalBottomSheet<XFile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedAudioRecorder(
        onCompleted: (file) => Navigator.pop(context, file),
        onCanceled: () => Navigator.pop(context),
      ),
    );
  }

  static Future<XFile?> _compressWithAnimation(
    BuildContext context,
    XFile file,
    String mediaType,
    MediaPickerConfig config,
  ) async {
    if (!context.mounted) return file;

    final compressedFile = await showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CompressionDialog(
        file: File(file.path),
        mediaType: mediaType,
        config: config,
      ),
    );

    if (compressedFile != null) {
      return XFile(compressedFile.path);
    }

    return file;
  }

  static Future<List<XFile>> _processMultipleFiles(
    BuildContext context,
    List<XFile> files,
    MediaPickerConfig config,
  ) async {
    // Fast check: if no files actually exceed size thresholds, bypass the dialog entirely!
    bool anyNeedsCompression = false;
    for (final f in files) {
      final mediaType = EnhancedMediaCompressor.detectMediaType(f.path);
      if (await EnhancedMediaCompressor.shouldCompress(File(f.path), mediaType)) {
        anyNeedsCompression = true;
        break;
      }
    }

    if (!anyNeedsCompression) {
      logD('⚡ [Instant Pick] All ${files.length} selected files within size limits. Bypassing compression dialog.');
      return files;
    }

    final processedFiles = <XFile>[];

    // Show batch processing dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _BatchProcessingDialog(
          files: files,
          config: config,
          onProcessed: (processed) {
            processedFiles.addAll(processed);
          },
        ),
      );
    }

    return processedFiles.isNotEmpty ? processedFiles : files;
  }

  static Future<List<XFile>> _routeThroughEditor(
    BuildContext context,
    List<XFile> files,
  ) async {
    if (files.isEmpty) return files;

    // Separate editable and non-editable files
    final editableFiles = <XFile>[];
    final nonEditableFiles = <XFile>[];

    for (final x in files) {
      final ext = path.extension(x.path).toLowerCase();
      if ([
        '.mp4',
        '.mov',
        '.avi',
        '.mkv',
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.heic',
      ].contains(ext)) {
        editableFiles.add(x);
      } else {
        nonEditableFiles.add(x);
      }
    }

    if (editableFiles.isEmpty) {
      return files;
    }

    final assets = editableFiles.map((x) {
      final ext = path.extension(x.path).toLowerCase();
      final type = ['.mp4', '.mov', '.avi', '.mkv'].contains(ext)
          ? MediaType.video
          : MediaType.image;
      return MediaAssetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + x.name,
        file: File(x.path),
        type: type,
      );
    }).toList();

    final editedAssets = await Navigator.push<List<MediaAssetModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaEditorScreen(mediaAssets: assets),
      ),
    );

    if (editedAssets != null && editedAssets.isNotEmpty) {
      final processedFiles = editedAssets
          .map((e) => XFile(e.editedFile?.path ?? e.file.path))
          .toList();
      return [...processedFiles, ...nonEditableFiles];
    }

    // If canceled, return empty list
    return [];
  }
}

// ============================================================
// MEDIA PICKER SHEET - IMPROVED UI
// ============================================================

class _EnhancedMediaPickerSheet extends StatefulWidget {
  final MediaPickerConfig config;
  final bool allowMultiple;
  final int maxFiles;

  const _EnhancedMediaPickerSheet({
    required this.config,
    this.allowMultiple = false,
    this.maxFiles = 1,
  });

  @override
  State<_EnhancedMediaPickerSheet> createState() =>
      _EnhancedMediaPickerSheetState();
}

class _EnhancedMediaPickerSheetState extends State<_EnhancedMediaPickerSheet>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _optionAnimController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _optionAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _animController.forward();
    _optionAnimController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _optionAnimController.dispose();
    super.dispose();
  }

  List<_MediaOption> _buildOptions() {
    final options = <_MediaOption>[];

    if (widget.config.allowCamera) {
      options.add(
        _MediaOption(
          label: 'Camera',
          icon: Icons.camera_alt_rounded,
          color: const Color(0xFF6366F1), // Indigo
          animationDelay: 0,
          onTap: () => _pickMedia(ImageSource.camera, 'media'),
        ),
      );
    }

    if (widget.config.allowGallery) {
      options.add(
        _MediaOption(
          label: 'Gallery',
          icon: Icons.photo_library_rounded,
          color: const Color(0xFFEC4899), // Pink
          animationDelay: 50,
          onTap: () => _pickMedia(ImageSource.gallery, 'media'),
        ),
      );
    }

    if (widget.config.allowAudio) {
      options.add(
        _MediaOption(
          label: 'Audio',
          icon: Icons.mic_rounded,
          color: const Color(0xFFF59E0B), // Amber
          animationDelay: 100,
          onTap: () => _pickMedia(ImageSource.gallery, 'audio_record'),
        ),
      );
    }

    if (widget.config.allowDocument) {
      options.add(
        _MediaOption(
          label: 'File',
          icon: Icons.folder_rounded,
          color: const Color(0xFF10B981), // Emerald
          animationDelay: 150,
          onTap: () => _pickMedia(ImageSource.gallery, 'document'),
        ),
      );
    }

    return options;
  }

  Future<void> _pickMedia(ImageSource source, String mediaType) async {
    HapticFeedback.selectionClick();

    if (!mounted) return;

    Navigator.pop(context, {
      'source': source,
      'mediaType': mediaType,
      'allowMultiple': widget.allowMultiple,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptions();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, screenHeight * 0.4 * _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 5,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle with Black background
            Container(
              width: double.infinity,
              color: isDark ? Colors.black : theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Grey Header
            Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF212121) : const Color(0xFFEEEEEE),
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Media',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.allowMultiple
                              ? 'Choose up to ${widget.maxFiles} files'
                              : 'Choose a file to continue',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Bucket Max File Size Info Badge
            Container(
              margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141414)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF38BDF8)
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Max size limit: ${widget.config.effectiveMaxFileSizeMB} MB per file${widget.config.bucket != null ? ' (${widget.config.bucket!.displayName})' : ''}',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Options Grid
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: _buildOptionsGrid(options, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(List<_MediaOption> options, bool isDark) {
    if (options.isEmpty) {
      return Center(
        child: Text(
          'No media options available',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: context.responsive(standard: 1.05, compact: 0.95, tablet: 1.2),
          ),
          itemCount: options.length,
          itemBuilder: (context, index) => _MediaOptionCard(
            option: options[index],
            animation: _optionAnimController,
          ),
        );
      },
    );
  }
}

// ============================================================
// MEDIA OPTION CLASSES - IMPROVED
// ============================================================

class _MediaOption {
  final String label;
  final IconData icon;
  final Color color;
  final int animationDelay;
  final VoidCallback onTap;

  _MediaOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.animationDelay,
    required this.onTap,
  });
}

class _MediaOptionCard extends StatefulWidget {
  final _MediaOption option;
  final Animation<double> animation;

  const _MediaOptionCard({required this.option, required this.animation});

  @override
  State<_MediaOptionCard> createState() => _MediaOptionCardState();
}

class _MediaOptionCardState extends State<_MediaOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final delayedAnimation = Interval(
          widget.option.animationDelay / 500,
          1.0,
          curve: Curves.easeOutCubic,
        ).transform(widget.animation.value);

        return Transform.scale(
          scale: delayedAnimation,
          child: Opacity(opacity: delayedAnimation, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _scaleController.reverse();
          widget.option.onTap();
        },
        onTapCancel: () => _scaleController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161616)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: widget.option.color.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.option.onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.option.color.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.option.icon,
                                size: 32,
                                color: widget.option.color,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.option.label,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// AUDIO RECORDER DIALOG - IMPROVED UI
// ============================================================

// ============================================================
// COMPRESSION DIALOG - IMPROVED
// ============================================================

class _CompressionDialog extends StatefulWidget {
  final File file;
  final String mediaType;
  final MediaPickerConfig config;

  const _CompressionDialog({
    required this.file,
    required this.mediaType,
    required this.config,
  });

  @override
  State<_CompressionDialog> createState() => _CompressionDialogState();
}

class _CompressionDialogState extends State<_CompressionDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  double _progress = 0.0;
  Subscription? _subscription;
  bool _isCompressing = true;
  String _statusMessage = 'Optimizing...';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _startCompression();
  }

  Future<void> _startCompression() async {
    if (widget.mediaType == 'video') {
      _subscription = EnhancedMediaCompressor.subscribeToProgress((progress) {
        if (mounted) {
          setState(() {
            _progress = progress / 100;
            _statusMessage = 'Compressing video... ${progress.toInt()}%';
          });
        }
      });
    }

    File? compressed;

    try {
      if (widget.mediaType == 'image') {
        setState(() => _statusMessage = 'Fixing orientation...');

        compressed = await EnhancedMediaCompressor.compressImage(
          widget.file,
          quality: widget.config.imageQuality,
          fixRotation: widget.config.fixRotation,
        );
      } else if (widget.mediaType == 'video') {
        compressed = await EnhancedMediaCompressor.compressVideo(
          widget.file,
          quality: widget.config.videoQuality,
        );
      }

      if (mounted) {
        setState(() {
          _isCompressing = false;
          _statusMessage = 'Complete!';
        });
        _progressController.forward();

        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          Navigator.pop(context, compressed ?? widget.file);
        }
      }
    } catch (e) {
      logE('Compression error: $e');
      if (mounted) {
        setState(() {
          _isCompressing = false;
          _statusMessage = 'Failed';
        });
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context, widget.file);
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isCompressing
                  ? RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_fix_high_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + (_progressAnimation.value * 0.2),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              _isCompressing ? 'Optimizing Media' : 'Complete!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Status
            Text(
              _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Progress Bar
            if (widget.mediaType == 'video' &&
                _progress > 0 &&
                _isCompressing) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FuturisticLinearLoadingIndicator(
                  value: _progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BATCH PROCESSING DIALOG
// ============================================================

class _BatchProcessingDialog extends StatefulWidget {
  final List<XFile> files;
  final MediaPickerConfig config;
  final Function(List<XFile>) onProcessed;

  const _BatchProcessingDialog({
    required this.files,
    required this.config,
    required this.onProcessed,
  });

  @override
  State<_BatchProcessingDialog> createState() => _BatchProcessingDialogState();
}

class _BatchProcessingDialogState extends State<_BatchProcessingDialog> {
  int _currentIndex = 0;
  final List<XFile> _processedFiles = [];
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _processFiles();
  }

  Future<void> _processFiles() async {
    for (int i = 0; i < widget.files.length; i++) {
      if (!mounted) break;

      setState(() => _currentIndex = i);

      final file = widget.files[i];
      final mediaType = EnhancedMediaCompressor.detectMediaType(file.path);

      if ((mediaType == 'image' || mediaType == 'video') &&
          widget.config.autoCompress) {
        final fileToCompress = File(file.path);
        final needsComp = await EnhancedMediaCompressor.shouldCompress(
          fileToCompress,
          mediaType,
        );
        if (needsComp) {
          final compressed = await EnhancedMediaCompressor.compressMedia(
            fileToCompress,
            fixRotation: widget.config.fixRotation,
            videoQuality: widget.config.videoQuality,
          );

          if (compressed != null) {
            _processedFiles.add(XFile(compressed.path));
          } else {
            _processedFiles.add(file);
          }
        } else {
          _processedFiles.add(file);
        }
      } else {
        _processedFiles.add(file);
      }
    }

    setState(() => _isComplete = true);
    widget.onProcessed(_processedFiles);

    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentIndex + 1) / widget.files.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isComplete
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Colors.green,
                    )
                  : SizedBox(
                      width: 64,
                      height: 64,
                      child: FuturisticLoadingIndicator(
                        value: progress,
                        strokeWidth: 4,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              _isComplete ? 'Complete!' : 'Processing Files',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_currentIndex + 1} of ${widget.files.length} files',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
