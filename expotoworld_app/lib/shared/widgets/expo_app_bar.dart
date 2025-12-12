import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_flag.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/locale_provider.dart';

/// Custom app bar with red header
/// Includes: Language toggle with flags, Logo (absolutely centered), QR Scanner
class ExpoAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showQrScanner;
  final VoidCallback? onQrTap;

  const ExpoAppBar({
    super.key,
    this.showSearch = true,
    this.showQrScanner = true,
    this.onQrTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        showSearch
            ? AppSpacing.appBarHeight + 52 + AppSpacing.md
            : AppSpacing.appBarHeight,
      );

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguagePickerSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final currentLocale = ref.watch(localeProvider);
    final currentLang = AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == currentLocale.languageCode,
      orElse: () => AppLanguage.english,
    );

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: const BoxDecoration(
        color: AppColors.themeRed,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main app bar row with absolute centering
          SizedBox(
            height: AppSpacing.appBarHeight,
            child: Stack(
              children: [
                // Absolutely centered logo
                Center(
                  child: SvgPicture.asset(
                    'assets/logo/block.svg',
                    height: 40,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFF8F9FA), // Off-white
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Left side - Language toggle
                Positioned(
                  left: AppSpacing.lg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showLanguagePicker(context, ref),
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          top: 4,
                          bottom: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LanguageFlag(
                              language: currentLang,
                              size: 35,
                            ),
                            const SizedBox(width: 0),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Right side - QR Scanner (no background)
                if (showQrScanner)
                  Positioned(
                    right: AppSpacing.lg,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: onQrTap,
                        child: SvgPicture.asset(
                          'assets/icons/qr_scan.svg',
                          width: AppSpacing.iconMd,
                          height: AppSpacing.iconMd,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Search bar - slimmer and aligned with flag/QR
          if (showSearch)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.md,
              ),
              child: _CompactSearchBar(
                onTap: () {
                  // Navigate to search screen
                  context.push('/search');
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact centered search bar
class _CompactSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const _CompactSearchBar({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Search',
              style: AppTypography.bodyMedium(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Language picker bottom sheet
class _LanguagePickerSheet extends StatelessWidget {
  final WidgetRef ref;

  const _LanguagePickerSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                'Select Language',
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
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(lang.locale);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLanguage lang,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
}

/// Glassmorphism search bar
class GlassSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  const GlassSearchBar({
    super.key,
    required this.hintText,
    this.onTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: AppSpacing.searchBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: AppSpacing.iconSm,
                  color: AppColors.foregroundSubtle(context),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    hintText,
                    style: AppTypography.bodyMedium(
                      color: AppColors.foregroundSubtle(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.mic_none_rounded,
                  size: AppSpacing.iconSm,
                  color: AppColors.foregroundSubtle(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
