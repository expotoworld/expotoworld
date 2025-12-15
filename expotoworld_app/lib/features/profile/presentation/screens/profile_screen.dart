import 'dart:math' as math;
import 'dart:ui' show lerpDouble, ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/app_router.dart';

/// Formats a number to a compact representation with max 3 significant digits
/// Examples: 1358 → "1.35K", 28743 → "28.7K", 1000000 → "1M", 134 → "134"
String formatCompactNumber(double value) {
  if (value >= 1000000000) {
    final billions = value / 1000000000;
    if (billions >= 100) return '${billions.floor()}B';
    if (billions >= 10) return '${(billions * 10).floor() / 10}B';
    return '${(billions * 100).floor() / 100}B';
  } else if (value >= 1000000) {
    final millions = value / 1000000;
    if (millions >= 100) return '${millions.floor()}M';
    if (millions >= 10) return '${(millions * 10).floor() / 10}M';
    return '${(millions * 100).floor() / 100}M';
  } else if (value >= 1000) {
    final thousands = value / 1000;
    if (thousands >= 100) return '${thousands.floor()}K';
    if (thousands >= 10) return '${(thousands * 10).floor() / 10}K';
    return '${(thousands * 100).floor() / 100}K';
  } else if (value >= 100) {
    return value.floor().toString();
  } else if (value >= 10) {
    return '${(value * 10).floor() / 10}';
  } else {
    return '${(value * 100).floor() / 100}';
  }
}

