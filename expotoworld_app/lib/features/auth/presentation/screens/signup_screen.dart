import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Placeholder signup screen
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralDarkest : AppColors.neutralLightest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.neutralLight : AppColors.neutralDarkest,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                AppLocalizations.of(context)!.authCreateAccount,
                style: AppTypography.h2(
                  color: isDark ? AppColors.neutralLight : AppColors.neutralDarkest,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.authJoinMadeInWorld,
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.neutralMid : AppColors.neutralDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxxl),
              // Name field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authFullName,
                  hintText: AppLocalizations.of(context)!.authFullNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              // Email field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authEmail,
                  hintText: AppLocalizations.of(context)!.authEmailHint,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSpacing.lg),
              // Phone field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authPhone,
                  hintText: AppLocalizations.of(context)!.authPhoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: AppSpacing.lg),
              // Password field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authPassword,
                  hintText: AppLocalizations.of(context)!.authPasswordCreateHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: AppSpacing.lg),
              // Confirm password field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authConfirmPassword,
                  hintText: AppLocalizations.of(context)!.authConfirmPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: AppSpacing.xxl),
              // Terms checkbox
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                    activeColor: AppColors.themeRed,
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: AppLocalizations.of(context)!.authAgreeToTerms,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.neutralMid : AppColors.neutralDark,
                        ),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context)!.authTermsOfService,
                            style: AppTypography.bodySmall(color: AppColors.themeRed),
                          ),
                          TextSpan(text: AppLocalizations.of(context)!.authAnd),
                          TextSpan(
                            text: AppLocalizations.of(context)!.authPrivacyPolicy,
                            style: AppTypography.bodySmall(color: AppColors.themeRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              // Sign up button
              ElevatedButton(
                onPressed: () {
                  // Navigate to home
                  context.go(RoutePaths.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.themeRed,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.authCreateAccount,
                  style: AppTypography.buttonLarge(color: Colors.white),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.authAlreadyHaveAccount,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.neutralMid : AppColors.neutralDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.authSignIn,
                      style: AppTypography.bodySmall(color: AppColors.themeRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
