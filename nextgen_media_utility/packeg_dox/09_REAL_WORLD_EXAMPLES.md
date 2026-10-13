# 09 — Real-World Project Examples 💡

Here are complete, copy-pasteable recipes for integrating `nextgen_media_utility` into common application workflows.

---

## 📱 Recipe 1: Profile Avatar Picker with Editor & Compression

Flow: User taps their avatar -> Picks image -> Edits/Crops it -> Compresses it -> Gets ready-to-upload avatar `File`.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<File?> pickAndPrepareAvatar(BuildContext context) async {
  // 1. Pick image from gallery or camera
  final ImagePicker picker = ImagePicker();
  final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
  if (picked == null) return null;

  File imageFile = File(picked.path);

  // 2. Open built-in Editor Suite for cropping and filters
  final File? edited = await Navigator.push<File?>(
    context,
    MaterialPageRoute(
      builder: (_) => MediaEditorSuiteScreen(imageFile: imageFile),
    ),
  );
  if (edited != null) imageFile = edited;

  // 3. Compress for high-speed network upload (e.g. 500x500 max, 80% quality)
  final File? optimizedAvatar = await EnhancedMediaCompressor.compressImage(
    imageFile,
    quality: 80,
    minWidth: 500,
    minHeight: 500,
  );

  return optimizedAvatar ?? imageFile;
}
```

---

## 💬 Recipe 2: Chat Input Bar Attachment Sheet

Flow: User taps attachment paperclip -> Chooses Camera, Gallery, Audio, or Custom Compression.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class ChatAttachmentBar extends StatelessWidget {
  final Function(List<File> files) onFilesReady;

  const ChatAttachmentBar({super.key, required this.onFilesReady});

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          spacing: 24,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildAction(ctx, Icons.camera_alt, 'Camera', () async {
              Navigator.pop(ctx);
              final res = await Navigator.push<CameraCaptureResult?>(
                context,
                MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
              );
              if (res != null) onFilesReady([res.file]);
            }),
            _buildAction(ctx, Icons.photo_library, 'Gallery', () async {
              Navigator.pop(ctx);
              final files = await Navigator.push<List<File>?>(
                context,
                MaterialPageRoute(builder: (_) => const GalleryPickerScreen(allowMultiple: true)),
              );
              if (files != null && files.isNotEmpty) onFilesReady(files);
            }),
            _buildAction(ctx, Icons.mic, 'Voice Note', () async {
              Navigator.pop(ctx);
              final audio = await EnhancedAudioRecorder.show(context);
              if (audio != null) onFilesReady([audio]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF00E676).withOpacity(0.15),
            child: Icon(icon, color: const Color(0xFF00E676), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file, color: Colors.white70),
      onPressed: () => _showMenu(context),
    );
  }
}
```

---

## 🗜️ Recipe 3: Media Upload with User-Chosen Compression

Flow: User selects a 50MB video or 10MB photo -> App presents `MediaCompressionSheet` -> User picks quality slider or Compact/Balanced/High preset -> Uploads compressed output.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> sendMediaWithUserCompression(
  BuildContext context,
  File rawFile,
  bool isVideo,
) async {
  // Let user decide how small to make their file
  final File? compressed = await MediaCompressionSheet.show(
    context,
    file: rawFile,
    isVideo: isVideo,
  );

  if (compressed != null) {
    // Proceed to upload compressed file
    uploadToServer(compressed);
  }
}

void uploadToServer(File file) {
  print('Uploading ${file.path} (${file.lengthSync()} bytes) to cloud storage...');
}
```

---

## 🖼️ Recipe 4: Social Feed Post with Dynamic Media Collage

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class SocialPostCard extends StatelessWidget {
  final String authorName;
  final String postText;
  final List<MediaAsset> attachedMedia;

  const SocialPostCard({
    super.key,
    required this.authorName,
    required this.postText,
    required this.attachedMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161922),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(postText, style: const TextStyle(color: Colors.white70)),
            if (attachedMedia.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Beautiful responsive grid that opens fullscreen zoom viewer on tap
              MediaDisplay(
                assets: attachedMedia,
                mode: MediaDisplayMode.grid,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```
---

