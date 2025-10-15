import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/subcategory.dart';
import '../../../../data/models/store.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/product.dart';
import '../../../../core/enums/store_type.dart';
import '../../../../core/enums/mini_app_type.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/category_chip.dart';
import '../../../widgets/common/store_locator_header.dart';
import '../../../widgets/common/product_details_modal.dart';
import '../../../providers/cart_provider.dart';

import '../../cart/cart_screen_wrapper.dart';
import 'exhibition_sales_locations_screen.dart';
import '../common/product_list_screen_wrapper.dart';
import '../../../../core/navigation/custom_page_transitions.dart';
import '../../../../core/config/api_config.dart';

class ExhibitionSalesScreen extends StatefulWidget {
  final String? instanceId;

  const ExhibitionSalesScreen({super.key, this.instanceId});

  @override
  State<ExhibitionSalesScreen> createState() => _ExhibitionSalesScreenState();
}

class _ExhibitionSalesScreenState extends State<ExhibitionSalesScreen> {
  int _currentIndex = 0;
  Store? _selectedStore;
  late final GlobalKey<_ProductsTabState> _productsTabKey;

  late final List<Widget> _screens;

  // Product details state management
  Product? _selectedProduct;
  String? _selectedCategoryName;
  String? _selectedSubcategoryName;
  String? _selectedStoreName;

  void _showProductDetails(Product product, {
    String? categoryName,
    String? subcategoryName,
    String? storeName,
  }) {
    setState(() {
      _selectedProduct = product;
      _selectedCategoryName = categoryName;
      _selectedSubcategoryName = subcategoryName;
      _selectedStoreName = storeName;
    });
  }

  void _hideProductDetails() {
    setState(() {
      _selectedProduct = null;
      _selectedCategoryName = null;
      _selectedSubcategoryName = null;
      _selectedStoreName = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // Create unique GlobalKey with instance ID
    final instanceId = widget.instanceId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _productsTabKey = GlobalKey<_ProductsTabState>(debugLabel: 'exhibition_products_tab_$instanceId');

    _screens = [
      _ProductsTab(
        key: _productsTabKey,
        onStoreSelected: _onStoreSelected,
        instanceId: widget.instanceId,
        onProductTap: _showProductDetails,
      ),
      _LocationsTab(key: ValueKey('exhibition_locations_$instanceId')),
      _MessagesTab(key: ValueKey('exhibition_messages_$instanceId')),
      _ProfileTab(key: ValueKey('exhibition_profile_$instanceId')),
    ];

    // Initialize cart context for exhibition sales mini-app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setMiniAppContext('ExhibitionSales');
      debugPrint('🛒 ExhibitionSalesScreen: Cart context initialized for ExhibitionSales');
    });
  }

  void _onStoreSelected(Store? store) {
    setState(() {
      _selectedStore = store;
    });
    // Update the selected store in the ProductsTab and refresh data
    _productsTabKey.currentState?.updateSelectedStore(store);

    // Update cart context with store_id
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final storeId = store?.id != null ? int.tryParse(store!.id) : null;
    cartProvider.setMiniAppContext('ExhibitionSales', storeId: storeId);
    debugPrint('🛒 ExhibitionSalesScreen: Updated cart context with store ID: $storeId');
  }

