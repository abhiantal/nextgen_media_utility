import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

// Custom StorageBackend for testing pluggability
class TestCustomStorageBackend implements StorageBackend {
  final Map<String, dynamic> uploadedFiles = {};
  final Map<String, String> resolvedUrls = {};

  @override
  Future<String?> upload({
    required dynamic file,
    required String path,
    required MediaBucket bucket,
    String? mimeType,
    void Function(double)? onProgress,
  }) async {
    uploadedFiles['${bucket.bucketId}/$path'] = file;
    onProgress?.call(1.0);
    return 'https://custom-cdn.example.com/${bucket.bucketId}/$path';
  }

  @override
  Future<String?> resolveUrl(String path, MediaBucket bucket) async {
    return resolvedUrls[path] ?? 'https://custom-cdn.example.com/${bucket.bucketId}/$path';
  }

  @override
  Future<bool> delete(String path, MediaBucket bucket) async {
    uploadedFiles.remove('${bucket.bucketId}/$path');
    return true;
  }
}

// Custom MediaCacheDelegate for testing offline DB delegate pluggability
class TestCustomCacheDelegate implements MediaCacheDelegate {
  final List<String> executedStatements = [];

  @override
  bool get isOnline => true;

  @override
  bool get isInitialized => true;

  @override
  Future<void> execute(String sql, [List<dynamic>? parameters]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, dynamic>>> executeQuery(String sql, {List<dynamic>? parameters}) async {
    executedStatements.add(sql);
    return [
      {'id': 'test_rec_1', 'remote_path': 'user/photo.jpg', 'local_path': '/local/photo.jpg'}
    ];
  }

  @override
  Future<Map<String, dynamic>?> querySingle(String sql, {List<dynamic>? parameters}) async {
    executedStatements.add(sql);
    return {'id': 'test_rec_1', 'remote_path': 'user/photo.jpg', 'local_path': '/local/photo.jpg'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaBucket — Universal & Customizable Architecture', () {
    test('Standard generic bucket is exposed with clean ID', () {
      expect(MediaBucket.general.bucketId, 'general');
      expect(MediaBucket.general.maxSizeMB, 50);
      expect(MediaBucket.general.isPublic, isFalse);
    });

    test('Third-party developers can define custom buckets with limits and allowed extensions', () {
      const customBucket = MediaBucket(
        bucketId: 'enterprise_invoices',
        folderPath: 'finance/invoices',
        maxSizeMB: 100,
        allowedExtensions: ['pdf', 'xlsx'],
        displayName: 'Invoices',
      );

      expect(customBucket.bucketId, 'enterprise_invoices');
      expect(customBucket.folderPath, 'finance/invoices');
      expect(customBucket.maxSizeMB, 100);
      expect(customBucket.allowedExtensions, contains('pdf'));
      expect(customBucket.displayName, 'Invoices');
    });

    test('MediaBucket.custom factory sets sensible defaults', () {
      final custom = MediaBucket.custom(bucketId: 'daily_logs', maxSizeMB: 20);
      expect(custom.bucketId, 'daily_logs');
      expect(custom.maxSizeMB, 20);
      expect(custom.allowedExtensions, isNull);
    });

    test('MediaBucket equality and hashCode are based strictly on bucketId', () {
      const b1 = MediaBucket(bucketId: 'assets', maxSizeMB: 10);
      const b2 = MediaBucket(bucketId: 'assets', maxSizeMB: 50);
      const b3 = MediaBucket(bucketId: 'documents');

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('MediaBucket toString contains bucketId and size limit', () {
      const b = MediaBucket(bucketId: 'reports', maxSizeMB: 15);
      expect(b.toString(), contains('reports'));
      expect(b.toString(), contains('15MB'));
    });
  });

  group('UniversalMediaService — Enterprise Storage & Custom Backend Pluggability', () {
    late UniversalMediaService service;
    late Directory tempDir;

    setUp(() {
      service = UniversalMediaService.instance;
      tempDir = Directory.systemTemp.createTempSync('ums_test_');
    });

    tearDown(() {
      UniversalMediaService.storageBackend = null;
      UniversalMediaService.databaseDelegate = null;
      UniversalMediaService.customPathBuilder = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Singleton identity holds across factory invocations', () {
      expect(identical(UniversalMediaService(), UniversalMediaService.instance), isTrue);
    });

    test('StorageBackend pluggability routes uploadSingle and resolveUrl to custom backend', () async {
      final customBackend = TestCustomStorageBackend();
      UniversalMediaService.storageBackend = customBackend;

      final testFile = File('${tempDir.path}/sample.jpg')..writeAsStringSync('dummy-image-bytes');
      const bucket = MediaBucket(bucketId: 'custom_storage_bucket');

      double progressValue = 0.0;
      final resultUrl = await service.uploadSingle(
        file: testFile,
        bucket: bucket,
        onProgress: (p) => progressValue = p,
      );

      expect(resultUrl, startsWith('https://custom-cdn.example.com/custom_storage_bucket/'));
      expect(progressValue, 1.0);
      expect(customBackend.uploadedFiles.isNotEmpty, isTrue);

      final resolved = await service.resolveUrl('custom_storage_bucket/sample.jpg', bucket);
      expect(resolved, contains('https://custom-cdn.example.com/'));
    });

    test('MediaCacheDelegate pluggability connects database queries', () async {
      final customDelegate = TestCustomCacheDelegate();
      UniversalMediaService.databaseDelegate = customDelegate;

      final result = await UniversalMediaService.databaseDelegate!.executeQuery('SELECT * FROM media');
      expect(result, isNotEmpty);
      expect(customDelegate.executedStatements, contains('SELECT * FROM media'));
    });

    test('getCanonicalStoragePath builds structured clean path', () {
      const bucket = MediaBucket(bucketId: 'profiles', folderPath: 'profile_images');
      final path = service.getCanonicalStoragePath(
        userId: 'user_42',
        bucket: bucket,
        uniqueName: 'avatar_99.png',
      );

      expect(path, 'user_42/profile_images/avatar_99.png');
    });

    test('customPathBuilder override enables developer-defined path formats', () {
      UniversalMediaService.customPathBuilder = ({
        required String? userId,
        required MediaBucket bucket,
        required String uniqueName,
        String? customPath,
      }) {
        return 'org_root/${bucket.bucketId}/$userId/$uniqueName';
      };

      const bucket = MediaBucket(bucketId: 'vault');
      final path = service.getCanonicalStoragePath(
        userId: 'admin_1',
        bucket: bucket,
        uniqueName: 'doc.pdf',
      );

      expect(path, 'org_root/vault/admin_1/doc.pdf');
    });

    test('validateFileSize accurately detects files within and exceeding size limits', () {
      const smallBucket = MediaBucket(bucketId: 'tight', maxSizeMB: 1); // 1 MB limit

      // Small file ~ 100 bytes
      final smallFile = File('${tempDir.path}/small.dat')..writeAsBytesSync(Uint8List(100));
      expect(UniversalMediaService.validateFileSize(smallFile, smallBucket, false), isTrue);

      // Oversized file ~ 2 MB
      final largeBytes = Uint8List(2 * 1024 * 1024);
      final largeFile = File('${tempDir.path}/large.dat')..writeAsBytesSync(largeBytes);
      expect(UniversalMediaService.validateFileSize(largeFile, smallBucket, false), isFalse);
    });

    test('Local memory cache priming and cache clearing', () async {
      service.primeLocalCache('remote/photo.png', '/device/cache/photo.png');

      final cachedUrl = await service.resolveUrl('remote/photo.png');
      expect(cachedUrl, '/device/cache/photo.png');

      await service.purgeLocalCache('remote/photo.png');
      await service.clearAllCache();
    });

    test('getValidAvatarUrl safely returns null for empty or null inputs', () async {
      final defaultAvatarNull = await service.getValidAvatarUrl(null);
      final defaultAvatarEmpty = await service.getValidAvatarUrl('');
      final customAvatar = await service.getValidAvatarUrl('https://example.com/avatar.png');

      expect(defaultAvatarNull, isNull);
      expect(defaultAvatarEmpty, isNull);
      expect(customAvatar, 'https://example.com/avatar.png');
    });
  });
}
