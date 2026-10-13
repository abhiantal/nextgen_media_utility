// ============================================================
// FILE: lib/media_utility/image_rotation_fixer.dart
// Centralized Image Rotation Fix Utility - UPDATED
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/media_logger.dart';

class ImageRotationFixer {
  ImageRotationFixer._();

  static Future<File> fixRotation(
    File file, {
    bool deleteOriginal = false,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fixedBytes = await fixRotationFromBytes(bytes);

      if (fixedBytes == null) {
        return file;
      }

      final tempDir = await getTemporaryDirectory();
      final extension = path.extension(file.path).toLowerCase();
      final outputPath = path.join(
        tempDir.path,
        'fixed_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      final fixedFile = File(outputPath);
      await fixedFile.writeAsBytes(fixedBytes);

      if (deleteOriginal) {
        try {
          await file.delete();
        } catch (e) {
          logW('Could not delete original file: $e');
        }
      }

      return fixedFile;
    } catch (e) {
      logE('Error fixing rotation: $e');
      return file;
    }
  }

  static Future<Uint8List?> fixRotationFromBytes(Uint8List bytes) async {
    try {
      final image = await compute(_decodeImage, bytes);
      if (image == null) return null;

      final originalWidth = image.width;
      final originalHeight = image.height;

      final fixedImage = await compute(_fixOrientation, image);

      final dimensionsChanged =
          fixedImage.width != originalWidth ||
          fixedImage.height != originalHeight;

      if (!dimensionsChanged) {
        return null;
      }

      final extension = _detectImageFormat(bytes);
      if (extension == 'png') {
        return await compute(_encodePng, fixedImage);
      } else {
        return await compute(_encodeJpg, fixedImage);
      }
    } catch (e) {
      logE('Error processing image bytes: $e');
      return null;
    }
  }

  static Future<bool> needsRotationFix(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await compute(_decodeImage, bytes);
      if (image == null) return false;

      final originalWidth = image.width;
      final originalHeight = image.height;

      final fixedImage = img.bakeOrientation(image);

      return fixedImage.width != originalWidth ||
          fixedImage.height != originalHeight;
    } catch (e) {
      return false;
    }
  }

  static Future<File> fixCameraImage(
    File file, {
    required bool isFrontCamera,
    bool deleteOriginal = false,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await compute(_decodeImage, bytes);
      if (image == null) return file;

      img.Image fixedImage = await compute(_fixOrientation, image);

      if (isFrontCamera) {
        fixedImage = img.flipHorizontal(fixedImage);
      }

      final outputBytes = await compute(_encodeJpg, fixedImage);

      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final fixedFile = File(outputPath);
      await fixedFile.writeAsBytes(outputBytes);

      if (deleteOriginal) {
        try {
          await file.delete();
        } catch (e) {
          logW('Could not delete original: $e');
        }
      }

      return fixedFile;
    } catch (e) {
      logE('Error fixing camera image: $e');
      return file;
    }
  }

  static Future<List<File>> fixMultipleFiles(
    List<File> files, {
    bool deleteOriginals = false,
    void Function(int current, int total)? onProgress,
  }) async {
    final fixedFiles = <File>[];

    for (int i = 0; i < files.length; i++) {
      try {
        final fixed = await fixRotation(
          files[i],
          deleteOriginal: deleteOriginals,
        );
        fixedFiles.add(fixed);
        onProgress?.call(i + 1, files.length);
      } catch (e) {
        logE('Error fixing file ${i + 1}: $e');
        fixedFiles.add(files[i]);
      }
    }

    return fixedFiles;
  }

  static img.Image? _decodeImage(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      return null;
    }
  }

  static img.Image _fixOrientation(img.Image image) {
    return img.bakeOrientation(image);
  }

  static Uint8List _encodePng(img.Image image) {
    return img.encodePng(image);
  }

  static Uint8List _encodeJpg(img.Image image) {
    return img.encodeJpg(image, quality: 92);
  }

  static String _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 8) return 'jpg';
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'jpg';
  }

  static double getRotationAngle(int orientation) {
    switch (orientation) {
      case 1:
        return 0;
      case 3:
        return 180;
      case 6:
        return 90;
      case 8:
        return 270;
      default:
        return 0;
    }
  }

  static bool needsHorizontalFlip(int orientation) {
    return orientation == 2 ||
        orientation == 4 ||
        orientation == 5 ||
        orientation == 7;
  }
}

extension FileRotationExtension on File {
  Future<File> fixRotation({bool deleteOriginal = false}) {
    return ImageRotationFixer.fixRotation(this, deleteOriginal: deleteOriginal);
  }

  Future<bool> needsRotationFix() {
    return ImageRotationFixer.needsRotationFix(this);
  }
}
