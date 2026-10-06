# 03 — In-App Camera & Video Capture 📸

The `CameraCaptureScreen` provides a high-performance in-app viewfinder with instant photo snapping, video recording, front/back lens switching, and flash control.

---

## 🚀 Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> openCamera(BuildContext context) async {
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
    if (result.isVideo) {
      print('Video captured: ${result.file.path}');
      print('Duration: ${result.duration?.inSeconds} seconds');
    } else {
      print('Photo captured: ${result.file.path}');
    }
  }
}
```

---

## ⚙️ Configuration Properties

| Parameter | Type | Default | Description |
|---|---|---|---|
| `allowVideo` | `bool` | `true` | Allows users to record video by long-pressing or tapping the record switch. |
| `maxVideoDurationSeconds` | `int` | `60` | Automatically stops recording when this threshold is reached. |
| `initialCameraLensDirection` | `CameraLensDirection` | `back` | Sets front or back camera on startup. |

---

## 📦 What is `CameraCaptureResult`?

When the user takes a photo or records a video and taps the checkmark to accept, `CameraCaptureScreen` returns a `CameraCaptureResult` object:

```dart
class CameraCaptureResult {
  final File file;             // The local photo or video file
  final bool isVideo;          // True if video, false if photo
  final Duration? duration;    // Duration of video (null for photos)
  final File? thumbnail;       // First-frame thumbnail preview (for videos)
}
```

---

## 🔄 Automatic Rotation Normalization

One of the most common Flutter bugs is captured photos appearing sideways or upside down when viewed on certain Android or iOS devices due to EXIF rotation tags.

`CameraCaptureScreen` includes automatic rotation normalization:
* Reads EXIF tags on a background thread.
* Re-encodes the image at native zero rotation.
* Ensures photos are oriented upright across all platforms and social media viewers.
