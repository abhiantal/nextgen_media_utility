import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────
  // EnhancedMediaFile — type detection & factory helpers
  // ──────────────────────────────────────────────────────────────
  group('EnhancedMediaFile — Type Detection', () {
    test('identifies image extensions correctly', () {
      for (final ext in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic']) {
        expect(
          EnhancedMediaFile.detectMediaType('https://cdn.example.com/asset.$ext'),
          equals(MediaFileType.image),
          reason: '.$ext should be image',
        );
      }
    });

    test('identifies video extensions correctly', () {
      for (final ext in ['mp4', 'mov', 'avi', 'mkv', 'webm']) {
        expect(
          EnhancedMediaFile.detectMediaType('https://cdn.example.com/clip.$ext'),
          equals(MediaFileType.video),
          reason: '.$ext should be video',
        );
      }
    });

    test('identifies audio extensions correctly', () {
      for (final ext in ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a']) {
        expect(
          EnhancedMediaFile.detectMediaType('https://cdn.example.com/sound.$ext'),
          equals(MediaFileType.audio),
          reason: '.$ext should be audio',
        );
      }
    });

    test('identifies document extensions correctly', () {
      for (final ext in ['pdf', 'doc', 'docx']) {
        expect(
          EnhancedMediaFile.detectMediaType('https://cdn.example.com/file.$ext'),
          equals(MediaFileType.document),
          reason: '.$ext should be document',
        );
      }
    });

    test('falls back to image for unknown extensions', () {
      expect(
        EnhancedMediaFile.detectMediaType('https://cdn.example.com/unknown'),
        equals(MediaFileType.image),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────
  // EnhancedMediaFile — factory constructors
  // ──────────────────────────────────────────────────────────────
  group('EnhancedMediaFile — Factory Constructors', () {
    test('fromUrl extracts correct properties', () {
      final file = EnhancedMediaFile.fromUrl(
        id: 'item_1',
        url: 'https://cdn.example.com/media/sample_landscape.jpg',
      );
      expect(file.id, equals('item_1'));
      expect(file.fileName, equals('sample_landscape.jpg'));
      expect(file.type, equals(MediaFileType.image));
      expect(file.isLocal, isFalse);
    });

    test('local audio file is flagged correctly', () {
      final file = EnhancedMediaFile(
        id: 'local_1',
        url: '/data/user/0/com.app/files/audio_note.aac',
        type: MediaFileType.audio,
        fileName: 'audio_note.aac',
        isLocal: true,
      );
      expect(file.isLocal, isTrue);
      expect(file.supportsFullScreen, isTrue);
    });

    test('document does not support full screen', () {
      final file = EnhancedMediaFile(
        id: 'doc_1',
        url: 'https://cdn.example.com/file.pdf',
        type: MediaFileType.document,
        isLocal: false,
      );
      expect(file.supportsFullScreen, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // convertUrlsToEnhancedMedia helper
  // ──────────────────────────────────────────────────────────────
  group('convertUrlsToEnhancedMedia', () {
    test('converts list of URLs preserving order', () {
      final urls = [
        'https://cdn.example.com/a.jpg',
        'https://cdn.example.com/b.mp4',
        'https://cdn.example.com/c.mp3',
      ];
      final result = convertUrlsToEnhancedMedia(urls);
      expect(result.length, equals(3));
      expect(result[0].type, equals(MediaFileType.image));
      expect(result[1].type, equals(MediaFileType.video));
      expect(result[2].type, equals(MediaFileType.audio));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // MediaAssetModel — creation & copyWith
  // ──────────────────────────────────────────────────────────────
  group('MediaAssetModel', () {
    test('creates model with correct defaults', () {
      final model = MediaAssetModel(
        id: 'asset_99',
        file: File('test_image.png'),
        type: MediaType.image,
      );
      expect(model.id, equals('asset_99'));
      expect(model.type, equals(MediaType.image));
      expect(model.brightness, equals(0.0));
      expect(model.hasEdits, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final original = MediaAssetModel(
        id: 'asset_1',
        file: File('original.png'),
        type: MediaType.image,
      );
      final copy = original.copyWith(brightness: 0.5, contrast: 0.2);
      expect(copy.id, equals('asset_1'));
      expect(copy.brightness, equals(0.5));
      expect(copy.contrast, equals(0.2));
      expect(copy.saturation, equals(0.0)); // unchanged
    });

    test('hasEdits returns true when brightness is non-zero', () {
      final model = MediaAssetModel(
        id: 'a',
        file: File('x.png'),
        type: MediaType.image,
      )..brightness = 0.3;
      expect(model.hasEdits, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // ColorFilters — preset validation
  // ──────────────────────────────────────────────────────────────
  group('ColorFilters — Preset Validation', () {
    test('getAllFilters returns non-empty list starting with Original', () {
      final filters = ColorFilters.getAllFilters();
      expect(filters, isNotEmpty);
      expect(filters.first['name'], equals('Original'));
      expect(filters.first['filter'], isNull);
      expect(filters.first['matrix'], isNull);
    });

    test('all preset matrices have exactly 20 elements', () {
      final filters = ColorFilters.getAllFilters();
      for (int i = 1; i < filters.length; i++) {
        final matrix = filters[i]['matrix'] as List<double>?;
        expect(matrix, isNotNull, reason: 'Filter ${filters[i]['name']} has no matrix');
        expect(matrix!.length, equals(20),
            reason: 'Filter ${filters[i]['name']} matrix must be 5×4=20');
      }
    });

    test('adjustment helpers return 20-element matrices', () {
      expect(ColorFilters.brightnessAdjust(0.5).length, equals(20));
      expect(ColorFilters.contrastAdjust(0.3).length, equals(20));
      expect(ColorFilters.saturationAdjust(-0.2).length, equals(20));
    });
  });

  // ──────────────────────────────────────────────────────────────
  // MediaTheme — ThemeData generation
  // ──────────────────────────────────────────────────────────────
  group('MediaTheme', () {
    test('lightTheme has correct brightness and primary color', () {
      final theme = MediaTheme.lightTheme();
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(MediaTheme.lightPrimary));
    });

    test('darkTheme has correct brightness and primary color', () {
      final theme = MediaTheme.darkTheme();
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(MediaTheme.darkPrimary));
    });

    test('both themes use Material3', () {
      expect(MediaTheme.lightTheme().useMaterial3, isTrue);
      expect(MediaTheme.darkTheme().useMaterial3, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // MediaLogger — no exceptions on all log levels
  // ──────────────────────────────────────────────────────────────
  group('MediaLogger', () {
    test('all log levels run without throwing', () {
      expect(() => MediaLogger.info('info message'), returnsNormally);
      expect(() => MediaLogger.warning('warning message'), returnsNormally);
      expect(() => MediaLogger.error('error message'), returnsNormally);
      expect(() => MediaLogger.error('with error', Exception('test')), returnsNormally);
    });

    test('log suppression works when enableLogs is false', () {
      MediaLogger.enableLogs = false;
      expect(() => MediaLogger.info('suppressed'), returnsNormally);
      MediaLogger.enableLogs = true; // restore
    });
  });

  // ──────────────────────────────────────────────────────────────
  // AppSnackbar static API — no exceptions when no UI context
  // ──────────────────────────────────────────────────────────────
  group('AppSnackbar — Static API', () {
    test('show, success, warning, error run without UI context', () {
      expect(() => AppSnackbar.show('Test notice'), returnsNormally);
      expect(() => AppSnackbar.success('Great job!'), returnsNormally);
      expect(() => AppSnackbar.warning('Watch out!'), returnsNormally);
      expect(() => AppSnackbar.error('Something failed'), returnsNormally);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // DrawingOverlayController — state management
  // ──────────────────────────────────────────────────────────────
  group('DrawingOverlayController', () {
    test('starts empty and canUndo is false', () {
      final ctrl = DrawingOverlayController();
      expect(ctrl.isEmpty, isTrue);
      expect(ctrl.canUndo, isFalse);
    });

    test('endStroke adds to strokes list', () {
      final ctrl = DrawingOverlayController();
      ctrl.startStroke(const Offset(0, 0));
      ctrl.addPoint(const Offset(10, 10));
      ctrl.endStroke();
      expect(ctrl.strokes.length, equals(1));
      expect(ctrl.canUndo, isTrue);
    });

    test('undo removes last stroke', () {
      final ctrl = DrawingOverlayController();
      ctrl.startStroke(const Offset(0, 0));
      ctrl.addPoint(const Offset(5, 5));
      ctrl.endStroke();
      ctrl.undo();
      expect(ctrl.strokes.isEmpty, isTrue);
    });

    test('clear removes all strokes', () {
      final ctrl = DrawingOverlayController();
      ctrl.startStroke(const Offset(0, 0));
      ctrl.addPoint(const Offset(5, 5));
      ctrl.endStroke();
      ctrl.clear();
      expect(ctrl.isEmpty, isTrue);
    });

    test('setColor updates current color', () {
      final ctrl = DrawingOverlayController();
      ctrl.setColor(Colors.blue);
      expect(ctrl.currentColor, equals(Colors.blue));
    });
  });
}
