import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/router/app_router.dart';

/// Main shell widget that wraps all screens with bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.home) && location == RoutePaths.home) {
      return 0;
    }
    if (location.startsWith(RoutePaths.map)) {
      return 1;
    }
    if (location.startsWith(RoutePaths.messages)) {
      return 2;
    }
    if (location.startsWith(RoutePaths.profile)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
        break;
      case 1:
        context.go(RoutePaths.map);
        break;
      case 2:
        context.go(RoutePaths.messages);
        break;
      case 3:
        context.go(RoutePaths.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: widget.child,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          bottom: bottomPadding > 5 ? bottomPadding - 5 : 0,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            // Solid semi-transparent background without backdrop blur - no artifacts
            color: isDark
                ? const Color(0xEE1C1C1E) // Dark gray, mostly opaque
                : const Color(0xF5FFFFFF), // White, mostly opaque
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTapped(0, context),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map_rounded,
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(2, context),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(3, context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item widget with wiggle animation
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wiggleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.09), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.09, end: 0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.03), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _wiggleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _wiggleController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _wiggleAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _wiggleAnimation.value,
            child: child,
          );
        },
        child: Container(
          // Fill available space from Expanded
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isSelected ? 30 : AppSpacing.md, // 30 for bubble padding
              vertical: widget.isSelected ? AppSpacing.md : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.themeRed.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              widget.isSelected ? widget.activeIcon : widget.icon,
              size: 28,
              color: widget.isSelected
                  ? AppColors.themeRed
                  : isDark
                      ? AppColors.darkForegroundSubtle
                      : AppColors.lightForegroundSubtle,
            ),
          ),
        ),
      ),
    );
  }
}
