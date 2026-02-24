import '../enums/mini_app_type.dart';

/// Product model for mini-app stores
/// Contains all product information including pricing, stock, and location data
class MiniAppProduct {
  final String id;
  final String name;
  final String description;
  final double originalPrice; // Strikethrough price
  final double currentPrice; // Main/sale price
  final int stockLeft;
  final int minimumOrderQuantity;
  final String? unit; // e.g., "capsule", "g", "kg", "L", "ml"
  final int? quantity; // e.g., 50 (for "50 capsules")
  final int? multiplier; // e.g., 5 (for "50 capsules x 5"), can be NULL
  final String?
  shelfCode; // Store location code e.g., "01-01-01" (admin-only, null from public API)
  final String? imageUrl;
  final String categoryId;
  final String subcategoryId;
  final String storeId; // Which store this product belongs to
  final String?
  storeName; // Store name for marquee display (e.g., "EXPO MEGA Lugano Centro")
  final StoreType? storeType; // Store type for color coding
  final bool isFeatured; // Whether this product is a recommendation

  const MiniAppProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.currentPrice,
    required this.stockLeft,
    required this.minimumOrderQuantity,
    this.unit,
    this.quantity,
    this.multiplier,
    this.shelfCode,
    this.imageUrl,
    required this.categoryId,
    required this.subcategoryId,
    required this.storeId,
    this.storeName,
    this.storeType,
    this.isFeatured = false,
  });

  /// Deserialize from backend `PublicProductResponse` JSON.
  ///
  /// Backend fields: product_id, product_uuid, sku, title, description,
  /// store_id, main_price, strikethrough_price, tax_rate, stock_left,
  /// minimum_order_quantity, net_content, content_unit, reference_price,
  /// reference_unit, is_active, is_featured, is_mini_app_recommendation,
  /// product_type, parent_id, visibility, is_default_variant, price_min,
  /// price_max, stock_total, variant_options_index, etw_store_type,
  /// etw_mini_app_type, primary_image_url, created_at, updated_at.
  ///
  /// The public API excludes: cost_price, owner_org_id, shelf_code,
  /// logistics_* fields (admin-only).
  factory MiniAppProduct.fromJson(Map<String, dynamic> json) {
    final mainPrice = (json['main_price'] as num?)?.toDouble() ?? 0.0;
    final strikethroughPrice =
        (json['strikethrough_price'] as num?)?.toDouble() ?? mainPrice;

    // Parse net_content as quantity and content_unit as unit.
    // Backend sends net_content as a JSON number (float64), so handle
    // both num (from API) and String (from potential mock data) gracefully.
    final netContentRaw = json['net_content'];
    int? parsedQuantity;
    if (netContentRaw != null) {
      if (netContentRaw is num) {
        parsedQuantity = netContentRaw.toInt();
      } else if (netContentRaw is String && netContentRaw.isNotEmpty) {
        parsedQuantity = int.tryParse(netContentRaw);
      }
    }

    // Extract first category/subcategory ID from the relations arrays
    // (present in PublicProductWithRelationsResponse)
    String categoryId = '';
    String subcategoryId = '';
    if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
      final cat = (json['categories'] as List).first;
      categoryId = (cat is Map ? cat['category_id'] : cat).toString();
    }
    if (json['subcategories'] is List &&
        (json['subcategories'] as List).isNotEmpty) {
      final sub = (json['subcategories'] as List).first;
      subcategoryId = (sub is Map ? sub['subcategory_id'] : sub).toString();
    }

    return MiniAppProduct(
      id: json['product_id'].toString(),
      name: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      originalPrice: strikethroughPrice,
      currentPrice: mainPrice,
      stockLeft: (json['stock_left'] as num?)?.toInt() ?? 0,
      minimumOrderQuantity:
          (json['minimum_order_quantity'] as num?)?.toInt() ?? 1,
      unit: json['content_unit'] as String?,
      quantity: parsedQuantity,
      multiplier: null, // Not directly exposed by public API
      shelfCode: json['shelf_code'] as String?, // null from public API
      imageUrl: json['primary_image_url'] as String?,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      storeId: json['store_id']?.toString() ?? '',
      storeName: null, // Resolved client-side from store data
      storeType: StoreTypeExtension.fromApiValue(
        json['etw_store_type'] as String?,
      ),
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  /// Legacy weight support - combines unit/quantity/multiplier
  /// e.g., "500g", "50 capsules", "50 capsules x 5"
  String get weight {
    if (unit == null || quantity == null) return '';

    final baseUnit = quantity == 1 ? unit! : '$quantity ${unit}s';
    if (multiplier != null && multiplier! > 1) {
      return '$baseUnit x $multiplier';
    }
    return baseUnit;
  }

  /// Formatted extra info for the bubble display
  /// e.g., "500g", "50 capsules", "50 capsules x 5"
  String? get formattedExtraInfo {
    if (unit == null || quantity == null) return null;

    // Pluralize unit if quantity > 1
    final unitText = quantity == 1 ? unit! : _pluralizeUnit(unit!);
    final base = '$quantity $unitText';

    if (multiplier != null && multiplier! > 1) {
      return '$base x $multiplier';
    }
    return base;
  }

  /// Helper to pluralize unit names
  String _pluralizeUnit(String unit) {
    // Common unit pluralization rules
    if (unit.endsWith('s') || unit.endsWith('x') || unit.endsWith('z')) {
      return '${unit}es';
    }
    if (unit == 'g' || unit == 'kg' || unit == 'L' || unit == 'ml') {
      return unit; // Weight/volume units don't pluralize
    }
    return '${unit}s';
  }

  /// Formatted original price with currency
  String get formattedOriginalPrice => '€${originalPrice.toStringAsFixed(2)}';

  /// Formatted current/sale price with currency
  String get formattedCurrentPrice => '€${currentPrice.toStringAsFixed(2)}';

  /// Whether product has a discount
  bool get hasDiscount => originalPrice > currentPrice;

  /// Discount percentage
  int get discountPercent => hasDiscount
      ? (((originalPrice - currentPrice) / originalPrice) * 100).round()
      : 0;

  /// Whether MOQ should be displayed (only if > 1)
  bool get showMoq => minimumOrderQuantity > 1;

  /// Whether product is in stock
  bool get isInStock => stockLeft > 0;
}

