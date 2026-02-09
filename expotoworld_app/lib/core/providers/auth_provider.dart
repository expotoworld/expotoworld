/// Auth Provider
/// 
/// Manages global authentication state using Riverpod.
/// Handles login, logout, and token refresh operations.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth/auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/sources/auth/auth_api.dart';
import '../../core/api/api_client.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/jwt_service.dart';

/// Auth state representing current authentication status
sealed class AuthState {
  const AuthState();
}

/// Initial loading state while checking stored credentials
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with user data
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

/// Unauthenticated state (guest mode)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Auth error state
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// --- Providers ---

/// Secure storage service provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
});

/// Auth API provider
final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(secureStorageProvider);
  final jwtService = ref.watch(jwtServiceProvider);
  return AuthRepository(api: api, storage: storage, jwtService: jwtService);
});

/// Main auth state provider - manages global auth state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Auth state notifier
class AuthNotifier extends Notifier<AuthState> {
  Timer? _refreshTimer;
  _LifecycleObserver? _lifecycleObserver;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Set up lifecycle observer for app resume recovery
    _lifecycleObserver = _LifecycleObserver(onResumed: _onAppResumed);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    // Clean up timer and lifecycle observer on dispose
    ref.onDispose(() {
      _refreshTimer?.cancel();
      if (_lifecycleObserver != null) {
        WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
      }
    });

    // Check initial auth status
    _checkAuthStatus();
    
    return const AuthInitial();
  }

  /// Check current authentication status from stored tokens
  Future<void> _checkAuthStatus() async {
    try {
      final (status, user) = await _repository.checkAuthStatus();
      
      switch (status) {
        case AuthStatus.authenticated:
          state = AuthAuthenticated(user!);
          _scheduleTokenRefresh();
          break;
        case AuthStatus.unauthenticated:
        case AuthStatus.initial:
          state = const AuthUnauthenticated();
          break;
      }
    } catch (e) {
      developer.log('Auth check error: $e', name: 'AuthNotifier');
      state = const AuthUnauthenticated();
    }
  }

  /// Handle successful authentication
  Future<void> onAuthSuccess(AuthResult result) async {
    state = AuthAuthenticated(result.user);
    _scheduleTokenRefresh();
    
    developer.log(
      'User authenticated: ${result.user.displayName}',
      name: 'AuthNotifier',
    );
  }

  /// Logout user
  Future<void> logout() async {
    _refreshTimer?.cancel();
    
    try {
      await _repository.logout();
    } finally {
      state = const AuthUnauthenticated();
    }
    
    developer.log('User logged out', name: 'AuthNotifier');
  }

  /// Update user data (e.g., after profile update)
  Future<void> updateUser(UserModel user) async {
    if (state is AuthAuthenticated) {
      await _repository.updateUser(user);
      state = AuthAuthenticated(user);
    }
  }

  /// Schedule token refresh before expiration
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    
    // Refresh 1 minute before expiration (token expires in 15 min)
    const refreshInterval = Duration(minutes: 13);
    
    _refreshTimer = Timer(refreshInterval, () async {
      developer.log('Scheduled token refresh triggered', name: 'AuthNotifier');
      
      final success = await _repository.refreshAccessToken();
      
      if (success) {
        _scheduleTokenRefresh();
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  /// Called when app returns to foreground — Instagram-like recovery
  Future<void> _onAppResumed() async {
    if (state is! AuthAuthenticated) return;

    developer.log('App resumed — checking token freshness', name: 'AuthNotifier');

    final storage = ref.read(secureStorageProvider);
    final jwtService = ref.read(jwtServiceProvider);

    // First check if the refresh token itself has expired
    final refreshExpiry = await storage.getRefreshTokenExpiry();
    if (refreshExpiry != null && DateTime.now().isAfter(refreshExpiry)) {
      developer.log(
        'Refresh token expired (${refreshExpiry.toIso8601String()}) — logging out',
        name: 'AuthNotifier',
      );
      state = const AuthUnauthenticated();
      await _repository.logout();
      return;
    }

    // Check if access token is expired or about to expire (< 2 min remaining)
    final accessToken = await storage.getAccessToken();
    if (accessToken == null) {
      developer.log('No access token found on resume — logging out', name: 'AuthNotifier');
      state = const AuthUnauthenticated();
      return;
    }

    final isExpired = jwtService.isExpired(accessToken, buffer: Duration.zero);
    final remaining = jwtService.getTimeUntilExpiration(accessToken);
    final needsRefresh = isExpired || (remaining != null && remaining.inMinutes < 2);

    if (needsRefresh) {
      developer.log(
        'Token expired or expiring soon (remaining: ${remaining?.inSeconds}s) — refreshing',
        name: 'AuthNotifier',
      );
      final success = await _repository.refreshAccessToken();

      if (success) {
        _scheduleTokenRefresh();
      } else {
        state = const AuthUnauthenticated();
      }
    } else {
      // Token still valid — reschedule timer (may have been killed in background)
      _scheduleTokenRefresh();
    }
  }

  /// Get current user if authenticated
  UserModel? get currentUser {
    final s = state;
    if (s is AuthAuthenticated) {
      return s.user;
    }
    return null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state is AuthAuthenticated;
}

/// Provider to easily check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Provider to get current user (null if not authenticated)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Lifecycle observer that triggers token refresh when app resumes from background.
/// This ensures session continuity after the app has been suspended — 
/// the 13-minute Timer gets killed by the OS in background, so on resume
/// we immediately check freshness and refresh if needed.
class _LifecycleObserver extends WidgetsBindingObserver {
  final Future<void> Function() onResumed;

  _LifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed(); // fire-and-forget — didChangeAppLifecycleState is void
    }
  }
}
