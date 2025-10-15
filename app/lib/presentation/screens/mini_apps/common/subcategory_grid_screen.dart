import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/subcategory.dart';
import '../../../../data/models/product.dart';
import '../../../../core/navigation/custom_page_transitions.dart';
import 'product_list_screen.dart';

class SubcategoryGridScreen extends StatelessWidget {
  final Category category;
  final List<Product> allProducts;
  final String miniAppName;

  const SubcategoryGridScreen({
    super.key,
    required this.category,
    required this.allProducts,
    required this.miniAppName,
  });

  @override
  Widget build(BuildContext context) {
    // Filter subcategories that have products
    final subcategoriesWithProducts = category.subcategories.where((subcategory) {
      return allProducts.any((product) => 
        product.subcategoryIds.contains(subcategory.id.toString())
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$miniAppName: ${category.name}',
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
        ),
      ),
      body: subcategoriesWithProducts.isEmpty
          ? _buildEmptyState()
          : _buildSubcategoryGrid(context, subcategoriesWithProducts),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无子分类',
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryGrid(BuildContext context, List<Subcategory> subcategories) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          final productCount = allProducts
              .where((product) => 
                  product.subcategoryIds.contains(subcategory.id.toString()))
              .length;

          return _buildSubcategoryCard(context, subcategory, productCount);
        },
      ),
    );
  }

  Widget _buildSubcategoryCard(BuildContext context, Subcategory subcategory, int productCount) {
    return GestureDetector(
      onTap: () {
        // Navigate to product list for this subcategory
        Navigator.of(context).push(
          SlideRightRoute(
            page: ProductListScreen(
              category: category,
              subcategory: subcategory,
              allProducts: allProducts,
              miniAppName: miniAppName,
            ),
            routeKey: 'subcategory_${subcategory.id}_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subcategory image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: AppColors.lightBackground,
                ),
                child: subcategory.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          subcategory.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            // Subcategory info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subcategory.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$productCount 个商品',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(
        Icons.category,
        size: 48,
        color: AppColors.secondaryText,
      ),
    );
  }
}
