# NextGen Media Utility

[![pub package](https://img.shields.io/pub/v/nextgen_media_utility.svg)](https://pub.dev/packages/nextgen_media_utility)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.10.0-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)](https://pub.dev/packages/nextgen_media_utility)

**The ultimate all-in-one Flutter media powerhouse.**  
`nextgen_media_utility` unites 8+ fragmented media libraries into a single production-tested, modular package. It provides hardware-accelerated camera capture, multi-album gallery picking, photo studio editing with 25+ filters & freehand canvas drawing, waveform audio recording & playback, adaptive media display collages with pinch-zoom viewers, video trimming, visual compression sliders, and an enterprise offline-first cloud storage engine — all with a clean, zero-boilerplate API.

---

## 📑 Table of Contents

- [✨ Features at a Glance](#-features-at-a-glance)
- [📦 Installation & Platform Setup](#-installation--platform-setup)
- [🚀 Quick Start: 30-Second Example](#-quick-start-30-second-example)
- [🛠️ Deep-Dive Feature Guides](#️-deep-dive-feature-guides)
  - [1. In-App Camera Suite](#1-in-app-camera-suite-cameracapturescreen)
  - [2. WhatsApp-Style Attachment Picker](#2-whatsapp-style-attachment-sheet-mediapickershowpickeroptions)
  - [3. Multi-Album Gallery Browser](#3-multi-album-gallery-browser-gallerypickerscreen)
  - [4. Photo Studio & Color Filters](#4-photo-studio--creative-editor-mediaeditorsuitescreen)
  - [5. Audio Recorder & Waveform Player](#5-audio-recorder--waveform-player)
  - [6. Adaptive Media Display & Zoom Viewer](#6-adaptive-media-display--fullscreen-zoom-viewer)
  - [7. Interactive Video Trimmer](#7-interactive-video-trimmer-videotrimmerview)
  - [8. Visual Media Compression Sheet](#8-visual-media-compression-sheet-mediacompressionsheet)
  - [9. Offline-First Cloud Storage Engine](#9-offline-first-cloud-storage-engine-universalmediaservice)
  - [10. Design System & Global Overlays](#10-material-3-design-system--global-overlays)
- [📚 Full Documentation Index](#-full-documentation-index)
- [🤝 Contributing & License](#-contributing--license)

---

## ✨ Features at a Glance

| Module | Core Classes | Highlights |
|---|---|---|
| 📸 **Camera** | `CameraCaptureScreen` | Photo snapping, video recording, front/back switch, flash modes, EXIF auto-rotation fix. |
| 🖼️ **Gallery** | `GalleryPickerScreen` | Multi-album dropdown (Camera, Screenshots, etc.), multi-select count badges, quota caps. |
| 📎 **Picker Sheet** | `MediaPicker.showPickerOptions` | Bottom sheet with Camera, Gallery, Audio, and Native Document picker buttons. |
| 🎨 **Photo Studio** | `MediaEditorSuiteScreen` | 6 matrix color presets (Vibrant, Noir, Sepia, etc.), freehand finger drawing, crop & rotate. |
| 🎙️ **Audio** | `EnhancedAudioRecorder` | Pulse-animated waveform recorder sheet, amplitude visualizer, duration timer, pause/resume. |
| 🔊 **Player** | `AnimatedAudioPlayer` | WhatsApp-style waveform scrubbing player, supports local files and remote streaming URLs. |
| 📱 **Media Grid** | `MediaDisplay` | Auto-arranging collage grids (1, 2, 3, 4+ items), pinch-to-zoom (up to 4x), Hero animations. |
| ✂️ **Video Trim** | `VideoTrimmerView` | Dual-handle range-slider with real-time synchronized video preview. |
| 🗜️ **Compression** | `MediaCompressionSheet` | User-facing visual quality slider with live file size estimation (Compact, Balanced, Custom). |
| ☁️ **Cloud Storage** | `UniversalMediaService` | Pluggable backends (S3, Firebase, Supabase), custom `MediaBucket`s, offline DB sync, zero-lag cache. |
| 🎨 **Theming** | `MediaTheme` | Ready-to-use Material 3 light/dark themes with neon accents and cohesive design tokens. |

---

## 📦 Installation & Platform Setup

### 1. Add Dependency

In your `pubspec.yaml`:

```yaml
dependencies:
  nextgen_media_utility: ^0.2.0
```

Enable Material Icons bundling:
```yaml
flutter:
  uses-material-design: true
```

### 2. Android Setup (`android/app/src/main/AndroidManifest.xml`)

Add the following permissions inside `<manifest>`:

```xml
<!-- Internet Access for Cloud Storage & Streaming -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Camera & Microphone -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Gallery (Android 12 and below) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" tools:replace="android:maxSdkVersion" />

<!-- Gallery (Android 13+ / API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

### 3. iOS Setup (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access so you can take photos and record videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record voice notes and video audio.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access so you can select and save media.</string>
```

### 4. Enable Global Snackbars & Overlays

Wrap your `MaterialApp` builder once:

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Demo',
      theme: MediaTheme.lightTheme(),
      darkTheme: MediaTheme.darkTheme(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          AppSnackbar(key: snackbarService.snackbarKey),
        ],
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## 🚀 Quick Start: 30-Second Example

Open a complete WhatsApp-style attachment sheet with one function call:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void openAttachmentMenu(BuildContext context) {
  MediaPicker.showPickerOptions(
    context,
    onMediaPicked: (List<File> files) {
      for (final file in files) {
        print('Ready to use: ${file.path}');
      }
    },
    allowMultiple: true,
  );
}
```

---

## 🛠️ Deep-Dive Feature Guides

### 1. In-App Camera Suite (`CameraCaptureScreen`)

Launches a high-performance viewfinder with instant photo snapping, video recording, multi-camera switching, flash modes, and automatic EXIF rotation normalization:

```dart
final CameraCaptureResult? result = await Navigator.push<CameraCaptureResult?>(
  context,
  MaterialPageRoute(
    builder: (_) => const CameraCaptureScreen(
      allowVideo: true,
      maxVideoDurationSeconds: 60,
    ),
  ),
);

if (result != null) {
  for (final file in result.files) {
    print('Captured file: ${file.path}');
  }
}
```

---

### 2. WhatsApp-Style Attachment Sheet (`MediaPicker.showPickerOptions`)

Displays an animated bottom sheet with one-tap icons for Camera, Gallery, Video, Audio, and Documents:

```dart
MediaPicker.showPickerOptions(
  context,
  allowMultiple: true,
  onMediaPicked: (List<File> pickedFiles) {
    print('Picked ${pickedFiles.length} items');
  },
);
```

---

### 3. Multi-Album Gallery Browser (`GalleryPickerScreen`)

Browse device photos and videos organized by album folders (Camera, Screenshots, WhatsApp, Downloads) with multi-select count badges:

```dart
final List<MediaAssetModel>? selected = await Navigator.push<List<MediaAssetModel>?>(
  context,
  MaterialPageRoute(
    builder: (_) => const GalleryPickerScreen(
      allowMultiple: true,
      maxSelection: 10,
    ),
  ),
);
```

---

### 4. Photo Studio & Creative Editor (`MediaEditorSuiteScreen`)

Empowers users to annotate images with freehand finger drawing, apply artistic color matrix filters, rotate, and crop:

```dart
final File? editedImage = await Navigator.push<File?>(
  context,
  MaterialPageRoute(
    builder: (_) => MediaEditorSuiteScreen(
      imageFile: File('/path/to/original.jpg'),
    ),
  ),
);
```

---

### 5. Audio Recorder & Waveform Player

#### Record Voice Notes:
```dart
final File? voiceNote = await EnhancedAudioRecorder.show(
  context,
  maxDurationSeconds: 120, // 2 minutes max
);
```

#### Play Audio with Waveform:
```dart
AnimatedAudioPlayer(
  url: 'https://example.com/audio/voice_message.m4a',
  isLocal: false,
  style: AudioPlayerStyle.bubble, // or AudioPlayerStyle.card
  showWaveform: true,
  accentColor: Colors.deepPurpleAccent,
)
```

---

### 6. Adaptive Media Display & Fullscreen Zoom Viewer

Automatically lays out media into responsive grids (1, 2, 3, or 4+ collages) with built-in pinch-to-zoom (up to 4x) and video playback:

```dart
// Convert a list of URL strings or Files effortlessly:
final mediaFiles = convertUrlsToEnhancedMedia([
  'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
  'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
]);

EnhancedMediaDisplay(
  mediaFiles: mediaFiles,
  config: MediaDisplayConfig(
    layoutMode: MediaLayoutMode.grid,
    allowFullScreen: true,
    showFileName: true,
  ),
)
```

---

### 7. Interactive Video Trimmer (`VideoTrimmerView`)

Lets users clip long videos with an interactive start/end slider before sending:

```dart
VideoTrimmerView(
  videoFile: File('/path/to/video.mp4'),
  maxDurationSeconds: 30,
  onTrimCompleted: (File trimmedVideo) {
    print('Trimmed video: ${trimmedVideo.path}');
  },
)
```

---

### 8. Visual Media Compression Sheet (`MediaCompressionSheet`)

Lets end-users visually compare compression quality and file sizes before uploading:

```dart
final File? compressedFile = await MediaCompressionSheet.show(
  context,
  file: File('/path/to/large_photo.jpg'),
  isVideo: false,
);
```

Or compress in the background without UI:
```dart
final File compressed = await EnhancedMediaCompressor.compress(
  originalFile,
  quality: 70,
  minWidth: 1280,
);
```

---

### 9. Offline-First Cloud Storage Engine (`UniversalMediaService`)

`UniversalMediaService` provides an enterprise-grade cloud media orchestration engine that connects to **any backend** (AWS S3, Firebase, Google Cloud, Supabase, or custom REST APIs) with zero boilerplate.

#### A. Define Your Own Custom Buckets (`MediaBucket`):
```dart
// 100% customizable bucket definition:
const invoiceBucket = MediaBucket(
  bucketId: 'enterprise_invoices',
  folderPath: 'finance/invoices',
  maxSizeMB: 25,
  isPublic: false,
  displayName: 'Invoice Documents',
  allowedExtensions: ['pdf', 'xlsx', 'docx'],
);

// Fallback general preset:
MediaBucket.general // 50MB limit, private
```

#### B. Validate File Quotas Automatically:
```dart
// Automatically checks file size against bucket limits and shows a warning snackbar if exceeded:
final isValid = UniversalMediaService.validateFileSize(file, invoiceBucket);
```

#### C. Upload with Live Progress:
```dart
final publicOrSignedUrl = await UniversalMediaService.instance.uploadSingle(
  file: myFile,
  bucket: invoiceBucket,
  userId: 'user_123',
  onProgress: (progress) => print('Progress: ${(progress * 100).toInt()}%'),
);
```

#### D. Pluggable Storage Backend (`StorageBackend`):
Connect AWS S3, Firebase, or your own custom API by implementing 3 methods:
```dart
class MyS3Backend implements StorageBackend {
  @override
  Future<String?> upload({required dynamic file, required String path, required MediaBucket bucket, ...}) async {
    // upload to AWS S3...
    return 'https://s3.amazonaws.com/my-bucket/$path';
  }

  @override
  Future<String?> resolveUrl(String path, MediaBucket bucket) async => 'https://.../$path';

  @override
  Future<bool> delete(String path, MediaBucket bucket) async => true;
}

// Register during app startup:
UniversalMediaService.storageBackend = MyS3Backend();
```

#### E. Zero-Lag Optimistic UI Rendering (`primeLocalCache`):
Prime in-memory caches before uploading so widgets render instantly without waiting for network latency:
```dart
// 1. Prime cache immediately:
UniversalMediaService.instance.primeLocalCache(cloudPath, localFile.path);

// 2. UI widgets resolve instantly to local file with zero delay:
final url = await UniversalMediaService.instance.resolveUrl(cloudPath);

// 3. Cloud upload runs in the background silently:
UniversalMediaService.instance.uploadSingle(file: localFile, bucket: myBucket, customPath: cloudPath);
```

---

### 10. Material 3 Design System & Global Overlays

```dart
// Floating modern snackbars:
AppSnackbar.success('Media saved to gallery!');
AppSnackbar.warning('File size exceeds 25MB limit');
AppSnackbar.error('Upload failed, retrying in background...');

// Fullscreen loading overlay:
MediaLoadingIndicator.show(context, message: 'Compressing video...');
MediaLoadingIndicator.hide();
```

---

## 📚 Full Documentation Index

Comprehensive chapter-by-chapter guides are available in the repository's `packeg_dox` folder:

| Guide | Description |
|---|---|
| [**01. All Features Overview**](packeg_dox/01_ALL_FEATURES.md) | Exhaustive breakdown of all classes, parameters, and return types. |
| [**02. Setup & Permissions**](packeg_dox/02_SETUP_AND_PERMISSIONS.md) | Complete Android Manifest and iOS Info.plist configurations. |
| [**03. Camera & Capture**](packeg_dox/03_CAMERA_AND_CAPTURE.md) | In-app viewfinder, multi-camera switching, flash, and video recording. |
| [**04. Media Picker & Gallery**](packeg_dox/04_PICKER_AND_GALLERY.md) | Multi-select gallery browser, album navigation, and document picking. |
| [**05. Media Compression**](packeg_dox/05_MEDIA_COMPRESSION.md) | Visual compression bottom sheet and programmatic background compressor. |
| [**06. Image Editor & Filters**](packeg_dox/06_EDITOR_AND_FILTERS.md) | Color filter matrices, canvas drawing, undo/redo, and crop/rotate. |
| [**07. Audio Recorder & Player**](packeg_dox/07_AUDIO_RECORDING_AND_PLAYER.md) | Voice message bottom sheet recorder and animated waveform player. |
| [**08. Media Display & Viewers**](packeg_dox/08_MEDIA_DISPLAY_AND_VIEWER.md) | Dynamic photo/video collage grids, Hero transitions, and zoom viewer. |
| [**09. Real-World Project Examples**](packeg_dox/09_REAL_WORLD_EXAMPLES.md) | Copy-paste recipes for Chat Attachments, Profile Avatars, Stories, and Feeds. |
| [**10. Universal Cloud Storage**](packeg_dox/10_UNIVERSAL_MEDIA_SERVICE_AND_STORAGE.md) | Enterprise offline storage, custom buckets, S3/Firebase integration, and sync. |

---

## 🤝 Contributing & License

Contributions, bug reports, and pull requests are warmly welcomed!  
Visit the [GitHub Repository](https://github.com/abhiantal/nextgen_media_utility) to open an issue or contribute.

Released under the **[MIT License](LICENSE)**.
