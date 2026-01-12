/// Auth Tokens Model
/// 
/// Represents the authentication tokens returned from the API.
library;

/// Authentication tokens response from API
class AuthTokens {
  /// JWT access token for API requests
  final String accessToken;

  /// Refresh token for obtaining new access tokens
  final String refreshToken;

  /// Token type (always "Bearer")
  final String tokenType;

  /// Expiration time in seconds from now
  final int expiresIn;

  /// Calculated expiration timestamp
  final DateTime expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? DateTime.now().add(Duration(seconds: expiresIn));

  /// Create from JSON response
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 900, // Default 15 min
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }

  /// Check if token is expired (with buffer)
  bool isExpired({Duration buffer = const Duration(minutes: 1)}) {
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }

  /// Get remaining time until expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  @override
  String toString() {
    return 'AuthTokens(tokenType: $tokenType, expiresIn: ${expiresIn}s)';
  }
}
