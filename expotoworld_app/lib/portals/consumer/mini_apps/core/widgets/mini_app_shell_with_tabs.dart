import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../providers/mini_app_providers.dart';
import '../screens/mini_app_cart_screen.dart';
import '../screens/mini_app_map_screen.dart';
import '../../to_b/to_b.dart';
import '../../to_c/to_c.dart';
import '../../to_u/to_u.dart';
import '../../to_x/to_x.dart';

/// Shell widget for mini-apps with internal tab management via IndexedStack
/// 
/// This approach preserves the navigation stack when switching tabs, ensuring
/// proper close animation (slide down) when exiting the mini-app.
class MiniAppShellWithTabs extends ConsumerStatefulWidget {
  final MiniAppType miniAppType;
  final int initialTabIndex;

  const MiniAppShellWithTabs({
    super.key,
    required this.miniAppType,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<MiniAppShellWithTabs> createState() => _MiniAppShellWithTabsState();
}

class _MiniAppShellWithTabsState extends ConsumerState<MiniAppShellWithTabs> {
  @override
  void initState() {
    super.initState();
    // Set initial tab index via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniAppActiveTabIndexProvider(widget.miniAppType).notifier).state = 
          widget.initialTabIndex;
    });
  }

  void _onIndexChanged(int index) {
    ref.read(miniAppActiveTabIndexProvider(widget.miniAppType).notifier).state = index;
  }

  Widget _buildHomeScreen() {
    // Home screens have their own handleClose() method which will use
    // Navigator.of(context, rootNavigator: true).pop() - this works because
    // we're now using a single GoRoute, so the stack is preserved.
    switch (widget.miniAppType) {
      case MiniAppType.toB:
        return const ToBHomeScreen();
      case MiniAppType.toC:
        return const ToCHomeScreen();
      case MiniAppType.toU:
        return const ToUHomeScreen();
      case MiniAppType.toX:
        return const ToXHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final cartItemCount = ref.watch(miniAppCartItemCountProvider(widget.miniAppType));
    final currentIndex = ref.watch(miniAppActiveTabIndexProvider(widget.miniAppType));

    // Build the tab screens
    final screens = [
      _buildHomeScreen(),
      if (widget.miniAppType.hasCart)
        MiniAppCartScreen(miniAppType: widget.miniAppType),
      if (widget.miniAppType.hasMap)
        MiniAppMapScreen(miniAppType: widget.miniAppType),
    ];

    // For toX, don't show bottom nav bar at all
    if (!widget.miniAppType.hasCart && !widget.miniAppType.hasMap) {
      return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: screens[0], // Only home screen for toX
      );
    }

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          bottom: bottomPadding > 5 ? bottomPadding - 5 : 0,
        ),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xEE1C1C1E)
                : const Color(0xF5FFFFFF),
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
                // Home tab
                Expanded(
                  child: _MiniAppNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    isSelected: currentIndex == 0,
                    onTap: () => _onIndexChanged(0),
                  ),
                ),
                // Cart tab (with badge)
                if (widget.miniAppType.hasCart)
                  Expanded(
                    child: _MiniAppNavItem(
                      icon: Icons.shopping_cart_outlined,
                      activeIcon: Icons.shopping_cart_rounded,
                      isSelected: currentIndex == 1,
                      onTap: () => _onIndexChanged(1),
                      badgeCount: cartItemCount,
                    ),
                  ),
                // Map tab
                if (widget.miniAppType.hasMap)
                  Expanded(
                    child: _MiniAppNavItem(
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      isSelected: currentIndex == 2,
                      onTap: () => _onIndexChanged(2),
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

/// Individual navigation item widget with scale tap animation and optional badge
class _MiniAppNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _MiniAppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_MiniAppNavItem> createState() => _MiniAppNavItemState();
}

class _MiniAppNavItemState extends State<_MiniAppNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Shrink first, then back to normal (press down effect)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleController.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              // Simple icon without AnimatedSwitcher to avoid dual-icon movement
              child: Icon(
                widget.isSelected ? widget.activeIcon : widget.icon,
                size: 28,
                color: widget.isSelected
                    ? AppColors.themeRed
                    : isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Badge for cart item count
          if (widget.badgeCount > 0)
            Positioned(
              top: 2,
              // Dynamic right position based on badge count width
              // count < 10: single digit, right: 30
              // count >= 10: double digit, right: 25
              // count >= 100: shows "99+", right: 20
              right: widget.badgeCount >= 100 ? 20 : widget.badgeCount >= 10 ? 25 : 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.themeRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                  style: AppTypography.caption(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
