# Floating Modern Snackbars

`AppSnackbar` provides animated floating toast notifications with countdown progress bars, shake animations, and haptic feedback.

---

## Setup: One-Line Integration

Wrap your `MaterialApp.builder` with `SnackbarHost`:

```dart
MaterialApp(
  builder: (context, child) => SnackbarHost(
    alignment: Alignment.topCenter, // Or Alignment.bottomCenter
    child: child!,
  ),
  home: const MyHome(),
)
```

---

## Triggering Snackbars (No `BuildContext` Required!)

```dart
// Success Toast
AppSnackbar.success(
  'Changes Saved!',
  description: 'Profile has been synchronized with the cloud.',
);

// Error Toast with Shake Animation
AppSnackbar.error(
  'Authentication Failed',
  description: 'Invalid credentials provided. Please check your password.',
);

// Warning Toast
AppSnackbar.warning(
  'Unsaved Changes',
  description: 'Navigating away will discard your draft.',
);

// Info Toast
AppSnackbar.info(
  title: 'Cloud Maintenance',
  message: 'Scheduled backup starting at midnight UTC.',
);

// Persistent Loading Indicator Toast
AppSnackbar.loading(title: 'Uploading 4K Assets...');
// When complete:
AppSnackbar.hideLoading();
```
