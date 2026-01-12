/// Success Step
/// 
/// Final step in auth flow - animated welcome message.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_flow_provider.dart';
import '../../../../core/theme/theme.dart';

/// Success step widget with welcome animation
class SuccessStep extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const SuccessStep({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<SuccessStep> createState() => _SuccessStepState();
}

class _SuccessStepState extends ConsumerState<SuccessStep>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _textController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Check mark animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations in sequence
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    
    _checkController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    _textController.forward();
    
    // Auto-close after animation completes
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    
    widget.onComplete();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authFlowProvider);
    final user = flowState.user;
    
    // Determine display name: prefer user firstName, then displayName,
    // then derive from contact (email: part before @, phone: user+digits)
    String getDisplayName() {
      if (user?.firstName != null && user!.firstName!.isNotEmpty) {
        return user.firstName!;
      }
      if (user?.displayName != null && user!.displayName.isNotEmpty) {
        return user.displayName;
      }
      // Fallback to deriving from contact
      final contact = flowState.contact;
      if (contact.contains('@')) {
        return contact.split('@').first;
      }
      // Phone number: extract digits only and create "user" + digits format
      final digitsOnly = contact.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isNotEmpty) {
        return 'user$digitsOnly';
      }
      return 'there';
    }
    
    final displayName = getDisplayName();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated check mark
          AnimatedBuilder(
            animation: _checkController,
            builder: (context, child) {
              return Opacity(
                opacity: _checkOpacity.value,
                child: Transform.scale(
                  scale: _checkScale.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.green,
                          AppColors.greenLight,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Animated welcome text
          AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacity.value,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome${flowState.isNewUser ? '' : ' back'},',
                        style: AppTypography.bodyLarge(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$displayName!',
                        style: AppTypography.h3(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (flowState.isNewUser) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "Your account has been created.",
                          style: AppTypography.bodyMedium(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
