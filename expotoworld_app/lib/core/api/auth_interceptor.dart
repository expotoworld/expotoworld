/// Shared Auth Interceptor
///
/// Reusable Dio interceptor that handles:
/// - Adding Bearer token to authenticated requests
/// - Adding X-Device-Id header for stable server-side fingerprinting
/// - Automatic token refresh on 401 responses
///
/// Used by both the Auth API client and Catalog API client.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import '../services/secure_storage_service.dart';

/// Auth interceptor that adds tokens and handles 401 refresh.
///
/// [authBaseUrl] is used to make refresh calls regardless of which
/// service's Dio instance this interceptor is attached to.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final String _authBaseUrl;
  bool _isRefreshing = false;

  /// Paths that should NOT have a Bearer token attached.
  /// These are auth-flow endpoints that use different credentials.
  static final List<String> _skipAuthPaths = [
    AuthEndpoints.sendCode,
    AuthEndpoints.verifyCode,
    AuthEndpoints.refresh,
    AuthEndpoints.jwks,
  ];

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required String authBaseUrl,
  }) : _secureStorage = secureStorage,
       _authBaseUrl = authBaseUrl;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Always include the persistent device ID for stable server-side fingerprinting
    try {
      final deviceId = await _secureStorage.getDeviceId();
      options.headers['X-Device-Id'] = deviceId;
    } catch (_) {
      // Non-fatal: proceed without device ID
    }

    // Skip auth header for auth-flow endpoints
    final isAuthEndpoint = _skipAuthPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isAuthEndpoint) {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only attempt refresh on 401 responses
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      // Create a one-off Dio to call the auth service refresh endpoint.
      // This ensures the refresh call always targets the auth service
      // regardless of which service's client triggered the 401.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _authBaseUrl,
          connectTimeout: ApiConfig.connectionTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      );

      final deviceId = await _secureStorage.getDeviceId();

      final response = await refreshDio.post(
        AuthEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'X-Device-Id': deviceId}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;

        // Persist new tokens
        await _secureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request with the fresh token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        _isRefreshing = false;

        // Use a fresh Dio for the retry to avoid interceptor loops
        final retryDio = Dio();
        final retryResponse = await retryDio.fetch(opts);
        return handler.resolve(retryResponse);
      }
    } catch (e) {
      // Refresh failed — clear tokens (forces re-login)
      debugPrint('Token refresh failed: $e');
      await _secureStorage.clearAll();
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }
}

/// Logging interceptor for debug mode.
///
/// Logs request/response details to the debug console.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 REQUEST[${options.method}] => ${options.uri}');
    debugPrint('Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
    );
    debugPrint('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '❌ ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}',
    );
    debugPrint('Message: ${err.message}');
    debugPrint('Response: ${err.response?.data}');
    handler.next(err);
  }
}
