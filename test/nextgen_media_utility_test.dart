import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnhancedMediaFile Type Detection', () {
    test('correctly identifies image URLs', () {
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/photo.jpg'),
        equals(MediaFileType.image),
      );
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/avatar.png'),
        equals(MediaFileType.image),
      );
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/banner.webp'),
        equals(MediaFileType.image),
      );
    });

    test('correctly identifies video URLs', () {
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/clip.mp4'),
        equals(MediaFileType.video),
      );
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/movie.mov'),
        equals(MediaFileType.video),
      );
    });

    test('correctly identifies audio URLs', () {
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/voice.mp3'),
        equals(MediaFileType.audio),
      );
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/sound.m4a'),
        equals(MediaFileType.audio),
      );
    });

    test('correctly identifies document URLs', () {
      expect(
        EnhancedMediaFile.detectMediaType('https://example.com/doc.pdf'),
        equals(MediaFileType.document),
      );
    });
  });

  group('EnhancedMediaFile Instance Helpers', () {
    test('extracts filename from URL properly', () {
      final file = EnhancedMediaFile.fromUrl(
        id: 'item_1',
        url: 'https://example.com/media/sample_landscape.jpg',
      );
      expect(file.id, equals('item_1'));
      expect(file.fileName, equals('sample_landscape.jpg'));
      expect(file.type, equals(MediaFileType.image));
      expect(file.isLocal, isFalse);
    });

    test('identifies local file paths correctly', () {
      final file = EnhancedMediaFile(
        id: 'local_1',
        url: '/data/user/0/com.app/files/audio_note.aac',
        type: MediaFileType.audio,
        fileName: 'audio_note.aac',
        isLocal: true,
      );
      expect(file.isLocal, isTrue);
      expect(file.fileName, equals('audio_note.aac'));
    });
  });

  group('MediaAssetModel Verification', () {
    test('creates and converts model properties', () {
      final dummyFile = File('test_image.png');
      final model = MediaAssetModel(
        id: 'asset_99',
        file: dummyFile,
        type: MediaType.image,
      );
      expect(model.id, equals('asset_99'));
      expect(model.type, equals(MediaType.image));

      final updated = model.copyWith(brightness: 0.5, contrast: 0.2);
      expect(updated.brightness, equals(0.5));
      expect(updated.contrast, equals(0.2));
      expect(updated.id, equals('asset_99'));
    });
  });

  group('MediaBucket Configuration', () {
    test('verifies default bucket size limits and names', () {
      expect(MediaBucket.userAvatars.maxSizeMB, equals(15));
      expect(MediaBucket.userAvatars.displayName, equals('Avatars'));

      expect(MediaBucket.bucketMedia.maxSizeMB, equals(50));
      expect(MediaBucket.general.maxSizeMB, equals(50));
    });
  });

  group('ColorFilters Presets', () {
    test('presets list contains valid matrices', () {
      final filters = ColorFilters.getAllFilters();
      expect(filters, isNotEmpty);
      expect(filters.first['name'], equals('Original'));
      for (int i = 1; i < filters.length; i++) {
        final filter = filters[i];
        expect(filter['name'], isNotEmpty);
        final matrix = filter['matrix'] as List<double>?;
        expect(matrix, isNotNull);
        expect(matrix!.length, equals(20));
      }
    });
  });

  group('MediaTheme Generator', () {
    test('creates valid ThemeData for light and dark modes', () {
      final light = MediaTheme.lightTheme();
      final dark = MediaTheme.darkTheme();

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));
      expect(light.primaryColor, isNotNull);
      expect(dark.primaryColor, isNotNull);
    });
  });

  group('UniversalMediaService', () {
    test('singleton instance resolves URLs correctly', () async {
      final service1 = UniversalMediaService();
      final service2 = UniversalMediaService();
      expect(identical(service1, service2), isTrue);

      const testUrl = 'https://cloud.storage.com/asset.jpg';
      final resolved = await service1.resolveUrl(testUrl);
      expect(resolved, equals(testUrl));

      final signed = await service1.getValidSignedUrl(testUrl);
      expect(signed, equals(testUrl));
    });
  });

  group('AppSnackbar & MediaLogger Diagnostics', () {
    test('logs diagnostic messages without exceptions', () {
      expect(() => MediaLogger.info('Diagnostic info test'), returnsNormally);
      expect(() => MediaLogger.warning('Diagnostic warning test'), returnsNormally);
      expect(() => MediaLogger.error('Diagnostic error test'), returnsNormally);
      expect(() => AppSnackbar.show('Silent test notice'), returnsNormally);
      expect(() => AppSnackbar.success('Success notice'), returnsNormally);
      expect(() => AppSnackbar.warning('Warning notice'), returnsNormally);
      expect(() => AppSnackbar.error('Error notice'), returnsNormally);
    });
  });
}
