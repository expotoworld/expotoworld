import 'user.dart';

/// Authentication state enumeration
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  awaitingVerification,
}

/// Authentication state model
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;
  // When awaiting verification, one of these will be populated
  final String? pendingEmail;
  final String? pendingPhone;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
    this.pendingEmail,
    this.pendingPhone,
  });

  /// Initial state
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  /// Loading state
  const AuthState.loading() : this(status: AuthStatus.loading);

  /// Authenticated state
  const AuthState.authenticated({
    required User user,
    required String token,
  }) : this(
          status: AuthStatus.authenticated,
          user: user,
          token: token,
        );

  /// Awaiting verification state
  const AuthState.awaitingVerification({String? email, String? phone})
      : this(
          status: AuthStatus.awaitingVerification,
          pendingEmail: email,
          pendingPhone: phone,
        );

  /// Unauthenticated state
  const AuthState.unauthenticated({String? errorMessage})
      : this(
          status: AuthStatus.unauthenticated,
          errorMessage: errorMessage,
        );

  /// Check if user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Check if authentication is loading
  bool get isLoading => status == AuthStatus.loading;

  /// Check if user is unauthenticated
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Copy with new values
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
    String? pendingEmail,
    String? pendingPhone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingPhone: pendingPhone ?? this.pendingPhone,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.email}, hasToken: ${token != null}, pendingEmail: $pendingEmail, pendingPhone: $pendingPhone)';
  }
}

/// Signup request model
class SignupRequest {
  final String username;
  final String email;
  final String password;
  final String? phone;
  final String? firstName;
  final String? lastName;

  SignupRequest({
    required this.username,
    required this.email,
    required this.password,
    this.phone,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'password': password,
    };

    if (phone != null) data['phone'] = phone;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;

    return data;
  }
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Authentication response model
class AuthResponse {
  final String token;
  final String? refreshToken;
  final User user;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
    );
  }
}

/// Error response model
class AuthErrorResponse {
  final String error;
  final String? message;

  AuthErrorResponse({
    required this.error,
    this.message,
  });

  factory AuthErrorResponse.fromJson(Map<String, dynamic> json) {
    return AuthErrorResponse(
      error: json['error'],
      message: json['message'],
    );
  }

  @override
  String toString() {
    return message ?? error;
  }
}

/// Profile response model for token validation
class ProfileResponse {
  final String userId;
  final String? email;
  final String message;

  ProfileResponse({
    required this.userId,
    this.email,
    required this.message,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      userId: json['user_id'] as String,
      email: json['email'] as String?,
      message: json['message'] as String,
    );
  }
}
