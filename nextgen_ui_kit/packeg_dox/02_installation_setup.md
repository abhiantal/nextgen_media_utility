# Installation & Setup

## 1. Add Dependency

Add `nextgen_ui_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  nextgen_ui_kit: ^0.1.0
```

Run in your terminal:
```bash
flutter pub get
```

---

## 2. Global Root Setup (Recommended)

To enable global floating snackbars and cloud sync banners without needing `BuildContext`, wrap your `MaterialApp` with `SnackbarHost`:

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

void main() {
  // Initialize structured logger
  AppLogger.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextGen App',
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF06B6D4),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF06B6D4),
      ),
      builder: (context, child) => SnackbarHost(
        child: Stack(
          children: [
            child!,
            const GlobalSyncStatusBanner(),
          ],
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
```
