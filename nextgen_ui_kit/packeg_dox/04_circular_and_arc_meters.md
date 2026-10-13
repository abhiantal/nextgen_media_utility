# Circular & Arc Progress Meters

`AdvancedProgressIndicator` delivers precision 360° circular rings and 180° speedometer arcs with neon glows and custom labels.

---

## Circular Progress Meter

```dart
AdvancedProgressIndicator(
  progress: 0.82,
  size: 130,
  strokeWidth: 10,
  shape: ProgressShape.circular,
  futuristicStyle: true,
  name: 'Storage Used',
  namePosition: ProgressLabelPosition.bottom,
  labelStyle: ProgressLabelStyle.percentage,
  foregroundColor: Color(0xFF10B981),
  shadowColor: Color(0xFF10B981),
  shadowBlur: 10.0,
)
```

---

## Speedometer Arc Meter

```dart
AdvancedProgressIndicator(
  progress: 0.65,
  size: 140,
  strokeWidth: 12,
  shape: ProgressShape.arc,
  arcStartAngle: 180,
  arcSweepAngle: 180,
  name: 'Engine Speed',
  labelStyle: ProgressLabelStyle.box,
  foregroundColor: Color(0xFFF59E0B),
)
```

---

## Custom Center Widgets & Badges

You can display custom text, icons, or status badges inside the center of the ring:

```dart
AdvancedProgressIndicator(
  progress: 1.0,
  size: 120,
  shape: ProgressShape.circular,
  labelStyle: ProgressLabelStyle.custom,
  customLabel: 'DONE',
  foregroundColor: Color(0xFF10B981),
)
```
