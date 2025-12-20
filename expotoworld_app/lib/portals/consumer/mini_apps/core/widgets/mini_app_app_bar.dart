import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/providers/locale_provider.dart';
import '../../../../../shared/widgets/language_flag.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';

/// App bar for mini-apps with store dropdown (for B, C, U) or just header (for X)
class MiniAppAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final MiniAppType miniAppType;
  final MiniAppStore? selectedStore;
  final List<MiniAppStore> stores;
  final ValueChanged<MiniAppStore>? onStoreChanged;
  final VoidCallback onClose;
  final bool showSearch;

  const MiniAppAppBar({
    super.key,
    required this.miniAppType,
    this.selectedStore,
    this.stores = const [],
    this.onStoreChanged,
    required this.onClose,
    this.showSearch = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        showSearch
            ? AppSpacing.appBarHeight + 52 + AppSpacing.md
            : AppSpacing.appBarHeight,
      );

  void _showStorePicker(BuildContext context) {
    if (stores.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _StorePickerSheet(
        stores: stores,
        selectedStore: selectedStore,
        onStoreSelected: (store) {
          onStoreChanged?.call(store);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // Show above bottom navigation bar
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
          // Main app bar row
          SizedBox(
            height: AppSpacing.appBarHeight,
            child: Stack(
              children: [
                // Center - Store dropdown or mini-app name with block logo
                Center(
                  child: miniAppType.hasPhysicalStores && stores.isNotEmpty
                      ? _StoreDropdown(
                          selectedStore: selectedStore,
                          onTap: () => _showStorePicker(context),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Block logo
                            SvgPicture.asset(
                              'assets/logo/block.svg',
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFF8F9FA), // Off-white
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            // Short name (e.g., "to X")
                            Text(
                              miniAppType.shortName,
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                        padding: const EdgeInsets.all(4),
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
                // Right side - Close button (X) without background
                Positioned(
                  right: AppSpacing.lg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onClose,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          if (showSearch)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xs,
                bottom: AppSpacing.md,
              ),
              child: _MiniAppSearchBar(
                onTap: () {
                  // TODO: Navigate to mini-app search
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Store dropdown button
class _StoreDropdown extends StatelessWidget {
  final MiniAppStore? selectedStore;
  final VoidCallback onTap;

  const _StoreDropdown({
    this.selectedStore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                selectedStore?.name ?? 'Select Store',
                style: AppTypography.bodySmall(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Store picker bottom sheet
class _StorePickerSheet extends StatelessWidget {
  final List<MiniAppStore> stores;
  final MiniAppStore? selectedStore;
  final ValueChanged<MiniAppStore> onStoreSelected;

  const _StorePickerSheet({
    required this.stores,
    this.selectedStore,
    required this.onStoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
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
            'Select Store',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Store list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                final isSelected = selectedStore?.id == store.id;
                
                return _StoreListItem(
                  store: store,
                  isSelected: isSelected,
                  onTap: () => onStoreSelected(store),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

/// Individual store list item
class _StoreListItem extends StatelessWidget {
  final MiniAppStore store;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreListItem({
    required this.store,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.themeRed
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Store icon with type color
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: store.storeType.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                store.storeType.icon,
                color: store.storeType.color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppTypography.bodyMedium(
                      color: AppColors.foreground(context),
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me_rounded,
                    size: 12,
                    color: AppColors.foregroundMuted(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    store.formattedDistance,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            // Removed selection indicator checkmark - red border already indicates selection
          ],
        ),
      ),
    );
  }
}

/// Mini-app search bar
class _MiniAppSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const _MiniAppSearchBar({this.onTap});

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
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.searchPlaceholder,
              style: AppTypography.bodySmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language picker bottom sheet (matches super-app ExpoAppBar pattern)
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