/// Service model for to X mini-app (group buying services)
class MiniAppService {
  final String id;
  final String name;
  final String description;
  final double? originalPrice; // Optional strikethrough price
  final double? currentPrice; // Optional price (some services show ranges)
  final String? priceRange; // e.g., "€50 - €200/month"
  final String provider; // e.g., "AXA", "Vodafone"
  final String? imageUrl;
  final String categoryId;
  final String subcategoryId;
  final List<String> features; // List of service features

  const MiniAppService({
    required this.id,
    required this.name,
    required this.description,
    this.originalPrice,
    this.currentPrice,
    this.priceRange,
    required this.provider,
    this.imageUrl,
    required this.categoryId,
    required this.subcategoryId,
    this.features = const [],
  });

  /// Formatted original price with currency
  String? get formattedOriginalPrice =>
      originalPrice != null ? '€${originalPrice!.toStringAsFixed(2)}' : null;

  /// Formatted current price with currency
  String? get formattedCurrentPrice =>
      currentPrice != null ? '€${currentPrice!.toStringAsFixed(2)}' : null;

  /// Display price (current price, price range, or "Request Quote")
  String get displayPrice {
    if (currentPrice != null) {
      return formattedCurrentPrice!;
    } else if (priceRange != null) {
      return priceRange!;
    }
    return 'Request Quote';
  }

  /// Whether service has a discount
  bool get hasDiscount =>
      originalPrice != null &&
      currentPrice != null &&
      originalPrice! > currentPrice!;
}
