# EXPO to World - Mobile App Architecture

## Overview

The EXPO to World mobile application is built with Flutter, providing a cross-platform solution for iOS and Android. The app enables users to browse products, locate unmanned stores, and make purchases through an intuitive mobile interface.

## Technology Stack

### Frontend Framework
- **Flutter**: 3.8.1
- **Dart**: 3.8.1

### State Management
- **Provider**: 6.1.1
  - `AuthProvider`: Manages authentication state
  - `CartProvider`: Manages shopping cart state
  - `LocationProvider`: Manages location services

### UI and Design
- **Google Fonts**: 6.1.0
- **Flutter SVG**: 2.0.9
- **Cached Network Image**: 3.3.0
- **Flutter Staggered Grid View**: 0.7.0
- **Animations**: 2.0.11

### Location Services
- **Geolocator**: 12.0.0
- **Permission Handler**: 11.3.1
- **Geocoding**: 3.0.0
- **Google Maps Flutter**: 2.6.1

### Local Storage
- **Shared Preferences**: 2.2.2 (for app settings)
- **Flutter Secure Storage**: 9.2.2 (for sensitive data like tokens)

### HTTP Client
- **http**: 1.1.0

### Other Dependencies
- **URL Launcher**: 6.2.5
- **Intl Phone Field**: 3.2.0
- **Phone Numbers Parser**: 9.0.11

## Architecture Pattern

The app follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (Screens, Widgets, Providers)      │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│       Business Logic Layer          │
│     (Providers, State Management)   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         Data Layer                  │
│   (Services, Models, API Clients)   │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      External Services              │
│  (API Gateway, Google Maps, etc.)   │
└─────────────────────────────────────┘
```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── api_config.dart          # API configuration and environment settings
│   ├── enums/
│   │   ├── store_type.dart          # Store type enumeration
│   │   └── mini_app_type.dart       # Mini app type enumeration
│   ├── navigation/
│   │   └── app_router.dart          # Navigation logic
│   ├── theme/
│   │   ├── app_theme.dart           # App theme configuration
│   │   ├── app_colors.dart          # Color palette
│   │   └── app_text_styles.dart     # Text styles
│   └── utils/
│       └── helpers.dart             # Utility functions
├── data/
│   ├── models/
│   │   ├── product.dart             # Product model
│   │   ├── category.dart            # Category model
│   │   ├── subcategory.dart         # Subcategory model
│   │   ├── store.dart               # Store model
│   │   ├── cart_models.dart         # Cart-related models
│   │   ├── auth_models.dart         # Authentication models
│   │   └── order_models.dart        # Order models
│   └── services/
│       ├── api_service.dart         # Main API service
│       ├── auth_service.dart        # Authentication service
│       ├── cart_service.dart        # Cart service
│       ├── order_service.dart       # Order service
│       ├── location_service.dart    # Location service
│       ├── storage_service.dart     # Local storage service
│       └── product_data_resolver.dart # Product data utilities
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── cart_provider.dart       # Cart state
│   │   └── location_provider.dart   # Location state
│   ├── screens/
│   │   ├── auth/
│   │   │   └── auth_screen.dart     # Login/verification screen
│   │   └── main/
│   │       ├── main_screen.dart     # Main navigation screen
│   │       ├── home_screen.dart     # Home screen
│   │       ├── categories_screen.dart # Categories screen
│   │       ├── cart_screen.dart     # Shopping cart screen
│   │       ├── profile_screen.dart  # User profile screen
│   │       └── messages_screen.dart # Messages screen
│   └── widgets/
│       └── common/                  # Reusable widgets
└── main.dart                        # App entry point
```

## API Integration

### API Gateway

The app connects to backend services through a Cloudflare Worker gateway:

- **Production**: `https://device-api.expotoworld.com`
- **Development**: `http://localhost:8080`

### API Endpoints

All API calls go through the gateway which routes to appropriate backend services:

- `/api/v1/products` - Product catalog
- `/api/v1/categories` - Categories and subcategories
- `/api/v1/stores` - Store information
- `/api/auth/*` - Authentication endpoints
- `/api/cart/*` - Cart management
- `/api/orders/*` - Order management

### API Configuration

