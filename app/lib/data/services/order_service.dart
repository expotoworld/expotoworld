import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../../core/config/api_config.dart';

/// Exception thrown when order operations fail
class OrderException implements Exception {
  final String message;
  final int? statusCode;

  const OrderException(this.message, [this.statusCode]);

  @override
  String toString() => 'OrderException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service for handling order-related API operations
class OrderService {
  /// Get the full API base URL depending on environment
  String get _apiBaseUrl {
    final base = ApiConfig.baseUrl;
    if (base.contains('localhost')) {
      // Local dev: direct to order-service on 8082
      return 'http://localhost:8082/api';
    } else {
      // Cloud/prod: use Cloudflare gateway (same host as catalog/auth)
      return '$base/api';
    }
  }

  /// Default headers for API requests
  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Create an order from current cart contents
  Future<OrderResponse> createOrder(
    String miniAppType,
    Map<String, String> authHeaders, {
    int? storeId,
  }) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/orders/$miniAppType');
      final headers = {..._defaultHeaders, ...authHeaders};

      // Prepare request body
      final body = <String, dynamic>{};
      if (storeId != null) {
        body['store_id'] = storeId;
      }

      debugPrint('DEBUG: Creating order at $url');
      debugPrint('DEBUG: Headers: ${headers.keys.toList()}');
      debugPrint('DEBUG: Request body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      ).timeout(ApiConfig.timeout);

      debugPrint('DEBUG: Create order response status: ${response.statusCode}');
      debugPrint('DEBUG: Create order response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return OrderResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw OrderException(
          errorData['error'] ?? 'Failed to create order',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const OrderException('Network error: Unable to connect to order service');
    } on http.ClientException {
      throw const OrderException('Network error: Request failed');
    } on FormatException {
      throw const OrderException('Invalid response format from server');
    } catch (e) {
      if (e is OrderException) rethrow;
      throw OrderException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get user's orders with pagination
  Future<OrderListResponse> getOrders(
    String miniAppType,
    Map<String, String> authHeaders, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final uri = Uri.parse('$_apiBaseUrl/orders/$miniAppType').replace(queryParameters: queryParams);
      final headers = {..._defaultHeaders, ...authHeaders};

      debugPrint('DEBUG: Getting orders from $uri');
      debugPrint('DEBUG: Headers: ${headers.keys.toList()}');

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      debugPrint('DEBUG: Get orders response status: ${response.statusCode}');
      debugPrint('DEBUG: Get orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderListResponse.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw OrderException(
          errorData['error'] ?? 'Failed to get orders',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const OrderException('Network error: Unable to connect to order service');
    } on http.ClientException {
      throw const OrderException('Network error: Request failed');
    } on FormatException {
      throw const OrderException('Invalid response format from server');
    } catch (e) {
      if (e is OrderException) rethrow;
      throw OrderException('Unexpected error: ${e.toString()}');
    }
  }

  /// Get a specific order by ID
  Future<OrderWithItems> getOrder(
    String orderId,
    Map<String, String> authHeaders,
  ) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/order/$orderId');
      final headers = {..._defaultHeaders, ...authHeaders};

      debugPrint('DEBUG: Getting order details from $url');
      debugPrint('DEBUG: Headers: ${headers.keys.toList()}');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(ApiConfig.timeout);

      debugPrint('DEBUG: Get order details response status: ${response.statusCode}');
      debugPrint('DEBUG: Get order details response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderWithItems.fromJson(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw OrderException(
          errorData['error'] ?? 'Failed to get order details',
          response.statusCode,
        );
      }
    } on SocketException {
      throw const OrderException('Network error: Unable to connect to order service');
    } on http.ClientException {
      throw const OrderException('Network error: Request failed');
    } on FormatException {
      throw const OrderException('Invalid response format from server');
    } catch (e) {
      if (e is OrderException) rethrow;
      throw OrderException('Unexpected error: ${e.toString()}');
    }
  }

  /// Check if order service is healthy
  Future<bool> checkHealth() async {
    try {
      final healthBase = ApiConfig.baseUrl.contains('localhost') ? 'http://localhost:8082' : ApiConfig.baseUrl;
      final url = Uri.parse('$healthBase/health');

      debugPrint('DEBUG: Checking order service health at $url');

      final response = await http.get(
        url,
        headers: _defaultHeaders,
      ).timeout(ApiConfig.healthTimeout);

      debugPrint('DEBUG: Order service health check status: ${response.statusCode}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DEBUG: Order service health check failed: $e');
      return false;
    }
  }
}
