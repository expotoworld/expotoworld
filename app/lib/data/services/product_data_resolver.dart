import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../models/store.dart';
import '../../core/enums/store_type.dart';
import 'api_service.dart';

/// Service to resolve product-related data like category names, subcategory names, and store information
class ProductDataResolver {
  static final ProductDataResolver _instance = ProductDataResolver._internal();
  factory ProductDataResolver() => _instance;
  ProductDataResolver._internal();

  final ApiService _apiService = ApiService();
  
  // Cache for resolved data to avoid repeated API calls
  final Map<String, String> _categoryNameCache = {};
  final Map<String, String> _subcategoryNameCache = {};
  final Map<String, String> _storeNameCache = {};
  final Map<String, StoreType> _storeTypeCache = {};
  
  // Cache for all categories and stores to enable quick lookups
  List<models.Category>? _allCategories;
  List<Store>? _allStores;
  DateTime? _lastCacheUpdate;
  
  // Cache validity duration (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Resolves product data including category name, subcategory name, and store information
  Future<ProductDataInfo> resolveProductData(Product product) async {
    debugPrint('🔍 ProductDataResolver: Resolving data for product ${product.id} (${product.title})');
    debugPrint('🔍 ProductDataResolver: Product categoryIds: ${product.categoryIds}');
    debugPrint('🔍 ProductDataResolver: Product subcategoryIds: ${product.subcategoryIds}');
    debugPrint('🔍 ProductDataResolver: Product storeId: ${product.storeId}');
    debugPrint('🔍 ProductDataResolver: Product storeType: ${product.storeType}');
    debugPrint('🔍 ProductDataResolver: Is location dependent: ${_isLocationDependentProduct(product)}');

    await _ensureCacheIsValid();

    String? categoryName;
    String? subcategoryName;
    String? storeName;

    // Resolve category name
    if (product.categoryIds.isNotEmpty) {
      categoryName = await _resolveCategoryName(product.categoryIds.first);
      debugPrint('🔍 ProductDataResolver: Resolved category name: $categoryName');
    } else {
      debugPrint('🔍 ProductDataResolver: No category IDs found');
    }

    // Resolve subcategory name
    if (product.subcategoryIds.isNotEmpty) {
      subcategoryName = await _resolveSubcategoryName(product.subcategoryIds.first);
      debugPrint('🔍 ProductDataResolver: Resolved subcategory name: $subcategoryName');
    } else {
      debugPrint('🔍 ProductDataResolver: No subcategory IDs found');
    }

    // Resolve store name for location-dependent mini-apps
    if (_isLocationDependentProduct(product) && product.storeId != null) {
      storeName = await _resolveStoreName(product.storeId!);
      debugPrint('🔍 ProductDataResolver: Resolved store name: $storeName');
    } else {
      debugPrint('🔍 ProductDataResolver: Store name not needed (not location dependent or no store ID)');
    }

    final result = ProductDataInfo(
      categoryName: categoryName,
      subcategoryName: subcategoryName,
      storeName: storeName,
    );

    debugPrint('🔍 ProductDataResolver: Final result - Category: $categoryName, Subcategory: $subcategoryName, Store: $storeName');
    return result;
  }

  /// Checks if the product belongs to a location-dependent mini-app
  bool _isLocationDependentProduct(Product product) {
    return product.storeType == StoreType.unmannedStore ||
           product.storeType == StoreType.unmannedWarehouse ||
           product.storeType == StoreType.exhibitionStore ||
           product.storeType == StoreType.exhibitionMall;
  }

  /// Ensures the cache is valid and refreshes if necessary
  Future<void> _ensureCacheIsValid() async {
    final now = DateTime.now();
    if (_lastCacheUpdate == null || 
        now.difference(_lastCacheUpdate!) > _cacheValidityDuration ||
        _allCategories == null ||
        _allStores == null) {
      await _refreshCache();
    }
  }

  /// Refreshes the cache by fetching all categories and stores
  Future<void> _refreshCache() async {
    try {
      debugPrint('ProductDataResolver: Refreshing cache...');

      // Fetch all categories and stores in parallel
      final futures = await Future.wait([
        _apiService.fetchCategoriesWithFilters(includeSubcategories: true),
        _apiService.fetchStores(),
      ]);

      _allCategories = futures[0] as List<models.Category>;
      _allStores = futures[1] as List<Store>;
      _lastCacheUpdate = DateTime.now();

      // Debug: Log categories and their subcategories
      debugPrint('🔍 ProductDataResolver: Loaded ${_allCategories!.length} categories:');
      for (final category in _allCategories!) {
        debugPrint('🔍 ProductDataResolver: Category ${category.id} (${category.name}) has ${category.subcategories.length} subcategories');
        for (final subcat in category.subcategories) {
          debugPrint('🔍 ProductDataResolver: - Subcategory ${subcat.id} (${subcat.name})');
        }
      }

      debugPrint('ProductDataResolver: Cache refreshed with ${_allCategories!.length} categories and ${_allStores!.length} stores');
    } catch (e) {
      debugPrint('ProductDataResolver: Error refreshing cache: $e');
      // Don't throw error, use existing cache if available
    }
  }

