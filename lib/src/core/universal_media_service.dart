// ============================================================
// NextGen Media Utility - Universal Media Service
// High-performance, modular, offline-first media toolkit
// Fully customizable storage & bucket management for Flutter apps
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'media_logger.dart';
import 'media_snackbar.dart';

// ============================================================
// BUCKET CONFIGURATION — 100% CUSTOMIZABLE FOR ANY DEVELOPER
// ============================================================

/// Flexible media bucket allowing any developer to define their own storage buckets,
/// size limits, public/private access, and display names.
class MediaBucket {
  /// Unique bucket identifier used by cloud storage (e.g. 'general', 'photos', 'attachments')
  final String bucketId;

  /// Maximum allowed file size in Megabytes for this bucket
  final int maxSizeMB;

  /// Whether the bucket is public (accessible via public URL) or private (requires signed URLs)
  final bool isPublic;

  /// User-friendly label for UI and warning messages
  final String displayName;

  /// Optional folder path inside the bucket (defaults to bucketId if null)
  final String? folderPath;

  /// Optional allowed file extensions (e.g. ['jpg', 'png', 'pdf']). If null, all extensions allowed.
  final List<String>? allowedExtensions;

  const MediaBucket({
    required this.bucketId,
    this.maxSizeMB = 50,
    this.isPublic = false,
    this.displayName = 'Media',
    this.folderPath,
    this.allowedExtensions,
  });

  /// Alias for bucketId
  String get bucketName => bucketId;

  /// Maximum file size in bytes
  int get maxSizeBytes => maxSizeMB * 1024 * 1024;

  /// Formatted limit string (e.g. '50MB')
  String get formattedSizeLimit => '${maxSizeMB}MB';

  /// Default general media bucket for zero-config fallback usage
  static const general = MediaBucket(
    bucketId: 'general',
    maxSizeMB: 50,
    isPublic: false,
    displayName: 'General Media',
  );

  /// Helper factory to easily create any custom bucket on the fly
  factory MediaBucket.custom({
    required String bucketId,
    int maxSizeMB = 50,
    bool isPublic = false,
    String? displayName,
    String? folderPath,
    List<String>? allowedExtensions,
  }) =>
      MediaBucket(
        bucketId: bucketId,
        maxSizeMB: maxSizeMB,
        isPublic: isPublic,
        displayName: displayName ?? bucketId,
        folderPath: folderPath,
        allowedExtensions: allowedExtensions,
      );

  static List<MediaBucket> get defaultBuckets => [general];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaBucket && runtimeType == other.runtimeType && bucketId == other.bucketId;

  @override
  int get hashCode => bucketId.hashCode;

  @override
  String toString() => 'MediaBucket($bucketId, ${maxSizeMB}MB, public: $isPublic)';
}

// ============================================================
// STORAGE EVENTS & STATS
// ============================================================

class UrlUpdateEvent {
  final String storagePath;
  final String newUrl;
  String get newHttpsUrl => newUrl;
  const UrlUpdateEvent({required this.storagePath, required this.newUrl});
}

class StorageStats {
  final Map<String, int> bucketStats;
  final int totalFiles;
  final int totalSize;

  const StorageStats({
    required this.bucketStats,
    this.totalFiles = 0,
    this.totalSize = 0,
  });
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ============================================================
// PLUGGABLE DATABASE DELEGATE (POWERSYNC / SQLITE / CUSTOM)
// ============================================================

/// Interface for apps that want to provide an offline database for query caching & sync queue
abstract class MediaCacheDelegate {
  Future<List<Map<String, dynamic>>> executeQuery(String sql, {List<dynamic>? parameters});
  Future<void> execute(String sql, [List<dynamic>? parameters]);
  Future<Map<String, dynamic>?> querySingle(String sql, {List<dynamic>? parameters});
  bool get isOnline;
  bool get isInitialized;
}

/// Generic adapter that can wrap any database service (like PowerSync) dynamically
class DynamicPowerSyncAdapter implements MediaCacheDelegate {
  final dynamic database;
  DynamicPowerSyncAdapter(this.database);

