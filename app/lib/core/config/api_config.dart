/// API Configuration for EXPO to World App
///
/// This file contains configuration settings for the API service.
/// Update the base URL here when deploying to different environments.
library;

class ApiConfig {
  // Prefer compile-time environment override; fall back to sensible defaults.
  // Usage:
  // flutter run --dart-define=API_BASE=https://device-api.expotoworld.com
  static const String _envBase = String.fromEnvironment('API_BASE');

  // Defaults for convenience
  static const String _devBaseUrl = 'http://localhost:8080';
  static const String _prodBaseUrl = 'https://device-api.expotoworld.com';

  // Toggle used only when API_BASE is not provided
  static const bool _isDevelopment = true;

  /// Resolve base URL with this priority: API_BASE -> dev/prod toggle defaults
  static String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    return _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  }

  /// API version path
  static const String apiVersion = '/api/v1';

  /// Full API base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  /// Health check timeout
  static const Duration healthTimeout = Duration(seconds: 10);
  
  /// Common HTTP headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Update configuration for different environments
  static void setEnvironment({required bool isDevelopment}) {
    // This would require a more sophisticated approach in a real app
    // For now, manually change _isDevelopment above
  }
  
  /// Get configuration info for debugging
  static Map<String, dynamic> get debugInfo => {
    'baseUrl': baseUrl,
    'apiBaseUrl': apiBaseUrl,
    'isDevelopment': _isDevelopment,
    'timeout': timeout.inSeconds,
  };
}

/// Environment-specific configurations
class EnvironmentConfig {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  /// Configuration for different environments
  static const Map<String, String> baseUrls = {
    development: 'http://localhost:8080',
    staging: 'http://staging-loadbalancer-url.com',
    production: 'http://production-loadbalancer-url.com',
  };
  
  /// Get base URL for specific environment
  static String getBaseUrl(String environment) {
    return baseUrls[environment] ?? baseUrls[development]!;
  }
}
