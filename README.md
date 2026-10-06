# NextGen Media Utility

[![pub package](https://img.shields.io/badge/pub.dev-nextgen__media__utility-blue.svg)](https://pub.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)

A modular, high-performance, all-in-one Flutter media powerhouse designed for modern mobile and cross-platform applications. `nextgen_media_utility` combines hardware-accelerated camera capture, multi-format gallery selection, interactive image & canvas editing, waveform audio recording/playback, and full-screen media galleries into an intuitive, zero-boilerplate API.

---

## ✨ Features

- 📸 **In-App Camera Suite (`CameraCaptureScreen`)**
  - Ultra-smooth photo capture & video recording with exposure and focus locking.
  - Multi-camera switching, torch/flash controls, and real-time recording timer animations.
  - Background compute-thread EXIF rotation correction and compression.

- 🖼️ **Multi-Format Gallery Picker (`GalleryPickerScreen` & `MediaPicker`)**
  - Album-aware media browser with custom buckets and file size caps.
  - Native multi-selection, live thumbnails, and instant previewing.
  - High-efficiency disk caching and storage path resolution.

- 🎨 **Creative Editor Suite (`MediaEditorSuiteScreen`)**
  - Interactive canvas drawing with multi-color brush strokes and variable thickness.
  - Preset artistic color filters (Vibrant, Sepia, Noir, Warm, Cold, Dramatic).
  - Crop & rotate tools, text overlays, and multi-asset collage composition.

- 🎙️ **Audio Recording & Playback (`EnhancedAudioRecorder` & `AnimatedAudioPlayer`)**
  - Pulse-animated audio recorder with live visualizer bars.
  - Interactive audio player supporting streaming URLs and local files.
  - Adaptive styling: chat bubble style or media card layout with seekable waveforms.

- 📱 **Adaptive Media Display Grid & Viewers (`MediaDisplay` & `FullScreenViewer`)**
  - Automatic detection for images, videos, audio notes, and documents.
  - Grid, carousel, and list layout modes with integrated Hero animations.
  - Fullscreen pinch-to-zoom viewer with video controls and one-click gallery saving (`Gal`).

---

## 🚀 Getting Started

### Installation

Add `nextgen_media_utility` to your `pubspec.yaml`:

```yaml
dependencies:
  nextgen_media_utility: ^0.0.1
```

Or run:

```bash
flutter pub add nextgen_media_utility
```

### Platform Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
</manifest>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to capture photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio messages and video sound.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires photo library access to pick and save media.</string>
```

---

## 📖 Quick Start & Usage

### 1. Launching In-App Camera

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> captureMedia(BuildContext context) async {
  final result = await Navigator.push<CameraCaptureResult?>(
    context,
    MaterialPageRoute(
      builder: (_) => const CameraCaptureScreen(
        allowVideo: true,
        maxVideoDurationSeconds: 60,
      ),
    ),
  );

  if (result != null && result.files.isNotEmpty) {
    print('Captured ${result.files.length} items');
  }
}
```

### 2. Picking Media with Size & Format Control

```dart
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> pickPhotos(BuildContext context) async {
  final mediaFiles = await Navigator.push<List<MediaAssetModel>?>(
    context,
    MaterialPageRoute(
      builder: (_) => const GalleryPickerScreen(
        allowMultiple: true,
        maxSelection: 10,
        bucket: MediaBucket.general,
      ),
    ),
  );

  if (mediaFiles != null) {
    print('Selected ${mediaFiles.length} files');
  }
}
```

### 3. Displaying Media in Your UI

```dart
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Widget buildMediaGrid(List<EnhancedMediaFile> mediaItems) {
  return MediaDisplay(
    mediaFiles: mediaItems,
    config: MediaDisplayConfig(
      layout: MediaDisplayLayout.grid,
      maxVisibleItems: 4,
      borderRadius: BorderRadius.circular(16),
      enableDownload: true,
      enableFullscreen: true,
    ),
  );
}
```

### 4. Interactive Audio Recording & Playback

```dart
// Audio Recording Sheet
void recordAudio(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EnhancedAudioRecorder(
      onRecordingCompleted: (file, duration) {
        print('Recorded file at: ${file.path} (${duration.inSeconds}s)');
      },
    ),
  );
}

// Audio Playback
Widget buildAudioMessage(String audioPathOrUrl) {
  return AnimatedAudioPlayer(
    url: audioPathOrUrl,
    style: AudioPlayerStyle.bubble,
    isMe: true,
    showWaveform: true,
  );
}
```

---

## 🛠️ Architecture

`nextgen_media_utility` is modularized into discrete, self-contained domain folders:

```
lib/
├── nextgen_media_utility.dart       # Main barrel export
└── src/
    ├── audio/                       # Audio recorder & waveform player
    ├── camera/                      # Camera engine & capture views
    ├── core/                        # Data models, theming, snackbars, loggers
    ├── display/                     # MediaDisplay widget, viewers & video player
    ├── editor/                      # Filters, drawing painter & collage tools
    ├── picker/                      # Gallery & multi-file pickers
    └── video/                       # Trimming & thumbnail utilities
```

---

## 🤝 Contributing

Contributions, bug reports, and pull requests are warmly welcomed! Please visit the [GitHub repository](https://github.com/abhiantal/nextgen_media_utility) to open issues or submit enhancements.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
