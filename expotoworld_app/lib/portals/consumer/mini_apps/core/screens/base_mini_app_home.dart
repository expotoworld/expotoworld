import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../providers/mini_app_providers.dart';
import '../widgets/category_pills.dart';
import '../widgets/subcategory_grid.dart';

/// Abstract base class for mini-app home screens
/// Implements the 70% shared functionality with slots for 30% customization
/// 
/// Customization slots (override in subclasses):
/// - [buildHeader] - App bar with store dropdown or custom header
/// - [buildSectionHeader] - Optional section header customization
/// - [getSubcategoryRoute] - Navigation path for subcategory tap
/// - [bottomPadding] - Space for floating nav bar
/// 
/// Example:
/// ```dart
/// class ToBHomeScreen extends BaseMiniAppHome {
///   @override
///   MiniAppType get miniAppType => MiniAppType.toB;
///   
///   @override
///   Widget buildHeader(BuildContext context, WidgetRef ref) {
///     return MiniAppAppBar(
///       miniAppType: miniAppType,
///       showMOQIndicator: true, // toB-specific
///       ...
///     );
///   }
/// }
/// ```
abstract class BaseMiniAppHome extends ConsumerStatefulWidget {
  const BaseMiniAppHome({super.key});

  /// The mini-app type this screen represents
  MiniAppType get miniAppType;
}

/// Base state class for mini-app home screens
abstract class BaseMiniAppHomeState<T extends BaseMiniAppHome>
    extends ConsumerState<T> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  //
  // CUSTOMIZATION SLOTS - Override these in subclasses
  //

  /// Build the header/app bar section
  /// Override to provide type-specific headers
  Widget buildHeader(BuildContext context);

  /// Build the section header above the subcategory grid
  /// Default implementation provided, override for customization
  Widget buildSectionHeader(
    BuildContext context,
    List<MiniAppCategory> categories,
    String? selectedCategoryId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: DefaultSectionHeader(
        title: selectedCategoryId == null ? 'Browse Categories' : 'Subcategories',
        subtitle: selectedCategoryId == null
            ? 'Explore products by brand'
            : _getCategoryName(categories, selectedCategoryId),
      ),
    );
  }

  /// Get the navigation route for subcategory tap
  /// Default goes to products, toX should override to services
  String getSubcategoryRoute(String subcategoryId) {
    return '/mini-app/${widget.miniAppType.name}/products/$subcategoryId';
  }

  /// Bottom padding for floating nav bar
  /// Override if no bottom nav (e.g., toX)
  double get bottomPadding => 100;

  /// Handle close button tap
  void handleClose() {
    context.go('/home');
  }

  /// Handle store selection change
  void handleStoreChanged(MiniAppStore store) {
    ref.read(selectedStoreProvider(widget.miniAppType).notifier).state = store;
    // Reset category selection when store changes
    ref.read(selectedCategoryIdProvider(widget.miniAppType).notifier).state = null;
  }

  /// Handle category pill selection
  void handleCategorySelected(String? categoryId) {
    ref.read(selectedCategoryIdProvider(widget.miniAppType).notifier).state = categoryId;
  }

  /// Handle subcategory card tap
  void handleSubcategoryTap(MiniAppSubcategory subcategory) {
    context.push(getSubcategoryRoute(subcategory.id));
  }

  //
  // SHARED IMPLEMENTATION - 70% common logic
  //

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(miniAppCategoriesProvider(widget.miniAppType));
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider(widget.miniAppType));
    final subcategories = ref.watch(miniAppSubcategoriesProvider((
      miniAppType: widget.miniAppType,
      categoryId: selectedCategoryId,
    )));

    return Scaffold(
      body: Column(
        children: [
          // SLOT: Header (customizable per mini-app)
          buildHeader(context),

          // SHARED: Scrollable content
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // SHARED: Category pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg,
                    ),
                    child: CategoryPills(
                      categories: categories,
                      selectedCategoryId: selectedCategoryId,
                      onCategorySelected: handleCategorySelected,
                    ),
                  ),
                ),

                // SLOT: Section header (customizable)
                SliverToBoxAdapter(
                  child: buildSectionHeader(context, categories, selectedCategoryId),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

                // SHARED: Subcategory grid
                SliverSubcategoryGrid(
                  subcategories: subcategories,
                  onSubcategoryTap: handleSubcategoryTap,
                ),

                // Bottom padding (customizable)
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomPadding),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(List<MiniAppCategory> categories, String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => MiniAppCategory(id: '', name: '', imageUrl: null),
    );
    return category.name;
  }
}

/// Default section header widget
/// Can be used as-is or replaced with custom implementation
class DefaultSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const DefaultSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.foreground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption(
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: AppTypography.labelMediumStyle.copyWith(
                color: AppColors.themeRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