API configuration is centralized in `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String _prodBaseUrl = 'https://device-api.expotoworld.com';
  static const String _devBaseUrl = 'http://localhost:8080';
  static const bool _isDevelopment = true;
  
  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    return _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  }
}
```

## State Management

### Provider Pattern

The app uses the Provider package for state management:

1. **AuthProvider**
   - Manages user authentication state
   - Handles login/logout
   - Stores user tokens securely
   - Provides authentication status to the app

2. **CartProvider**
   - Manages shopping cart items
   - Calculates totals
   - Syncs with backend API
   - Depends on AuthProvider for user context

3. **LocationProvider**
   - Manages GPS location
   - Handles location permissions
   - Provides current location to screens
   - Calculates distances to stores

### State Flow

```
User Action → Provider Method → API Service → Backend
                    ↓
              State Update
                    ↓
            UI Rebuild (Consumer)
```

## Authentication Flow

1. User enters email address
2. App sends verification code request to `/api/auth/send-verification`
3. User enters verification code
4. App verifies code at `/api/auth/verify-code`
5. Backend returns access token and refresh token
6. Tokens stored in Flutter Secure Storage
7. AuthProvider updates state to authenticated
8. App navigates to main screen

## Platform-Specific Configuration

### Android

**Package Structure**:
- **Namespace**: `com.expotoworld.app`
- **Application ID**: `com.expotoworld.app`
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: Latest

**Build Flavors**:
- **dev**: Development flavor with `.dev` suffix
- **prod**: Production flavor

**Permissions** (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**Google Maps API Key**:
Configured via `local.properties`:
```properties
MAPS_API_KEY=your_api_key_here
```

### iOS

**Bundle Configuration**:
- **Bundle Name**: `expotoworld_app`
- **Bundle Identifier**: Configured in Xcode project
- **Min iOS Version**: 12.0

**Permissions** (`Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show nearby unmanned stores and provide location-based services.</string>
```

**Google Maps API Key**:
Configured via Xcode build settings (`Maps_API_KEY` variable).

## Build and Deployment

### Development Build

```bash
# Run with local API
flutter run --dart-define=API_BASE=http://localhost:8080

# Run with dev flavor
flutter run --flavor dev
```

### Production Build

#### Android

```bash
# APK
flutter build apk --release --flavor prod --dart-define=API_BASE=https://device-api.expotoworld.com

# App Bundle (for Google Play)
flutter build appbundle --release --flavor prod --dart-define=API_BASE=https://device-api.expotoworld.com
```

#### iOS

```bash
flutter build ios --release --flavor prod --dart-define=API_BASE=https://device-api.expotoworld.com
```

## Security

### Token Storage

- **Access Token**: Stored in Flutter Secure Storage
- **Refresh Token**: Stored in Flutter Secure Storage
- **User Data**: Stored in Shared Preferences (non-sensitive data only)

### API Security

- All API calls use HTTPS in production
- Tokens included in Authorization header
- Automatic token refresh on expiration

### Location Privacy

- Location permission requested only when needed
- Location data not stored permanently
- User can deny location access

## Performance Optimization

### Image Caching

- Uses `cached_network_image` for efficient image loading
- Automatic memory and disk caching
- Placeholder images during loading

### API Caching

- Local caching of frequently accessed data
- Offline support for previously loaded content
- Background sync when network available

### Lazy Loading

- Products loaded on demand
- Pagination for large lists
- Staggered grid view for better performance

## Testing

### Unit Tests

Located in `test/` directory:
- Model tests
- Service tests
- Provider tests

### Widget Tests

- Screen tests
- Widget interaction tests

### Integration Tests

- End-to-end user flows
- API integration tests

## Troubleshooting

### Common Issues

1. **Google Maps not displaying**:
   - Verify API key is correct
   - Check Maps SDK is enabled in Google Cloud Console
   - Ensure location permissions granted

2. **API connection failures**:
   - Verify API base URL
   - Check network connectivity
   - Review API logs

3. **Build errors**:
   - Run `flutter clean`
   - Delete `pubspec.lock` and run `flutter pub get`
   - Verify Flutter/Dart SDK versions

## Future Enhancements

- Push notifications
- Offline mode improvements
- Payment integration
- QR code scanning
- Social sharing
- Multi-language support expansion

## Related Documentation

- [README.md](./README.md) - Quick start guide
- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)

