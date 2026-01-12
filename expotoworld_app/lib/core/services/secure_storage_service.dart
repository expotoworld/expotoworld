/// Secure Storage Service
/// 
/// Wrapper around flutter_secure_storage for managing
/// authentication tokens and sensitive data.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Keys for secure storage
class _StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userPhone = 'user_phone';
  static const String userName = 'user_name';
  static const String userData = 'user_data';
}

/// Secure Storage Service
/// 
/// Provides secure storage for authentication tokens and user data.
/// Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android).
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    // Configure secure storage with appropriate options
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
    );
    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
  }

  // ============================================================
  // Token Management
  // ============================================================

  /// Save authentication tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiry,
  }) async {
    await Future.wait([
      _storage.write(key: _StorageKeys.accessToken, value: accessToken),
      _storage.write(key: _StorageKeys.refreshToken, value: refreshToken),
      if (expiry != null)
        _storage.write(
          key: _StorageKeys.tokenExpiry,
          value: expiry.toIso8601String(),
        ),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _StorageKeys.accessToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _StorageKeys.refreshToken);
  }

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: _StorageKeys.tokenExpiry);
    if (expiryString == null) return null;
    return DateTime.tryParse(expiryString);
  }

  /// Check if tokens exist
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.accessToken),
      _storage.delete(key: _StorageKeys.refreshToken),
      _storage.delete(key: _StorageKeys.tokenExpiry),
    ]);
  }

  // ============================================================
  // User Data Management
  // ============================================================

  /// Save complete user data as JSON
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _StorageKeys.userData, value: jsonString);
    
    // Also save individual fields for backward compatibility
    await saveUserData(
      userId: userData['id']?.toString() ?? '',
      email: userData['email'] as String?,
      phone: userData['phone'] as String?,
      name: userData['name'] as String?,
    );
  }

  /// Get complete user data as JSON
  Future<Map<String, dynamic>?> getUser() async {
    final jsonString = await _storage.read(key: _StorageKeys.userData);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Save user data (individual fields)
  Future<void> saveUserData({
    required String userId,
    String? email,
    String? phone,
    String? name,
  }) async {
    await Future.wait([
      _storage.write(key: _StorageKeys.userId, value: userId),
      if (email != null)
        _storage.write(key: _StorageKeys.userEmail, value: email),
      if (phone != null)
        _storage.write(key: _StorageKeys.userPhone, value: phone),
      if (name != null) _storage.write(key: _StorageKeys.userName, value: name),
    ]);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _StorageKeys.userId);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _StorageKeys.userEmail);
  }

  /// Get user phone
  Future<String?> getUserPhone() async {
    return await _storage.read(key: _StorageKeys.userPhone);
  }

  /// Get user name
  Future<String?> getUserName() async {
    return await _storage.read(key: _StorageKeys.userName);
  }

  /// Clear user data
  Future<void> clearUserData() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.userId),
      _storage.delete(key: _StorageKeys.userEmail),
      _storage.delete(key: _StorageKeys.userPhone),
      _storage.delete(key: _StorageKeys.userName),
    ]);
  }

  // ============================================================
  // Utility Methods
  // ============================================================

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if storage contains any data
  Future<bool> isEmpty() async {
    final all = await _storage.readAll();
    return all.isEmpty;
  }
}
