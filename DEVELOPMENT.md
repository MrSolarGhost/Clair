# Clair Development Guide

## Quick Start

### Prerequisites

- Flutter SDK 3.27+ installed
- Android SDK for Android development
- A connected Android device or emulator

### Installation

1. Clone the repository:
```bash
cd ~/Code/Clair
```

2. Install dependencies:
```bash
flutter pub get
```

### Running the App

#### Android
```bash
flutter run
```

#### Linux Desktop
```bash
flutter run -d linux
```

#### Windows Desktop
```bash
flutter run -d windows
```

#### macOS Desktop
```bash
flutter run -d macos
```

### Building APK

#### Debug APK
```bash
flutter build apk --debug
```

#### Release APK
```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Live Debugging

#### Hot Reload
While `flutter run` is active:
- Press `r` to hot reload (instant UI updates)
- Press `R` to hot restart (full app restart)
- Press `p` to show performance overlay
- Press `o` to toggle platform (iOS/Android styles)

#### USB Debugging
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify connection
5. Run `flutter run`

#### Wireless Debugging (Android 11+)
1. Enable Wireless Debugging in Developer Options
2. Run `adb pair <IP>:<PORT>` with pairing code
3. Run `adb connect <IP>:<PORT>`
4. Run `flutter run`

### Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/              # UI screens
│   └── home_screen.dart  # Main home screen
├── services/             # Business logic & platform integration
│   └── input_service.dart # Gamepad/keyboard input handling
├── models/               # Data models
├── widgets/              # Reusable UI components
└── utils/                # Helper functions
```

### Input Testing

The app supports **controller-first navigation**:

- **Keyboard**: Arrow keys (←→) to navigate, Enter to select
- **Gamepad**: D-pad to navigate, A button to select
- **Touch**: Tap any menu item

Connect a Bluetooth gamepad to test controller input on Android handhelds!

### Features Implemented

✅ Controller-first input handling
✅ Keyboard navigation support
✅ Touch fallback
✅ Dark console-like theme
✅ Cross-platform (Android, Linux, Windows, macOS)
✅ Hot reload for rapid development

### Coming Soon

- Game library scanning
- SQLite database integration
- Emulator launching
- Completion tracking
- Collections management

### Tips

- Use an Android handheld (AYANEO, Retroid, etc.) for authentic testing
- Test on multiple screen sizes
- Verify gamepad D-pad and button mapping
- Check performance with `flutter run --profile`

---

For more details, see the main [README.md](README.md) and [AGENTS.md](AGENTS.md).
