# NextGen UI Kit 🚀

A futuristic, highly customizable, and high-performance Flutter UI component library designed for next-generation apps, executive dashboards, analytics monitors, and modern digital experiences.

[![Pub Version](https://img.shields.io/pub/v/nextgen_ui_kit?color=blue)](https://pub.dev/packages/nextgen_ui_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%203.10+-02569B?logo=flutter)](https://flutter.dev)

---

## 🌟 Key Highlights

* ⚡ **Futuristic Visual Aesthetics**: Neon glowing rings, cyber particle orbits, pulsating energy cores, and laser HUD scanners.
* 📊 **Universal Metric & KPI System**: Sleek executive stat cards (`elevated`, `flat`, `glass`, `gradient`), live pulsing status beacons, directional trend deltas, and high-impact tag pills.
* 🔄 **Next-Gen Progress Meters**: Circular & semicircular arc meters with rotating neon glows, customizable center widgets, and theme adaptation.
* ✍️ **Theme-Smart Form Inputs**: `CustomTextField` with built-in presets (`.email()`, `.password()` with visibility eye toggle, `.search()` with clear button, `.phone()`, `.multiline()`) and glassmorphism support.
* 🍞 **Modern Floating Feedback**: `AppSnackbar` & `SnackbarHost` delivering zero-configuration floating toasts with timeout progress bars and shake animations.
* 🌐 **Smart Cloud Sync Banner**: `GlobalSyncStatusBanner` that slides down during network offline, server pause, or session expiration with a grace period and auto-retry to prevent alarming users during transient drops.
* 🪵 **Structured Debug Logger**: `AppLogger` with color-coded terminal messages, stack traces, tagging, and extension helpers.

---

## 📦 Installation

Add `nextgen_ui_kit` to your `pubspec.yaml`:

```yaml
dependencies:
  nextgen_ui_kit: ^0.1.0
```

Import the package:

```dart
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';
```

---

## 🛠️ Quick Start & Component Showcase

### 1. Futuristic Loading Indicators

```dart
// Dual counter-rotating neon cyber rings
FuturisticLoadingIndicator.dualRings(
  size: 54,
  color: Color(0xFF00E5FF),
  secondaryColor: Color(0xFFD500F9),
)

// Cyber orbital satellite particles
FuturisticLoadingIndicator.cyberOrbit(
  size: 54,
  color: Color(0xFF10B981),
)

// Energy breathing core
FuturisticLoadingIndicator.pulsingCore(
  size: 50,
  color: Color(0xFFFF0055),
)

// Sweeping radar HUD scanner
FuturisticLoadingIndicator.radarScanner(
  size: 50,
  color: Color(0xFF38BDF8),
)

// Futuristic linear laser progress bar
FuturisticLinearLoadingIndicator(
  value: 0.72,
  minHeight: 6,
  color: Color(0xFF06B6D4),
  glowRadius: 5,
)
```

---

### 2. Executive Metric & KPI Cards

```dart
MetricCard(
  title: 'Total Revenue',
  value: '$84,230',
  subtitle: '+14.2% vs previous period',
  trend: '+14.2%',
  icon: Icons.account_balance_wallet_rounded,
  iconColor: Color(0xFF10B981),
  variant: MetricCardVariant.elevated,
  badge: MetricBadge.success(label: 'On Target', size: MetricBadgeSize.small),
  onTap: () => print('Card tapped!'),
)
```

#### Metric Badges, Status Pills & Live Beacons:

```dart
MetricIndicatorGroup(
  spacing: 8,
  children: [
    // Live pulsating beacon
    MetricBadge.live(),

    // Status presets
    MetricBadge.success(label: 'Operational', value: '99.9%'),
    MetricBadge.warning(label: 'Review Required', value: '3'),
    MetricBadge.error(label: 'Failed Builds', value: '1'),
    MetricBadge.info(label: 'Syncing Data'),

    // Trend Indicators
    TrendIndicator(value: '+28.4%'),
    TrendIndicator(value: '-4.2%'),
  ],
)
```

---

### 3. Circular & Arc Progress Meters

```dart
// Circular meter with rotating neon cyber HUD effect
AdvancedProgressIndicator(
  progress: 0.75,
  size: 120,
  strokeWidth: 10,
  shape: ProgressShape.circular,
  futuristicStyle: true,
  name: 'Storage Used',
  labelStyle: ProgressLabelStyle.percentage,
)

// Semicircular speedometer arc meter
AdvancedProgressIndicator(
  progress: 0.65,
  size: 130,
  shape: ProgressShape.arc,
  arcStartAngle: 180,
  arcSweepAngle: 180,
  name: 'System Memory',
)
```

---

### 4. Smart Form Inputs (`CustomTextField`)

Eliminate boilerplate with built-in presets:

```dart
// Search field with instant clear button
CustomTextField.search(
  hintText: 'Search products or tags...',
  onChanged: (query) => print(query),
)

// Email field with email keyboard & autocorrect disabled
CustomTextField.email(
  required: true,
  validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
)

// Password field with eye visibility toggle
CustomTextField.password(
  required: true,
)

// Multiline notes field with live counter
CustomTextField.multiline(
  label: 'User Notes',
  hintText: 'Write notes here...',
  maxLength: 250,
)
```

---

### 5. Floating Modern Snackbars (`SnackbarHost`)

Add `SnackbarHost` once in your `MaterialApp.builder`, then trigger toasts anywhere without passing `BuildContext`!

```dart
// In your main MaterialApp:
MaterialApp(
  builder: (context, child) => SnackbarHost(child: child!),
  home: const MyHomeScreen(),
)

// Anywhere in your business logic or UI:
AppSnackbar.success('Record Saved!', description: 'Your changes have been safely committed.');
AppSnackbar.error('Connection Failed', description: 'Could not reach the database.');
AppSnackbar.warning('Storage Warning', description: 'Volume remaining is under 10%.');
AppSnackbar.info(title: 'Update Available', message: 'Version 2.0 is ready to download.');
```

---

### 6. Global Cloud Sync Status Banner

A non-intrusive sliding banner that keeps users informed about offline modes, server outages, or expired sessions without alarming them over transient 1-second reconnects:

```dart
GlobalSyncStatusBanner(
  // Automatically handles grace duration (default: 12s) and background retry
  graceDuration: const Duration(seconds: 12),
  config: const SyncBannerConfig(
    offlineTitle: 'Offline Mode Active',
    localDataSafetyNote: 'Your edits are saved locally and will sync once connected.',
  ),
)

// Broadcast status changes from anywhere:
SyncStatusController.update(ServerSyncState.offline);
SyncStatusController.update(ServerSyncState.serverPaused);
SyncStatusController.update(ServerSyncState.synced);
```

---

### 7. Structured Debug Logging (`AppLogger`)

```dart
// Initialize custom logging preferences
AppLogger.init();

// Log with clean visual cards and tags
AppLogger.d('Debug details', tag: 'NETWORK');
AppLogger.i('User authenticated', tag: 'AUTH');
AppLogger.w('Cache miss', tag: 'CACHE');
AppLogger.e('Database query failed', error: exception, stackTrace: stack);

// Or via convenient object extensions:
'Payload processed successfully'.logInfo();
```

---

## 🎨 Design System & Theme Customization

Every component in NextGen UI Kit respects `Theme.of(context)` while providing deep styling overrides:
* **Custom Gradients**: Provide your own `LinearGradient` or `SweepGradient`.
* **Glassmorphism**: Select `.glass` variants on `MetricCard` and `CustomTextField` for frosted backgrounds.
* **Haptics**: Touch interactions provide subtle system haptic feedback.
* **Light / Dark Mode**: Colors automatically resolve between dark slate surfaces and crisp light tones.

---

## 📄 License

NextGen UI Kit is released under the [MIT License](LICENSE).
