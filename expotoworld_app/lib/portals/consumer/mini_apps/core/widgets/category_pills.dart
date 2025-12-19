import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/store_model.dart';

/// Horizontal scrollable category pills for mini-apps
/// First pill is always "Recommended", followed by category brands
/// Auto-scrolls selected pill to the center (with graceful edge handling)
class CategoryPills extends StatefulWidget {
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
  State<CategoryPills> createState() => _CategoryPillsState();
}

class _CategoryPillsState extends State<CategoryPills> {
  final ScrollController _scrollController = ScrollController();
  
  // Track pill widths for scroll calculation
  final List<GlobalKey> _pillKeys = [];
  
  @override
  void initState() {
    super.initState();
    _initializeKeys();
  }
  
  @override
  void didUpdateWidget(CategoryPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize keys if categories changed
    if (oldWidget.categories.length != widget.categories.length) {
      _initializeKeys();
    }
  }
  
  void _initializeKeys() {
    _pillKeys.clear();
    // +1 for "Recommended" pill
    for (int i = 0; i < widget.categories.length + 1; i++) {
      _pillKeys.add(GlobalKey());
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToIndex(int index, {String? categoryName}) {
    // Use Flutter's built-in viewport calculation for accurate centering
    // with proper boundary clamping to prevent floating items
    
    // Safety check: ensure the item is rendered and controller is attached
    if (index >= _pillKeys.length || !_scrollController.hasClients) return;
    
    final key = _pillKeys[index];
    final context = key.currentContext;
    
    // If the item is not visible/rendered, we can't calculate its position
    if (context == null) return;
    
    final renderObject = context.findRenderObject();
    if (renderObject == null) return;
    
    // Use Flutter's internal engine to find the exact scroll offset
    // needed to center this specific item (alignment: 0.5 = center)
    final viewport = RenderAbstractViewport.of(renderObject);
    final revealedOffset = viewport.getOffsetToReveal(renderObject, 0.5);
    
    // CLAMP the calculated offset - ensures we never scroll past
    // physical start (0.0) or physical end (maxScrollExtent)
    final minScroll = _scrollController.position.minScrollExtent;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final double finalOffset = revealedOffset.offset.clamp(minScroll, maxScroll);
    
    _scrollController.animateTo(
      finalOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState(context);
    }

    // Wrap ClipRect in Padding to pull the "clipping wall" slightly inward.
    // This ensures pills are cut off by a straight vertical line BEFORE they
    // reach the parent container's rounded corner area.
    // ShaderMask adds gradient fade on edges for smoother visual cutoff.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, 0.02, 0.98, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // Adjusted padding to account for outer padding
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                right: AppSpacing.xs,
              ),
              itemCount: widget.categories.length + 1, // +1 for "Recommended" pill
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "Recommended" is always first
                  return _CategoryPill(
                    key: _pillKeys[0],
                    label: 'Recommended',
                    isSelected: widget.selectedCategoryId == null,
                    onTap: () {
                      widget.onCategorySelected(null);
                      _scrollToIndex(0, categoryName: 'Recommended');
                    },
                    isFirst: true,
                  );
                }
                
                final category = widget.categories[index - 1];
                return _CategoryPill(
                  key: _pillKeys[index],
                  label: category.name,
                  imageUrl: category.imageUrl,
                  isSelected: widget.selectedCategoryId == category.id,
                  onTap: () {
                    widget.onCategorySelected(category.id);
                    _scrollToIndex(index, categoryName: category.name);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Simple loading state without ShaderMask
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
    super.key,
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
          // Only show border when not selected to avoid anti-aliasing artifacts
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
          // No shadows - flat design per user request
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
