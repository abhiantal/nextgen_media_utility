# 05 — Media Compression & Optimization 🗜️

Large photo and video uploads waste bandwidth, slow down servers, and cause app crashes. `nextgen_media_utility` provides two powerful compression options:
1. **Interactive UI Sheet (`MediaCompressionSheet`)** — Lets end-users choose their compression level visually.
2. **Programmatic Compressor (`EnhancedMediaCompressor`)** — Automated background compression in code.

---

## 1. User-Facing Modal: `MediaCompressionSheet`

Open the interactive bottom sheet for any photo or video:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> letUserCompressMedia(BuildContext context, File originalFile, bool isVideo) async {
  final File? compressedFile = await MediaCompressionSheet.show(
    context,
    file: originalFile,
    isVideo: isVideo,
  );

  if (compressedFile != null) {
    final originalSize = (await originalFile.length() / (1024 * 1024)).toStringAsFixed(2);
    final newSize = (await compressedFile.length() / (1024 * 1024)).toStringAsFixed(2);
    print('Reduced file from ${originalSize}MB to ${newSize}MB!');
  }
}
```

### Features inside the sheet:
* **One-Tap Presets**:
  * `Compact (Low Data)`: 35% quality, 720p max dimension (fastest upload, minimal bandwidth).
  * `Balanced (Recommended)`: 65% quality, 1080p max dimension (optimal quality-to-size balance).
  * `High Detail`: 85% quality, 1920p max dimension (preserves fine detail).
  * `Custom`: Allows manual adjustment of both slider and dimensions.
* **Continuous Slider**: Quality adjustment from 15% to 95%.
* **Live Size Estimation**: Shows the original file size vs estimated/compressed file size in real-time.
* **One-Tap Confirm**: Returns the compressed `File` ready to send or upload.

---

## 2. Programmatic API: `EnhancedMediaCompressor`

### A. Image Compression
```dart
import 'dart:io';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<File?> compressImageExample(File inputImage) async {
  final File? compressed = await EnhancedMediaCompressor.compressImage(
    inputImage,
    quality: 75,        // Quality from 1 to 100 (default: 50)
    minWidth: 1080,     // Max bounding width
    minHeight: 1080,    // Max bounding height
    fixRotation: true,  // Fixes phone rotation orientation natively
  );

  return compressed;
}
```

### B. Video Compression
```dart
import 'dart:io';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';
import 'package:video_compress/video_compress.dart';

Future<File?> compressVideoExample(File inputVideo) async {
  final File? compressed = await EnhancedMediaCompressor.compressVideo(
    inputVideo,
    quality: VideoQuality.MediumQuality, // LowQuality, MediumQuality, DefaultQuality
    force: true, // Forces compression even if the video is already under 35MB
  );

  return compressed;
}
```

### C. Helper Checks
```dart
// Check if a file is already compressed or requires compression
final bool needsCompression = await EnhancedMediaCompressor.shouldCompress(
  file,
  MediaType.image,
);
```
