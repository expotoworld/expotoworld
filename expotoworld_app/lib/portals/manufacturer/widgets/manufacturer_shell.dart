import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shell widget for the Manufacturer portal
/// Provides bottom navigation for manufacturer screens
class ManufacturerShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const ManufacturerShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.themeRed,
        unselectedItemColor: Colors.grey[500],
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    // TODO: Implement GoRouter navigation for manufacturer portal
    // Routes:
    // - /manufacturer/dashboard
    // - /manufacturer/products
    // - /manufacturer/orders
    // - /manufacturer/analytics
    // - /manufacturer/profile
    // context.go('/manufacturer/${_getRoute(index)}');
  }
}
