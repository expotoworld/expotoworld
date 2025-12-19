import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                // Center - Store dropdown or mini-app name
                Center(
                  child: miniAppType.hasPhysicalStores && stores.isNotEmpty
                      ? _StoreDropdown(
                          selectedStore: selectedStore,
                          onTap: () => _showStorePicker(context),
                        )
                      : Text(
                          miniAppType.shortName,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                // Right side - Close button (X) instead of QR scanner
                Positioned(
                  right: AppSpacing.lg,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 22,
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
            // Selection indicator
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.themeRed,
                  size: 22,
                ),
              ),
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

/// Language picker bottom sheet (reused from ExpoAppBar pattern)
class _LanguagePickerSheet extends StatelessWidget {
  final WidgetRef ref;

  const _LanguagePickerSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);

    return Container(
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
            'Select Language',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Language list
          ...AppLanguage.values.map((lang) {
            final isSelected =
                lang.locale.languageCode == currentLocale.languageCode;
            return ListTile(
              leading: LanguageFlag(language: lang, size: 40),
              title: Text(
            lang.nativeName,
                style: AppTypography.bodyMedium(
                  color: AppColors.foreground(context),
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.themeRed)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(lang.locale);
                Navigator.pop(context);
              },
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}
