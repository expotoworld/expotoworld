/// Auth Result Model
/// 
/// Represents the result of a successful authentication.
library;

import 'auth_tokens.dart';
import 'user_model.dart';

/// Result of successful authentication
class AuthResult {
  /// Authentication tokens
  final AuthTokens tokens;

  /// User information (may be minimal from JWT)
  final UserModel user;

  /// Whether this is a newly created user
  final bool isNewUser;

  AuthResult({
    required this.tokens,
    required this.user,
    this.isNewUser = false,
  });

  @override
  String toString() {
    return 'AuthResult(user: ${user.displayName}, isNewUser: $isNewUser)';
  }
}
