/// OTP Input Step
/// 
/// Second step in auth flow - enter the 6-digit verification code.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/providers/auth_flow_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/buttons.dart';

/// OTP input step widget
class OtpInputStep extends ConsumerStatefulWidget {
  const OtpInputStep({super.key});

  @override
  ConsumerState<OtpInputStep> createState() => _OtpInputStepState();
}

class _OtpInputStepState extends ConsumerState<OtpInputStep> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    await ref.read(authFlowProvider.notifier).verifyCode(code);
  }

  Future<void> _resend() async {
    await ref.read(authFlowProvider.notifier).resendCode();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authFlowProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pin themes
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: AppTypography.h3(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: AppColors.themeRed,
          width: 2,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.themeRed.withValues(alpha: 0.05),
        border: Border.all(
          color: AppColors.themeRed.withValues(alpha: 0.3),
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: AppColors.themeRed,
          width: 2,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,  // Top padding to clear close button
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title (unified for both email and phone)
          Text(
            'Verify Code',
            style: AppTypography.h4(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Subtitle with contact
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.bodyMedium(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                TextSpan(
                  text: flowState.contact,
                  style: AppTypography.bodyMedium(
                    color: AppColors.themeRed,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          // OTP Input
          Center(
            child: Pinput(
              controller: _otpController,
              focusNode: _focusNode,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              errorPinTheme: errorPinTheme,
              forceErrorState: flowState.error != null,
              pinputAutovalidateMode: PinputAutovalidateMode.disabled,
              showCursor: true,
              cursor: Container(
                width: 2,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.themeRed,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              onCompleted: _verify,
              onChanged: (_) {
                // Clear error when user types
                if (flowState.error != null) {
                  ref.read(authFlowProvider.notifier).reset();
                }
              },
            ),
          ),
          
          // Error message
          if (flowState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              flowState.error!,
              style: AppTypography.bodySmall(color: AppColors.themeRed),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: AppSpacing.xl),
          
          // Verify button
          PrimaryButton(
            label: 'Verify',
            isLoading: flowState.isLoading,
            isFullWidth: true,
            onPressed: flowState.isLoading || _otpController.text.length != 6
                ? null
                : () => _verify(_otpController.text),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Resend code
          _ResendCodeButton(
            countdown: flowState.resendCountdown,
            isLoading: flowState.isLoading,
            onResend: _resend,
          ),
        ],
      ),
    );
  }
}

/// Resend code button with countdown
class _ResendCodeButton extends StatelessWidget {
  final int countdown;
  final bool isLoading;
  final VoidCallback onResend;

  const _ResendCodeButton({
    required this.countdown,
    required this.isLoading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = countdown == 0 && !isLoading;

    return Center(
      child: GestureDetector(
        onTap: canResend ? onResend : null,
        child: RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            children: [
              const TextSpan(text: "Didn't receive the code? "),
              if (countdown > 0)
                TextSpan(
                  text: 'Resend in ${countdown}s',
                  style: AppTypography.bodyMedium(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                TextSpan(
                  text: 'Resend',
                  style: AppTypography.bodyMedium(
                    color: AppColors.themeRed,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
