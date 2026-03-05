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

  // ============================================================
  // Auth Service
  // ============================================================

  /// Base URLs for different environments
  static const String _devAuthBaseUrl = 'http://localhost:8081';
  static const String _prodAuthBaseUrl = 'https://auth.expotoworld.com';

  /// Auth service base URL
  static String get authBaseUrl =>
      _isProduction ? _prodAuthBaseUrl : _devAuthBaseUrl;

  // ============================================================
  // Catalog Service (consumer public endpoints)
  // ============================================================

  /// Dev: direct to catalog service; Prod: via Cloudflare Worker gateway
  static const String _devCatalogBaseUrl = 'http://localhost:8080';
  static const String _prodCatalogBaseUrl =
      'https://device-api.expotoworld.com';

  /// Catalog service base URL
  static String get catalogBaseUrl =>
      _isProduction ? _prodCatalogBaseUrl : _devCatalogBaseUrl;

  // ============================================================
  // Timeouts
  // ============================================================

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

/// Catalog API Public Endpoints (consumer-facing, read-only)
///
/// These map to the backend's `/api/v1/public/*` routes which require
/// authentication but NOT admin role. Admin-only fields (cost_price,
/// owner_org_id, shelf_code, logistics_*) are excluded from responses.
class CatalogEndpoints {
  CatalogEndpoints._();

  /// Base path for public catalog endpoints
  static const String basePath = '/api/v1/public';

  // -- Stores --
  static String get stores => '$basePath/stores';
  static String store(int id) => '$basePath/stores/$id';

  // -- Categories --
  static String get categories => '$basePath/categories';
  static String get categoryTree => '$basePath/categories/tree';
  static String category(int id) => '$basePath/categories/$id';
  static String subcategories(int categoryId) =>
      '$basePath/categories/$categoryId/subcategories';

  // -- Collections --
  static String collections(int subcategoryId) =>
      '$basePath/subcategories/$subcategoryId/collections';

  // -- Subcollections --
  static String subcollections(int collectionId) =>
      '$basePath/collections/$collectionId/subcollections';

  // -- Products --
  static String get products => '$basePath/products';
  static String product(int id) => '$basePath/products/$id';
  static String productChildren(int id) => '$basePath/products/$id/children';
}