  // Store locator header for exhibition sales
  PreferredSizeWidget _buildAppBar() {
    return StoreLocatorHeader(
      miniAppName: '展销展消',
      allowedStoreTypes: const [StoreType.exhibitionStore, StoreType.exhibitionMall],
      selectedStore: _selectedStore,
      onStoreSelected: _onStoreSelected,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REPLACE the old appBar with this conditional line
      appBar: _currentIndex == 1 ? null : _buildAppBar(),
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            key: const ValueKey('exhibition_indexed_stack'),
            index: _currentIndex,
            children: _screens,
          ),
          // Product details overlay
          if (_selectedProduct != null)
            ProductDetailsModal(
              key: ValueKey('product_details_${_selectedProduct!.id}'),
              product: _selectedProduct!,
              onClose: _hideProductDetails,
              categoryName: _selectedCategoryName,
              subcategoryName: _selectedSubcategoryName,
              storeName: _selectedStoreName,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                // Left nav items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home,
                        label: '首页',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.location_on,
                        label: '地点',
                      ),
                    ],
                  ),
                ),

                // Center FAB for cart
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => CartScreenWrapper(
                              miniAppType: 'ExhibitionSales',
                              instanceId: widget.instanceId,
                              storeId: _selectedStore?.id != null ? int.tryParse(_selectedStore!.id) : null,
                            ),
                            transitionDuration: Duration.zero, // Instant transition
                            reverseTransitionDuration: Duration.zero, // Instant reverse transition
                          ),
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.themeRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.shopping_cart,
                                color: AppColors.white,
                                size: 24,
                              ),
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    cartProvider.itemCount.toString(),
                                    style: const TextStyle(
                                      color: AppColors.themeRed,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Right nav items
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(index: 2, icon: Icons.message, label: '消息'),
                      _buildNavItem(index: 3, icon: Icons.person, label: '我的'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.navActive
                  : AppTextStyles.navInactive,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final Function(Store?) onStoreSelected;
  final String? instanceId;
  final Function(Product, {String? categoryName, String? subcategoryName, String? storeName})? onProductTap;

  const _ProductsTab({
    super.key,
    required this.onStoreSelected,
    this.instanceId,
    this.onProductTap,
  });

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String? _selectedCategoryId = 'featured'; // Default to featured/推荐
  Store? _selectedStore; // Selected store for location-based categories
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Product>> _productsFuture;
  @override
  void initState() {
    super.initState();
    // Initialize data with empty futures to prevent LateInitializationError
    _categoriesFuture = Future.value([]);
    _productsFuture = Future.value([]);
    // Initialize store selection
    _initializeStore();
  }

  void _initializeStore() async {
    try {
      // Get exhibition sales stores from API using mini_app_type filter
      final stores = await _apiService.fetchStores();
      debugPrint('DEBUG: Exhibition Sales - Total stores fetched: ${stores.length}');

      // Filter for exhibition sales stores (展销商店 and 展销商城)
      final exhibitionStores = stores
          .where(
            (store) =>
                store.type == StoreType.exhibitionStore ||
                store.type == StoreType.exhibitionMall,
          )
          .toList();

      debugPrint('DEBUG: Exhibition Sales - Exhibition stores found: ${exhibitionStores.length}');
      for (final store in exhibitionStores) {
        debugPrint('DEBUG: Exhibition store: ${store.name} (${store.type.displayName})');
      }

      if (exhibitionStores.isNotEmpty && _selectedStore == null) {
        // Auto-select first store if none selected
        setState(() {
          _selectedStore = exhibitionStores.first;
        });
        debugPrint('DEBUG: Exhibition Sales - Selected store: ${_selectedStore!.name}');
        // Notify parent about the selected store
        widget.onStoreSelected(_selectedStore);
        // Fetch data after store is initialized
        fetchData();
      } else if (exhibitionStores.isEmpty) {
        debugPrint('DEBUG: Exhibition Sales - No exhibition stores found! Please create exhibition stores in the admin panel.');
        // Still fetch data without store filter to show any available data
        fetchData();
      }
    } catch (e) {
      debugPrint('ERROR: Exhibition Sales - Error loading stores: $e');
    }
  }

  void updateSelectedStore(Store? store) {
    setState(() {
      _selectedStore = store;
      // Reset to featured/推荐 category when store changes
      _selectedCategoryId = 'featured';
    });
    fetchData();
  }

  void fetchData() {
    final storeId = _selectedStore?.id != null ? int.tryParse(_selectedStore!.id) : null;
    debugPrint('🔍 DEBUG: Exhibition Sales - Fetching data for store ID: $storeId');
    debugPrint('🔍 DEBUG: Exhibition Sales - Selected store: ${_selectedStore?.name}');
    debugPrint('🔍 DEBUG: Exhibition Sales - Selected store type: ${_selectedStore?.type}');
    debugPrint('🔍 DEBUG: Exhibition Sales - Selected store type API value: ${_selectedStore?.type.apiValue}');

    setState(() {
      // For categories: use miniAppType for filtering, and storeId for store-specific categories
      _categoriesFuture = _apiService.fetchCategoriesWithFilters(
        miniAppType: MiniAppType.exhibitionSales,
        storeId: storeId,
        includeSubcategories: true,
      ).then((categories) {
        debugPrint('🔍 DEBUG: Exhibition Sales - Categories fetched: ${categories.length}');
        for (final category in categories) {
          debugPrint('🔍 DEBUG: Exhibition category: ${category.name} (ID: ${category.id})');
        }
        return categories;
      });

      // For products: use storeId for precise filtering (store type is automatically determined by backend)
      // This ensures recommendations are filtered by the specific store location
      _productsFuture = _apiService.fetchProducts(
        storeId: storeId, // Only use storeId - backend will determine the correct store type
      ).then((products) {
        debugPrint('🔍 DEBUG: Exhibition Sales - Products fetched: ${products.length}');

        // Count recommendations vs featured vs regular products
        final recommendedProducts = products.where((p) => p.isMiniAppRecommendation).length;
        final featuredProducts = products.where((p) => p.isFeatured).length;
        final regularProducts = products.where((p) => !p.isMiniAppRecommendation && !p.isFeatured).length;

        debugPrint('🔍 DEBUG: Product breakdown - Recommended: $recommendedProducts, Featured: $featuredProducts, Regular: $regularProducts');

        for (int i = 0; i < products.length && i < 5; i++) {
          final product = products[i];
          debugPrint('🔍 DEBUG: Product $i: ${product.title} (Recommended: ${product.isMiniAppRecommendation}, Featured: ${product.isFeatured}, StoreType: ${product.storeType})');
        }
        return products;
      });
    });
  }

  Future<void> _refreshData() async {
    fetchData();
    try {
      await Future.wait([_categoriesFuture, _productsFuture]);
    } catch (e) {
      // Handle errors silently for refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _categoriesFuture,
          _productsFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text('加载失败', style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final allCategories = snapshot.data![0] as List<Category>;
            final allProducts = snapshot.data![1] as List<Product>;

            // Use the proper category building method with deduplication
            final categories = _buildCategoriesWithFeatured(allCategories, allProducts);



            return Column(
              children: [
                // Store selector moved to header

                // Categories horizontal list
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return CategoryChip(
                        category: category,
                        isSelected: _selectedCategoryId == category.id ||
                            (_selectedCategoryId == null && category.id == 'featured'),
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                      );
                    },
                  ),
                ),

                // Level 2: Subcategory Grid or Level 3: Product Grid
                Expanded(
                  child: _buildContentArea(categories, allProducts),
                ),
              ],
            );
          } else {
            return const Center(child: Text('暂无数据'));
          }
        },
      ),
    );
  }

  /// Builds the content area based on selected category
  Widget _buildContentArea(List<Category> categories, List<Product> allProducts) {
    if (_selectedCategoryId == null || _selectedCategoryId == 'featured') {
      // Show mini-app recommendations directly
      final recommendedProducts = allProducts.where((product) => product.isMiniAppRecommendation).toList();

      return _buildProductGrid(recommendedProducts);
    } else {
      // Find the selected category
      final selectedCategory = categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse: () => categories.first,
      );

      // Check if category has subcategories
      if (selectedCategory.subcategories.isNotEmpty) {
        // Show subcategory grid (Level 2)
        return _buildSubcategoryGrid(selectedCategory, allProducts);
      } else {
        // Show products directly if no subcategories
        final categoryProducts = allProducts.where((product) =>
            product.categoryIds.contains(_selectedCategoryId)).toList();
        return _buildProductGrid(categoryProducts);
      }
    }
  }

  /// Builds the subcategory grid (Level 2)
  Widget _buildSubcategoryGrid(Category category, List<Product> allProducts) {
    // Filter subcategories that have products
    final subcategoriesWithProducts = category.subcategories.where((subcategory) {
      return allProducts.any((product) =>
        product.subcategoryIds.contains(subcategory.id.toString())
      );
    }).toList();

    if (subcategoriesWithProducts.isEmpty) {
      return _buildEmptyState('该分类暂无商品');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns for better visual aesthetics and readability
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75, // Adjusted ratio for larger cards in 3-column layout
        ),
        itemCount: subcategoriesWithProducts.length,
        itemBuilder: (context, index) {
          final subcategory = subcategoriesWithProducts[index];

          return _buildSubcategoryCard(context, category, subcategory, allProducts);
        },
      ),
    );
  }

  /// Builds a subcategory card
  Widget _buildSubcategoryCard(BuildContext context, Category category, Subcategory subcategory, List<Product> allProducts) {
    return GestureDetector(
      onTap: () {
        // Navigate to product list for this subcategory (Level 3)
        Navigator.of(context).push(
          SlideRightRoute(
            page: ProductListScreenWrapper(
              category: category,
              subcategory: subcategory,
              allProducts: allProducts,
              miniAppName: '展销展消',
              miniAppType: 'exhibition_sales',
              selectedStore: _selectedStore, // Pass the selected store context
              instanceId: widget.instanceId,
            ),
            routeKey: 'exhibition_subcategory_${subcategory.id}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image area - square container with small border radius
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8), // Added 8px border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8), // Match container border radius
              child: AspectRatio(
                aspectRatio: 1.0, // Perfect square (1:1 ratio)
                child: Container(
                  color: AppColors.lightBackground,
                  child: subcategory.imageUrl != null
                      ? Image.network(
                          _buildFullImageUrl(subcategory.imageUrl!),
                          fit: BoxFit.contain, // Show complete image without cropping
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.lightBackground,
                              child: Icon(
                                Icons.category,
                                size: 24,
                                color: AppColors.secondaryText,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.lightBackground,
                          child: Icon(
                            Icons.category,
                            size: 24,
                            color: AppColors.secondaryText,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Text area - completely separate below the image
          const SizedBox(height: 4), // Reduced space between image and text
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                subcategory.name,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // Increased font size for better readability in 3-column layout
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds full image URL from relative path
  String _buildFullImageUrl(String imageUrl) {
    // If the URL is already a full URL (starts with http), return as is
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    // If it's a relative path, prepend the base URL
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  /// Resolves category, subcategory, and store names for a product
  Future<Map<String, String?>> _resolveProductTagData(Product product) async {
    try {
      String? categoryName;
      String? subcategoryName;
      String? storeName;

      // Resolve category and subcategory names from the fetched categories
      final categories = await _categoriesFuture;
      for (final category in categories) {
        // Find subcategory that matches the product's subcategory IDs
        for (final subcategory in category.subcategories) {
          if (product.subcategoryIds.contains(subcategory.id)) {
            categoryName = category.name;
            subcategoryName = subcategory.name;
            break;
          }
        }
        if (categoryName != null) break;
      }

      // Format store name for location-dependent mini-apps
      if (_selectedStore != null) {
        storeName = '${_selectedStore!.type.displayName}: ${_selectedStore!.name}';
      }

      return {
        'categoryName': categoryName,
        'subcategoryName': subcategoryName,
        'storeName': storeName,
      };
    } catch (e) {
      debugPrint('🔍 Error resolving product tag data: $e');
      return {
        'categoryName': null,
        'subcategoryName': null,
        'storeName': null,
      };
    }
  }

  /// Builds the product grid
  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return _buildEmptyState('暂无商品');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          return FutureBuilder<Map<String, String?>>(
            future: _resolveProductTagData(product),
            builder: (context, snapshot) {
              final tagData = snapshot.data ?? {};

              return ProductCard(
                product: product,
                categoryName: tagData['categoryName'],
                subcategoryName: tagData['subcategoryName'],
                storeName: tagData['storeName'],
                onTap: widget.onProductTap != null
                    ? () => widget.onProductTap!(product,
                        categoryName: tagData['categoryName'],
                        subcategoryName: tagData['subcategoryName'],
                        storeName: tagData['storeName'])
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  /// Builds empty state widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of categories with recommendations category, ensuring no duplicates
  List<Category> _buildCategoriesWithFeatured(List<Category> apiCategories, List<Product> allProducts) {
    final List<Category> result = [];

    // Check if there are any mini-app recommendations
    final hasRecommendedProducts = allProducts.any((product) => product.isMiniAppRecommendation);

    // Always add recommendations category first if there are mini-app recommendations
    if (hasRecommendedProducts) {
      result.add(Category(
        id: 'featured',
        name: '推荐',
        storeTypeAssociation: StoreTypeAssociation.all,
        miniAppAssociation: [],
      ));
    }

    // Add all API categories except any "推荐" categories (to avoid duplicates)
    for (final category in apiCategories) {
      if (category.name != '推荐' && category.id != 'featured') {
        result.add(category);
      }
    }

    return result;
  }
}

class _LocationsTab extends StatelessWidget {
  const _LocationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExhibitionSalesLocationsScreen();
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('消息功能开发中...'));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('个人中心功能开发中...'));
  }
}
