/// Auth Flow Provider
/// 
/// Manages the state of the authentication modal dialog.
/// Handles steps: contact input → OTP verification → success
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/auth/auth.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_provider.dart';

/// Auth flow step enumeration
enum AuthFlowStep {
  /// Initial step: enter email or phone
  contactInput,
  
  /// OTP verification step
  otpVerification,
  
  /// Success step with welcome animation
  success,
}

/// Contact type (email or phone)
enum ContactType {
  email,
  phone;

  String get label {
    switch (this) {
      case ContactType.email:
        return 'Email';
      case ContactType.phone:
        return 'Phone';
    }
  }

  String get placeholder {
    switch (this) {
      case ContactType.email:
        return 'Enter your email address';
      case ContactType.phone:
        return 'Enter your phone number';
    }
  }

  String get icon {
    switch (this) {
      case ContactType.email:
        return '📧';
      case ContactType.phone:
        return '📱';
    }
  }
}

/// Auth flow state
class AuthFlowState {
  /// Current step in the flow
  final AuthFlowStep step;

  /// Selected contact type (email or phone)
  final ContactType contactType;

  /// Contact value (email or phone number)
  final String contact;

  /// Whether an operation is in progress
  final bool isLoading;

  /// Error message if any
  final String? error;

  /// Authenticated user (after success)
  final UserModel? user;

  /// Whether this is a new user
  final bool isNewUser;

  /// OTP resend countdown (seconds)
  final int resendCountdown;

  const AuthFlowState({
    this.step = AuthFlowStep.contactInput,
    this.contactType = ContactType.email,
    this.contact = '',
    this.isLoading = false,
    this.error,
    this.user,
    this.isNewUser = false,
    this.resendCountdown = 0,
  });

  /// Check if resend is available
  bool get canResend => resendCountdown == 0;

  /// Copy with updated fields
  AuthFlowState copyWith({
    AuthFlowStep? step,
    ContactType? contactType,
    String? contact,
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isNewUser,
    int? resendCountdown,
  }) {
    return AuthFlowState(
      step: step ?? this.step,
      contactType: contactType ?? this.contactType,
      contact: contact ?? this.contact,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isNewUser: isNewUser ?? this.isNewUser,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }

  @override
  String toString() {
    return 'AuthFlowState(step: $step, contact: $contact, isLoading: $isLoading)';
  }
}

/// Auth flow notifier - manages the modal dialog state
final authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlowState>(() {
  return AuthFlowNotifier();
});

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  Timer? _countdownTimer;

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  AuthNotifier get _authNotifier => ref.read(authProvider.notifier);

  @override
  AuthFlowState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    
    return const AuthFlowState();
  }

  /// Reset flow to initial state
  void reset() {
    _countdownTimer?.cancel();
    state = const AuthFlowState();
  }

  /// Switch contact type (email/phone)
  void setContactType(ContactType type) {
    state = state.copyWith(
      contactType: type,
      contact: '',
      error: null,
    );
  }

  /// Send OTP code to contact
  Future<bool> sendCode(String contact) async {
    state = state.copyWith(
      contact: contact,
      isLoading: true,
      error: null,
    );

    try {
      final success = await _repository.sendCode(contact: contact);
      
      if (success) {
        state = state.copyWith(
          step: AuthFlowStep.otpVerification,
          isLoading: false,
        );
        _startResendCountdown();
        
        developer.log('OTP sent to: $contact', name: 'AuthFlowNotifier');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to send verification code. Please try again.',
        );
        return false;
      }
    } catch (e) {
      developer.log('Send code error: $e', name: 'AuthFlowNotifier');
      
      String errorMessage = 'An error occurred. Please try again.';
      if (e.toString().contains('rate limit')) {
        errorMessage = 'Too many attempts. Please wait a moment and try again.';
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'Please enter a valid ${state.contactType.label.toLowerCase()}.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Resend OTP code
  Future<bool> resendCode() async {
    if (!state.canResend) return false;
    
    return sendCode(state.contact);
  }

  /// Verify OTP code
  Future<bool> verifyCode(String code) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final result = await _repository.verifyCode(
        contact: state.contact,
        code: code,
      );
      
      // Update global auth state
      await _authNotifier.onAuthSuccess(result);
      
      // Move to success step
      state = state.copyWith(
        step: AuthFlowStep.success,
        isLoading: false,
        user: result.user,
        isNewUser: result.isNewUser,
      );
      
      developer.log(
        'OTP verified, user: ${result.user.displayName}',
        name: 'AuthFlowNotifier',
      );
      
      return true;
    } catch (e) {
      developer.log('Verify code error: $e', name: 'AuthFlowNotifier');
      
      // Default error message for wrong code
      String errorMessage = 'Invalid verification code. Please try again.';
      
      // Check for specific error types
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('expired') && !errorStr.contains('invalid')) {
        // Only show expired if it's specifically about expiration, not a combined error
        errorMessage = 'Code expired. Please request a new one.';
      } else if (errorStr.contains('too many') || errorStr.contains('rate limit')) {
        errorMessage = 'Too many attempts. Please wait and try again.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Go back to contact input step
  void goBack() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      step: AuthFlowStep.contactInput,
      error: null,
      resendCountdown: 0,
    );
  }

  /// Start countdown for OTP resend
  void _startResendCountdown() {
    _countdownTimer?.cancel();
    
    const duration = 60; // 60 seconds cooldown
    state = state.copyWith(resendCountdown: duration);
    
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (state.resendCountdown > 0) {
          state = state.copyWith(
            resendCountdown: state.resendCountdown - 1,
          );
        } else {
          timer.cancel();
        }
      },
    );
  }
}

/// Provider to check if auth modal should be visible
/// This is typically controlled by the UI layer
final authModalVisibleProvider = StateProvider<bool>((ref) => false);