## ☁️ Recipe 5: Enterprise Media Upload with Custom Bucket & Progress

Flow: User selects media -> Compresses with `EnhancedMediaCompressor` -> Validates file size -> Uploads via `UniversalMediaService.uploadSingle` with live progress callback.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

// 1. Define your custom domain bucket
const reportBucket = MediaBucket(
  bucketId: 'field_reports',
  folderPath: 'reports/media',
  maxSizeMB: 30,
  isPublic: false,
  displayName: 'Field Reports',
  allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'pdf'],
);

Future<String?> uploadFieldReportMedia({
  required BuildContext context,
  required File originalFile,
  required String userId,
  required Function(double) onProgress,
}) async {
  // 2. Validate file size against bucket rules
  final isValid = UniversalMediaService.validateFileSize(originalFile, reportBucket);
  if (!isValid) return null;

  // 3. Compress image/video before uploading to conserve bandwidth
  final compressed = await EnhancedMediaCompressor.compress(
    originalFile,
    quality: 75,
    minWidth: 1280,
  );

  // 4. Upload via UniversalMediaService
  final publicOrSignedUrl = await UniversalMediaService.instance.uploadSingle(
    file: compressed,
    bucket: reportBucket,
    userId: userId,
    onProgress: onProgress,
  );

  return publicOrSignedUrl;
}
```

---

## 🔌 Recipe 6: Connecting a Custom Cloud Storage Backend (AWS S3 / Firebase)

Flow: Plug in your own cloud storage provider (e.g. AWS S3, Google Cloud, Firebase Storage) by implementing `StorageBackend`.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class CustomCloudStorageBackend implements StorageBackend {
  final String apiBaseUrl;

  CustomCloudStorageBackend({required this.apiBaseUrl});

  @override
  Future<String?> upload({
    required dynamic file,
    required String path,
    required MediaBucket bucket,
    String? mimeType,
    void Function(double)? onProgress,
  }) async {
    final Uint8List bytes = file is File ? await file.readAsBytes() : file as Uint8List;

    // Call your custom REST API, AWS S3 SDK, or Firebase Storage SDK here:
    // final response = await myHttpUpload(url: '$apiBaseUrl/upload', bytes: bytes);
    onProgress?.call(1.0);

    return '$apiBaseUrl/storage/${bucket.bucketId}/$path';
  }

  @override
  Future<String?> resolveUrl(String path, MediaBucket bucket) async {
    return '$apiBaseUrl/storage/${bucket.bucketId}/$path';
  }

  @override
  Future<bool> delete(String path, MediaBucket bucket) async {
    // await myHttpDelete('$apiBaseUrl/storage/${bucket.bucketId}/$path');
    return true;
  }
}

// Register during app startup:
void configureMediaBackend() {
  UniversalMediaService.storageBackend = CustomCloudStorageBackend(
    apiBaseUrl: 'https://api.mycompany.com',
  );
}
```

---

## ⚡ Recipe 7: Instant Zero-Lag UI Rendering with Cache Priming

Flow: When an end-user captures a photo or picks an image, don't make them wait for the cloud upload to finish before viewing it. Prime the local cache with `primeLocalCache` for immediate rendering.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> sendChatPhotoOptimistic({
  required File localPhoto,
  required String currentUserId,
}) async {
  final service = UniversalMediaService.instance;
  
  // 1. Generate the canonical cloud storage path
  final cloudPath = service.getCanonicalStoragePath(
    userId: currentUserId,
    bucket: const MediaBucket(bucketId: 'chat_media', maxSizeMB: 50),
    uniqueName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
  );

  // 2. Prime the cache immediately with the local file path
  // Any UI widget resolving `cloudPath` will display `localPhoto.path` instantly!
  service.primeLocalCache(cloudPath, localPhoto.path);

  // 3. Initiate the background cloud upload asynchronously
  service.uploadSingle(
    file: localPhoto,
    bucket: const MediaBucket(bucketId: 'chat_media', maxSizeMB: 50),
    customPath: cloudPath,
  ).then((uploadedUrl) {
    print('Background cloud upload completed: $uploadedUrl');
  }).catchError((error) {
    print('Upload failed, will retry: $error');
  });
}
```
