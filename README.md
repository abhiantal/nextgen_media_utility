# NextGen Media Utility

[![pub package](https://img.shields.io/pub/v/nextgen_media_utility.svg)](https://pub.dev/packages/nextgen_media_utility)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)

A modular, high-performance, all-in-one Flutter media powerhouse for modern mobile apps.  
`nextgen_media_utility` bundles hardware-accelerated camera capture, multi-format gallery selection, interactive image & canvas editing, waveform audio recording/playback, and a full-screen adaptive media gallery — all behind a clean, zero-boilerplate API.

---

## ✨ Features

| Module | Widget / API | Highlights |
|--------|-------------|------------|
| 📸 **Camera** | `CameraCaptureScreen` | Photo & video, flash, multi-camera, EXIF fix |
| 🖼️ **Gallery Picker** | `GalleryPickerScreen` | Album browser, multi-select, size caps |
| 📎 **Attachment Sheet** | `EnhancedMediaPicker` | WhatsApp-style picker (camera, gallery, audio, docs) |
| 🎨 **Photo Studio** | `MediaEditorScreen` | 25+ filters, freehand drawing, crop & rotate |
| 🔊 **Audio** | `EnhancedAudioRecorder` / `AnimatedAudioPlayer` | Live waveform, bubble & card styles |
| 📱 **Media Display** | `EnhancedMediaDisplay` | Grid, carousel, list — Hero fullscreen viewer |
| ✂️ **Video Trimmer** | `VideoTrimmerView` | Range-slider trim with live preview |
| 🗜️ **Compressor** | `MediaCompressionSheet` | Quality presets, size preview |

---

## 🚀 Getting Started

### 1. Add the dependency

```yaml
dependencies:
  nextgen_media_utility: ^0.1.0
```

Or run:

```bash
flutter pub add nextgen_media_utility
```

### 2. Platform Permissions

#### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

#### iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Required for in-app photo and video capture.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Required for audio recording.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to pick and save media.</string>
```

### 3. Register the Snackbar overlay

Wrap your `MaterialApp` builder to enable the global in-app notifications:

```dart
MaterialApp(
  builder: (context, child) => Stack(
    children: [
      if (child != null) child,
      AppSnackbar(key: snackbarService.snackbarKey),
    ],
  ),
)
```

---

## 📖 Usage Examples

### In-App Camera

```dart
final result = await Navigator.push<CameraCaptureResult?>(
  context,
  MaterialPageRoute(
    builder: (_) => const CameraCaptureScreen(allowVideo: true),
  ),
);

if (result != null && result.files.isNotEmpty) {
  // result.files → List<XFile>
  // result.filter → applied ColorFilter (nullable)
}
```

### Gallery Picker (multi-select)

```dart
final assets = await Navigator.push<List<MediaAssetModel>?>(
  context,
  MaterialPageRoute(
    builder: (_) => const GalleryPickerScreen(
      allowMultiple: true,
      maxSelection: 10,
    ),
  ),
);
```

### Photo Studio (editor)

```dart
final edited = await Navigator.push<List<MediaAssetModel>?>(
  context,
  MaterialPageRoute(
    builder: (_) => MediaEditorScreen(mediaAssets: [myAsset]),
  ),
);
```

### Waveform Audio Recorder

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) => EnhancedAudioRecorder(
    onCompleted: (XFile xfile) { /* handle */ },
    onCanceled: () => Navigator.pop(context),
  ),
);
```

### Animated Audio Player

```dart
AnimatedAudioPlayer(
  url: '/path/to/audio.m4a',
  isLocal: true,
  style: AudioPlayerStyle.card,
  accentColor: Colors.indigo,
  showWaveform: true,
)
```

### Adaptive Media Display

```dart
EnhancedMediaDisplay(
  mediaFiles: [
    EnhancedMediaFile.fromUrl(id: '1', url: 'https://…/photo.jpg'),
    EnhancedMediaFile.fromFile(file: File('/path/video.mp4')),
  ],
  config: MediaDisplayConfig(
    layoutMode: MediaLayoutMode.grid,
    allowFullScreen: true,
    allowDelete: true,
    showFileName: true,
  ),
  onDelete: (id) { /* remove item */ },
)
```

### Media Compressor

```dart
final compressed = await MediaCompressionSheet.show(
  context,
  file: File('/path/to/image.jpg'),
  isVideo: false,
);
```

### Global Snackbar Notifications

```dart
AppSnackbar.success('Saved!');
AppSnackbar.error('Upload failed', description: 'Check your connection.');
AppSnackbar.info(title: 'Tip', message: 'Swipe down to dismiss.');
AppSnackbar.loading(title: 'Processing…');
AppSnackbar.hideLoading();
```

---

## 🏗️ Architecture

```
lib/
├── nextgen_media_utility.dart   # Main barrel export
└── src/
    ├── core/                    # Models, theme, snackbar, logger, layout
    ├── camera/                  # CameraCaptureScreen
    ├── editor/                  # Filters, drawing, editor suite
    ├── picker/                  # Gallery picker, attachment sheet, compressor
    ├── audio/                   # Recorder & waveform player
    ├── display/                 # EnhancedMediaDisplay & fullscreen viewers
    └── video/                   # VideoTrimmerView
```

---

## 🤝 Contributing

Issues and pull requests are welcome! Visit the [GitHub repository](https://github.com/abhiantal/nextgen_media_utility).

## 📄 License

MIT — see [LICENSE](LICENSE).
