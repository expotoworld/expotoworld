/// Auth API Source
/// 
/// Makes HTTP requests to the backend auth endpoints.
/// Handles send-code, verify-code, refresh, and logout operations.
library;

import 'dart:developer' as developer;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../models/auth/auth.dart';

/// Auth API data source for making auth requests
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Send OTP code to email or phone
  /// 
  /// Returns true if code was sent successfully.
  /// [contact] can be an email address or phone number (E.164 format).
  Future<bool> sendCode({required String contact}) async {
    try {
      developer.log('Sending OTP to: $contact', name: 'AuthApi');
      
      // Determine if contact is email or phone
      final isEmail = contact.contains('@');
      
      // Backend expects 'email' field for email, 'phone' field for phone
      final Map<String, dynamic> requestData;
      if (isEmail) {
        requestData = {'email': contact};
      } else {
        // Phone number should be in E.164 format (e.g., +15551234567)
        requestData = {'phone': contact};
      }
      
      final response = await _client.post(
        AuthEndpoints.sendCode,
        data: requestData,
      );

      final success = response.statusCode == 200;
      developer.log('Send code result: $success', name: 'AuthApi');
      
      return success;
    } on ApiException catch (e) {
      developer.log(
        'Send code error: ${e.message}',
        name: 'AuthApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Verify OTP code and get tokens
  /// 
  /// Returns [AuthTokens] on success.
  /// [contact] is the email/phone that received the code.
  /// [code] is the 6-digit OTP code.
  Future<AuthResult> verifyCode({
    required String contact,
    required String code,
  }) async {
    try {
      developer.log('Verifying OTP for: $contact', name: 'AuthApi');
      
      // Determine if contact is email or phone
      final isEmail = contact.contains('@');
      
      // Backend expects 'email' field for email, 'phone' field for phone
      final Map<String, dynamic> requestData;
      if (isEmail) {
        requestData = {
          'email': contact,
          'code': code,
        };
      } else {
        // Phone number in E.164 format
        requestData = {
          'phone': contact,
          'code': code,
        };
      }
      
      final response = await _client.post(
        AuthEndpoints.verifyCode,
        data: requestData,
      );

      final data = response.data as Map<String, dynamic>;
      
      // Parse tokens
      final tokens = AuthTokens.fromJson(data);
      
      // Parse user from response or create minimal user from JWT
      UserModel user;
      if (data['user'] != null) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        // Create minimal user from token claims
        user = UserModel.fromJwt(
          id: data['user_id'] as String? ?? '',
          email: contact.contains('@') ? contact : null,
          role: 'Customer',
        );
      }

      final isNewUser = data['is_new_user'] as bool? ?? false;

      developer.log(
        'Verify code success: ${user.displayName}, isNew: $isNewUser',
        name: 'AuthApi',
      );
      
      return AuthResult(
        tokens: tokens,
        user: user,
        isNewUser: isNewUser,
      );
    } on ApiException catch (e) {
      developer.log(
        'Verify code error: ${e.message}',
        name: 'AuthApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  /// 
  /// Returns new [AuthTokens] on success.
  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    try {
      developer.log('Refreshing access token', name: 'AuthApi');
      
      final response = await _client.post(
        AuthEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );

      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      
      developer.log('Token refresh success', name: 'AuthApi');
      
      return tokens;
    } on ApiException catch (e) {
      developer.log(
        'Refresh token error: ${e.message}',
        name: 'AuthApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Logout and invalidate tokens
  /// 
  /// Returns true if logout was successful.
  Future<bool> logout({required String refreshToken}) async {
    try {
      developer.log('Logging out', name: 'AuthApi');
      
      final response = await _client.post(
        AuthEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );

      final success = response.statusCode == 200;
      developer.log('Logout result: $success', name: 'AuthApi');
      
      return success;
    } on ApiException catch (e) {
      developer.log(
        'Logout error: ${e.message}',
        name: 'AuthApi',
        error: e,
      );
      // Don't rethrow for logout - still clear local state
      return false;
    }
  }
}
