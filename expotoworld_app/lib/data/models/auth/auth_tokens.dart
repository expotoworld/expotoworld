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

  /// Expiration time in seconds from now (access token)
  final int expiresIn;

  /// Refresh token expiration time in seconds from now
  final int? refreshExpiresIn;

  /// Refresh token absolute expiration (ISO 8601 from backend)
  final String? refreshExpiresAtRaw;

  /// Calculated access token expiration timestamp
  final DateTime expiresAt;

  /// Calculated refresh token expiration timestamp
  final DateTime refreshExpiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    this.refreshExpiresIn,
    this.refreshExpiresAtRaw,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
  })  : expiresAt = expiresAt ?? DateTime.now().add(Duration(seconds: expiresIn)),
        refreshExpiresAt = refreshExpiresAt ??
            (refreshExpiresAtRaw != null
                ? (DateTime.tryParse(refreshExpiresAtRaw) ??
                    DateTime.now().add(const Duration(days: 90)))
                : (refreshExpiresIn != null
                    ? DateTime.now().add(Duration(seconds: refreshExpiresIn))
                    : DateTime.now().add(const Duration(days: 90))));

  /// Create from JSON response
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 900, // Default 15 min
      refreshExpiresIn: json['refresh_expires_in'] as int?,
      refreshExpiresAtRaw: json['refresh_expires_at'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      if (refreshExpiresIn != null) 'refresh_expires_in': refreshExpiresIn,
      if (refreshExpiresAtRaw != null) 'refresh_expires_at': refreshExpiresAtRaw,
    };
  }

  /// Check if access token is expired (with buffer)
  bool isExpired({Duration buffer = const Duration(minutes: 1)}) {
    return DateTime.now().add(buffer).isAfter(expiresAt);
  }

  /// Check if refresh token is expired
  bool isRefreshExpired() {
    return DateTime.now().isAfter(refreshExpiresAt);
  }

  /// Get remaining time until access token expiration
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Get remaining time until refresh token expiration
  Duration get refreshRemainingTime => refreshExpiresAt.difference(DateTime.now());

  @override
  String toString() {
    return 'AuthTokens(tokenType: $tokenType, expiresIn: ${expiresIn}s, refreshExpiresAt: $refreshExpiresAt)';
  }
}
