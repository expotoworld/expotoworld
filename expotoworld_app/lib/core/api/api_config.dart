/// API Configuration
/// 
/// Environment-aware configuration for API endpoints.
/// Update these values based on your deployment environment.
library;

import 'package:flutter/foundation.dart';

/// API Configuration class
class ApiConfig {
  ApiConfig._();

  /// Environment configuration
  static const bool _isProduction = kReleaseMode;

  /// Base URLs for different environments
  static const String _devAuthBaseUrl = 'http://localhost:8081';
  static const String _prodAuthBaseUrl = 'https://auth.expotoworld.com';
  
  /// Auth service base URL
  static String get authBaseUrl => _isProduction ? _prodAuthBaseUrl : _devAuthBaseUrl;

  /// Connection timeout in milliseconds
  static const Duration connectionTimeout = Duration(seconds: 30);

  /// Receive timeout in milliseconds
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Auth API Endpoints
class AuthEndpoints {
  AuthEndpoints._();

  /// Base path for user auth endpoints
  static const String basePath = '/api/v1/auth';

  /// Send verification code (OTP) to email or phone
  static String get sendCode => '$basePath/send-code';

  /// Verify the OTP code and get tokens
  static String get verifyCode => '$basePath/verify-code';

  /// Refresh access token using refresh token
  static String get refresh => '$basePath/refresh';

  /// Logout and invalidate refresh token
  static String get logout => '$basePath/logout';

  /// JWKS endpoint for token verification
  static const String jwks = '/.well-known/jwks.json';
}
