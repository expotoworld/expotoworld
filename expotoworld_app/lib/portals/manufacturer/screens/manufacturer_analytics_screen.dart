import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/manufacturer_shell.dart';

/// Analytics screen for the Manufacturer portal
class ManufacturerAnalyticsScreen extends StatelessWidget {
  const ManufacturerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManufacturerShell(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.themeRed,
          title: Text('Analytics', style: AppTypography.h4(color: Colors.white)),
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
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, size: 64, color: Colors.purple),
                ),
                const SizedBox(height: 24),
                Text('Coming Soon', style: AppTypography.h3()),
                const SizedBox(height: 8),
                Text(
                  'Advanced analytics and insights will be available here',
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
