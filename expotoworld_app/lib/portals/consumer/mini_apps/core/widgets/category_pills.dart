import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/store_model.dart';

/// Horizontal scrollable category pills for mini-apps
/// First pill is always "Recommended", followed by category brands
class CategoryPills extends StatelessWidget {
  final List<MiniAppCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final bool isLoading;

  const CategoryPills({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length + 1, // +1 for "Recommended" pill
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Recommended" is always first
            return _CategoryPill(
              label: 'Recommended',
              isSelected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
              isFirst: true,
            );
          }
          
          final category = categories[index - 1];
          return _CategoryPill(
            label: category.name,
            imageUrl: category.imageUrl,
            isSelected: selectedCategoryId == category.id,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          width: index == 0 ? 110 : 90,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
      ),
    );
  }
}

/// Individual category pill
class _CategoryPill extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;

  const _CategoryPill({
    required this.label,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          left: isFirst ? 0 : 0,
          right: AppSpacing.sm,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: imageUrl != null ? AppSpacing.sm : AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed
              : isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.themeRed
                : isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.themeRed.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category logo if available
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  imageUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.themeRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.themeRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            // Category name
            Text(
              label,
              style: AppTypography.labelMediumStyle.copyWith(
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            // Star icon for Recommended pill
            if (isFirst) ...[
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.star_rounded,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.amber
                        : Colors.amber.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version of category pills for smaller spaces
class CategoryPillsCompact extends StatelessWidget {
  final List<MiniAppCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryPillsCompact({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CompactPill(
              label: 'All',
              isSelected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
            );
          }
          
          final category = categories[index - 1];
          return _CompactPill(
            label: category.name,
            isSelected: selectedCategoryId == category.id,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isSelected
                ? Colors.white
                : AppColors.foreground(context),
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
