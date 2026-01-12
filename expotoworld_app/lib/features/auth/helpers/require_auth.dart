/// Require Auth Helper
/// 
/// Helper function to protect actions that require authentication.
/// Shows the auth dialog if user is not authenticated.
library;

export '../../../data/models/auth/user_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/auth/user_model.dart';
import '../presentation/widgets/auth_dialog.dart';

/// Execute an action that requires authentication.
/// 
/// If user is authenticated, executes the [action] immediately.
/// If not authenticated, shows the auth dialog first.
/// Returns false if user cancelled auth or action failed.
/// 
/// Example:
/// ```dart
/// await requireAuth(context, ref, () async {
///   // Navigate to checkout
///   context.push('/checkout');
/// });
/// ```
Future<bool> requireAuth(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  
  if (isAuthenticated) {
    await action();
    return true;
  }
  
  // Show auth dialog
  final result = await showAuthDialog(context);
  
  if (result) {
    // User authenticated successfully, execute action
    await action();
    return true;
  }
  
  // User cancelled auth
  return false;
}

/// Synchronous check if user is authenticated, shows dialog if not.
/// 
/// Returns true if user is authenticated (or successfully authenticated).
/// Returns false if user cancelled.
/// 
/// Example:
/// ```dart
/// final canProceed = await checkAuth(context, ref);
/// if (canProceed) {
///   // Do something that needs auth
/// }
/// ```
Future<bool> checkAuth(BuildContext context, WidgetRef ref) async {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  
  if (isAuthenticated) {
    return true;
  }
  
  return showAuthDialog(context);
}

/// Extension on WidgetRef for easier auth checks
extension AuthRefExtension on WidgetRef {
  /// Check if user is currently authenticated
  bool get isAuthenticated => read(isAuthenticatedProvider);
  
  /// Get current user or null
  UserModel? get currentUser => read(currentUserProvider);
}