  /// Resolves category name from category ID
  Future<String?> _resolveCategoryName(String categoryId) async {
    // Check cache first
    if (_categoryNameCache.containsKey(categoryId)) {
      return _categoryNameCache[categoryId];
    }
    
    // Find in all categories
    if (_allCategories != null) {
      final category = _allCategories!.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => models.Category(
          id: '',
          name: '',
          storeTypeAssociation: StoreTypeAssociation.all,
          miniAppAssociation: [],
        ),
      );
      
      if (category.id.isNotEmpty) {
        _categoryNameCache[categoryId] = category.name;
        return category.name;
      }
    }
    
    return null;
  }

  /// Resolves subcategory name from subcategory ID
  Future<String?> _resolveSubcategoryName(String subcategoryId) async {
    debugPrint('🔍 ProductDataResolver: Looking for subcategory ID: $subcategoryId');

    // Check cache first
    if (_subcategoryNameCache.containsKey(subcategoryId)) {
      debugPrint('🔍 ProductDataResolver: Found subcategory in cache: ${_subcategoryNameCache[subcategoryId]}');
      return _subcategoryNameCache[subcategoryId];
    }

    // Find in all categories' subcategories
    if (_allCategories != null) {
      debugPrint('🔍 ProductDataResolver: Searching through ${_allCategories!.length} categories');

      for (final category in _allCategories!) {
        if (category.subcategories.isNotEmpty) {
          debugPrint('🔍 ProductDataResolver: Checking category ${category.id} (${category.name}) with ${category.subcategories.length} subcategories');

          for (final subcat in category.subcategories) {
            debugPrint('🔍 ProductDataResolver: Comparing subcategory ${subcat.id} (${subcat.name}) with target $subcategoryId');
            if (subcat.id == subcategoryId) {
              debugPrint('🔍 ProductDataResolver: Found matching subcategory: ${subcat.name}');
              _subcategoryNameCache[subcategoryId] = subcat.name;
              return subcat.name;
            }
          }
        }
      }
    } else {
      debugPrint('🔍 ProductDataResolver: _allCategories is null');
    }

    debugPrint('🔍 ProductDataResolver: Subcategory not found for ID: $subcategoryId');
    return null;
  }

  /// Resolves store name from store ID with proper formatting
  Future<String?> _resolveStoreName(String storeId) async {
    // Check cache first
    if (_storeNameCache.containsKey(storeId)) {
      return _storeNameCache[storeId];
    }

    // Find in all stores
    if (_allStores != null) {
      final store = _allStores!.firstWhere(
        (store) => store.id.toString() == storeId,
        orElse: () => Store(
          id: '-1',
          name: '',
          city: '',
          address: '',
          latitude: 0.0,
          longitude: 0.0,
          type: StoreType.exhibitionStore,
          isActive: false,
        ),
      );

      if (store.id != '-1') {
        // Format store name with store type prefix for location-dependent mini-apps
        final formattedStoreName = _formatStoreNameWithType(store.name, store.type);
        _storeNameCache[storeId] = formattedStoreName;
        _storeTypeCache[storeId] = store.type;
        return formattedStoreName;
      }
    }

    return null;
  }

  /// Formats store name with store type prefix
  String _formatStoreNameWithType(String storeName, StoreType storeType) {
    final storeTypePrefix = storeType.displayName;
    return '$storeTypePrefix: $storeName';
  }

  /// Gets store type from store ID (used for tag coloring)
  StoreType? getStoreType(String? storeId) {
    if (storeId == null) return null;
    return _storeTypeCache[storeId];
  }

  /// Clears all caches
  void clearCache() {
    _categoryNameCache.clear();
    _subcategoryNameCache.clear();
    _storeNameCache.clear();
    _storeTypeCache.clear();
    _allCategories = null;
    _allStores = null;
    _lastCacheUpdate = null;
  }
}

/// Data class to hold resolved product information
class ProductDataInfo {
  final String? categoryName;
  final String? subcategoryName;
  final String? storeName;

  const ProductDataInfo({
    this.categoryName,
    this.subcategoryName,
    this.storeName,
  });
}
