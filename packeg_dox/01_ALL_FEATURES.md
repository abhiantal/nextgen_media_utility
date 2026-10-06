# 01 — All Features Overview 🌟

`nextgen_media_utility` eliminates the need for 8+ fragmented media packages by uniting all essential media operations into one cohesive, production-tested toolkit.

---

## 📋 Comprehensive Feature Breakdown

### 1. In-App Camera Suite (`CameraCaptureScreen`)
* **Photo Capture**: Fast high-resolution photo shooting.
* **Video Recording**: Single-tap/long-press recording with real-time pulsing progress timer.
* **Camera Switching**: Smooth front-facing and rear-facing camera toggle.
* **Flash & Torch Control**: Off, Auto, On, and Torch modes.
* **Rotation Normalization**: Automatically runs background thread EXIF rotation correction to prevent landscape/portrait flipped images on Android/iOS.
* **Return Object**: Delivers `CameraCaptureResult` containing `file`, `isVideo`, `duration`, and `thumbnail`.

---

### 2. Gallery Picker & Media Browser (`GalleryPickerScreen` & `MediaPicker`)
* **WhatsApp / Telegram Style Picker**: Integrated bottom modal showing quick camera access, recent gallery thumbnails, and expandable full album browser.
* **Album Hierarchy**: Switch between albums (Camera, Screenshots, WhatsApp, Downloads, etc.) powered by `photo_manager`.
* **Multi-Select Mode**: Select multiple photos and videos simultaneously with numbered selection badges.
* **Maximum Limit Enforcement**: Enforce `maxItems` limits (e.g., max 5 photos) with animated snackbar feedback.
* **Direct File / Document Picker**: Pick PDFs, docs, spreadsheets, or any arbitrary file type with native platform picker.

---

### 3. Media Compression & Optimization (`EnhancedMediaCompressor` & `MediaCompressionSheet`)
* **Interactive Compression Sheet (`MediaCompressionSheet`)**:
  * Lets end-users decide how much compression they want before uploading.
  * **Presets**: Compact (35% quality / 720p), Balanced (65% quality / 1080p), High Detail (85% quality / 1920p), and Custom.
  * **Visual Slider**: Smoothly adjust quality from 15% to 95%.
  * **Live Size Estimation**: Shows the original size vs estimated or compressed size.
* **Programmatic Image Compression**:
  * Adjust `quality` (1–100), `minWidth`, `minHeight`, and output formats.
  * Automatically strips heavy EXIF metadata and fixes image rotation.
* **Programmatic Video Compression**:
  * Hardware-accelerated MP4 compression via `video_compress`.
  * Presets: `LowQuality`, `MediumQuality`, `DefaultQuality`.
  * Configurable size thresholds (auto-skip small files or `force: true` to compress).

---

### 4. Creative Photo Editor Suite (`MediaEditorSuiteScreen`)
* **Artistic Color Filters**:
  * 6 preset matrix filters: *Vibrant*, *Sepia*, *Noir / Black & White*, *Warm Glow*, *Cool Breeze*, and *Dramatic Contrast*.
* **Freeform Canvas Drawing**:
  * Interactive finger drawing canvas over images with adjustable stroke widths and colors.
  * Full Undo / Clear capabilities.
* **Crop & Rotate**:
  * Straighten, rotate 90°, 180°, 270°, and crop to custom aspect ratios.
* **Non-destructive Processing**:
  * Preserves original file while exporting high-quality edited JPG.

---

### 5. Audio Voice Recorder & Waveform Player (`EnhancedAudioRecorder` & `AnimatedAudioPlayer`)
* **Pulse Animated Audio Recorder**:
  * Modern bottom sheet recorder with live amplitude visualizer bars.
  * Live recording duration counter, pause, resume, and trash controls.
  * Outputs standardized `.m4a` / `.aac` audio files.
* **Waveform Audio Player**:
  * Plays both local audio files (`File`) and remote HTTP streaming URLs.
  * Animated scrubbing waveform with elapsed time and total duration.
  * Supports Chat Bubble layout mode or Media Card layout mode.

---

### 6. Media Display Grid & Fullscreen Zoom Viewer (`MediaDisplay`)
* **Automatic Media Type Detection**:
  * Automatically classifies `MediaAsset` into Image, Video, Audio, or Document.
* **Layout Modes**:
  * `MediaDisplayMode.grid`: Responsive 1, 2, 3, or 4+ image collage layout.
  * `MediaDisplayMode.carousel`: Horizontal swiping media cards.
  * `MediaDisplayMode.list`: Vertical stream with thumbnails and metadata.
* **Fullscreen Interactive Viewer**:
  * Pinch-to-zoom (up to 4x) with smooth Hero transitions.
  * Integrated video player with play/pause, seekbar, and mute.
  * Direct one-tap **Save to Device Gallery** using `gal`.

---

### 7. Video Trimmer (`VideoTrimmerView`)
* Interactive start/end time slider for clipping videos before sending.
* Real-time preview playback of the selected trimmed clip.

---

### 8. Core Utilities & Design System
* **`MediaTheme`**: Cohesive dark/light tokens with neon accents (`primaryNeon`, `glassmorphism`, `cardSurface`).
* **`MediaLogger`**: Colored debug logs (`logI`, `logW`, `logE`, `logD`) that automatically disable in production release builds.
* **`MediaSnackbar`**: Floating snackbars for warnings, errors, and success notifications.
* **`MediaLoadingIndicator`**: Sleek loading overlays with customizable messages and progress bars.
