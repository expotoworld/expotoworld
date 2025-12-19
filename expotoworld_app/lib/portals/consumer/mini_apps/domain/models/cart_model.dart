import 'product_model.dart';

/// Cart item model for mini-app cart
class CartItem {
  final MiniAppProduct product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  /// Total price for this cart item
  double get totalPrice => product.currentPrice * quantity;

  /// Formatted total price
  String get formattedTotalPrice => '€${totalPrice.toStringAsFixed(2)}';

  /// Create a copy with updated quantity
  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
      );
}

/// Cart model for managing cart state (immutable)
class MiniAppCart {
  final List<CartItem> items;

  const MiniAppCart({this.items = const []});

  /// Factory for empty cart
  factory MiniAppCart.empty() => const MiniAppCart(items: []);

  /// Total number of unique products in cart
  int get itemCount => items.length;

  /// Total number of all products (sum of quantities)
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Alias for totalItems
  int get totalQuantity => totalItems;

  /// Total price (subtotal)
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Formatted total price
  String get formattedTotalPrice => '€${totalPrice.toStringAsFixed(2)}';

  /// Add product to cart (returns new cart)
  MiniAppCart addProduct(MiniAppProduct product, int quantity) {
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    final newItems = List<CartItem>.from(items);
    
    if (existingIndex != -1) {
      final existingItem = items[existingIndex];
      newItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Start with MOQ if quantity is less
      final initialQty = quantity < product.minimumOrderQuantity
          ? product.minimumOrderQuantity
          : quantity;
      newItems.add(CartItem(product: product, quantity: initialQty));
    }
    
    return MiniAppCart(items: newItems);
  }

  /// Update quantity for a product (returns new cart)
  MiniAppCart updateQuantity(String productId, int quantity) {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return this;
    
    final product = items[index].product;
    final newItems = List<CartItem>.from(items);
    
    if (quantity < product.minimumOrderQuantity) {
      // Remove from cart if below MOQ
      newItems.removeAt(index);
    } else {
      newItems[index] = items[index].copyWith(quantity: quantity);
    }
    
    return MiniAppCart(items: newItems);
  }

  /// Remove product from cart (returns new cart)
  MiniAppCart removeProduct(String productId) {
    final newItems = items.where((item) => item.product.id != productId).toList();
    return MiniAppCart(items: newItems);
  }

  /// Check if product is in cart
  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  /// Get quantity of a product in cart
  int getQuantity(String productId) {
    final item = items.where((item) => item.product.id == productId).firstOrNull;
    return item?.quantity ?? 0;
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;
}
