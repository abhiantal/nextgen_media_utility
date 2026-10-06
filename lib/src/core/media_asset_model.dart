// ============================================================
// FILE: lib/src/core/media_asset_model.dart
// NextGen Media Utility - Universal Media Asset Model
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';

enum MediaType { image, video, audio }

class MediaAssetModel {
  final String id;
  final File file;
  File? editedFile;
  final MediaType type;

  List<DrawStroke> drawingPaths = [];

  double brightness = 0.0;
  double contrast = 0.0;
  double saturation = 0.0;

  double cropLeft = 0.0;
  double cropTop = 0.0;
  double cropRight = 1.0;
  double cropBottom = 1.0;

  Duration? videoTrimStart;
  Duration? videoTrimEnd;
  Duration? videoDuration;
  File? audioOverlay;
  double videoVolume = 1.0;
  double audioOverlayVolume = 0.5;

  ColorFilter? appliedFilter;
  String? filterName;

  MediaAssetModel({
    required this.id,
    required this.file,
    required this.type,
    this.editedFile,
    this.videoDuration,
    ColorFilter? appliedFilter,
    String? filterName,
  });

  MediaAssetModel copyWith({
    File? file,
    File? editedFile,
    MediaType? type,
    List<DrawStroke>? drawingPaths,
    double? brightness,
    double? contrast,
    double? saturation,
    Duration? videoTrimStart,
    Duration? videoTrimEnd,
    ColorFilter? appliedFilter,
    String? filterName,
  }) {
    return MediaAssetModel(
      id: id,
      file: file ?? this.file,
      type: type ?? this.type,
      editedFile: editedFile ?? this.editedFile,
      videoDuration: videoDuration,
    )
      ..drawingPaths = drawingPaths ?? List.from(this.drawingPaths)
      ..brightness = brightness ?? this.brightness
      ..contrast = contrast ?? this.contrast
      ..saturation = saturation ?? this.saturation
      ..videoTrimStart = videoTrimStart ?? this.videoTrimStart
      ..videoTrimEnd = videoTrimEnd ?? this.videoTrimEnd
      ..appliedFilter = appliedFilter ?? this.appliedFilter
      ..filterName = filterName ?? this.filterName;
  }

  bool get hasEdits {
    return drawingPaths.isNotEmpty ||
        filterName != null ||
        brightness != 0 ||
        contrast != 0 ||
        saturation != 0 ||
        editedFile != null;
  }
}

class DrawStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

enum MediaFileType { image, video, audio, document }

class EnhancedMediaFile {
  final String id;
  final String url;
  final MediaFileType type;
  final String? fileName;
  final int? size;
  final DateTime? uploadedAt;
  final double? aspectRatio;
  final Duration? duration;
  final bool isLocal;
  final String? thumbnailUrl;

  EnhancedMediaFile({
    required this.id,
    required this.url,
    required this.type,
    this.fileName,
    this.size,
    this.uploadedAt,
    this.aspectRatio,
    this.duration,
    this.isLocal = false,
    this.thumbnailUrl,
  });

  factory EnhancedMediaFile.fromUrl({
    required String id,
    required String url,
    String? fileName,
    int? size,
    DateTime? uploadedAt,
    String? thumbnailUrl,
  }) {
    final type = detectMediaType(url);
    final isThumbVideo =
        thumbnailUrl != null && detectMediaType(thumbnailUrl) == MediaFileType.video;
    return EnhancedMediaFile(
      id: id,
      url: url,
      type: type,
      fileName: fileName ?? _extractFileName(url),
      size: size,
      uploadedAt: uploadedAt ?? DateTime.now(),
      isLocal: false,
      thumbnailUrl: isThumbVideo ? null : thumbnailUrl,
    );
  }

  factory EnhancedMediaFile.fromFile({
    required File file,
    String? id,
    MediaFileType? type,
  }) {
    final path = file.path;
    return EnhancedMediaFile(
      id: id ?? path,
      url: path,
      type: type ?? detectMediaType(path),
      fileName: path.split(Platform.pathSeparator).last,
      size: file.existsSync() ? file.lengthSync() : 0,
      uploadedAt: DateTime.now(),
      isLocal: true,
    );
  }

  static MediaFileType detectMediaType(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();

      if (path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png') ||
          path.endsWith('.gif') ||
          path.endsWith('.webp') ||
          path.endsWith('.heic')) {
        return MediaFileType.image;
      }

      if (path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.avi') ||
          path.endsWith('.mkv') ||
          path.endsWith('.webm')) {
        return MediaFileType.video;
      }

      if (path.endsWith('.mp3') ||
          path.endsWith('.wav') ||
          path.endsWith('.aac') ||
          path.endsWith('.flac') ||
          path.endsWith('.ogg') ||
          path.endsWith('.m4a')) {
        return MediaFileType.audio;
      }

      if (path.endsWith('.pdf') ||
          path.endsWith('.doc') ||
          path.endsWith('.docx')) {
        return MediaFileType.document;
      }

      return MediaFileType.image;
    } catch (e) {
      return MediaFileType.image;
    }
  }

  static String _extractFileName(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (e) {
      return 'media_file';
    }
  }

  bool get supportsFullScreen =>
      type == MediaFileType.image ||
      type == MediaFileType.video ||
      type == MediaFileType.audio;
}

List<EnhancedMediaFile> convertUrlsToEnhancedMedia(List<String> urls) {
  return urls.asMap().entries.map((entry) {
    return EnhancedMediaFile.fromUrl(
      id: '${entry.value}_${entry.key}',
      url: entry.value,
    );
  }).toList();
}
