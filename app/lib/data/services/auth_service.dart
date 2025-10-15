import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

import '../../core/config/api_config.dart';

/// Authentication service for API communication with Go auth service
class AuthService {
  // Base is provided by ApiConfig (resolves --dart-define=API_BASE)
  // Use ApiConfig.baseUrl directly at call sites; no private field needed.

  // Timeout duration for HTTP requests
  static const Duration _timeout = Duration(seconds: 30);

  // HTTP client instance
  static final http.Client _client = http.Client();

  /// Common headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers with authorization token
  static Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  /// Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');

      debugPrint('AuthService: Checking health at $uri');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      debugPrint('AuthService: Health check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy';
      }

      return false;
    } catch (e) {
      debugPrint('AuthService: Health check failed: $e');
      return false;
    }
  }

  /// Send verification code to email (passwordless authentication)
  Future<void> sendVerificationCode(String email) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/send-verification');

      debugPrint('AuthService: Sending verification code to $email at $uri');

      final requestBody = {'email': email};

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('AuthService: Send verification response: ${response.statusCode}');
      debugPrint('AuthService: Send verification body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - verification code sent
        return;
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Send verification error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Verify email code and authenticate user (passwordless authentication)
  Future<AuthResponse> verifyEmailCode(String email, String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-code');

      debugPrint('AuthService: Verifying code for $email at $uri');

      final requestBody = {
        'email': email,
        'code': code,
      };

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('AuthService: Verify code response: ${response.statusCode}');
      debugPrint('AuthService: Verify code body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Verify code error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Send verification code to phone (passwordless authentication via SMS)
  Future<void> sendPhoneVerification(String phoneE164) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/send-phone-verification');
      debugPrint('AuthService: Sending phone verification to $phoneE164 at $uri');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({'phone': phoneE164}),
          )
          .timeout(_timeout);
      debugPrint('AuthService: Send phone verification response: ${response.statusCode}');
      debugPrint('AuthService: Body: ${response.body}');
      if (response.statusCode == 200) return;
      final errorData = json.decode(response.body);
      final error = AuthErrorResponse.fromJson(errorData);
      throw AuthException(error.toString(), response.statusCode);
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Send phone verification error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Verify phone code and authenticate user
  Future<AuthResponse> verifyPhoneCode(String phoneE164, String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-phone-code');
      debugPrint('AuthService: Verifying phone code for $phoneE164 at $uri');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({'phone': phoneE164, 'code': code}),
          )
          .timeout(_timeout);
      debugPrint('AuthService: Verify phone code response: ${response.statusCode}');
      debugPrint('AuthService: Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResponse.fromJson(data);
      }
      final errorData = json.decode(response.body);
      final error = AuthErrorResponse.fromJson(errorData);
      throw AuthException(error.toString(), response.statusCode);
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Verify phone code error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }


  /// Sign up a new user (DEPRECATED - use email verification instead)
  @Deprecated('Use sendVerificationCode and verifyEmailCode instead')
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/signup');

      debugPrint('AuthService: Signing up user at $uri (DEPRECATED)');
      debugPrint('AuthService: Request data: ${request.toJson()}');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(_timeout);

      debugPrint('AuthService: Signup response: ${response.statusCode}');
      debugPrint('AuthService: Signup body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Signup error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Log in an existing user (DEPRECATED - use email verification instead)
  @Deprecated('Use sendVerificationCode and verifyEmailCode instead')
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');

      debugPrint('AuthService: Logging in user at $uri (DEPRECATED)');
      debugPrint('AuthService: Request data: ${request.toJson()}');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(_timeout);

      debugPrint('AuthService: Login response: ${response.statusCode}');
      debugPrint('AuthService: Login body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Login error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Validate JWT token and get user profile (legacy). Some environments may not expose
  /// this endpoint. Prefer using refreshToken() for validation and renewal.
  Future<ProfileResponse> validateToken(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/protected/profile');
      debugPrint('AuthService: Validating token at $uri');
      final response = await _client.get(uri, headers: _authHeaders(token)).timeout(_timeout);
      debugPrint('AuthService: Token validation response: ${response.statusCode}');
      debugPrint('AuthService: Token validation body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Token validation error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Refresh JWT token. This both validates the current token and returns a new one when valid.
  /// Returns the new token string.
  Future<String> refreshToken(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh');
      debugPrint('AuthService: Refreshing token at $uri');
      final response = await _client
          .post(uri, headers: _authHeaders(token))
          .timeout(_timeout);
      debugPrint('AuthService: Refresh response: ${response.statusCode}');
      debugPrint('AuthService: Refresh body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String;
        return newToken;
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Token refresh error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }

  /// Refresh using a long-lived refresh token. Returns both new access and refresh tokens.
  Future<Map<String, String>> refreshWithRefreshToken(String refreshToken) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/token/refresh');
      debugPrint('AuthService: Refreshing using refresh token at $uri');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);
      debugPrint('AuthService: Refresh-with-refresh response: ${response.statusCode}');
      debugPrint('AuthService: Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = (data['token'] ?? data['access_token']) as String;
        final newRefresh = data['refresh_token'] as String;
        return {
          'token': token,
          'refresh_token': newRefresh,
        };
      } else {
        final errorData = json.decode(response.body);
        final error = AuthErrorResponse.fromJson(errorData);
        throw AuthException(error.toString(), response.statusCode);
      }
    } on SocketException {
      throw AuthException('No internet connection. Please check your network.', 0);
    } on HttpException {
      throw AuthException('Network error occurred. Please try again.', 0);
    } on FormatException {
      throw AuthException('Invalid response format from server.', 0);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('AuthService: Refresh-with-refresh error: $e');
      throw AuthException('An unexpected error occurred: $e', 0);
    }
  }


  /// Dispose of the HTTP client
  static void dispose() {
    _client.close();
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, this.statusCode);

  @override
  String toString() => message;

  /// Check if error is due to invalid credentials
  bool get isInvalidCredentials => statusCode == 401;

  /// Check if error is due to duplicate email
  bool get isDuplicateEmail => statusCode == 409;

  /// Check if error is due to network issues
  bool get isNetworkError => statusCode == 0;

  /// Check if error is due to server issues
  bool get isServerError => statusCode >= 500;
}
