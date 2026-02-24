import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../providers/mini_app_providers.dart';
import '../widgets/collection_grid.dart';

/// Collections screen — intermediate tier between subcategory and products.
///
/// Shows a 3-column grid of active collections for the selected subcategory.
/// Tapping a collection navigates to the products screen filtered by that
/// collection's ID.
///
/// If the subcategory has zero collections the user is sent directly to the
/// products screen (no empty collections page is shown).
class CollectionsScreen extends ConsumerStatefulWidget {
  final MiniAppType miniAppType;
  final String subcategoryId;

  const CollectionsScreen({
    super.key,
    required this.miniAppType,
    required this.subcategoryId,
  });

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _borderRadius = 24.0;

  static const double _maxRadius = 24.0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newRadius = (_maxRadius - (offset / _scrollThreshold * _maxRadius))
        .clamp(0.0, _maxRadius);
    if (newRadius != _borderRadius) {
      setState(() => _borderRadius = newRadius);
    }
  }

  /// Resolve the subcategory name from the providers cache.
  String _resolveSubcategoryName() {
    final selectedCategoryId = ref.read(
      selectedCategoryIdProvider(widget.miniAppType),
    );
    final subcategoriesAsync = ref.read(
      miniAppSubcategoriesProvider((
        miniAppType: widget.miniAppType,
        categoryId: selectedCategoryId,
      )),
    );
    final subcategories = subcategoriesAsync.value ?? [];

    try {
      return subcategories.firstWhere((s) => s.id == widget.subcategoryId).name;
    } catch (_) {
      return 'Collections';
    }
  }

  void _handleCollectionTap(MiniAppCollection collection) {
    context.push(
      '/mini-app/${widget.miniAppType.name}/products/${widget.subcategoryId}'
      '?collectionId=${collection.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final title = _resolveSubcategoryName();

    final collectionsAsync = ref.watch(
      miniAppCollectionsProvider((
        miniAppType: widget.miniAppType,
        subcategoryId: widget.subcategoryId,
      )),
    );

    // If we have resolved to 0 collections, skip straight to products.
    if (collectionsAsync.hasValue && collectionsAsync.value!.isEmpty) {
      // Schedule the redirect after the current frame to avoid build-phase
      // navigation issues.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement(
            '/mini-app/${widget.miniAppType.name}/products/${widget.subcategoryId}',
          );
        }
      });
    }

    return Container(
      color: AppColors.themeRed,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: const BoxDecoration(color: AppColors.themeRed),
            child: _CollectionsHeader(
              title: title,
              collectionCount: collectionsAsync.value?.length ?? 0,
              onBack: () => context.pop(),
            ),
          ),

          // Content area
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121212)
                    : AppColors.neutralWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
                child: collectionsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.themeRed),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.foregroundMuted(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load collections',
                          style: AppTypography.bodyMedium(
                            color: AppColors.foregroundMuted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (collections) => SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      bottom: 140,
                    ),
                    child: CollectionGrid(
                      collections: collections,
                      onCollectionTap: _handleCollectionTap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header widget for the collections screen.
class _CollectionsHeader extends StatelessWidget {
  final String title;
  final int collectionCount;
  final VoidCallback onBack;

  const _CollectionsHeader({
    required this.title,
    required this.collectionCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
