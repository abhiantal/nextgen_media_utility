# 10 — Universal Media Service & Cloud Storage ☁️

The `UniversalMediaService` is an enterprise-grade, offline-first media orchestration engine. It decouples file storage, local caching, URL resolution, and database synchronization, empowering developers to connect **any backend** (Supabase, AWS S3, Google Cloud, Firebase Storage, or custom REST APIs) with zero boilerplate.

---

## 🌟 Key Capabilities

* **100% Customizable Buckets (`MediaBucket`)**: Define unlimited custom storage buckets with file size limits, custom folder structures, public/private access, and allowed file extensions.
* **Pluggable Storage Backends (`StorageBackend`)**: Switch between Supabase, AWS S3, Firebase, MinIO, or custom REST endpoints by implementing a 3-method interface.
* **Pluggable Database Delegates (`MediaCacheDelegate`)**: Connect PowerSync, SQLite, Drift, or Hive to sync media records with local databases and track sync statuses.
* **Instant Zero-Lag UI Display (`primeLocalCache`)**: Prime in-memory memory caches with freshly captured or edited local file paths, preventing white-screen flicker while uploads occur in the background.
* **Intelligent Fast Hashing & Deduplication**: Prevents duplicate uploads using fast SHA-256 chunk hashing.
* **Automatic File Size & Extension Validation**: Enforces bucket-specific quotas (`validateFileSize`) and warns users automatically.
* **Unified URL & Signed URL Resolution**: Resolves remote cloud keys, public URLs, and signed URLs seamlessly with automatic cache TTL management.

---

## 🪣 1. Defining Media Buckets (`MediaBucket`)

`MediaBucket` gives developers complete freedom to define and isolate storage destinations according to their own backend schema, access controls, and file size limits.

### A. Defining Your Own Buckets

Third-party developers define their own custom buckets with their own limits, visibility, and allowed file types:

```dart
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

// Example 1: Private documents bucket with file type restrictions
const invoiceBucket = MediaBucket(
  bucketId: 'enterprise_invoices',
  folderPath: 'finance/invoices',
  maxSizeMB: 25,
  isPublic: false,
  displayName: 'Invoice Documents',
  allowedExtensions: ['pdf', 'xlsx', 'docx'],
);

// Example 2: Public media bucket using the MediaBucket.custom factory
final publicGalleryBucket = MediaBucket.custom(
  bucketId: 'public_gallery',
  maxSizeMB: 100,
  isPublic: true,
  displayName: 'Public Gallery',
  folderPath: 'gallery',
  allowedExtensions: ['jpg', 'png', 'webp', 'mp4'],
);

// Example 3: User avatars bucket
const avatarBucket = MediaBucket(
  bucketId: 'user_avatars',
  maxSizeMB: 10,
  isPublic: true,
  displayName: 'User Avatars',
  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
);
```

### B. Out-of-the-Box Fallback (`MediaBucket.general`)

For quick zero-config prototyping or apps that only need a single default bucket, a generic fallback is provided:

```dart
MediaBucket.general // bucketId: 'general', 50MB, private
```

### C. Validating Files Against Bucket Quotas

```dart
final file = File('/path/to/video.mp4');

// Validates whether the file respects the bucket's maxSizeMB.
// If it exceeds the limit, automatically displays a warning snackbar.
final isValid = UniversalMediaService.validateFileSize(file, invoiceBucket);

if (!isValid) {
  print('File exceeds allowed limit for this bucket!');
  return;
}
```

---

## 🚀 2. Uploading Media

### A. Single File Upload (`uploadSingle`)

```dart
import 'dart:io';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<String?> uploadProfilePhoto(File imageFile, String userId) async {
  final service = UniversalMediaService.instance;

  final publicOrSignedUrl = await service.uploadSingle(
    file: imageFile,
    bucket: avatarBucket,
    userId: userId,
    onProgress: (double progress) {
      print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
    },
  );

  print('Uploaded URL: $publicOrSignedUrl');
  return publicOrSignedUrl;
}
```

