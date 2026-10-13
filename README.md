# 🚀 NextGen Flutter Packages Monorepo

Welcome to the official monorepo for production-grade Flutter packages published by [Abhi Kumar](https://github.com/abhiantal). This repository hosts high-performance, developer-first Flutter packages engineered for speed, extreme customizability, and state-of-the-art UI/UX.

---

## 📦 Packages in this Repository

| Package | Version | Description | Quick Links |
| :--- | :---: | :--- | :--- |
| **`nextgen_media_utility`** | `0.3.0` | Comprehensive media powerhouse: camera capture, multi-picker, smart cropper, image/video compression, audio waveform player, full-screen viewer, and offline-first pluggable storage engine with customizable `MediaBucket`. | [Documentation](nextgen_media_utility/README.md) • [10 Feature Guides](nextgen_media_utility/packeg_dox/) • [Example App](nextgen_media_utility/example/) |
| **`nextgen_ui_kit`** | `0.1.0` | Futuristic, high-performance Flutter UI component library: neon indicators, cyber particle orbits, circular & arc meters, executive KPI cards, smart form inputs, floating toasts, cloud sync banners, and structured logger. | [Documentation](nextgen_ui_kit/README.md) • [10 Component Guides](nextgen_ui_kit/packeg_dox/) • [Example App](nextgen_ui_kit/example/) |

---

## 🧭 Monorepo Structure

```
flutter_packages_pub.dev/
│
├── nextgen_media_utility/                  # Complete media capture, edit & storage suite
│   ├── lib/                               # Source code
│   │   ├── src/audio/                     # Animated waveform audio player & recorder
│   │   ├── src/camera/                    # In-app camera capture screen
│   │   ├── src/core/                      # UniversalMediaService, MediaBucket, storage engine
│   │   ├── src/editor/                    # Filters, rotation fixer, drawing canvas
│   │   ├── src/picker/                    # Gallery picker & compression sheets
│   │   └── src/video/                     # Video trimmer & player
│   ├── packeg_dox/                        # 10 comprehensive architectural guides
│   ├── example/                           # Interactive sample application
│   ├── test/                              # 39 passing unit and widget tests
│   ├── README.md                          # Package guide with copy-paste recipes
│   └── pubspec.yaml                       # v0.3.0
│
├── nextgen_ui_kit/                         # Futuristic UI, KPI & Feedback library
│   ├── lib/                               # Source code
│   │   ├── src/indicators/                # Futuristic loading, bar & circular progress meters
│   │   ├── src/indicators/metric_indicators.dart # Executive KPI cards, badges & live beacons
│   │   ├── src/inputs/                    # CustomTextField with email, password, search presets
│   │   ├── src/feedback/                  # AppSnackbar, SnackbarHost & GlobalSyncStatusBanner
│   │   └── src/logging/                   # AppLogger structured logging
│   ├── packeg_dox/                        # 10 component & usage guides
│   ├── example/                           # 4-tab interactive showcase with theme toggle
│   ├── test/                              # 15 passing unit and widget tests
│   ├── README.md                          # Full component catalog & recipes
│   └── pubspec.yaml                       # v0.1.0
│
└── README.md                              # Monorepo portal (you are here)
```

---

## ⚡ Quick Start: 30-Second Recipes

### 1. `nextgen_media_utility` (v0.3.0)

Add to `pubspec.yaml`:
```yaml
dependencies:
  nextgen_media_utility: ^0.3.0
```

#### Pick, Edit, and Compress:
```dart
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

// Single image with instant cropping
final result = await MediaPicker.pickSingleImage(
  context,
  enableCrop: true,
  maxDimension: 1920,
);

// Multiple image selection
final images = await MediaPicker.pickMultiImage(
  context,
  maxImages: 10,
);
```

#### Universal Pluggable Storage & Uploads:
```dart
// Define your custom bucket (no app-specific limits)
final profileBucket = MediaBucket.custom(
  bucketId: 'user-profiles',
  maxBytes: 15 * 1024 * 1024,
  isPublic: true,
);

// Plug in any cloud backend (Supabase, S3, Firebase, Appwrite, REST)
UniversalMediaService().configure(
  storageBackend: MyCustomS3Backend(),
);

// Clean upload API
final publicUrl = await UniversalMediaService().uploadSingle(
  file: myImageFile,
  bucket: profileBucket,
  entityId: 'user_123',
);
```

👉 **[Read the complete 10-chapter NextGen Media Utility Guides](nextgen_media_utility/packeg_dox/)**

---

### 2. `nextgen_ui_kit` (v0.1.0)

Add to `pubspec.yaml`:
```yaml
dependencies:
  nextgen_ui_kit: ^0.1.0
```

#### One-Line App Integration:
```dart
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

MaterialApp(
  // Automatically enables floating toasts and non-intrusive sync banners
  builder: (context, child) => SnackbarHost(
    child: Stack(
      children: [
        child!,
        const GlobalSyncStatusBanner(),
      ],
    ),
  ),
  home: const MyHomeScreen(),
);
```

#### Futuristic Indicators & KPI Cards:
```dart
// Cyber dual-rotating neon rings
FuturisticLoadingIndicator.dualRings(
  size: 54,
  color: Color(0xFF00E5FF),
  secondaryColor: Color(0xFFD500F9),
)

// Executive KPI Card
MetricCard(
  title: 'Active Revenue',
  value: '$94,200',
  trend: '+14.5%',
  icon: Icons.trending_up_rounded,
  iconColor: Color(0xFF10B981),
  variant: MetricCardVariant.elevated,
  badge: MetricBadge.success(label: 'Target Met', size: MetricBadgeSize.small),
)

// Modern Text Input with zero boilerplate
CustomTextField.email(required: true)
CustomTextField.password(required: true)
CustomTextField.search(hintText: 'Search products...')

// Floating toasts from anywhere (no BuildContext needed!)
AppSnackbar.success('Changes Saved!', description: 'Profile updated in the cloud.');
```

👉 **[Read the complete 10-chapter NextGen UI Kit Guides](nextgen_ui_kit/packeg_dox/)**

---

## 🧪 Testing & Code Quality

Both packages adhere to strict Flutter quality standards:
* **Flutter Analyze**: 0 errors, 0 warnings, 0 hints.
* **Flutter Test**: 100% test pass rate (54 total unit & widget tests).
* **Documentation**: Over 20 comprehensive markdown guides complete with copy-paste snippets.
* **Pub.dev Readiness**: Verified via `flutter pub publish --dry-run` with 0 warnings.

---

## 🤝 Contributing

Contributions, feedback, and feature requests are welcome!
1. Fork this repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'feat: add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 📄 License

All packages in this repository are licensed under the [MIT License](nextgen_ui_kit/LICENSE).
