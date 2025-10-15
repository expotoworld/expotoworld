# Development Scripts

This directory contains development scripts for the Expo to World project.

## 📱 Flutter Launch Scripts

### `flutter_dev_ios.sh`
Launch the Flutter mobile app in development mode for iOS simulator.

**Usage:**
```bash
./scripts/flutter_dev_ios.sh
```

**Configuration:**
- Flavor: `dev`
- API Base URL: `http://127.0.0.1:8787` (localhost)

**Or use Makefile:**
```bash
make dev-flutter-ios
```

---

### `flutter_dev_android.sh`
Launch the Flutter mobile app in development mode for Android emulator.

**Usage:**
```bash
./scripts/flutter_dev_android.sh
```

**Configuration:**
- Flavor: `dev`
- API Base URL: `http://10.0.2.2:8787` (Android emulator's host machine)

**Or use Makefile:**
```bash
make dev-flutter-android
```

---

### `flutter_prod.sh`
Launch the Flutter mobile app in production mode.

**Usage:**
```bash
./scripts/flutter_prod.sh
```

**Configuration:**
- Flavor: `prod`
- API Base URL: `https://device-api.expomadeinworld.com`

---

## 🎨 iOS Development Scripts

### `ios/apply_dev_badge.sh`
Apply a "DEV" badge overlay to iOS app icons to visually distinguish development builds from production builds.

**Usage:**
```bash
./scripts/ios/apply_dev_badge.sh
```

**Requirements:**
- Xcode command line tools installed
- `AppIcon-Dev.appiconset` directory exists in `app/ios/Runner/Assets.xcassets/`

**What it does:**
- Scans all PNG files in the dev app icon set
- Applies a dark banner with "DEV" text overlay
- Overwrites the original icons with badged versions

---

### `ios/dev_icon_overlay.swift`
Swift script used by `apply_dev_badge.sh` to render the "DEV" badge overlay on icon images.

**Usage:**
```bash
xcrun swift scripts/ios/dev_icon_overlay.swift <input.png> <output.png>
```

**Note:** This script is typically called by `apply_dev_badge.sh` and not used directly.

---

## 🚀 Quick Start

For the fastest development experience, use the root-level Makefile:

```bash
# Start all backend + frontend services
make dev-env

# Start only backend services
make dev-backend

# Start only frontend applications
make dev-frontend

# Launch Flutter app (iOS)
make dev-flutter-ios

# Launch Flutter app (Android)
make dev-flutter-android

# Stop all services
make stop
```

See the root-level `Makefile` for more details.

