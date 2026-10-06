# 04 — Media Picker & Album Gallery 🖼️

The package provides both a complete WhatsApp/Telegram-style bottom sheet picker (`MediaPicker.showPickerOptions`) and a standalone multi-album media browser (`GalleryPickerScreen`).

---

## 1. Quick Attachment Sheet (`MediaPicker.showPickerOptions`)

This displays a modal sheet with icons for Camera, Gallery, Video, Audio, and Documents:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void openAttachmentMenu(BuildContext context) {
  MediaPicker.showPickerOptions(
    context,
    onMediaPicked: (List<File> files) {
      print('Picked ${files.length} items');
      for (final file in files) {
        print('Path: ${file.path}');
      }
    },
    allowMultiple: true, // Allow user to pick more than 1 item
    maxFiles: 5,        // Limit to 5 selections
  );
}
```

---

## 2. Advanced Multi-Album Gallery Picker (`GalleryPickerScreen`)

If you want an Instagram or WhatsApp-style full screen gallery picker where users can switch between device albums (Screenshots, Camera, Downloads, etc.) and multi-select photos/videos with numbered check circles:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> openFullGallery(BuildContext context) async {
  final List<File>? selectedFiles = await Navigator.push<List<File>?>(
    context,
    MaterialPageRoute(
      builder: (_) => const GalleryPickerScreen(
        allowMultiple: true,
        maxSelectable: 10,
        type: RequestType.common, // RequestType.image, RequestType.video, or common
      ),
    ),
  );

  if (selectedFiles != null && selectedFiles.isNotEmpty) {
    print('User selected ${selectedFiles.length} files from gallery');
  }
}
```

---

## 3. Picking Documents & Custom Files

To allow users to pick PDF files, spreadsheets, or documents:

```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> pickDocumentFiles() async {
  final List<File>? docs = await MediaPicker.pickDocumentFiles(
    allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'txt'],
    allowMultiple: true,
  );

  if (docs != null) {
    for (final doc in docs) {
      print('Selected document: ${doc.path}');
    }
  }
}
```

---

## 4. Single-Action Helper Methods

| Method | Description |
|---|---|
| `MediaPicker.pickSingleImage(source)` | Quickly picks an image from `ImageSource.camera` or `ImageSource.gallery`. |
| `MediaPicker.pickSingleVideo(source)` | Quickly picks a video from `ImageSource.camera` or `ImageSource.gallery`. |
| `MediaPicker.pickMultipleImages()` | Opens system gallery multi-image picker. |
