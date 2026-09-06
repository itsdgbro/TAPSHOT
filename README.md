# TAPSHOT ⚡

**TAPSHOT** is a fast-paced, cyber-themed mobile aim trainer and reflex challenge game built with Flutter. Test your reaction time, precision tapping, and target tracking across high-octane game modes.

---

## 🎮 Game Modes

- **♾️ Endless Mode**: 3 lives. The further you get, the smaller and faster targets spawn. Survive the escalating difficulty as long as you can.
- **⏱️ 30 Seconds Mode**: High-intensity speed test with selectable difficulties:
  - **Easy**: Relaxed target sizes and lifetimes for warm-ups.
  - **Medium**: Faster pace with subtle target drift.
  - **Hard**: Ultra-fast, compact targets with high-speed drift and a **2x score multiplier**.

---

## ✨ Features

- **⚡ Cyberpunk & Tech Aesthetic**: Dark UI with glowing accents, animated HUD elements, custom radar target painter, and combo hit effects.
- **🎯 Dynamic Mechanics**:
  - Combo system with score multipliers.
  - Accuracy and reaction time (ms) tracking.
  - Smooth target movement and drift physics.
- **🎨 Unlockable Target Skins**:
  - `Volt Tech` (Default Acid Yellow)
  - `Cyberpunk` (Neon Magenta & Cyan)
  - `Crimson` (Hyper-focus Red)
  - `Frost` (Ice White & Glacier Blue)
- **🔊 Audio & Haptics**: Procedural synth audio effects, combo cues, UI click feedback, and vibration triggers.
- **📊 Match Analytics & History**: Detailed post-game performance breakdown (accuracy %, avg reaction time, max combo, total hits) and persistent high scores via `shared_preferences`.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.13.2`)
- **State Management**: Clean controller & service-oriented pattern
- **Audio**: [`audioplayers`](https://pub.dev/packages/audioplayers)
- **Storage**: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **Styling**: Custom Flutter `CustomPainter` renderers and neon design system

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.2`)
- Android Studio / VS Code with Flutter & Dart extensions
- Connected Android/iOS device or emulator

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/itsdgbro/TAPSHOT.git
   cd TAPSHOT
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

### Running Tests / Analysis

```bash
# Analyze code for lint rules
flutter analyze

# Run unit / widget tests
flutter test
```

---

## 📁 Project Structure

```
lib/
├── controllers/      # Game loop, target generation, and scoring logic
├── models/           # App skins, game modes, difficulties, and records
├── screens/          # Home, Game, Settings, Difficulty, and Result views
├── services/         # Audio, Haptics, and Local Storage services
├── theme/            # Color palettes, typography, and visual tokens
├── widgets/          # Tech buttons, target painters, combo counters, HUD
└── main.dart         # App entry point & initialization
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) (or your chosen license).
