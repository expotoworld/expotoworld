import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item.dart';
import '../../core/config/api_config.dart';

class CartService {
  // Get the order service base URL
  String get _baseUrl {
    final base = ApiConfig.baseUrl;
    if (base.contains('localhost')) {
      // Local dev: talk directly to order-service on port 8082
      return 'http://localhost:8082/api';
    }
    // Cloud/prod: use the same Cloudflare gateway host as the catalog/auth services
    // The Worker routes /api/* to order-service
    return '$base/api';
  }

  // Get cart items for authenticated user and specific mini-app
  Future<List<CartItem>> getCart(String miniAppType, Map<String, String> authHeaders) async {
    try {
      debugPrint('🛒 CartService: Getting cart for mini-app: $miniAppType');

      final response = await http.get(
        Uri.parse('$_baseUrl/cart/$miniAppType'),
        headers: authHeaders,
      );

      debugPrint('🛒 CartService: Get cart response status: ${response.statusCode}');
      debugPrint('🛒 CartService: Get cart response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartResponse = data['data'] as Map<String, dynamic>;
        final items = cartResponse['items'] as List<dynamic>?;

        // Handle null items (empty cart)
        if (items == null) {
          return [];
        }

        return items.map((item) => CartItem.fromBackendJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw CartException('Authentication required');
      } else {
        final errorData = jsonDecode(response.body);
        throw CartException(errorData['error'] ?? 'Failed to get cart');
      }
    } catch (e) {
      debugPrint('🛒 CartService: Error getting cart: $e');
      if (e is CartException) rethrow;
      throw CartException('Network error: ${e.toString()}');
    }
  }

  // Add item to cart
  Future<void> addToCart(
    String miniAppType,
    String productId,
    int quantity,
    Map<String, String> authHeaders,
    {int? storeId}
  ) async {
    try {
      debugPrint('🛒 CartService: Adding to cart - miniApp: $miniAppType, product: $productId, quantity: $quantity, store: $storeId');

      final body = <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      };

      // Add store_id for location-based mini-apps
      if (storeId != null) {
        body['store_id'] = storeId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/cart/$miniAppType/add'),
        headers: authHeaders,
        body: jsonEncode(body),
      );

      debugPrint('🛒 CartService: Add to cart response status: ${response.statusCode}');
      debugPrint('🛒 CartService: Add to cart response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw CartException('Authentication required');
      } else {
        final errorData = jsonDecode(response.body);
        throw CartException(errorData['error'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      debugPrint('🛒 CartService: Error adding to cart: $e');
      if (e is CartException) rethrow;
      throw CartException('Network error: ${e.toString()}');
    }
  }

  // Update cart item quantity
  Future<void> updateCartItem(
    String miniAppType,
    String productId,
    int quantity,
    Map<String, String> authHeaders
  ) async {
    try {
      debugPrint('🛒 CartService: Updating cart item - miniApp: $miniAppType, product: $productId, quantity: $quantity');

      final response = await http.put(
        Uri.parse('$_baseUrl/cart/$miniAppType/update'),
        headers: authHeaders,
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      debugPrint('🛒 CartService: Update cart response status: ${response.statusCode}');
      debugPrint('🛒 CartService: Update cart response body: ${response.body}');

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw CartException('Authentication required');
      } else {
        final errorData = jsonDecode(response.body);
        throw CartException(errorData['error'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      debugPrint('🛒 CartService: Error updating cart item: $e');
      if (e is CartException) rethrow;
      throw CartException('Network error: ${e.toString()}');
    }
  }

  // Remove item from cart
  Future<void> removeCartItem(
    String miniAppType,
    String productId,
    Map<String, String> authHeaders
  ) async {
    try {
      debugPrint('🛒 CartService: Removing cart item - miniApp: $miniAppType, product: $productId');

      final response = await http.delete(
        Uri.parse('$_baseUrl/cart/$miniAppType/remove/$productId'),
        headers: authHeaders,
      );

      debugPrint('🛒 CartService: Remove cart response status: ${response.statusCode}');
      debugPrint('🛒 CartService: Remove cart response body: ${response.body}');

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw CartException('Authentication required');
      } else {
        final errorData = jsonDecode(response.body);
        throw CartException(errorData['error'] ?? 'Failed to remove cart item');
      }
    } catch (e) {
      debugPrint('🛒 CartService: Error removing cart item: $e');
      if (e is CartException) rethrow;
      throw CartException('Network error: ${e.toString()}');
    }
  }

  // Check service health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl.replaceAll('/api', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Cart service health check failed: $e');
      return false;
    }
  }
}

class CartException implements Exception {
  final String message;
  
  CartException(this.message);
  
  @override
  String toString() => 'CartException: $message';
}
