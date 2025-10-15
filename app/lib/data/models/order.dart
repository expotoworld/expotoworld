import 'product.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return '待处理';
      case OrderStatus.confirmed:
        return '已确认';
      case OrderStatus.processing:
        return '处理中';
      case OrderStatus.shipped:
        return '已发货';
      case OrderStatus.delivered:
        return '已送达';
      case OrderStatus.cancelled:
        return '已取消';
    }
  }

  String get displayColor {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA726'; // Orange
      case OrderStatus.confirmed:
        return '#42A5F5'; // Blue
      case OrderStatus.processing:
        return '#AB47BC'; // Purple
      case OrderStatus.shipped:
        return '#26C6DA'; // Cyan
      case OrderStatus.delivered:
        return '#66BB6A'; // Green
      case OrderStatus.cancelled:
        return '#EF5350'; // Red
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String miniAppType;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.miniAppType,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      miniAppType: json['mini_app_type'] ?? 'RetailStore',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mini_app_type': miniAppType,
      'total_amount': totalAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;
  final DateTime createdAt;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.createdAt,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['unit_price'] ?? json['total_price'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      product: json['product'] != null ? Product.fromBackendJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'product': product?.toJson(),
    };
  }
}

class OrderWithItems {
  final String id;
  final String userId;
  final String miniAppType;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final int itemCount;

  OrderWithItems({
    required this.id,
    required this.userId,
    required this.miniAppType,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.itemCount,
  });

  factory OrderWithItems.fromJson(Map<String, dynamic> json) {
    return OrderWithItems(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      miniAppType: json['mini_app_type'] ?? 'RetailStore',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      itemCount: json['item_count'] ?? (json['items'] as List<dynamic>?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mini_app_type': miniAppType,
      'total_amount': totalAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'item_count': itemCount,
    };
  }
}

class OrderResponse {
  final OrderWithItems order;
  final String message;

  OrderResponse({
    required this.order,
    required this.message,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      order: OrderWithItems.fromJson(json['data'] ?? json['order'] ?? {}),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order.toJson(),
      'message': message,
    };
  }
}

class OrderListResponse {
  final List<Order> orders;
  final int totalCount;
  final int page;
  final int pageSize;

  OrderListResponse({
    required this.orders,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders: (json['orders'] as List<dynamic>?)
          ?.map((order) => Order.fromJson(order))
          .toList() ?? [],
      totalCount: json['total_count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orders': orders.map((order) => order.toJson()).toList(),
      'total_count': totalCount,
      'page': page,
      'page_size': pageSize,
    };
  }
}
