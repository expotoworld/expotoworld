import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Promotional banner carousel with infinite seamless auto-play
class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  // Virtual infinite scroll - use a large number
  static const int _virtualPageCount = 10000;

  // TODO: DUMMY DATA
  final List<PromoItem> _promos = [
    PromoItem(
      title: 'Welcome to EXPO to WORLD',
      subtitle: 'Your gateway to premium global retail',
      color: AppColors.themeRed,
      icon: Icons.celebration_rounded,
    ),
    PromoItem(
      title: 'New Arrivals',
      subtitle: 'Discover the latest products from top manufacturers',
      color: AppColors.blue,
      icon: Icons.new_releases_rounded,
    ),
    PromoItem(
      title: 'Group Deals',
      subtitle: 'Join now and save up to 40%',
      color: AppColors.purple,
      icon: Icons.groups_rounded,
    ),
  ];

  // Start from the middle to allow scrolling both directions
  int get _initialPage => (_virtualPageCount ~/ 2) - ((_virtualPageCount ~/ 2) % _promos.length);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _currentPage = 0;
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        // Always animate to next page (scrolls left, seamless infinite loop)
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          // Banner PageView with virtual infinite scroll
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index % _promos.length);
            },
            // Virtual infinite item count
            itemCount: _virtualPageCount,
            itemBuilder: (context, index) {
              // Map virtual index to actual promo index
              final actualIndex = index % _promos.length;
              final promo = _promos[actualIndex];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      promo.color,
                      promo.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: promo.color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        promo.icon,
                        size: 140,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        top: AppSpacing.xl,
                        bottom: AppSpacing.xxxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo.title,
                            style: AppTypography.h3(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            promo.subtitle,
                            style: AppTypography.bodySmall(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Fixed page indicators (outside PageView)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _promos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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

class PromoItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  PromoItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}
