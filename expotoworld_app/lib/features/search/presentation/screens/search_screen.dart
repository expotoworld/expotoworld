import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';

/// Full-screen search UI
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
      body: Column(
        children: [
          // Search header with red background
          Container(
            padding: EdgeInsets.only(
              top: statusBarHeight + AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.themeRed,
            ),
            child: Row(
              children: [
                // Search input field - transparent background
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: AppTypography.bodyMedium(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products, stores...',
                              hintStyle: AppTypography.bodyMedium(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                            cursorColor: Colors.white,
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Cancel button - blue color
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium(
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search content
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSuggestions(isDark)
                : _buildSearchResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          Text(
            'Recent Searches',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildSearchChip('Italian leather bags', isDark),
              _buildSearchChip('Swiss watches', isDark),
              _buildSearchChip('Japanese electronics', isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Popular searches
          Text(
            'Popular Right Now',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTrendingItem('EXPO to B - Business Exhibition', Icons.trending_up, isDark),
          _buildTrendingItem('French Wine Collection', Icons.trending_up, isDark),
          _buildTrendingItem('German Automotive Parts', Icons.trending_up, isDark),
          _buildTrendingItem('Korean Beauty Products', Icons.trending_up, isDark),
          _buildTrendingItem('Made in Italy Fashion', Icons.trending_up, isDark),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Categories
          Text(
            'Browse by Category',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCategoryItem('Fashion & Apparel', Icons.checkroom_outlined, isDark),
          _buildCategoryItem('Electronics', Icons.devices_outlined, isDark),
          _buildCategoryItem('Food & Beverage', Icons.restaurant_outlined, isDark),
          _buildCategoryItem('Home & Living', Icons.home_outlined, isDark),
          _buildCategoryItem('Health & Beauty', Icons.spa_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: AppTypography.bodySmall().copyWith(
                color: isDark ? AppColors.neutralGray300 : AppColors.neutralGray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingItem(String text, IconData icon, bool isDark) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.themeRed,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium().copyWith(
                  color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? AppColors.neutralGray500 : AppColors.neutralGray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String text, IconData icon, bool isDark) {
    return InkWell(
      onTap: () {
        // Navigate to category
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.themeRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.themeRed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium().copyWith(
                  color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? AppColors.neutralGray500 : AppColors.neutralGray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    // Placeholder for search results
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: isDark ? AppColors.neutralGray600 : AppColors.neutralGray300,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Searching for "${_searchController.text}"',
            style: AppTypography.bodyMedium().copyWith(
              color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Results will appear here',
            style: AppTypography.bodySmall().copyWith(
              color: isDark ? AppColors.neutralGray500 : AppColors.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }
}