### B. High-Throughput Batch Uploads (`uploadMultiple`)

`uploadMultiple` handles parallel batch uploads with concurrency control and deduplication:

```dart
Future<List<String>> uploadGalleryBatch(List<File> files, String userId) async {
  final service = UniversalMediaService.instance;

  final urls = await service.uploadMultiple(
    files: files,
    bucket: MediaBucket.general,
    userId: userId,
    onProgress: (double overallProgress) {
      print('Batch progress: ${(overallProgress * 100).toStringAsFixed(0)}%');
    },
  );

  print('Successfully uploaded ${urls.length} files.');
  return urls;
}
```

---

## 🔌 3. Custom Storage Backend Pluggability (`StorageBackend`)

By default, `UniversalMediaService` connects to `Supabase.instance.client` if initialized. However, developers can plug in **AWS S3, Firebase Storage, Google Cloud Storage, or any custom API** simply by setting `UniversalMediaService.storageBackend`.

### Implementing a Custom Backend

```dart
import 'dart:typed_data';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class AwsS3StorageBackend implements StorageBackend {
  final String s3BucketName;
  final String region;

  AwsS3StorageBackend({required this.s3BucketName, required this.region});

  @override
  Future<String?> upload({
    required dynamic file,
    required String path,
    required MediaBucket bucket,
    String? mimeType,
    void Function(double)? onProgress,
  }) async {
    // 1. Read bytes from File, XFile, or Uint8List
    final Uint8List bytes = file is File ? await file.readAsBytes() : file as Uint8List;

    // 2. Perform upload to your S3 bucket / presigned URL
    // await myS3Client.putObject(bucket: s3BucketName, key: path, body: bytes);
    onProgress?.call(1.0);

    return 'https://$s3BucketName.s3.$region.amazonaws.com/$path';
  }

  @override
  Future<String?> resolveUrl(String path, MediaBucket bucket) async {
    // Return direct CDN or generate an S3 presigned URL
    return 'https://$s3BucketName.s3.$region.amazonaws.com/$path';
  }

  @override
  Future<bool> delete(String path, MediaBucket bucket) async {
    // await myS3Client.deleteObject(bucket: s3BucketName, key: path);
    return true;
  }
}
```

### Registering Your Backend

Set the static backend anywhere during app startup (e.g., in `main()`):

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Plug in your custom storage backend
  UniversalMediaService.storageBackend = AwsS3StorageBackend(
    s3BucketName: 'my-app-media',
    region: 'us-east-1',
  );

  runApp(const MyApp());
}
```

---

## 💾 4. Offline Database Delegate Pluggability (`MediaCacheDelegate`)

For offline-first apps that synchronize attachments through **PowerSync, SQLite, Drift, or Couchbase**, `UniversalMediaService` provides the `MediaCacheDelegate` interface.

### A. PowerSync Integration

If you use PowerSync, you can plug in your PowerSync database instance directly:

```dart
// Automatic dynamic adapter wrapping:
UniversalMediaService.powerSyncInstance = myPowerSyncDatabase;
```

### B. Custom SQLite / Drift / Hive Delegate

You can also provide a custom implementation of `MediaCacheDelegate`:

```dart
class MySqfliteCacheDelegate implements MediaCacheDelegate {
  final Database db;

  MySqfliteCacheDelegate(this.db);

  @override
  bool get isOnline => true; // Or wire to connectivity_plus

  @override
  bool get isInitialized => true;

  @override
  Future<List<Map<String, dynamic>>> executeQuery(String sql, {List<dynamic>? parameters}) async {
    return await db.rawQuery(sql, parameters);
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? parameters]) async {
    await db.rawExecute(sql, parameters);
  }

  @override
  Future<Map<String, dynamic>?> querySingle(String sql, {List<dynamic>? parameters}) async {
    final results = await db.rawQuery(sql, parameters);
    return results.isNotEmpty ? results.first : null;
  }
}

