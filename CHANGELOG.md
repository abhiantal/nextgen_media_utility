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
