import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightRed : AppColors.white,
          borderRadius: BorderRadius.circular(8), // Changed from 20 to 8 for rectangular design
          border: Border.all(
            color: isSelected ? AppColors.themeRed : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center( // Added Center widget to ensure perfect centering
          child: Text(
            category.name,
            style: AppTextStyles.moduleLabel.copyWith(
              color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
            ),
            textAlign: TextAlign.center, // Added text alignment for perfect centering
          ),
        ),
      ),
    );
  }
}
