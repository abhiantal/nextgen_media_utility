# NextGen Media Utility — Complete Documentation 📚

Welcome to the official developer documentation for **`nextgen_media_utility`**.

`nextgen_media_utility` is an all-in-one Flutter media powerhouse designed for modern mobile and cross-platform apps. It consolidates camera capture, album gallery picking, custom media compression, image/video editing, audio voice note recording, and full-screen viewers into an intuitive, zero-boilerplate API.

---

## 📑 Documentation Index

| Guide | Description |
|---|---|
| [**01. All Features Overview**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/01_ALL_FEATURES.md) | Exhaustive list of all capabilities, classes, and supported formats. |
| [**02. Setup & Permissions**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/02_SETUP_AND_PERMISSIONS.md) | Platform configuration for Android (Manifest, Gradle) and iOS (Info.plist). |
| [**03. Camera & Capture**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/03_CAMERA_AND_CAPTURE.md) | In-app camera, multi-camera switching, flash/torch, and video capture. |
| [**04. Media Picker & Gallery**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/04_PICKER_AND_GALLERY.md) | Native gallery picker, multi-select, and WhatsApp-style album explorer. |
| [**05. Media Compression**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/05_MEDIA_COMPRESSION.md) | User-facing interactive compression modal (`MediaCompressionSheet`) & programmatic API. |
| [**06. Image Editor & Filters**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/06_EDITOR_AND_FILTERS.md) | Canvas drawing, crop/rotate, stickers, text overlays, and color filters. |
| [**07. Audio Recorder & Player**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/07_AUDIO_RECORDING_AND_PLAYER.md) | Pulse-animated voice recorder and interactive waveform audio player. |
| [**08. Media Display & Viewers**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/08_MEDIA_DISPLAY_AND_VIEWER.md) | Adaptive media grids (chat, social feeds), Hero transitions, and zoom viewer. |
| [**09. Real-World Project Examples**](file:///c:/StudioProjects/nextgen_media_utility/packeg_dox/09_REAL_WORLD_EXAMPLES.md) | Copy-paste recipes for Chat Attachments, Profile Avatars, Stories, and more. |

---

## ⚡ Quick 30-Second Example

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void openAttachmentPicker(BuildContext context) {
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

## 🏛️ Architecture Overview

The package is structured into clean modular layers:

```
nextgen_media_utility/
├── lib/
│   ├── nextgen_media_utility.dart  # Central export entrypoint
│   └── src/
│       ├── camera/                 # Hardware camera capture & video recording
│       ├── picker/                 # MediaPicker, GalleryPicker, Compression Sheet
│       ├── editor/                 # Color filters, drawing canvas, rotation fixes
│       ├── audio/                  # Audio recorder sheet & waveform player
│       ├── display/                # MediaDisplay, full-screen zoom, save to gallery
│       ├── video/                  # Video trimmer view
│       └── core/                   # Theming, snackbars, logging, loaders
```

Each module can be used independently or combined seamlessly.
