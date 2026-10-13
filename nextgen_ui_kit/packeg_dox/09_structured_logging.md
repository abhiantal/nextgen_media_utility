# Structured Debug Logging (`AppLogger`)

`AppLogger` provides color-coded terminal messages, stack trace formatting, and tag filtering.

---

## Configuration

Initialize logger settings once during app boot:

```dart
void main() {
  AppLogger.init(
    level: Level.debug,
  );
  runApp(const MyApp());
}
```

---

## Logging Methods

```dart
// Debug log
AppLogger.d('Parsing JSON payload: 42 records', tag: 'PARSER');

// Info log
AppLogger.i('User signed in: uid=84192', tag: 'AUTH');

// Warning log
AppLogger.w('Token expires in 60 seconds', tag: 'AUTH');

// Error log with stack trace
try {
  fetchData();
} catch (e, stack) {
  AppLogger.e('Network request failed', error: e, stackTrace: stack, tag: 'API');
}
```

---

## Top-Level Helpers & Object Extensions

```dart
// Top-level shortcuts
logD('Quick debug message');
logI('Quick info message');
logW('Quick warning message');
logE('Quick error message');

// Extension methods on any Dart object
"User profile loaded".logInfo();
myObject.logDebug();
```
