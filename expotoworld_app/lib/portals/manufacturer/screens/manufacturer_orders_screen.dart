import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/manufacturer_shell.dart';

/// Orders screen for the Manufacturer portal
class ManufacturerOrdersScreen extends StatelessWidget {
  const ManufacturerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManufacturerShell(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.themeRed,
          title: Text('Orders', style: AppTypography.h4(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text('No Orders Yet', style: AppTypography.h3()),
                const SizedBox(height: 8),
                Text(
                  'Orders will appear here when customers purchase your products',
                  style: AppTypography.bodyMedium(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
