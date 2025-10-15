import 'package:flutter/foundation.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/services/cart_service.dart';
import '../../core/enums/store_type.dart';
import '../../core/enums/mini_app_type.dart';
import 'auth_provider.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  final AuthProvider _authProvider;

  // Cart items per mini-app type for isolation
  final Map<String, List<CartItem>> _cartsByMiniApp = {};

  // Current mini-app context
  String? _currentMiniAppType;
  int? _currentStoreId; // For location-based mini-apps

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  CartProvider(this._authProvider) {
    // Listen to auth changes to load/clear cart
    _authProvider.addListener(_onAuthChanged);
  }

  // Getters for current mini-app cart
  List<CartItem> get items => _currentMiniAppType != null
      ? List.unmodifiable(_cartsByMiniApp[_currentMiniAppType] ?? [])
      : [];

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get currentMiniAppType => _currentMiniAppType;

  int? get currentStoreId => _currentStoreId;

  /// Set the current mini-app context for cart operations
  void setMiniAppContext(String miniAppType, {int? storeId}) {
    debugPrint('🛒 CartProvider: Setting mini-app context - type: $miniAppType, storeId: $storeId');
    debugPrint('🛒 CartProvider: Auth status: ${_authProvider.isAuthenticated}');
    debugPrint('🛒 CartProvider: Auth token exists: ${_authProvider.token != null}');

    _currentMiniAppType = miniAppType;
    _currentStoreId = storeId;

    // Load cart for this mini-app if authenticated
    if (_authProvider.isAuthenticated) {
      debugPrint('🛒 CartProvider: Loading cart from backend for mini-app: $miniAppType');
      _loadCartFromBackend();
    } else {
      debugPrint('🛒 CartProvider: User not authenticated, skipping cart load');
    }
  }

  /// Handle authentication state changes
  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      // User logged in - load cart from backend
      if (_currentMiniAppType != null) {
        _loadCartFromBackend();
      }
    } else {
      // User logged out - clear all carts
      _cartsByMiniApp.clear();
      notifyListeners();
    }
  }

  // Get quantity of a specific product in cart
  int getProductQuantity(String productId) {
    final currentItems = items;
    final item = currentItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(product: Product(
        id: '',
        sku: '',
        title: '',
        descriptionShort: '',
        descriptionLong: '',
        manufacturerId: '',
        storeType: StoreType.exhibitionStore,
        miniAppType: MiniAppType.retailStore,
        mainPrice: 0,
        imageUrls: [],
        categoryIds: [],
      ), quantity: 0),
    );
    return item.product.id.isEmpty ? 0 : item.quantity;
  }

  // Add product to cart
  Future<void> addProduct(Product product) async {
    await addProductWithQuantity(product, 1);
  }

  // Add product to cart with specific quantity
  Future<void> addProductWithQuantity(Product product, int quantity) async {
    debugPrint('🛒 CartProvider: addProductWithQuantity called for ${product.id} with quantity $quantity');
    debugPrint('🛒 CartProvider: Auth status: ${_authProvider.isAuthenticated}');
    debugPrint('🛒 CartProvider: Current mini-app type: $_currentMiniAppType');
    debugPrint('🛒 CartProvider: Current store ID: $_currentStoreId');

    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      final errorMsg = !_authProvider.isAuthenticated
          ? 'Authentication required'
          : 'Mini-app context not set';
      debugPrint('🛒 CartProvider: Error - $errorMsg');
      _setError(errorMsg);
      throw Exception(errorMsg); // Rethrow so caller knows about the error
    }

    if (quantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    _setLoading(true);
    _clearError();

    try {
      // Call backend API with specified quantity
      await _cartService.addToCart(
        _currentMiniAppType!,
        product.id,
        quantity,
        _getAuthHeaders(),
        storeId: _currentStoreId,
      );

      // Reload cart from backend to get updated state
      await _loadCartFromBackend();
    } catch (e) {
      final errorMsg = 'Failed to add product to cart: ${e.toString()}';
      _setError(errorMsg);
      throw Exception(errorMsg); // Rethrow so caller knows about the error
    } finally {
      _setLoading(false);
    }
  }

  /// Load cart from backend for current mini-app
  Future<void> _loadCartFromBackend() async {
    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) return;

    try {
      final cartItems = await _cartService.getCart(
        _currentMiniAppType!,
        _getAuthHeaders(),
      );

      _cartsByMiniApp[_currentMiniAppType!] = cartItems;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cart from backend: $e');
      // Don't show error to user for background loading
    }
  }

  /// Get authentication headers for API calls
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    };
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Remove one quantity of product from cart
  Future<void> removeProduct(String productId) async {
    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      final errorMsg = 'Authentication required';
      _setError(errorMsg);
      throw Exception(errorMsg);
    }

    final currentQuantity = getProductQuantity(productId);
    if (currentQuantity <= 0) return;

    _setLoading(true);
    _clearError();

    try {
      if (currentQuantity > 1) {
        // Update quantity to current - 1
        await _cartService.updateCartItem(
          _currentMiniAppType!,
          productId,
          currentQuantity - 1,
          _getAuthHeaders(),
        );
      } else {
        // Remove item completely
        await _cartService.removeCartItem(
          _currentMiniAppType!,
          productId,
          _getAuthHeaders(),
        );
      }

      // Reload cart from backend
      await _loadCartFromBackend();
    } catch (e) {
      final errorMsg = 'Failed to remove product: ${e.toString()}';
      _setError(errorMsg);
      throw Exception(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  // Remove all quantities of a product from cart
  Future<void> removeAllOfProduct(String productId) async {
    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      final errorMsg = 'Authentication required';
      _setError(errorMsg);
      throw Exception(errorMsg);
    }

    _setLoading(true);
    _clearError();

    try {
      await _cartService.removeCartItem(
        _currentMiniAppType!,
        productId,
        _getAuthHeaders(),
      );

      // Reload cart from backend
      await _loadCartFromBackend();
    } catch (e) {
      final errorMsg = 'Failed to remove product: ${e.toString()}';
      _setError(errorMsg);
      throw Exception(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  // Update product quantity directly
  Future<void> updateProductQuantity(String productId, int quantity) async {
    debugPrint('🛒 CartProvider: updateProductQuantity called for $productId with quantity $quantity');
    debugPrint('🛒 CartProvider: Auth status: ${_authProvider.isAuthenticated}');
    debugPrint('🛒 CartProvider: Current mini-app type: $_currentMiniAppType');

    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      final errorMsg = !_authProvider.isAuthenticated
          ? 'Authentication required'
          : 'Mini-app context not set';
      debugPrint('🛒 CartProvider: Error - $errorMsg');
      _setError(errorMsg);
      throw Exception(errorMsg); // Rethrow so caller knows about the error
    }

    if (quantity <= 0) {
      await removeAllOfProduct(productId);
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _cartService.updateCartItem(
        _currentMiniAppType!,
        productId,
        quantity,
        _getAuthHeaders(),
      );

      // Reload cart from backend
      await _loadCartFromBackend();
    } catch (e) {
      final errorMsg = 'Failed to update quantity: ${e.toString()}';
      _setError(errorMsg);
      throw Exception(errorMsg); // Rethrow so caller knows about the error
    } finally {
      _setLoading(false);
    }
  }

  // Refresh cart from backend
  Future<void> refreshCart() async {
    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      return;
    }
    await _loadCartFromBackend();
  }

  // Clear entire cart for current mini-app
  Future<void> clearCart() async {
    if (!_authProvider.isAuthenticated || _currentMiniAppType == null) {
      _setError('Authentication required');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Remove all items one by one (backend doesn't have clear all endpoint)
      final currentItems = List.from(items);
      for (final item in currentItems) {
        try {
          await _cartService.removeCartItem(
            _currentMiniAppType!,
            item.product.id,
            _getAuthHeaders(),
          );
        } catch (e) {
          // Ignore individual item removal errors (item might already be removed)
          debugPrint('🛒 CartProvider: Ignoring cart item removal error: $e');
        }
      }

      // Reload cart from backend to get the actual state
      await _loadCartFromBackend();
    } catch (e) {
      // Only set error for critical failures, not individual item removal failures
      debugPrint('🛒 CartProvider: Cart clearing completed with some errors: $e');
      // Still reload cart to get current state
      await _loadCartFromBackend();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Check if product is in cart
  bool isProductInCart(String productId) {
    return items.any((item) => item.product.id == productId);
  }
}