/// Profile screen with animated header, user info containers, settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  // Scroll controller for header animation
  final ScrollController _scrollController = ScrollController();

  // Animation controller for orbiting username
  late AnimationController _orbitAnimationController;

  // Header scroll state
  double _scrollOffset = 0;
  static const double _maxScrollOffset = 50;

  // Example user data (will be dynamic when connected to backend)
  static const String _username = 'soleyonghaosong2003isthebest!?';
  static const String _realName = 'Sole Yonghao Song';
  static const String _profileImageUrl =
      ''; // Empty for now, will show initials

  // Stats data (example values)
  static const double _totalSpent = 123456.78; // Will show as 123K
  static const double _totalSaved = 9870.0; // Will show as 9.87K
  static const int _memberYears = 1;
  static const int _memberMonths = 12;

  // Orders, Transactions, and Wallet data (example values)
  static const int _totalOrders = 1489;
  static const int _totalTransactions = 421;
  static const double _walletBalance = 3562.58;

  // Auth state (will be connected to actual auth provider later)
  static const bool _isLoggedIn = true; // Change to false to test inactive logout

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize orbit animation controller (10 seconds for one full rotation)
    _orbitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0, _maxScrollOffset);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _orbitAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate header animation values
    final scrollProgress = (_scrollOffset / _maxScrollOffset).clamp(0.0, 1.0);
    final titleScale = 1.0 - (scrollProgress * 0.4); // Scale from 1.0 to 0.6

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sticky header
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileHeaderDelegate(
              statusBarHeight: statusBarHeight,
              screenWidth: screenWidth,
              isDark: isDark,
              titleScale: titleScale,
              scrollProgress: scrollProgress,
              title: AppLocalizations.of(context)!.profileTitle,
              onNotificationTap: () {
                // Handle notification tap
              },
            ),
          ),

          // User info containers (space from header)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xl, // Reduced from xl*2 to xl
              ),
              child: _buildUserInfoContainers(context, isDark),
            ),
          ),

          // Orders and Transactions containers (side by side)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md, // Reduced from xl to md (50% less)
              ),
              child: _buildOrdersTransactionsRow(context, isDark),
            ),
          ),

          // Wallet container (full width)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md, // Reduced from xl to md (50% less)
              ),
              child: _buildWalletContainer(context, isDark),
            ),
          ),

          // Settings content - simplified list without cards/dividers
          SliverPadding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg, // Match header "Profile" text alignment
              right: AppSpacing.lg, // Match header bell icon alignment
              top: AppSpacing.xl,
              bottom: 100, // Comfortable buffer above bottom nav
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Simplified settings items with larger height
                _buildSimpleSettingsItem(
                  isDark: isDark,
                  icon: Icons.manage_accounts_outlined,
                  title: AppLocalizations.of(context)!.settingsAccountSettings,
                  onTap: () {
                    context.push(RoutePaths.accountSettings);
                  },
                ),
                _buildSimpleSettingsItem(
                  isDark: isDark,
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)!.settingsGetHelp,
                  onTap: () {
                    context.push(RoutePaths.getHelp);
                  },
                ),
                _buildSimpleSettingsItem(
                  isDark: isDark,
                  icon: Icons.lock_outline, // Changed from privacy_tip to lock
                  title: AppLocalizations.of(context)!.settingsPrivacy,
                  onTap: () {},
                ),
                _buildSimpleSettingsItem(
                  isDark: isDark,
                  icon: Icons.menu_book_outlined, // Changed from gavel to book
                  title: AppLocalizations.of(context)!.settingsLegal,
                  onTap: () {},
                ),
                SizedBox(height: AppSpacing.lg),
                // Logout button (conditional styling based on login state)
                _buildLogoutButton(context, isDark),
                SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single unified GlassCard with profile (left ~60%) and stats (right ~40%)
  /// High-gloss "Reflective" glass effect with specular highlight
  Widget _buildUserInfoContainers(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // Soft diffuse shadow to lift glass from background
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              radius: AppSpacing.radiusLg,
              strokeWidth: 1.5,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Base glass layer
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    // Glass fill with subtle gradient overlay for reflection
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.grey.shade900.withValues(alpha: 0.35),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.55),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left side (~60%) - Profile image with curved circular text
                        Expanded(
                          flex: 6,
                          child: _buildProfileSection(
                            context,
                            isDark,
                            _orbitAnimationController,
                          ),
                        ),
                        // Right side (~40%) - Stats columns
                        Expanded(flex: 4, child: _buildStatsSection(context, isDark)),
                      ],
                    ),
                  ),
                ),
                // Specular highlight - simulates bright light reflection
                Positioned(
                  top: -20,
                  left: -20,
                  right: 60,
                  child: IgnorePointer(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.2,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.15 : 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Secondary subtle shine along top edge
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.radiusLg),
                          topRight: Radius.circular(AppSpacing.radiusLg),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: isDark ? 0.4 : 0.7),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Orders and Transactions containers side by side
  Widget _buildOrdersTransactionsRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Orders container (left)
        Expanded(child: _buildOrdersContainer(context, isDark)),
        SizedBox(width: AppSpacing.md),
        // Transactions container (right)
        Expanded(child: _buildTransactionsContainer(context, isDark)),
      ],
    );
  }

  /// Orders container with monochromatic purple gradient + decorative shapes
  Widget _buildOrdersContainer(BuildContext context, bool isDark) {
    // Format number with comma separators
    final formattedOrders = _totalOrders.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // Purple-tinted shadow
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF4A2C58), // Deep purple (darker at bottom)
                Color(0xFF6A1B9A), // Exotic Purple (middle)
                Color(0xFF9C27B0), // Lighter purple (top)
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative translucent shapes for visual interest
              Positioned(
                top: -25,
                right: -20,
                child: IgnorePointer(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -18,
                left: 10,
                child: IgnorePointer(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFAB47BC).withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: -22,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                      width: 35,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              // Content layer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 18,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Total Orders',
                        style: AppTypography.caption().copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    formattedOrders,
                    style: AppTypography.h3(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Transactions container with monochromatic blue gradient + decorative shapes
  Widget _buildTransactionsContainer(BuildContext context, bool isDark) {
    // Format number with comma separators
    final formattedTransactions = _totalTransactions
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // Blue-tinted shadow
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF1A3D5C), // Slightly lighter navy (bottom) - smoother transition
                Color(0xFF2A5A8A), // Mid-blue transition
                Color(0xFF0066CC), // Blue (middle)
                Color(0xFF4A7CAA), // Transition to lighter
                Color(0xFF5A8CBC), // Lighter blue-grey (top)
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: const Color(0xFF5A8CBC).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative translucent shapes for visual interest
              Positioned(
                top: -22,
                left: -18,
                child: IgnorePointer(
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4A6C8C).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: 5,
                child: IgnorePointer(
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: -20,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      width: 30,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
              // Content layer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: 18,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Transactions',
                        style: AppTypography.caption().copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    formattedTransactions,
                    style: AppTypography.h3(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wallet container with glossy crystal effect (full width)
  Widget _buildWalletContainer(BuildContext context, bool isDark) {
    // Format balance with euro sign and comma separators
    final wholePart = _walletBalance.floor();
    final decimalPart = ((_walletBalance - wholePart) * 100)
        .round()
        .toString()
        .padLeft(2, '0');
    final formattedWhole = wholePart.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formattedBalance = '€$formattedWhole.$decimalPart';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // Colored shadow matching primary color
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          children: [
            // Base gradient layer (keeping original amber → red-orange)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFFEF4444), // Red-Orange (darker at bottom)
                    Color(0xFFF59E0B), // Amber (lighter at top)
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                // 1px white border for shape definition
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet, // Filled icon (bolder)
                          color: Colors.white,
                          size: 24, // Larger icon
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Wallet Balance',
                            style: AppTypography.caption().copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxs),
                          Text(
                            formattedBalance,
                            style: AppTypography.h2(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
            // Gloss overlay for crystal effect
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left section with circular profile image and curved circular text (stamp effect)
  Widget _buildProfileSection(
    BuildContext context,
    bool isDark,
    AnimationController orbitController,
  ) {
    // Get initials from real name
    final nameParts = _realName.split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : nameParts.first.substring(0, 2);

    // Avatar and orbit dimensions - 20% larger avatar (110 * 1.2 = 132)
    const double avatarSize = 132.0;
    const double orbitRadius = 82.0; // Distance from center to text characters
    const double containerSize = avatarSize + (orbitRadius * 2) + 6;

    // Prepare username for circular text (without @)
    final displayUsername = _username;

    return Align(
      alignment: const Alignment(0, 0),
      child: SizedBox(
        width: containerSize,
        height: containerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated curved circular text ring
            AnimatedBuilder(
              animation: orbitController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: orbitController.value * 2 * math.pi,
                  child: _buildCurvedText(
                    text: displayUsername,
                    radius: orbitRadius,
                    isDark: isDark,
                  ),
                );
              },
            ),
            // Central circular profile image (static)
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.themeRed, AppColors.themeRedLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeRed.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _profileImageUrl.isEmpty
                    ? Text(
                        initials.toUpperCase(),
                        style: AppTypography.h1(color: AppColors.neutralWhite),
                      )
                    : ClipOval(
                        child: Image.network(
                          _profileImageUrl,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds curved text arranged in a circle (stamp/coin effect)
  Widget _buildCurvedText({
    required String text,
    required double radius,
    required bool isDark,
  }) {
    final characters = text.split('');
    final characterCount = characters.length;

    // Calculate angle per character (evenly space characters around the circle)
    // Use a portion of the circle based on character count
    final totalArcAngle = math.min(
      2 * math.pi, // Max full circle
      characterCount * 0.18, // ~10.3 degrees per character (50% more spacing)
    );
    final startAngle =
        -math.pi / 2 - totalArcAngle / 2; // Start from top center

    return SizedBox(
      width: radius * 2 + 20,
      height: radius * 2 + 20,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(characterCount, (index) {
          // Calculate angle for this character
          final angle = startAngle + (index / characterCount) * totalArcAngle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(math.cos(angle) * radius, math.sin(angle) * radius)
              ..rotateZ(angle + math.pi / 2), // Rotate text to follow the curve
            child: Text(
              characters[index],
              style: TextStyle(
                color: isDark
                    ? AppColors.neutralGray400
                    : AppColors.neutralGray600,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Right section with stats (spent, saved, duration) - vertical layout, left-aligned, fills height
  Widget _buildStatsSection(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spent stat
        _buildStatItem(
          isDark: isDark,
          value: formatCompactNumber(_totalSpent),
          label: 'spent',
          prefix: '€',
        ),
        // Horizontal divider
        Container(
          height: 1,
          width: double.infinity,
          margin: EdgeInsets.only(right: AppSpacing.lg),
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        // Saved stat
        _buildStatItem(
          isDark: isDark,
          value: formatCompactNumber(_totalSaved),
          label: 'saved',
          prefix: '€',
        ),
        // Horizontal divider
        Container(
          height: 1,
          width: double.infinity,
          margin: EdgeInsets.only(right: AppSpacing.lg),
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        // Duration stat (years and months)
        _buildDurationItem(isDark: isDark, context: context),
      ],
    );
  }

  /// Single stat item widget - left-aligned, numbers on one line, label on next
  Widget _buildStatItem({
    required bool isDark,
    required String value,
    required String label,
    String? prefix,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number line with prefix (normal text, not superscript)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (prefix != null)
              Text(
                prefix,
                style: AppTypography.h4(
                  color: isDark
                      ? AppColors.neutralWhite
                      : AppColors.neutralBlack,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            Text(
              value,
              style: AppTypography.h4(
                color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        // Label line (bold w600, but not as bold as numbers w700)
        Text(
          label,
          style: AppTypography.caption().copyWith(
            color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Duration item widget - year and months as separate columns, left-aligned, with 'on EXPO to WORLD' below
  Widget _buildDurationItem({
    required bool isDark,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year and Months side by side as separate columns
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year column
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$_memberYears'.padLeft(2, '0'),
                  style: AppTypography.h4(
                    color: isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _memberYears == 1
                      ? l10n.profileYearSingular
                      : l10n.profileYearPlural,
                  style: AppTypography.caption().copyWith(
                    color: isDark
                        ? AppColors.neutralGray400
                        : AppColors.neutralGray600,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(width: AppSpacing.md),
            // Months column
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$_memberMonths'.padLeft(2, '0'),
                  style: AppTypography.h4(
                    color: isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _memberMonths == 1
                      ? l10n.profileMonthSingular
                      : l10n.profileMonthPlural,
                  style: AppTypography.caption().copyWith(
                    color: isDark
                        ? AppColors.neutralGray400
                        : AppColors.neutralGray600,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xxs),
        // 'on EXPO to WORLD' text (bold w600)
        Text(
          l10n.profileOnExpoToWorld,
          style: AppTypography.caption().copyWith(
            color: isDark ? AppColors.neutralGray500 : AppColors.neutralGray500,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Simplified settings item without card/border - just icon, text, and chevron
  /// Larger height to match wallet number size for elegant appearance
  Widget _buildSimpleSettingsItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.lg, // Increased from md to lg for taller items
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark
                  ? AppColors.neutralGray300
                  : AppColors.neutralGray700,
              size: 28, // Increased from 24 to 28 (matching wallet text scale)
            ),
            SizedBox(width: AppSpacing.lg), // Increased from md to lg
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium().copyWith(
                  color: isDark
                      ? AppColors.neutralWhite
                      : AppColors.neutralBlack,
                  fontWeight: FontWeight.w500,
                  fontSize: 14, // Reduced from 18 (25% less)
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.neutralGray500
                  : AppColors.neutralGray400,
              size: 28, // Increased from 24 to match icon size
            ),
          ],
        ),
      ),
    );
  }

  /// Simple logout button with border and conditional styling
  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    final isActive = _isLoggedIn;
    final buttonColor = isActive
        ? AppColors.red500
        : (isDark ? AppColors.neutralGray600 : AppColors.neutralGray400);

    return InkWell(
      onTap: isActive ? () {
        // Handle logout
      } : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: buttonColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: buttonColor,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.profileLogout,
              style: AppTypography.bodyMedium().copyWith(
                color: buttonColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom header delegate for sticky header with animation
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double screenWidth;
  final bool isDark;
  final double titleScale;
  final double scrollProgress;
  final String title;
  final VoidCallback onNotificationTap;

  _ProfileHeaderDelegate({
    required this.statusBarHeight,
    required this.screenWidth,
    required this.isDark,
    required this.titleScale,
    required this.scrollProgress,
    required this.title,
    required this.onNotificationTap,
  });

  // Position constants matching Messages screen exactly
  static const double _bellRowTop =
      16.0; // Same as search icon position in Messages
  static const double _titleRowTop = 65.0; // Title initial position
  static const double _collapsedTitleTop =
      20.0; // Title moves to bell row level

  @override
  double get minExtent => statusBarHeight + 80; // Collapsed height (no pills)

  @override
  double get maxExtent => statusBarHeight + 110; // Expanded height (no pills)

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.scrollProgress != scrollProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.title != title;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Show divider when scrolled (fade in effect)
    final showDivider = shrinkOffset > 10;
    final dividerOpacity = ((shrinkOffset - 10) / 20).clamp(0.0, 1.0);

    // Calculate animated positions
    final titleTop = lerpDouble(
      _titleRowTop,
      _collapsedTitleTop,
      scrollProgress,
    )!;

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color:
                        (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05))
                            .withValues(alpha: dividerOpacity * 0.06),
                    width: 1,
                  ),
                )
              : null,
          boxShadow: showDivider
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: dividerOpacity * 0.05,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Profile title (animates up on scroll)
            Positioned(
              top: statusBarHeight + titleTop,
              left: AppSpacing.lg,
              right: 60, // Leave room for bell icon when collapsed
              child: Transform.scale(
                scale: titleScale,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTypography.h1(
                    color: isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Notification bell icon (top right, same position as search icon in Messages)
            Positioned(
              top: statusBarHeight + _bellRowTop,
              right: AppSpacing.lg,
              child: _buildNotificationBell(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the notification bell icon matching the search icon style from Messages
  Widget _buildNotificationBell() {
    const buttonSize = 48.0;
    const safeChildSize = 46.0;

    return GestureDetector(
      onTap: onNotificationTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: safeChildSize,
            height: safeChildSize,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.themeRed,
                    size: 24,
                  ),
                  // Notification badge (optional - showing example with count)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.themeRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.neutralBlack
                              : AppColors.neutralWhite,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for gradient border effect on glassmorphic containers
class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}
