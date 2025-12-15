import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/promo_banner.dart';
import '../widgets/featured_products_section.dart';

/// Home screen with 2x2 sub-app grid and content feed
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _borderRadius = 24.0;
  
  // Configuration for the corner animation
  static const double _maxRadius = 24.0;
  static const double _scrollThreshold = 50.0; // Flatten within 50px of scroll
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final newRadius = (_maxRadius - (scrollOffset / _scrollThreshold * _maxRadius))
        .clamp(0.0, _maxRadius);
    
    if (newRadius != _borderRadius) {
      setState(() {
        _borderRadius = newRadius;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.themeRed,
      body: Column(
        children: [
          // Fixed header - stays at top while content scrolls
          ExpoAppBar(
            onQrTap: () {
              // TODO: NEED TO FULLY IMPLEMENT - Open QR scanner
            },
          ),
          
          // Scrollable content area with dynamic rounded top corners
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : AppColors.neutralWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner carousel section
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: 14,
                          bottom: AppSpacing.md,
                        ),
                        child: const PromoBanner(),
                      ),

                      // Mini-apps section with SVG images
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: AppSpacing.xs,
                          bottom: 10, // ~10px gap (sm + 2px)
                        ),
                        child: const SubAppGrid(),
                      ),

                      // Featured Products section
                      const Padding(
                        padding: EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          top: AppSpacing.md,
                          bottom: AppSpacing.md,
                        ),
                        child: FeaturedProductsSection(),
                      ),

                      // Bottom spacing for navigation bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2x2 Grid of sub-apps with SVG images
class SubAppGrid extends StatelessWidget {
  const SubAppGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate width for 2 columns with spacing
    // Screen width - padding (16*2) - gap (12) = available width / 2
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reduced horizontal gap (4px instead of 12px) to make logos ~10% wider
        const horizontalGap = AppSpacing.xs;
        final tileWidth = (constraints.maxWidth - horizontalGap) / 2;
        const tileHeight = 75.0;

        return Wrap(
          spacing: horizontalGap,
          runSpacing: AppSpacing.xs, // Reduced vertical gap between rows
          children: [
            // Row 1
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _MiniAppTile(
                assetPath: 'assets/mini-apps/toB.svg',
                onTap: () {
                  // TODO: Navigate to toB mini-app
                },
              ),
            ),
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _MiniAppTile(
                assetPath: 'assets/mini-apps/toC.svg',
                onTap: () {
                  // TODO: Navigate to toC mini-app
                },
              ),
            ),
            // Row 2
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _MiniAppTile(
                assetPath: 'assets/mini-apps/toU.svg',
                onTap: () {
                  // TODO: Navigate to toU mini-app
                },
              ),
            ),
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: _MiniAppTile(
                assetPath: 'assets/mini-apps/toX.svg',
                onTap: () {
                  // TODO: Navigate to toX mini-app
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual mini-app tile with SVG image, sheen effect, and breathing animation
class _MiniAppTile extends StatefulWidget {
  const _MiniAppTile({
    required this.assetPath,
    this.onTap,
  });

  final String assetPath;
  final VoidCallback? onTap;

  @override
  State<_MiniAppTile> createState() => _MiniAppTileState();
}

class _MiniAppTileState extends State<_MiniAppTile>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;

  // Sheen animation controller (sweeps every 3 seconds)
  late final AnimationController _sheenController;
  late final Animation<double> _sheenAnimation;

  // Breathing animation controller (gentle float up/down)
  late final AnimationController _breathingController;
  late final Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Sheen effect: sweeps diagonally every 3 seconds (3200ms sweep duration)
    _sheenController = AnimationController(
      duration: const Duration(milliseconds: 3200),
      vsync: this,
    );
    _sheenAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _sheenController, curve: Curves.easeInOut),
    );
    // Repeat sheen every 3 seconds
    _startSheenLoop();

    // Breathing effect: heartbeat-style pulse
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 200), // Slower pulse duration
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.005).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeOut),
    );
    _startHeartbeatLoop();
  }

  void _startSheenLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _sheenController.forward(from: 0);
      }
    }
  }

  // Heartbeat pattern: two beats, then 5 second pause, repeat
  void _startHeartbeatLoop() async {
    while (mounted) {
      // First beat: increase → decrease
      if (mounted) {
        await _breathingController.forward();
        await _breathingController.reverse();
      }
      // Short pause between beats
      await Future.delayed(const Duration(milliseconds: 150));
      // Second beat: increase → decrease
      if (mounted) {
        await _breathingController.forward();
        await _breathingController.reverse();
      }
      // Long pause (5 seconds) before repeating
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  void dispose() {
    _sheenController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _isPressed || _isHovered;

    return AnimatedBuilder(
      animation: Listenable.merge([_sheenAnimation, _breathingAnimation]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(_isPressed ? 0.96 : _breathingAnimation.value),
              child: Stack(
                children: [
                  // Subtle directional shadow - bottom-right
                  if (!_isPressed)
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              // Shadow - red in dark mode for visibility, black in light mode
                              color: isDark
                                  ? AppColors.themeRed
                                      .withValues(alpha: isActive ? 0.5 : 0.3)
                                  : Colors.black
                                      .withValues(alpha: isActive ? 0.2 : 0.15),
                              blurRadius: isActive ? 12 : 10,
                              spreadRadius: isActive ? 1 : 0,
                              offset: const Offset(4, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // SVG logo - fills tile with minimal margin
                  Padding(
                    padding: const EdgeInsets.all(1),
                    child: SvgPicture.asset(
                      widget.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Sheen effect overlay - diagonal light sweep
                  Positioned.fill(
                    child: ClipRect(
                      child: IgnorePointer(
                        child: Transform.translate(
                          offset: Offset(
                            _sheenAnimation.value * 200,
                            _sheenAnimation.value * 80,
                          ),
                          child: Transform.rotate(
                            angle: -0.5, // Diagonal angle
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white
                                        .withValues(alpha: isDark ? 0.35 : 0.3),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
