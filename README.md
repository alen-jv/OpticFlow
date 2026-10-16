# 👁 20·20·20 — Eye Health Timer

A minimalist Flutter app implementing the **20-20-20 rule** for eye health:

> Every **20 minutes**, look at something **20 feet away** for **20 seconds**.

---

## Features

| Feature | Details |
|---|---|
| ⏱ Focus Timer | 20-minute countdown with custom ring progress |
| 🌿 Break Timer | 20-second eye-rest session with calming emerald theme |
| ▶ Controls | Start · Pause · Reset |
| 📅 Daily Counter | Tracks breaks completed today (auto-resets at midnight) |
| 🎨 Adaptive Theme | Dark navy during focus → deep emerald during break |
| ✨ Animations | Glow pulse, animated gradient arc, smooth transitions |

---

## Project Structure

```
lib/
  main.dart              # App entry point + provider setup
  models/
    session_type.dart    # Focus / Break enum
  timer/
    timer_provider.dart  # State management + countdown engine
  utils/
    app_theme.dart       # Color palette, typography, theme
    format_time.dart     # MM:SS formatter
  screens/
    home_screen.dart     # Main screen layout
  widgets/
    circular_timer_painter.dart  # Custom painted ring
    control_buttons.dart         # Start / Pause / Reset
    daily_counter_badge.dart     # Today's break count pill
    session_label.dart           # Animated session heading
```

---

## Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on a connected device or emulator
flutter run

# 3. Run unit tests
flutter test
```

## Replacing the placeholder sound

Replace `assets/sounds/ding.wav` with your preferred notification sound (.wav or .mp3).
Then in `timer_provider.dart`, uncomment the audioplayers lines to enable audio.

---

## Dependencies

- `provider ^6.1.2` — Reactive state management
- `shared_preferences ^2.3.2` — Daily counter persistence
- `audioplayers ^6.1.0` — Session transition sounds
