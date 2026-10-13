# 06 — Image Editor Suite & Color Filters 🎨

The `MediaEditorSuiteScreen` gives your app a built-in photo studio with freeform finger drawing, rotation, crop tools, and artistic color filters.

---

## 🚀 Launching the Editor

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> openPhotoEditor(BuildContext context, File originalImage) async {
  final File? editedImage = await Navigator.push<File?>(
    context,
    MaterialPageRoute(
      builder: (_) => MediaEditorSuiteScreen(
        imageFile: originalImage,
      ),
    ),
  );

  if (editedImage != null) {
    print('Edited image saved at: ${editedImage.path}');
  }
}
```

---

## 🖌️ Editor Features

### 1. Artistic Color Filters
Applies hardware-accelerated 5x4 matrix transformations:
* **Vibrant**: Enhances saturation and contrast.
* **Sepia**: Classic vintage warm photo look.
* **Noir**: High-contrast black and white.
* **Warm**: Golden hour warm tones.
* **Cold**: Crisp winter blue tones.
* **Dramatic**: Deep shadows and rich color highlights.

### 2. Freehand Canvas Drawing
* Users can sketch annotations, arrows, or draw freely directly on top of the image.
* **Brush Size**: Adjustable stroke width slider.
* **Color Palette**: Preset primary colors (Neon Green, Red, Blue, White, Yellow, Purple).
* **Undo / Redo / Clear**: Step-by-step history to revert accidental marks.

### 3. Crop & Rotation
* **90° Steps**: Rotates the image seamlessly in 90-degree increments.
* **Crop Rect**: Freeform or fixed-ratio cropping before exporting.

---

## 💾 Saving & Exporting
When the user taps **Save / Done**, the editor rasterizes the canvas and applied matrix filters into a clean, uncompressed JPEG image and returns the new `File` object.
