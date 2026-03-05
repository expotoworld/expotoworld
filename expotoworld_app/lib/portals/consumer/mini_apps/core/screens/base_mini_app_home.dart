import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../providers/mini_app_providers.dart';
import '../widgets/catalog_breadcrumbs.dart';

/// Abstract base class for mini-app home screens.
///
/// Implements the **Progressive Disclosure** pattern with **Persistent
/// Predictive Breadcrumbs**.  Users browse one catalog tier at a time
/// (Category → Subcategory → Collection) using a single scrollable view.
/// Selecting an item triggers a slide animation to the next tier.  The
/// product grid is only shown once all three tiers have been defined (via
/// navigation to the products screen).
///
/// Customization slots (override in subclasses):
/// - [buildHeader] – App bar with store dropdown or custom header.
/// - [bottomPadding] – Space for floating nav bar.
abstract class BaseMiniAppHome extends ConsumerStatefulWidget {
  const BaseMiniAppHome({super.key});

  /// The mini-app type this screen represents.
  MiniAppType get miniAppType;
}

/// Base state class for mini-app home screens.
abstract class BaseMiniAppHomeState<T extends BaseMiniAppHome>
    extends ConsumerState<T> {
  // ── Corner animation ─────────────────────────────────────────────────────
  double _borderRadius = 24.0;
  static const double _maxRadius = 24.0;
  static const double _scrollThreshold = 50.0;

  // ── Tier navigation state ────────────────────────────────────────────────
  int _currentTier =
      1; // 1 = category, 2 = subcategory, 3 = collection, 4 = subcollection
  bool _goingForward = true; // animation direction flag
  MiniAppCategory? _selectedCategory;
  MiniAppSubcategory? _selectedSubcategory;
  MiniAppCollection? _selectedCollection;

  // Track whether we've already scheduled a redirect for empty tiers.
  bool _emptyCollectionsRedirectScheduled = false;
  bool _emptySubcollectionsRedirectScheduled = false;

  //
  // CUSTOMIZATION SLOTS ───────────────────────────────────────────────────
  //

  /// Build the header / app-bar section.
  Widget buildHeader(BuildContext context);

  /// Bottom padding for floating nav bar.
  double get bottomPadding => 140;

  /// Handle close button tap – navigates back to super-app home.
  void handleClose() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  /// Handle store selection change.
  void handleStoreChanged(MiniAppStore store) {
    ref.read(selectedStoreProvider(widget.miniAppType).notifier).state = store;
    // Reset tier navigation when store changes.
    _resetToTier(1);
  }

  //
  // TIER NAVIGATION ──────────────────────────────────────────────────────
  //

  /// Navigate to a specific tier, clearing subsequent selections.
  void _resetToTier(int tier) {
    setState(() {
      _goingForward = tier > _currentTier;
      _emptyCollectionsRedirectScheduled = false;
      _emptySubcollectionsRedirectScheduled = false;
      if (tier <= 1) {
        _selectedCategory = null;
        _selectedSubcategory = null;
        _selectedCollection = null;
        ref
                .read(selectedCategoryIdProvider(widget.miniAppType).notifier)
                .state =
            null;
      } else if (tier <= 2) {
        _selectedSubcategory = null;
        _selectedCollection = null;
      } else if (tier <= 3) {
        _selectedCollection = null;
      }
      _currentTier = tier;
      _borderRadius = _maxRadius;
    });
  }

  /// Called when the user taps a category card.
  void _handleCategoryTap(MiniAppCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = null;
      _goingForward = true;
      _currentTier = 2;
      _borderRadius = _maxRadius;
      _emptyCollectionsRedirectScheduled = false;
    });
    ref.read(selectedCategoryIdProvider(widget.miniAppType).notifier).state =
        category.id;
  }

  /// Called when the user taps a subcategory card.
  void _handleSubcategoryTap(MiniAppSubcategory subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
      _goingForward = true;
      _currentTier = 3;
      _borderRadius = _maxRadius;
      _emptyCollectionsRedirectScheduled = false;
    });
  }

  /// Called when the user taps a collection card → advance to subcollections tier.
  /// If the collection has no subcollections, the subcollections grid will
  /// auto-redirect to the products screen (same pattern as empty collections).
  void _handleCollectionTap(MiniAppCollection collection) {
    setState(() {
      _selectedCollection = collection;
      _goingForward = true;
      _currentTier = 4;
      _borderRadius = _maxRadius;
      _emptySubcollectionsRedirectScheduled = false;
    });
  }

  /// Called when the user taps a subcollection card → navigate to products.
  void _handleSubcollectionTap(MiniAppSubcollection subcollection) {
    context.push(
      '/mini-app/${widget.miniAppType.name}/products/${_selectedSubcategory!.id}'
      '?collectionId=${_selectedCollection!.id}'
      '&subcollectionId=${subcollection.id}',
    );
  }

  /// Called when the user taps a breadcrumb node.
  void _handleBreadcrumbTap(int tier) {
    _resetToTier(tier);
  }

  //
  // TIER CONTENT BUILDERS ────────────────────────────────────────────────
  //

  /// Build the content for the current tier wrapped with a [ValueKey].
  Widget _buildTierContent() {
    return Container(
      key: ValueKey(_currentTier),
      child: switch (_currentTier) {
        1 => _buildCategoriesGrid(),
        2 => _buildSubcategoriesGrid(),
        3 => _buildCollectionsGrid(),
        4 => _buildSubcollectionsGrid(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildCategoriesGrid() {
    final categoriesAsync = ref.watch(
      miniAppCategoriesProvider(widget.miniAppType),
    );

    return categoriesAsync.when(
      loading: () => _buildTierLoading(),
      error: (_, __) =>
          _buildTierError(AppLocalizations.of(context)!.failedToLoadCategories),
      data: (categories) {
        if (categories.isEmpty) {
          return _buildTierEmpty(
            AppLocalizations.of(context)!.noCategoriesAvailable,
            Icons.category_outlined,
          );
        }
        return _buildItemGrid(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _TierItemCard(
              name: cat.name,
              imageUrl: cat.imageUrl,
              onTap: () => _handleCategoryTap(cat),
            );
          },
        );
      },
    );
  }

  Widget _buildSubcategoriesGrid() {
    final subcategoriesAsync = ref.watch(
      miniAppSubcategoriesProvider((
        miniAppType: widget.miniAppType,
        categoryId: _selectedCategory?.id,
      )),
    );

    return subcategoriesAsync.when(
      loading: () => _buildTierLoading(),
      error: (_, __) => _buildTierError(
        AppLocalizations.of(context)!.failedToLoadSubcategories,
      ),
      data: (subcategories) {
        if (subcategories.isEmpty) {
          return _buildTierEmpty(
            AppLocalizations.of(context)!.noSubcategoriesAvailable,
            Icons.category_outlined,
          );
        }
        return _buildItemGrid(
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            return _TierItemCard(
              name: sub.name,
              imageUrl: sub.imageUrl,
              onTap: () => _handleSubcategoryTap(sub),
            );
          },
        );
      },
    );
  }

  Widget _buildCollectionsGrid() {
    final collectionsAsync = ref.watch(
      miniAppCollectionsProvider((
        miniAppType: widget.miniAppType,
        subcategoryId: _selectedSubcategory!.id,
      )),
    );

    // If zero collections, redirect to products without a collection filter.
    if (collectionsAsync.hasValue &&
        collectionsAsync.value!.isEmpty &&
        !_emptyCollectionsRedirectScheduled) {
      _emptyCollectionsRedirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.push(
            '/mini-app/${widget.miniAppType.name}/products/${_selectedSubcategory!.id}',
          );
        }
      });
      return _buildTierLoading();
    }

    return collectionsAsync.when(
      loading: () => _buildTierLoading(),
      error: (_, __) => _buildTierError(
        AppLocalizations.of(context)!.failedToLoadCollections,
      ),
      data: (collections) {
        if (collections.isEmpty) {
          // Already handled above – show loading while redirecting.
          return _buildTierLoading();
        }
        return _buildItemGrid(
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final col = collections[index];
            return _TierItemCard(
              name: col.name,
              imageUrl: col.imageUrl,
              onTap: () => _handleCollectionTap(col),
            );
          },
        );
      },
    );
  }

  Widget _buildSubcollectionsGrid() {
    final subcollectionsAsync = ref.watch(
      miniAppSubcollectionsProvider((
        miniAppType: widget.miniAppType,
        collectionId: _selectedCollection!.id,
      )),
    );

    // If zero subcollections, redirect to products under the collection directly.
    if (subcollectionsAsync.hasValue &&
        subcollectionsAsync.value!.isEmpty &&
        !_emptySubcollectionsRedirectScheduled) {
      _emptySubcollectionsRedirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.push(
            '/mini-app/${widget.miniAppType.name}/products/${_selectedSubcategory!.id}'
            '?collectionId=${_selectedCollection!.id}',
          );
        }
      });
      return _buildTierLoading();
    }

    return subcollectionsAsync.when(
      loading: () => _buildTierLoading(),
      error: (_, __) => _buildTierError(
        AppLocalizations.of(context)!.failedToLoadSubcollections,
      ),
      data: (subcollections) {
        if (subcollections.isEmpty) {
          // Already handled above – show loading while redirecting.
          return _buildTierLoading();
        }
        return _buildItemGrid(
          itemCount: subcollections.length,
          itemBuilder: (context, index) {
            final sc = subcollections[index];
            return _TierItemCard(
              name: sc.name,
              imageUrl: sc.imageUrl,
              onTap: () => _handleSubcollectionTap(sc),
            );
          },
        );
      },
    );
  }

  //
  // SHARED HELPER WIDGETS ────────────────────────────────────────────────
  //

  Widget _buildItemGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: bottomPadding,
      ),
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
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildTierLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(color: AppColors.themeRed),
      ),
    );
  }

  Widget _buildTierError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
              message,
              style: AppTypography.bodyMedium(
                color: AppColors.foregroundMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierEmpty(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.foregroundMuted(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium(
                color: AppColors.foregroundMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //
  // ANIMATED TIER TRANSITION ─────────────────────────────────────────────
  //

  Widget _buildTierTransition(Widget child, Animation<double> animation) {
    final childKey = (child.key as ValueKey<int>).value;
    final isIncoming = childKey == _currentTier;

    // Forward → new content slides in from below, old slides out to top.
    // Backward → new content slides in from above, old slides out to bottom.
    Offset begin;
    if (_goingForward) {
      begin = isIncoming
          ? const Offset(0, 0.15) // enter from below
          : const Offset(0, -0.15); // exit to top
    } else {
      begin = isIncoming
          ? const Offset(0, -0.15) // enter from above
          : const Offset(0, 0.15); // exit to bottom
    }

    final slide = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }

  //
  // BUILD ─────────────────────────────────────────────────────────────────
  //

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: AppColors.themeRed,
      child: Column(
        children: [
          // ── SLOT: Header (customizable per mini-app) ──
          buildHeader(context),

          // ── Content area with animated rounded top corners ──
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
                child: Column(
                  children: [
                    // ── Persistent Breadcrumbs (fixed at top) ──
                    CatalogBreadcrumbs(
                      currentTier: _currentTier,
                      totalTiers: _currentTier >= 4 ? 4 : 3,
                      selectedCategory: _selectedCategory,
                      selectedSubcategory: _selectedSubcategory,
                      selectedCollection: _selectedCollection,
                      onTierTap: _handleBreadcrumbTap,
                      categoryLabel: l10n.category,
                      subcategoryLabel: l10n.subcategory,
                      collectionLabel: l10n.collection,
                      subcollectionLabel: l10n.subcollection,
                    ),

                    // ── Tier content with slide animation ──
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            final offset = notification.metrics.pixels;
                            final newRadius =
                                (_maxRadius -
                                        (offset /
                                            _scrollThreshold *
                                            _maxRadius))
                                    .clamp(0.0, _maxRadius);
                            if (newRadius != _borderRadius) {
                              setState(() => _borderRadius = newRadius);
                            }
                          }
                          return false;
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: _buildTierTransition,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: _buildTierContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Private tier-item card (square image + gradient + text overlay)
// ─────────────────────────────────────────────────────────────────────────

class _TierItemCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _TierItemCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.neutralMid.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: AppColors.foregroundMuted(context),
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: AppColors.foregroundMuted(context),
                  ),
                ),

              // Bottom gradient + name
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    name,
                    style: AppTypography.caption(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