// Register during initialization:
UniversalMediaService.databaseDelegate = MySqfliteCacheDelegate(database);
```

---

## 🛣️ 5. Custom Path Formatting (`customPathBuilder`)

By default, files are stored following the pattern:
```
{userId}/{bucketId}/{hash_timestamp.ext}
```

You can customize this layout globally for your entire project:

```dart
UniversalMediaService.customPathBuilder = ({
  required String? userId,
  required MediaBucket bucket,
  required String uniqueName,
  String? customPath,
}) {
  final now = DateTime.now();
  final yearMonth = '${now.year}/${now.month.toString().padLeft(2, '0')}';

  // Custom path: tenant_id/2026/04/bucket/userId/filename
  return 'tenant_abc/$yearMonth/${bucket.bucketId}/$userId/$uniqueName';
};
```

---

## ⚡ 6. Zero-Lag Local Cache Priming (`primeLocalCache`)

When an end-user takes a picture or picks a photo from the gallery, uploading to the cloud takes seconds. Calling `primeLocalCache` stores the local file path in memory mapped to the upcoming remote storage key. 

When your UI immediately asks `resolveUrl`, the local file displays instantly with **zero delay**, while the cloud upload finishes silently in the background:

```dart
final localImageFile = File('/data/user/0/cache/photo_123.jpg');
final remoteStoragePath = 'users/42/avatars/photo_123.jpg';

// 1. Prime the cache immediately:
UniversalMediaService.instance.primeLocalCache(remoteStoragePath, localImageFile.path);

// 2. Any UI widget calling resolveUrl receives the local path instantly:
final displayUrl = await UniversalMediaService.instance.resolveUrl(remoteStoragePath);
// displayUrl == '/data/user/0/cache/photo_123.jpg' (instant display, no network latency!)

// 3. Initiate the background upload:
UniversalMediaService.instance.uploadSingle(
  file: localImageFile,
  bucket: avatarBucket,
  customPath: remoteStoragePath,
);
```

---

## 🧹 7. Cache Management & Invalidation

`UniversalMediaService` provides complete cache life-cycle controls:

```dart
final service = UniversalMediaService.instance;

// Purge cache for a specific key
await service.purgeLocalCache('users/42/avatars/photo_123.jpg');

// Clear all memory and temporary disk cache
await service.clearAllCache();

// Inspect local cache disk usage in Megabytes
final double sizeMB = await service.getCacheSizeMB();
print('Local media cache is currently consuming: ${sizeMB.toStringAsFixed(1)} MB');
```

---

## 📖 API Reference Table

| Member | Type | Description |
|---|---|---|
| `UniversalMediaService.instance` | Getter | Global singleton instance. |
| `UniversalMediaService.storageBackend` | Static property | Set custom `StorageBackend` (AWS S3, Firebase, etc.). |
| `UniversalMediaService.databaseDelegate` | Static property | Set custom `MediaCacheDelegate` for local offline sync. |
| `UniversalMediaService.powerSyncInstance` | Static setter | Pass PowerSync database instance directly. |
| `UniversalMediaService.customPathBuilder` | Static property | Override cloud storage path generation logic. |
| `UniversalMediaService.validateFileSize(file, bucket)` | Static method | Validates file size against bucket's `maxSizeMB`. |
| `uploadSingle({file, bucket, ...})` | Method | Uploads a single file and returns the accessible URL. |
| `uploadMultiple({files, bucket, ...})` | Method | High-performance parallel batch uploader. |
| `uploadAvatar(file, {userId})` | Method | Convenience method for avatar uploads. |
| `resolveUrl(pathOrUrl, [bucket])` | Method | Resolves paths/keys to local cache, CDN, or signed URLs. |
| `getValidAvatarUrl(path)` | Method | Resolves avatar paths with fallback handling. |
| `primeLocalCache(storagePath, localPath)` | Method | Pre-loads local file into memory for instant UI rendering. |
| `deleteSingle({path, bucket})` | Method | Removes file from cloud storage and local cache. |
| `clearAllCache()` | Method | Clears in-memory URL cache and disk cache. |
| `getCacheSizeMB()` | Method | Returns current disk cache consumption in MB. |