  @override
  Future<List<Map<String, dynamic>>> executeQuery(String sql, {List<dynamic>? parameters}) async {
    try {
      final res = await database.executeQuery(sql, parameters: parameters);
      if (res is List) return res.cast<Map<String, dynamic>>();
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? parameters]) async {
    try {
      await database.execute(sql, parameters);
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> querySingle(String sql, {List<dynamic>? parameters}) async {
    try {
      final res = await database.querySingle(sql, parameters: parameters);
      if (res is Map) return res.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isOnline {
    try {
      return database?.isOnline ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  bool get isInitialized {
    try {
      return database?.isInitialized ?? false;
    } catch (_) {
      return false;
    }
  }
}

// ============================================================
// PLUGGABLE STORAGE BACKEND INTERFACE
// ============================================================

/// Allows developers to implement any backend: AWS S3, Firebase, Custom REST API, Supabase, etc.
abstract class StorageBackend {
  Future<String?> upload({
    required File file,
    required String path,
    required MediaBucket bucket,
    void Function(double)? onProgress,
  });

  Future<String?> resolveUrl(String path, MediaBucket bucket);
  Future<bool> delete(String path, MediaBucket bucket);
}

// ============================================================
// UNIVERSAL MEDIA SERVICE (SINGLETON)
// ============================================================

/// Comprehensive media management service supporting local caching, file size checks,
/// URL resolution, deduping, and pluggable cloud storage.
class UniversalMediaService {
  static final UniversalMediaService _instance = UniversalMediaService._internal();
  factory UniversalMediaService() => _instance;
  UniversalMediaService._internal();

  /// Global singleton instance getter
  static UniversalMediaService get instance => _instance;

  /// Pluggable custom storage backend (e.g. Supabase, Firebase, S3, custom API)
  static StorageBackend? storageBackend;

  /// Pluggable offline database delegate (e.g. PowerSyncService)
  static MediaCacheDelegate? databaseDelegate;

  /// Setter allowing developers to pass PowerSync or any custom DB instance
  static set powerSyncInstance(dynamic instance) {
    if (instance == null) {
      databaseDelegate = null;
    } else if (instance is MediaCacheDelegate) {
      databaseDelegate = instance;
    } else {
      databaseDelegate = DynamicPowerSyncAdapter(instance);
    }
  }

  /// Custom path builder callback allowing developers to format their cloud file paths
  static String Function({
    required String? userId,
    required MediaBucket bucket,
    required String uniqueName,
    String? customPath,
  })? customPathBuilder;

  // Stream of URL updates
  final StreamController<UrlUpdateEvent> _urlUpdateController =
      StreamController<UrlUpdateEvent>.broadcast();
  Stream<UrlUpdateEvent> get urlUpdates => _urlUpdateController.stream;

  // In-memory signed URL cache
  final Map<String, _CachedUrl> _signedUrlCache = {};

  // In-flight upload deduplication map
  final Map<String, Future<String?>> _inFlightUploads = {};

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _isOnline {
    if (databaseDelegate != null) {
      return databaseDelegate!.isOnline;
    }
    return true;
  }

  // ============================================================
  // INITIALIZATION & DIRECTORY SETUP
  // ============================================================

  /// Initializes the media service and creates local cache folders for registered buckets
  Future<void> init([List<MediaBucket>? buckets]) async {
    try {
      MediaLogger.info('🚀 Initializing UniversalMediaService...');
      final documentsDir = await getApplicationDocumentsDirectory();
      final targetBuckets = buckets ?? MediaBucket.defaultBuckets;
      for (final bucket in targetBuckets) {
        final dir = Directory(p.join(documentsDir.path, 'media_cache', bucket.bucketId));
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      MediaLogger.info('✅ UniversalMediaService initialized');
    } catch (e, stack) {
      logE('Failed to init UniversalMediaService', e, stack);
    }
  }

  // ============================================================
  // FILE SIZE VALIDATION
  // ============================================================

  /// Validates whether a file is within the maximum size limit for the given [bucket].
  /// Shows an animated warning snackbar if [showWarning] is true.
  static bool validateFileSize(
    File file, [
    dynamic bucket,
    bool showWarning = true,
  ]) {
    try {
      if (!file.existsSync()) return true;
      final maxMB = (bucket is MediaBucket) ? bucket.maxSizeMB : 50;
      final maxBytes = maxMB * 1024 * 1024;
      final size = file.lengthSync();
      if (size > maxBytes) {
        final sizeMBStr = (size / (1024 * 1024)).toStringAsFixed(1);
        final displayName = (bucket is MediaBucket) ? bucket.displayName : 'Media';
        MediaLogger.warning('File exceeds limit: $sizeMBStr MB > $maxMB MB ($displayName)');
        if (showWarning) {
          AppSnackbar.warning(
            'File Too Large',
            description: 'Selected file is $sizeMBStr MB, exceeding the $maxMB MB limit for $displayName.',
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      MediaLogger.warning('Error checking file size: $e');
      return true;
    }
  }

  // ============================================================
  // PATH GENERATION & DEDUPLICATION HASH
  // ============================================================

  Future<String> _computeFastHash(File file) async {
    try {
      final length = await file.length();
      if (length <= 512 * 1024) {
        final bytes = await file.readAsBytes();
        return sha256.convert(bytes).toString().substring(0, 16);
      }
      final raf = await file.open(mode: FileMode.read);
      try {
        final head = await raf.read(32 * 1024);
        List<int> tail = [];
        if (length > 64 * 1024) {
          await raf.setPosition(length - 32 * 1024);
          tail = await raf.read(32 * 1024);
        }
        final bytes = <int>[...head, ...utf8.encode(length.toString()), ...tail];
        return sha256.convert(bytes).toString().substring(0, 16);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    }
  }

  /// Generates a clean, customizable cloud storage path
  String getCanonicalStoragePath({
    required String? userId,
    required MediaBucket bucket,
    required String uniqueName,
    String? customPath,
    String? overrideBucketFolder,
  }) {
    if (customPathBuilder != null) {
      return customPathBuilder!(
        userId: userId,
        bucket: bucket,
        uniqueName: uniqueName,
        customPath: customPath,
      );
    }

    final uid = userId ?? 'guest';
    String cleanCustom = '';
    if (customPath != null && customPath.isNotEmpty) {
      cleanCustom = customPath.startsWith(uid)
          ? customPath.substring(uid.length).replaceAll(RegExp(r'^/'), '')
          : customPath;
    }
    cleanCustom = cleanCustom.replaceAll(RegExp(r'^/+|/+$'), '');

    if (cleanCustom.isNotEmpty) {
      return '$uid/$cleanCustom/$uniqueName';
    }
    final folder = overrideBucketFolder ?? bucket.folderPath ?? bucket.bucketId;
    return '$uid/$folder/$uniqueName';
  }

  /// Primes the in-memory cache with a local file path for instant zero-lag UI display
  void primeLocalCache(String storagePath, String localFilePath) {
    if (storagePath.isEmpty || localFilePath.isEmpty) return;
    _signedUrlCache[storagePath] = _CachedUrl(
      localFilePath,
      DateTime.now().add(const Duration(hours: 24)),
    );
  }

  // ============================================================
  // UPLOAD API
  // ============================================================

  /// Uploads a single file to the specified bucket with progress tracking
  Future<String?> uploadSingle({
    required File file,
    dynamic bucket,
    String? customPath,
    String? exactStoragePath,
    String? userId,
    bool autoCompress = true,
    void Function(double)? onProgress,
  }) async {
    final effectiveBucket = bucket is MediaBucket
        ? bucket
        : MediaBucket.custom(bucketId: bucket?.toString() ?? 'general');

    final results = await uploadMultiple(
      files: [file],
      bucket: effectiveBucket,
      customPath: customPath,
      exactStoragePath: exactStoragePath,
      userId: userId,
      autoCompress: autoCompress,
      onProgress: onProgress,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Uploads multiple files in parallel with deduplication and progress callback
  Future<List<String>> uploadMultiple({
    required List<File> files,
    required MediaBucket bucket,
    String? customPath,
    String? exactStoragePath,
    String? overrideBucketFolder,
    String? userId,
    bool autoCompress = true,
    void Function(double)? onProgress,
  }) async {
    if (files.isEmpty) return [];

    final client = _supabase;
    final effectiveUserId = userId ?? client?.auth.currentUser?.id;
    int processed = 0;
    final total = files.length;

    final uploadTasks = files.map((file) async {
      final fileName = p.basename(file.path);
      final ext = p.extension(fileName);

      if (!validateFileSize(file, bucket, true)) {
        return null;
      }

      final hashSnippet = await _computeFastHash(file);
      final uniqueName = '$hashSnippet$ext';

      final storagePath = (files.length == 1 && exactStoragePath != null)
          ? exactStoragePath
          : getCanonicalStoragePath(
              userId: effectiveUserId,
              bucket: bucket,
              uniqueName: uniqueName,
              customPath: customPath,
              overrideBucketFolder: overrideBucketFolder,
            );

      // In-flight deduplication
      if (_inFlightUploads.containsKey(storagePath)) {
        final result = await _inFlightUploads[storagePath];
        processed++;
        onProgress?.call(processed / total);
        return result ?? storagePath;
      }

      // Memory cache local path for instant UI display
      primeLocalCache(storagePath, file.path);

      // Custom backend check
      if (storageBackend != null) {
        final customResult = await storageBackend!.upload(
          file: file,
          path: storagePath,
          bucket: bucket,
          onProgress: onProgress,
        );
        processed++;
        onProgress?.call(processed / total);
        return customResult ?? storagePath;
      }

      if (client == null || !_isOnline) {
        processed++;
        onProgress?.call(processed / total);
        return storagePath;
      }

      final completer = Completer<String?>();
      _inFlightUploads[storagePath] = completer.future;

      try {
        await client.storage.from(bucket.bucketId).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true, cacheControl: '36000'),
            );

        String resolvedUrl;
        if (bucket.isPublic) {
          resolvedUrl = client.storage.from(bucket.bucketId).getPublicUrl(storagePath);
        } else {
          try {
            resolvedUrl = await client.storage.from(bucket.bucketId).createSignedUrl(storagePath, 3600);
          } catch (_) {
            resolvedUrl = file.path;
          }
        }

        _signedUrlCache[storagePath] = _CachedUrl(
          resolvedUrl,
          DateTime.now().add(const Duration(minutes: 50)),
        );
        _urlUpdateController.add(UrlUpdateEvent(storagePath: storagePath, newUrl: resolvedUrl));

        completer.complete(storagePath);
        processed++;
        onProgress?.call(processed / total);
        return storagePath;
      } catch (e) {
        MediaLogger.warning('Direct upload fallback to local for $storagePath: $e');
        completer.complete(storagePath);
        processed++;
        onProgress?.call(processed / total);
        return storagePath;
      } finally {
        _inFlightUploads.remove(storagePath);
      }
    });

    final results = await Future.wait(uploadTasks);
    return results.whereType<String>().toList();
  }

  // ============================================================
  // CONVENIENCE UPLOAD HELPERS
  // ============================================================

  /// Generic convenience helper to upload an avatar or profile image
  Future<String?> uploadAvatar({
    required dynamic file,
    MediaBucket bucket = MediaBucket.general,
    String? userId,
    String? customPath,
    void Function(double)? onProgress,
  }) async {
    return uploadSingle(
      file: file,
      bucket: bucket,
      userId: userId,
      customPath: customPath ?? 'avatars',
      onProgress: onProgress,
    );
  }

  // ============================================================
  // URL RESOLUTION & CACHING
  // ============================================================

  /// Resolves any path, cloud key, or URL into a viewable display URL or cached local file
  Future<String?> resolveUrl(
    String? pathOrUrl, [
    dynamic bucket,
  ]) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    // Fast-path: local absolute file
    if (!pathOrUrl.startsWith('http') && _isLocalPath(pathOrUrl)) {
      if (File(pathOrUrl).existsSync()) return pathOrUrl;
    }

    // Fast-path: public URL with query token
    if (pathOrUrl.startsWith('http') && (pathOrUrl.contains('token=') || !pathOrUrl.contains('/storage/v1/'))) {
      return pathOrUrl;
    }

    final effectiveBucket = bucket is MediaBucket
        ? bucket
        : MediaBucket.custom(bucketId: bucket?.toString() ?? 'general');

    final cleanStoragePath = _normalizeStoragePath(pathOrUrl, effectiveBucket);

    // 1. In-memory signed URL cache
    final cached = _signedUrlCache[cleanStoragePath];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    // 2. Check local disk cache
    final diskFile = await findFileOnDisk(cleanStoragePath, effectiveBucket);
    if (diskFile != null) {
      _signedUrlCache[cleanStoragePath] = _CachedUrl(
        diskFile,
        DateTime.now().add(const Duration(hours: 1)),
      );
      return diskFile;
    }

    // 3. Custom backend resolution
    if (storageBackend != null) {
      return await storageBackend!.resolveUrl(cleanStoragePath, effectiveBucket);
    }

    // 4. Supabase resolution if online
    final client = _supabase;
    if (client != null && _isOnline) {
      try {
        if (effectiveBucket.isPublic) {
          final pubUrl = client.storage.from(effectiveBucket.bucketId).getPublicUrl(cleanStoragePath);
          _signedUrlCache[cleanStoragePath] = _CachedUrl(
            pubUrl,
            DateTime.now().add(const Duration(days: 7)),
          );
          return pubUrl;
        } else {
          final signed = await client.storage.from(effectiveBucket.bucketId).createSignedUrl(cleanStoragePath, 3600);
          _signedUrlCache[cleanStoragePath] = _CachedUrl(
            signed,
            DateTime.now().add(const Duration(minutes: 50)),
          );
          return signed;
        }
      } catch (e) {
        MediaLogger.warning('resolveUrl error for $cleanStoragePath: $e');
      }
    }

    return pathOrUrl;
  }

  /// Convenience resolver for avatar paths
  Future<String?> getValidAvatarUrl(String? path, [MediaBucket? bucket]) async {
    if (path == null || path.isEmpty) return null;
    return resolveUrl(path, bucket ?? MediaBucket.general);
  }

  /// Backwards-compatibility alias for signed URL
  Future<String?> getValidSignedUrl(String path) => resolveUrl(path);

  // ============================================================
  // DOWNLOAD & DISK LOOKUP
  // ============================================================

  /// Downloads remote media file to the local device storage
  Future<File?> downloadFile({
    dynamic urlOrPath,
    String? mediaUrl,
    dynamic bucket,
    String? targetPath,
  }) async {
    final effectiveUrl = mediaUrl ?? urlOrPath?.toString();
    if (effectiveUrl == null || effectiveUrl.isEmpty) return null;

    try {
      if (targetPath != null) {
        final f = File(targetPath);
        if (f.existsSync()) return f;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final effectiveBucket = bucket is MediaBucket
          ? bucket
          : MediaBucket.custom(bucketId: bucket?.toString() ?? 'general');

      final fileN = p.basename(Uri.parse(effectiveUrl).path).replaceAll('%', '_');
      final savePath = targetPath ?? p.join(appDir.path, 'media_cache', effectiveBucket.bucketId, fileN);
      final destFile = File(savePath);

      if (destFile.existsSync()) return destFile;

      final resolved = await resolveUrl(effectiveUrl, effectiveBucket);
      if (resolved == null || !resolved.startsWith('http')) return null;

      final resp = await http.get(Uri.parse(resolved)).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        await destFile.parent.create(recursive: true);
        await destFile.writeAsBytes(resp.bodyBytes);
        return destFile;
      }
    } catch (e) {
      MediaLogger.warning('downloadFile failed for $effectiveUrl: $e');
    }
    return null;
  }

  /// Searches the local disk cache across registered buckets for a file
  Future<String?> findFileOnDisk(String urlOrPath, [dynamic bucket]) async {
    try {
      final f = File(urlOrPath);
      if (f.existsSync()) return f.path;

      final appDir = await getApplicationDocumentsDirectory();
      final bName = (bucket is MediaBucket) ? bucket.bucketId : (bucket?.toString() ?? '');
      final fileName = p.basename(urlOrPath);

      if (bName.isNotEmpty) {
        final cand = File(p.join(appDir.path, 'media_cache', bName, fileName));
        if (cand.existsSync()) return cand.path;
      }

      for (final b in MediaBucket.defaultBuckets) {
        final cand = File(p.join(appDir.path, 'media_cache', b.bucketId, fileName));
        if (cand.existsSync()) return cand.path;
      }
    } catch (_) {}
    return null;
  }

  /// Deletes a file from storage and purges cache
  Future<bool> deleteSingle({
    required String mediaUrl,
    dynamic bucket,
  }) async {
    try {
      final effectiveBucket = bucket is MediaBucket
          ? bucket
          : MediaBucket.custom(bucketId: bucket?.toString() ?? 'general');
      final path = _normalizeStoragePath(mediaUrl, effectiveBucket);

      _signedUrlCache.remove(path);

      if (storageBackend != null) {
        return await storageBackend!.delete(path, effectiveBucket);
      }

      final client = _supabase;
      if (client != null && _isOnline) {
        await client.storage.from(effectiveBucket.bucketId).remove([path]);
      }
      return true;
    } catch (e) {
      MediaLogger.warning('deleteSingle error: $e');
      return false;
    }
  }

  /// Evicts a specific key from the in-memory cache
  Future<void> purgeLocalCache(String storageKey) async {
    _signedUrlCache.remove(storageKey);
  }

  /// Clears in-memory URL cache and disk cache
  Future<void> clearAllCache() async {
    _signedUrlCache.clear();
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'media_cache'));
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Returns total disk cache size consumed by the package in Megabytes
  Future<double> getCacheSizeMB() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'media_cache'));
      if (!await cacheDir.exists()) return 0.0;
      int bytes = 0;
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) bytes += await file.length();
      }
      return bytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isLocalPath(String path) {
    if (path.startsWith('/') || path.startsWith('file://')) return true;
    if (path.length >= 3 && path[1] == ':' && (path[2] == '\\' || path[2] == '/')) return true;
    return false;
  }

  String _normalizeStoragePath(String path, MediaBucket bucket) {
    if (path.contains('/storage/v1/object/public/${bucket.bucketId}/')) {
      return path.split('/storage/v1/object/public/${bucket.bucketId}/').last.split('?').first;
    }
    if (path.contains('/storage/v1/object/sign/${bucket.bucketId}/')) {
      return path.split('/storage/v1/object/sign/${bucket.bucketId}/').last.split('?').first;
    }
    return path.split('?').first;
  }
}

final mediaService = UniversalMediaService();
