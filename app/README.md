# EXPO to World - Mobile Application

Flutter mobile application for EXPO to World platform, providing access to unmanned stores and exhibition sales.

## Technology Stack

- **Flutter SDK**: ^3.8.1
- **Dart SDK**: ^3.8.1
- **State Management**: Provider 6.1.1
- **HTTP Client**: http 1.1.0
- **Maps**: Google Maps Flutter 2.6.1
- **Location Services**: Geolocator 12.0.0
- **Local Storage**: Shared Preferences 2.2.2, Flutter Secure Storage 9.2.2

## Features

- **Authentication**: Email verification code login
- **Product Catalog**: Browse products by category and store type
- **Shopping Cart**: Add products to cart and manage orders
- **Store Locator**: Find nearby unmanned stores using GPS
- **Google Maps Integration**: View store locations on map
- **Multi-language Support**: Chinese and English
- **Offline Support**: Local caching for better performance

## Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / Xcode (for platform-specific builds)
- Google Maps API Key (for maps functionality)

## Getting Started

### 1. Install Dependencies

```bash
cd app
flutter pub get
```

### 2. Configure Google Maps API Key

#### Android

Create or edit `android/local.properties` and add:

```properties
MAPS_API_KEY=your_google_maps_api_key_here
```

#### iOS

The Maps API key is configured via Xcode build settings. Update the `Maps_API_KEY` variable in the Xcode project.

### 3. Run the App

#### Development Mode (Local API)

```bash
flutter run --dart-define=API_BASE=http://localhost:8080
```

#### Production Mode

```bash
flutter run --dart-define=API_BASE=https://device-api.expotoworld.com
```

#### Build Flavors

The app supports dev and prod flavors:

```bash
# Development flavor
flutter run --flavor dev

# Production flavor
flutter run --flavor prod
```

## Build for Release

### Android

#### APK

```bash
flutter build apk --release --flavor prod
```

#### App Bundle (for Google Play)

```bash
flutter build appbundle --release --flavor prod
```

### iOS

```bash
flutter build ios --release --flavor prod
```

## Project Structure

```
app/
├── lib/
│   ├── core/
│   │   ├── config/          # API configuration
│   │   ├── enums/           # Enums (store types, mini app types)
│   │   ├── navigation/      # Navigation logic
│   │   ├── theme/           # App theme and colors
│   │   └── utils/           # Utility functions
│   ├── data/
│   │   ├── models/          # Data models
│   │   └── services/        # API services
│   ├── presentation/
│   │   ├── providers/       # State management providers
│   │   ├── screens/         # UI screens
│   │   └── widgets/         # Reusable widgets
│   └── main.dart            # App entry point
├── android/                 # Android-specific code
├── ios/                     # iOS-specific code
├── assets/                  # Images and other assets
├── test/                    # Unit and widget tests
└── pubspec.yaml             # Dependencies

```

## API Configuration

The app connects to backend services through a Cloudflare Worker gateway:

- **Production**: `https://device-api.expotoworld.com`
- **Development**: `http://localhost:8080`

API configuration is managed in `lib/core/config/api_config.dart`.

### Environment Variables

You can override the API base URL using Dart defines:

```bash
flutter run --dart-define=API_BASE=https://your-api-url.com
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test

```bash
flutter test test/widget_test.dart
```

## Code Analysis

```bash
flutter analyze
```

## Platform-Specific Notes

### Android

- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: Latest
- **Package Name**: `com.expotoworld.app`
- **Permissions**: Location, Internet

### iOS

- **Minimum iOS Version**: 12.0
- **Bundle Identifier**: Configured in Xcode
- **Permissions**: Location (NSLocationWhenInUseUsageDescription)

## Troubleshooting

### Common Issues

1. **Google Maps not showing**:
   - Verify API key is correctly configured
   - Check that Maps SDK is enabled in Google Cloud Console
   - Ensure location permissions are granted

2. **Build errors**:
   - Run `flutter clean`
   - Delete `pubspec.lock` and run `flutter pub get`
   - Check Flutter and Dart SDK versions

3. **API connection issues**:
   - Verify API base URL is correct
   - Check network connectivity
   - Review API logs for errors

## Documentation

- [Architecture Documentation](./ARCHITECTURE.md)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Documentation](https://pub.dev/packages/provider)

## License

Proprietary - EXPO to World

## Support

For issues and questions, please contact the development team.

