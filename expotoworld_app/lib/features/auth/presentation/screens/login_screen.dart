import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Placeholder login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralDarkest : AppColors.neutralLightest,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPaddingH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.themeRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.public,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              // Title
              Text(
                AppLocalizations.of(context)!.authWelcomeBack,
                style: AppTypography.h2(
                  color: isDark ? AppColors.neutralLight : AppColors.neutralDarkest,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.authSignInToContinue,
                style: AppTypography.bodyMedium(
                  color: isDark ? AppColors.neutralMid : AppColors.neutralDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxxl),
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
              // Password field
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.authPassword,
                  hintText: AppLocalizations.of(context)!.authPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: const Icon(Icons.visibility_off_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: AppSpacing.sm),
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    AppLocalizations.of(context)!.authForgotPassword,
                    style: AppTypography.bodySmall(color: AppColors.themeRed),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              // Login button
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
                  AppLocalizations.of(context)!.authSignIn,
                  style: AppTypography.buttonLarge(color: Colors.white),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.authNoAccount,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.neutralMid : AppColors.neutralDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(RoutePaths.signup);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.authSignup,
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
