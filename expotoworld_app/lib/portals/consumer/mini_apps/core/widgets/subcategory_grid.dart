import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/store_model.dart';

/// 3-column grid of subcategory cards
/// Displayed below category pills when a category is selected
class SubcategoryGrid extends StatelessWidget {
  final List<MiniAppSubcategory> subcategories;
  final ValueChanged<MiniAppSubcategory> onSubcategoryTap;
  final bool isLoading;

  const SubcategoryGrid({
    super.key,
    required this.subcategories,
    required this.onSubcategoryTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (subcategories.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0, // Square cards
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          return _SubcategoryCard(
            subcategory: subcategory,
            onTap: () => onSubcategoryTap(subcategory),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0, // Square cards
        ),
        itemCount: 9,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: AppColors.foregroundMuted(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No subcategories available',
              style: AppTypography.bodyMedium(
                color: AppColors.foregroundMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual subcategory card - Square with image and text overlay
class _SubcategoryCard extends StatelessWidget {
  final MiniAppSubcategory subcategory;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.subcategory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0, // Square
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-size image or placeholder
                _buildImage(context, isDark),
                
                // Bottom gradient overlay for text readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Text at bottom, horizontally centered
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.sm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text(
                      subcategory.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool isDark) {
    if (subcategory.imageUrl != null) {
      return Image.network(
        subcategory.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderIcon(context, isDark),
      );
    }
    return _buildPlaceholderIcon(context, isDark);
  }

  Widget _buildPlaceholderIcon(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.themeRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Center(
        child: Icon(
          _getIconForSubcategory(subcategory.name),
          size: 28,
          color: AppColors.themeRed.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  IconData _getIconForSubcategory(String name) {
    final nameLower = name.toLowerCase();
    
    // Food items
    if (nameLower.contains('pasta') || nameLower.contains('spaghetti')) {
      return Icons.restaurant_rounded;
    }
    if (nameLower.contains('coffee') || nameLower.contains('espresso') || nameLower.contains('caffè')) {
      return Icons.coffee_rounded;
    }
    if (nameLower.contains('sauce') || nameLower.contains('sugo') || nameLower.contains('pomodoro')) {
      return Icons.soup_kitchen_rounded;
    }
    if (nameLower.contains('oil') || nameLower.contains('olio')) {
      return Icons.opacity_rounded;
    }
    if (nameLower.contains('chocolate') || nameLower.contains('cioccolato')) {
      return Icons.cake_rounded;
    }
    if (nameLower.contains('biscuit') || nameLower.contains('cookie') || nameLower.contains('biscotti')) {
      return Icons.cookie_rounded;
    }
    if (nameLower.contains('drink') || nameLower.contains('beverage') || nameLower.contains('bibite')) {
      return Icons.local_drink_rounded;
    }
    if (nameLower.contains('snack') || nameLower.contains('chip')) {
      return Icons.fastfood_rounded;
    }
    
    // Services
    if (nameLower.contains('insurance') || nameLower.contains('assicurazione')) {
      return Icons.security_rounded;
    }
    if (nameLower.contains('mobile') || nameLower.contains('phone') || nameLower.contains('telecom')) {
      return Icons.phone_android_rounded;
    }
    if (nameLower.contains('internet') || nameLower.contains('fiber') || nameLower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (nameLower.contains('electric') || nameLower.contains('energy') || nameLower.contains('luce')) {
      return Icons.bolt_rounded;
    }
    if (nameLower.contains('gas')) {
      return Icons.local_fire_department_rounded;
    }
    if (nameLower.contains('health') || nameLower.contains('salute')) {
      return Icons.health_and_safety_rounded;
    }
    if (nameLower.contains('travel') || nameLower.contains('viaggio')) {
      return Icons.flight_rounded;
    }
    if (nameLower.contains('home') || nameLower.contains('casa')) {
      return Icons.home_rounded;
    }
    if (nameLower.contains('car') || nameLower.contains('auto')) {
      return Icons.directions_car_rounded;
    }
    
    // Default
    return Icons.category_rounded;
  }
}

/// Sliver version of subcategory grid for use in CustomScrollView
class SliverSubcategoryGrid extends StatelessWidget {
  final List<MiniAppSubcategory> subcategories;
  final ValueChanged<MiniAppSubcategory> onSubcategoryTap;

  const SliverSubcategoryGrid({
    super.key,
    required this.subcategories,
    required this.onSubcategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0, // Square cards
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subcategory = subcategories[index];
            return _SubcategoryCard(
              subcategory: subcategory,
              onTap: () => onSubcategoryTap(subcategory),
            );
          },
          childCount: subcategories.length,
        ),
      ),
    );
  }
}
