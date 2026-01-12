/// JWT Service
/// 
/// Utilities for decoding and validating JWT tokens.
/// Note: This is client-side validation only - actual verification happens server-side.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// JWT Service Provider
final jwtServiceProvider = Provider<JwtService>((ref) {
  return JwtService();
});

/// JWT Payload data from access token
class JwtPayload {
  /// User ID (sub claim)
  final String userId;
  
  /// User email (if present)
  final String? email;
  
  /// User phone (if present)
  final String? phone;
  
  /// User role
  final String role;
  
  /// Token issuer
  final String issuer;
  
  /// Issued at timestamp
  final DateTime issuedAt;
  
  /// Expiration timestamp
  final DateTime expiresAt;

  JwtPayload({
    required this.userId,
    this.email,
    this.phone,
    required this.role,
    required this.issuer,
    required this.issuedAt,
    required this.expiresAt,
  });

  /// Check if token is expired (with optional buffer time)
  bool isExpired({Duration buffer = const Duration(minutes: 1)}) {
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }

  /// Get remaining time until expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Create from JWT claims map
  factory JwtPayload.fromClaims(Map<String, dynamic> claims) {
    return JwtPayload(
      userId: claims['sub'] as String,
      email: claims['email'] as String?,
      phone: claims['phone'] as String?,
      role: claims['role'] as String? ?? 'Customer',
      issuer: claims['iss'] as String? ?? '',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(
        ((claims['iat'] as num?) ?? 0).toInt() * 1000,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        ((claims['exp'] as num?) ?? 0).toInt() * 1000,
      ),
    );
  }

  @override
  String toString() {
    return 'JwtPayload(userId: $userId, email: $email, phone: $phone, role: $role, expiresAt: $expiresAt)';
  }
}

/// JWT Service for decoding and validating tokens
class JwtService {
  /// Decode a JWT token without verification
  /// 
  /// This is for client-side use only to extract user information.
  /// Actual token verification should happen server-side.
  JwtPayload? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode payload (second part)
      final payload = parts[1];
      final normalized = _normalizeBase64(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = json.decode(decoded) as Map<String, dynamic>;

      return JwtPayload.fromClaims(claims);
    } catch (e) {
      return null;
    }
  }

  /// Check if a token is expired
  /// 
  /// [buffer] adds time before actual expiration to account for latency
  bool isExpired(String token, {Duration buffer = const Duration(minutes: 1)}) {
    final payload = decode(token);
    if (payload == null) return true;
    return payload.isExpired(buffer: buffer);
  }

  /// Get user ID from token
  String? getUserId(String token) {
    return decode(token)?.userId;
  }

  /// Get user email from token
  String? getEmail(String token) {
    return decode(token)?.email;
  }

  /// Get user role from token
  String? getRole(String token) {
    return decode(token)?.role;
  }

  /// Get expiration time from token
  DateTime? getExpirationTime(String token) {
    return decode(token)?.expiresAt;
  }

  /// Calculate time until token expiration
  Duration? getTimeUntilExpiration(String token) {
    final payload = decode(token);
    if (payload == null) return null;
    return payload.remainingTime;
  }

  /// Normalize base64 string (handle URL-safe encoding)
  String _normalizeBase64(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    
    // Add padding if necessary
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Invalid base64 string');
    }
    
    return output;
  }
}
