import 'dart:ui';
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
                color: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
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
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          top: AppSpacing.xs,
                          bottom: AppSpacing.md,
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
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        // Fixed height - taller than SVG aspect ratio for equal vertical padding
        const tileHeight = 90.0;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
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

/// Individual mini-app tile with SVG image and lift effect
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

class _MiniAppTileState extends State<_MiniAppTile> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _isPressed || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.96 : 1.0)
            ..translate(0.0, _isPressed ? 2.0 : 0.0),
          child: Stack(
            children: [
              // Red glow layer - MORE AGGRESSIVE for both modes
              if (!_isPressed)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        // Primary red glow - STRONGER
                        BoxShadow(
                          color: AppColors.themeRed.withValues(
                            alpha: isDark
                                ? (isActive ? 0.35 : 0.2)
                                : (isActive ? 0.4 : 0.25), // More visible in light mode
                          ),
                          blurRadius: isActive ? 28 : 20,
                          spreadRadius: isActive ? 4 : 1,
                          offset: const Offset(0, 6),
                        ),
                        // Secondary red glow for edge lighting
                        BoxShadow(
                          color: AppColors.themeRed.withValues(
                            alpha: isDark ? 0.15 : 0.18,
                          ),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                        // Deep shadow for lift effect
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),
              // Glass morphism card with red accent border
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      // Glass gradient - slightly warmer in light mode
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.04),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.85),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      // Subtle border - no red accent
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: isActive ? 0.15 : 0.08)
                            : Colors.black.withValues(alpha: isActive ? 0.1 : 0.05),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Top edge red accent line (premium detail)
                        Positioned(
                          top: 0,
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                          height: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.themeRed.withValues(alpha: 0),
                                  AppColors.themeRed.withValues(alpha: isDark ? 0.5 : 0.6),
                                  AppColors.themeRed.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Specular highlight (top shine)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 35,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppSpacing.radiusXl),
                                topRight: Radius.circular(AppSpacing.radiusXl),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // SVG content with shadow effect
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              widget.assetPath,
                              fit: BoxFit.contain,
                              colorFilter: isDark
                                  ? null // Keep original colors in dark mode
                                  : null, // Keep original colors in light mode
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
