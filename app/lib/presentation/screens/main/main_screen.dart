import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'locations_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(key: ValueKey('main_home')),
    const LocationsScreen(key: ValueKey('main_locations')),
    const MessagesScreen(key: ValueKey('main_messages')),
    const ProfileScreen(key: ValueKey('main_profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        key: const ValueKey('main_indexed_stack'),
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // The outer container for decoration (border and color) is fine.
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1.0,
            ),
          ),
        ),
        // Use SafeArea to wrap your content.
        child: SafeArea(
          // We remove the fixed-height container and use Padding for spacing.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home,
                      label: l10n.navHome,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.location_on,
                      label: l10n.navLocations,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.message,
                      label: l10n.navMessages,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person,
                      label: l10n.navProfile,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected ? AppTextStyles.navActive : AppTextStyles.navInactive,
            ),
          ],
        ),
      ),
    );
  }
}