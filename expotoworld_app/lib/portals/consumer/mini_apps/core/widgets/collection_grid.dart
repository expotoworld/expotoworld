import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/store_model.dart';

/// 3-column grid of collection cards
/// Displayed when a subcategory is selected, before showing products
class CollectionGrid extends StatelessWidget {
  final List<MiniAppCollection> collections;
  final ValueChanged<MiniAppCollection> onCollectionTap;
  final bool isLoading;

  const CollectionGrid({
    super.key,
    required this.collections,
    required this.onCollectionTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (collections.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0, // Square cards
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          return _CollectionCard(
            collection: collection,
            onTap: () => onCollectionTap(collection),
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
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.0,
        ),
        itemCount: 6,
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
              Icons.collections_bookmark_outlined,
              size: 48,
              color: AppColors.foregroundMuted(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No collections available',
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

/// Individual collection card - Square with image and text overlay
class _CollectionCard extends StatelessWidget {
  final MiniAppCollection collection;
  final VoidCallback onTap;

  const _CollectionCard({required this.collection, required this.onTap});

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      collection.name,
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
    if (collection.imageUrl != null) {
      return Image.network(
        collection.imageUrl!,
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
          Icons.collections_bookmark_rounded,
          size: 28,
          color: AppColors.themeRed.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Sliver version of collection grid for use in CustomScrollView
class SliverCollectionGrid extends StatelessWidget {
  final List<MiniAppCollection> collections;
  final ValueChanged<MiniAppCollection> onCollectionTap;

  const SliverCollectionGrid({
    super.key,
    required this.collections,
    required this.onCollectionTap,
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
        delegate: SliverChildBuilderDelegate((context, index) {
          final collection = collections[index];
          return _CollectionCard(
            collection: collection,
            onTap: () => onCollectionTap(collection),
          );
        }, childCount: collections.length),
      ),
    );
  }
}
