# NextGen UI Kit Documentation — Overview

Welcome to the official developer guide for **NextGen UI Kit** (`nextgen_ui_kit`), a futuristic, highly customizable, and high-performance Flutter component library.

---

## 🎯 Purpose & Philosophy

Modern applications require UI elements that feel alive, futuristic, and responsive:
1. **Zero Domain Lock-In**: Every component is 100% decoupled from any specific backend, database, or domain model.
2. **Extreme Customizability**: From color palettes and gradients to stroke widths, animations, and glassmorphic styling, every detail is configurable.
3. **Batteries Included**: Comprehensive factory presets (`.email()`, `.password()`, `.dualRings()`, `.cyberOrbit()`, `.success()`, `.warning()`) eliminate boilerplate.
4. **Theme Responsive**: Automatically resolves light and dark themes with zero manual logic.

---

## 📂 Component Architecture

| Component | Path | Description |
| :--- | :--- | :--- |
| **Futuristic Indicators** | `src/indicators/futuristic_loading_indicator.dart` | Dual neon rings, cyber orbits, pulsing core, radar HUD, and laser progress bars. |
| **Bar Progress Meters** | `src/indicators/bar_progress_indicator.dart` | Animated linear meters with growth dimensions and percentage boxes/bubbles. |
| **Circular & Arc Meters** | `src/indicators/circular_progress_indicator.dart` | High-precision 360° circular and 180° speedometer arc progress meters. |
| **Metrics & KPIs** | `src/indicators/metric_indicators.dart` | Executive cards (`MetricCard`), status pills (`MetricBadge`), trend deltas (`TrendIndicator`), and live beacons (`PulseIndicator`). |
| **Custom Text Inputs** | `src/inputs/custom_text_field.dart` | Feature-rich input fields with password visibility toggle, clear button, and glassmorphism. |
| **Modern Snackbars** | `src/feedback/app_snackbar.dart` | Floating toasts with animated progress timers, haptics, and `SnackbarHost`. |
| **Global Sync Banner** | `src/feedback/global_sync_status_banner.dart` | Smart sliding banner with grace periods and proactive auto-retry for offline/paused backends. |
| **Structured Logger** | `src/logging/app_logger.dart` | Tag-based, color-coded terminal logger with formatted output and stack traces. |

---

## 🧭 Documentation Navigation

1. [01 — Overview](01_overview.md)
2. [02 — Installation & Setup](02_installation_setup.md)
3. [03 — Indicators & Futuristic Loaders](03_indicators_and_loaders.md)
4. [04 — Circular & Arc Progress Meters](04_circular_and_arc_meters.md)
5. [05 — Metrics, KPIs & Badges](05_metrics_kpis_and_badges.md)
6. [06 — Smart Form Inputs](06_smart_form_inputs.md)
7. [07 — Floating Snackbars](07_floating_snackbars.md)
8. [08 — Global Cloud Sync Status Banner](08_global_sync_banner.md)
9. [09 — Structured Logging](09_structured_logging.md)
10. [10 — Complete Production Recipes](10_complete_production_recipes.md)
