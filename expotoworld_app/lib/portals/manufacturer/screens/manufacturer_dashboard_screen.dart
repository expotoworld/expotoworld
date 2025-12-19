import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/manufacturer_shell.dart';

/// Dashboard screen for the Manufacturer portal
/// Shows overview of factory operations, orders, and analytics
class ManufacturerDashboardScreen extends StatelessWidget {
  const ManufacturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManufacturerShell(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: AppColors.themeRed,
          title: Text(
            'Dashboard',
            style: AppTypography.h4(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                Text('Overview', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                Text('Recent Orders', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildRecentOrdersList(),
                const SizedBox(height: 24),
                Text('Quick Actions', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.themeRed, AppColors.themeRed.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back!', style: AppTypography.h3(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Manufacturer Portal - Coming Soon',
            style: AppTypography.bodyMedium(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🏭 Production Mode',
              style: AppTypography.bodySmall(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Products', '0', Icons.inventory_2_outlined, Colors.blue),
        _buildStatCard('Pending Orders', '0', Icons.shopping_bag_outlined, Colors.orange),
        _buildStatCard('Shipped Today', '0', Icons.local_shipping_outlined, Colors.green),
        _buildStatCard('Revenue (MTD)', '\$0', Icons.attach_money, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.h3()),
              Text(title, style: AppTypography.labelSmall(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No orders yet', style: AppTypography.bodyMedium(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            'Orders will appear here once you start selling',
            style: AppTypography.labelSmall(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionButton('Add Product', Icons.add_box_outlined, Colors.blue, () {})),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton('View Analytics', Icons.analytics_outlined, Colors.purple, () {})),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: AppTypography.bodySmall(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
