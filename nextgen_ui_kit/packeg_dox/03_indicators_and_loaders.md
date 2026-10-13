# Indicators & Futuristic Loaders

`FuturisticLoadingIndicator` provides next-generation animated loading rings and cyber orbital particles.

---

## Presets & Styles

### 1. Dual Rings
Two counter-rotating glowing neon rings with gap arcs:
```dart
FuturisticLoadingIndicator.dualRings(
  size: 60,
  color: Color(0xFF00E5FF),
  secondaryColor: Color(0xFFD500F9),
  strokeWidth: 3.5,
  glowRadius: 6.0,
)
```

### 2. Cyber Orbit
Planetary orbit particles with rotating satellite nodes:
```dart
FuturisticLoadingIndicator.cyberOrbit(
  size: 54,
  color: Color(0xFF10B981),
  secondaryColor: Color(0xFFF59E0B),
)
```

### 3. Pulsing Core
Breathing core with an expanding outer energy halo:
```dart
FuturisticLoadingIndicator.pulsingCore(
  size: 48,
  color: Color(0xFFFF0055),
  glowRadius: 8.0,
)
```

### 4. Radar Scanner
Sweeping radar HUD scanner:
```dart
FuturisticLoadingIndicator.radarScanner(
  size: 50,
  color: Color(0xFF38BDF8),
)
```

---

## Futuristic Linear Progress Bar

`FuturisticLinearLoadingIndicator` supports both indeterminate laser sweeps and determinate progress fills:

```dart
// Determinate Laser Progress
FuturisticLinearLoadingIndicator(
  value: 0.75, // 75%
  minHeight: 6.0,
  color: Color(0xFF06B6D4),
  glowRadius: 5.0,
  borderRadius: BorderRadius.circular(10),
)

// Indeterminate Laser Sweep
FuturisticLinearLoadingIndicator(
  minHeight: 4.0,
  color: Color(0xFF8B5CF6),
)
```
