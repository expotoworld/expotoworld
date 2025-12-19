import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/providers/locale_provider.dart' show localeProvider, AppLanguage;
import '../../../../../shared/widgets/language_flag.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';

/// Account Settings screen with user details and payment information
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  // Example user data (will be dynamic when connected to backend)
  static const String _username = 'soleyonghaosong2003isthebest!?';
  static const String _email = 'solesong2003@gmail.com';
  static const String _phoneNumber = ''; // Empty means "Not Provided"

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Get localized strings
    final l10n = AppLocalizations.of(context)!;

    // Get theme display text
    String themeText;
    switch (themeMode) {
      case ThemeMode.dark:
        themeText = l10n.accountSettingsThemeDark;
        break;
      case ThemeMode.light:
        themeText = l10n.accountSettingsThemeLight;
        break;
      case ThemeMode.system:
        themeText = l10n.accountSettingsThemeSystem;
        break;
    }

    // Get language display text using AppLanguage enum (native name)
    final languageText = AppLanguage.values
        .firstWhere(
          (lang) => lang.locale.languageCode == locale.languageCode,
          orElse: () => AppLanguage.english,
        )
        .nativeName;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.accountSettingsTitle,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, // Increased padding for more space
              vertical: AppSpacing.md,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Your Details section
                _buildSectionHeader(l10n.accountSettingsYourDetails, isDark),
                SizedBox(height: AppSpacing.xxxl), // Increased spacing between title and items (32px)

                // Username
                _buildDetailItem(
                  context: context,
                  isDark: isDark,
                  label: l10n.accountSettingsUsername,
                  value: _username,
                  onEdit: () {
                    // Handle edit username
                  },
                ),
                SizedBox(height: AppSpacing.xxl), // Increased spacing between items (24px)

                // Email
                _buildDetailItem(
                  context: context,
                  isDark: isDark,
                  label: l10n.accountSettingsEmail,
                  value: _email,
                  onEdit: () {
                    // Handle edit email
                  },
                ),
                SizedBox(height: AppSpacing.xxl), // Increased spacing between items (24px)

                // Phone Number
                _buildDetailItem(
                  context: context,
                  isDark: isDark,
                  label: l10n.accountSettingsPhoneNumber,
                  value: _phoneNumber.isEmpty ? l10n.accountSettingsNotProvided : _phoneNumber,
                  onEdit: () {
                    // Handle edit phone
                  },
                ),
                SizedBox(height: AppSpacing.xxl), // Increased spacing between items (24px)

                // Language
                _buildDetailItem(
                  context: context,
                  isDark: isDark,
                  label: l10n.accountSettingsLanguage,
                  value: languageText,
                  onEdit: () {
                    _showLanguageSelector(context, ref, isDark);
                  },
                ),
                SizedBox(height: AppSpacing.xxl), // Increased spacing between items (24px)

                // Theme
                _buildDetailItem(
                  context: context,
                  isDark: isDark,
                  label: l10n.accountSettingsTheme,
                  value: themeText,
                  onEdit: () {
                    _showThemeSelector(context, ref, isDark, themeMode);
                  },
                ),

                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Divider(
                    color: isDark
                        ? AppColors.neutralGray700
                        : AppColors.neutralGray300,
                    thickness: 1,
                  ),
                ),

                // Payment Details section
                _buildSectionHeader(l10n.accountSettingsPaymentDetails, isDark),
                SizedBox(height: AppSpacing.xxxl), // Increased spacing between title and items (32px)

                // Payment methods
                _buildNavigationItem(
                  context: context,
                  isDark: isDark,
                  title: l10n.accountSettingsPaymentMethods,
                  onTap: () {
                    // Navigate to payment methods
                  },
                ),
                SizedBox(height: AppSpacing.md), // Keep original spacing for payment items (12px)

                // Your transactions
                _buildNavigationItem(
                  context: context,
                  isDark: isDark,
                  title: l10n.accountSettingsYourTransactions,
                  onTap: () {
                    // Navigate to transactions
                  },
                ),
                SizedBox(height: AppSpacing.md), // Keep original spacing for payment items (12px)

                // Your orders
                _buildNavigationItem(
                  context: context,
                  isDark: isDark,
                  title: l10n.accountSettingsYourOrders,
                  onTap: () {
                    // Navigate to orders
                  },
                ),

                // Buffer space at bottom (comfortable spacing above nav bar)
                SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Section header with bold text
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// Detail item with label, value, and Edit button
  Widget _buildDetailItem({
    required BuildContext context,
    required bool isDark,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                label,
                style: AppTypography.bodyMedium().copyWith(
                  color: isDark
                      ? AppColors.neutralWhite
                      : AppColors.neutralBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              // Value - same color as label but smaller and lighter weight
              Text(
                value,
                style: AppTypography.bodySmall().copyWith(
                  color: isDark
                      ? AppColors.neutralGray400
                      : AppColors.neutralGray600,
                ),
              ),
            ],
          ),
        ),
        // Edit button - same color as label text (Username, Email, etc.)
        GestureDetector(
          onTap: onEdit,
          child: Text(
            AppLocalizations.of(context)!.accountSettingsEdit,
            style: AppTypography.bodyMedium().copyWith(
              color: isDark
                  ? AppColors.neutralWhite
                  : AppColors.neutralBlack,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: isDark
                  ? AppColors.neutralWhite
                  : AppColors.neutralBlack,
            ),
          ),
        ),
      ],
    );
  }

  /// Navigation item for payment section
  Widget _buildNavigationItem({
    required BuildContext context,
    required bool isDark,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium().copyWith(
                  color:
                      isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.neutralGray500
                  : AppColors.neutralGray400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Show language selector popup - matching home screen style
  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final currentLocale = ref.watch(localeProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    AppLocalizations.of(context)!.accountSettingsSelectLanguage,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Language options - scrollable
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
                      itemCount: AppLanguage.values.length,
                      itemBuilder: (context, index) {
                        final lang = AppLanguage.values[index];
                        final isSelected = currentLocale.languageCode == lang.locale.languageCode;
                        return _buildLanguageOption(
                          context: context,
                          lang: lang,
                          isSelected: isSelected,
                          isDark: isDark,
                          ref: ref,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Language option item - matching home screen style
  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLanguage lang,
    required bool isSelected,
    required bool isDark,
    required WidgetRef ref,
  }) {
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(lang.locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected
              ? Border.all(color: AppColors.themeRed.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            LanguageFlag(
              language: lang,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: AppTypography.bodyMedium().copyWith(
                      color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    lang.englishName,
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.themeRed,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }

  /// Show theme selector popup - matching home screen style
  void _showThemeSelector(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeMode currentMode,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    AppLocalizations.of(context)!.accountSettingsSelectTheme,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Theme options
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    isDark: isDark,
                    mode: ThemeMode.light,
                    label: AppLocalizations.of(context)!.accountSettingsThemeLight,
                    icon: Icons.wb_sunny_outlined,
                    currentMode: currentMode,
                  ),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    isDark: isDark,
                    mode: ThemeMode.dark,
                    label: AppLocalizations.of(context)!.accountSettingsThemeDark,
                    icon: Icons.nightlight_outlined,
                    currentMode: currentMode,
                  ),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    isDark: isDark,
                    mode: ThemeMode.system,
                    label: AppLocalizations.of(context)!.accountSettingsThemeSystem,
                    icon: Icons.brightness_auto_outlined,
                    currentMode: currentMode,
                  ),
                  SizedBox(height: bottomPadding + AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Theme option item - matching home screen language option style
  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected
              ? Border.all(color: AppColors.themeRed.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? AppColors.neutralWhite
                    : AppColors.neutralBlack,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium().copyWith(
                  color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.themeRed,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
