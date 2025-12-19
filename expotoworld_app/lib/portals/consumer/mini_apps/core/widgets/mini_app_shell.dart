import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../providers/mini_app_providers.dart';

/// Shell widget for mini-apps with 3-tab bottom navigation (Home, Cart, Map)
/// or 1-tab for to X (only Home screen)
class MiniAppShell extends ConsumerWidget {
  final MiniAppType miniAppType;
  final Widget child;

  const MiniAppShell({
    super.key,
    required this.miniAppType,
    required this.child,
  });

  int _getSelectedIndex(String location) {
    if (location.contains('/cart')) return 1;
    if (location.contains('/map')) return 2;
    return 0;
  }

  void _onIndexChanged(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/mini-app/${miniAppType.name}/home');
        break;
      case 1:
        context.go('/mini-app/${miniAppType.name}/cart');
        break;
      case 2:
        context.go('/mini-app/${miniAppType.name}/map');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);
    final cartItemCount = ref.watch(miniAppCartItemCountProvider(miniAppType));

    // For to X, don't show bottom nav bar at all
    if (!miniAppType.hasCart && !miniAppType.hasMap) {
      return Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: child,
      );
    }

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: child,
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
                    isSelected: selectedIndex == 0,
                    onTap: () => _onIndexChanged(context, 0),
                  ),
                ),
                // Cart tab (with badge)
                if (miniAppType.hasCart)
                  Expanded(
                    child: _MiniAppNavItem(
                      icon: Icons.shopping_cart_outlined,
                      activeIcon: Icons.shopping_cart_rounded,
                      isSelected: selectedIndex == 1,
                      onTap: () => _onIndexChanged(context, 1),
                      badgeCount: cartItemCount,
                    ),
                  ),
                // Map tab
                if (miniAppType.hasMap)
                  Expanded(
                    child: _MiniAppNavItem(
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      isSelected: selectedIndex == 2,
                      onTap: () => _onIndexChanged(context, 2),
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

/// Individual navigation item widget with wiggle animation and optional badge
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  key: ValueKey(widget.isSelected),
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
                top: 4,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.themeRed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.themeRed.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                    style: AppTypography.caption(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
