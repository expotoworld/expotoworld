import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/subcategory.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/store.dart';
import '../../../../core/enums/store_type.dart';
import '../../../widgets/common/product_card.dart';
import '../../../widgets/common/product_details_modal.dart';

class ProductListScreen extends StatefulWidget {
  final Category category;
  final Subcategory subcategory;
  final List<Product> allProducts;
  final String miniAppName;
  final Store? selectedStore; // Add selected store context
  final Function(Product, {String? categoryName, String? subcategoryName, String? storeName})? onProductTap;

  const ProductListScreen({
    super.key,
    required this.category,
    required this.subcategory,
    required this.allProducts,
    required this.miniAppName,
    this.selectedStore, // Optional store context for location-dependent mini-apps
    this.onProductTap,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
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
  Widget build(BuildContext context) {
    // Filter products for this subcategory
    final products = widget.allProducts
        .where((product) =>
            product.subcategoryIds.contains(widget.subcategory.id.toString()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category.name}: ${widget.subcategory.name}',
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          products.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(products),
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
    );
  }

  Widget _buildEmptyState() {
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
            '暂无商品',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '该子分类下暂时没有商品',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          // Format store name with store type prefix for location-dependent mini-apps
          String? formattedStoreName;
          if (widget.selectedStore != null) {
            final storeTypePrefix = widget.selectedStore!.type.displayName;
            formattedStoreName = '$storeTypePrefix: ${widget.selectedStore!.name}';
          }

          return ProductCard(
            product: product,
            categoryName: widget.category.name,
            subcategoryName: widget.subcategory.name,
            storeName: formattedStoreName, // Pass the formatted store name
            onTap: () => _showProductDetails(
              product,
              categoryName: widget.category.name,
              subcategoryName: widget.subcategory.name,
              storeName: formattedStoreName,
            ),
          );
        },
      ),
    );
  }


}
