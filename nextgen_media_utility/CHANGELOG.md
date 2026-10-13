## 0.2.0

* **UniversalMediaService**: Added enterprise-grade, offline-first media orchestration engine with upload queueing, deduplication, and in-memory TTL caching.
* **100% Customizable MediaBucket**: Developers can define custom cloud buckets with arbitrary bucket IDs, size limits (`maxSizeMB`), subfolders (`folderPath`), and extension constraints (`allowedExtensions`).
* **Pluggable StorageBackend**: Added pluggable storage interface allowing any developer to seamlessly connect AWS S3, Google Cloud, Firebase Storage, Supabase, or custom REST APIs.
* **Pluggable MediaCacheDelegate**: Added offline database delegate interface with dynamic PowerSync, SQLite, Drift, or Hive support.
* **Zero-Lag UI Cache Priming**: Added `primeLocalCache` and unified `resolveUrl` to eliminate UI white-screen flicker while background uploads process.
* **High-Throughput Parallel Batch Uploads**: Added `uploadMultiple` with progress tracking and SHA-256 deduplication.
* **Comprehensive Test Suite**: Added 39 unit tests covering storage backends, delegates, quota validation, and path formatting with 100% pass rate.
* **Documentation**: Added comprehensive chapter 10 and real-world recipes in `packeg_dox`.

## 0.1.0

* **Breaking change**: `MediaTheme` now exposes a complete Material 3 `ThemeData` for both
  light and dark modes, including `AppBar`, `Card`, `ElevatedButton`, `TextButton`,
  `OutlinedButton`, `InputDecoration`, `Chip`, `Slider`, `BottomSheet`, and `Divider` themes.
  All package screens and widgets now share the same consistent design tokens.

* Added `MediaTheme.cardDecoration()` helper for consistent card styling across custom widgets.

* Added radius constants: `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl`, `radius2xl`.

* Added shared brand-colour constants: `accentGreen`, `accentAmber`, `accentRed`, `accentBlue`.

* Improved `pubspec.yaml`: bumped to `0.1.0`, improved description for pub.dev scoring,
  added `topics` (media, camera, image-picker, audio, video).

* Fixed stale file-path comments in source files (`lib/media_utility/` → correct paths).

* Rewrote `test/nextgen_media_utility_test.dart`: removed references to non-existent
  APIs; added full coverage for `DrawingOverlayController`, `EnhancedMediaFile` factories,
  `convertUrlsToEnhancedMedia`, `MediaTheme`, `MediaLogger`, and `AppSnackbar`.

## 0.0.1

* Initial release of `nextgen_media_utility`.
* Added `CameraCaptureScreen` with high-fps preview, photo/video capture, flash controls, and multi-camera support.
* Added `GalleryPickerScreen` with album grouping, multi-asset selection, and custom size validation buckets.
* Added `MediaEditorSuiteScreen` featuring freehand canvas drawing, rotation correction, and preset color filters.
* Added `EnhancedAudioRecorder` and `AnimatedAudioPlayer` with live waveform visualization.
* Added `MediaDisplay` adaptive widget supporting grid, carousel, and list presentations with integrated fullscreen viewer.
* Added `MediaCompressionSheet` with quality presets and live size preview.
* Added `VideoTrimmerView` for in-app video trimming with range-slider UI.
