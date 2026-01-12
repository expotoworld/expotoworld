/// Auth Modal Dialog
/// 
/// Center dialog for authentication flow.
/// Steps: Contact input → OTP verification → Success welcome
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_flow_provider.dart';
import '../../../../core/theme/theme.dart';
import 'contact_input_step.dart';
import 'otp_input_step.dart';
import 'success_step.dart';

/// Show the auth dialog
/// 
/// Returns true if authentication was successful.
Future<bool> showAuthDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true, // Allow closing by tapping outside
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => const AuthDialog(),
  );
  
  return result ?? false;
}

/// Auth dialog widget
class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
    
    // Reset flow state when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authFlowProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close({bool success = false}) async {
    // Don't proceed if already disposed
    if (!mounted) return;
    
    await _controller.reverse();
    if (mounted) {
      // Reset flow state before closing
      ref.read(authFlowProvider.notifier).reset();
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authFlowProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 420.0 : screenWidth * 0.9;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(AppSpacing.xl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: dialogWidth,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkCardGradient
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.98),
                                Colors.white.withValues(alpha: 0.92),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    // Use Column with MainAxisSize.min to shrink-wrap content
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stack allows header to float without pushing content down
                        Stack(
                          children: [
                            // Content layer (bottom)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildContent(flowState),
                            ),
                            
                            // Header layer (top) - floats over content
                            if (flowState.step != AuthFlowStep.success)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: _buildHeader(flowState),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthFlowState flowState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          // Back button (only on OTP step)
          if (flowState.step == AuthFlowStep.otpVerification)
            IconButton(
              onPressed: () {
                ref.read(authFlowProvider.notifier).goBack();
              },
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 48),
          
          const Spacer(),
          
          // Close button
          IconButton(
            onPressed: () => _close(),
            icon: Icon(
              Icons.close_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthFlowState flowState) {
    switch (flowState.step) {
      case AuthFlowStep.contactInput:
        return ContactInputStep(
          key: const ValueKey('contact'),
        );
      
      case AuthFlowStep.otpVerification:
        return OtpInputStep(
          key: const ValueKey('otp'),
        );
      
      case AuthFlowStep.success:
        return SuccessStep(
          key: const ValueKey('success'),
          onComplete: () => _close(success: true),
        );
    }
  }
}
