/// Auth Repository
/// 
/// Manages authentication business logic, coordinating between
/// API calls and local secure storage.
library;

import 'dart:developer' as developer;

import '../../core/api/api_client.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/jwt_service.dart';
import '../models/auth/auth.dart';
import '../sources/auth/auth_api.dart';

/// Authentication state
enum AuthStatus {
  /// Initial state, checking stored credentials
  initial,
  
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated (guest)
  unauthenticated,
}

/// Auth repository for managing authentication
class AuthRepository {
  final AuthApi _api;
  final SecureStorageService _storage;
  final JwtService _jwtService;

  AuthRepository({
    required AuthApi api,
    required SecureStorageService storage,
    required JwtService jwtService,
  })  : _api = api,
        _storage = storage,
        _jwtService = jwtService;

  /// Check current authentication status from stored tokens
  Future<(AuthStatus, UserModel?)> checkAuthStatus() async {
    try {
      final accessToken = await _storage.getAccessToken();
      
      if (accessToken == null) {
        developer.log('No access token found', name: 'AuthRepository');
        return (AuthStatus.unauthenticated, null);
      }

      // Decode and validate token
      final payload = _jwtService.decode(accessToken);
      
      if (payload == null) {
        developer.log('Failed to decode access token', name: 'AuthRepository');
        return (AuthStatus.unauthenticated, null);
      }
      
      if (payload.isExpired()) {
        developer.log('Access token expired, trying refresh', name: 'AuthRepository');
        
        // Try to refresh
        final refreshed = await _tryRefreshTokens();
        if (!refreshed) {
          return (AuthStatus.unauthenticated, null);
        }
        
        // Get fresh token
        final newToken = await _storage.getAccessToken();
        if (newToken == null) {
          return (AuthStatus.unauthenticated, null);
        }
        
        final newPayload = _jwtService.decode(newToken);
        if (newPayload == null) {
          return (AuthStatus.unauthenticated, null);
        }
        
        final user = _userFromPayload(newPayload);
        return (AuthStatus.authenticated, user);
      }

      final user = _userFromPayload(payload);
      developer.log('User authenticated: ${user.displayName}', name: 'AuthRepository');
      
      return (AuthStatus.authenticated, user);
    } catch (e) {
      developer.log('Auth check error: $e', name: 'AuthRepository', error: e);
      return (AuthStatus.unauthenticated, null);
    }
  }

  /// Send OTP code to contact (email or phone)
  Future<bool> sendCode({required String contact}) async {
    return _api.sendCode(contact: contact);
  }

  /// Verify OTP code and authenticate
  Future<AuthResult> verifyCode({
    required String contact,
    required String code,
  }) async {
    final result = await _api.verifyCode(contact: contact, code: code);
    
    // Store tokens
    await _storage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    
    // Store refresh token expiry for session tracking
    await _storage.saveRefreshTokenExpiry(result.tokens.refreshExpiresAt);
    
    // Store user data
    await _storage.saveUser(result.user.toJson());
    
    developer.log(
      'Auth successful: ${result.user.displayName}, refresh expires: ${result.tokens.refreshExpiresAt}',
      name: 'AuthRepository',
    );
    
    return result;
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    return _tryRefreshTokens();
  }

  /// Logout and clear all auth data
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken != null) {
        // Notify server (best effort)
        await _api.logout(refreshToken: refreshToken);
      }
    } catch (e) {
      developer.log('Logout API error: $e', name: 'AuthRepository');
    } finally {
      // Always clear local storage
      await _storage.clearAll();
      developer.log('Local auth data cleared', name: 'AuthRepository');
    }
  }

  /// Get current access token (for API requests)
  Future<String?> getAccessToken() async {
    final token = await _storage.getAccessToken();
    
    if (token == null) return null;
    
    final payload = _jwtService.decode(token);
    if (payload == null || payload.isExpired()) {
      // Try refresh
      final refreshed = await _tryRefreshTokens();
      if (!refreshed) return null;
      
      return _storage.getAccessToken();
    }
    
    return token;
  }

  /// Get stored user
  Future<UserModel?> getStoredUser() async {
    final userData = await _storage.getUser();
    if (userData == null) return null;
    
    try {
      return UserModel.fromJson(userData);
    } catch (e) {
      developer.log('Failed to parse stored user: $e', name: 'AuthRepository');
      return null;
    }
  }

  /// Update stored user data
  Future<void> updateUser(UserModel user) async {
    await _storage.saveUser(user.toJson());
  }

  // --- Private Methods ---

  /// Attempt to refresh tokens using stored refresh token
  Future<bool> _tryRefreshTokens() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      
      if (refreshToken == null) {
        developer.log('No refresh token available', name: 'AuthRepository');
        return false;
      }

      final newTokens = await _api.refreshToken(refreshToken: refreshToken);
      
      await _storage.saveTokens(
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
      );
      
      // Update refresh token expiry (sliding window — each refresh extends it)
      await _storage.saveRefreshTokenExpiry(newTokens.refreshExpiresAt);
      
      developer.log('Tokens refreshed successfully', name: 'AuthRepository');
      return true;
    } on ApiException catch (e) {
      developer.log('Token refresh failed: ${e.message}', name: 'AuthRepository');
      
      // If refresh failed, clear auth data
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _storage.clearAll();
      }
      
      return false;
    } catch (e) {
      developer.log('Token refresh error: $e', name: 'AuthRepository');
      return false;
    }
  }

  /// Create minimal user from JWT payload
  UserModel _userFromPayload(JwtPayload payload) {
    return UserModel.fromJwt(
      id: payload.userId,
      email: payload.email,
      phone: payload.phone,
      role: payload.role,
    );
  }
}
