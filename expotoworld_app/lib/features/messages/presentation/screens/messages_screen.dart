import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Message filter categories
enum MessageFilter {
  all('All'),
  unread('Unread'),
  system('System'),
  support('Support'),
  orders('Orders');

  final String label;
  const MessageFilter(this.label);
}

/// Message type for different message categories
enum MessageType { system, support, order, promo }

/// Message model
class Message {
  final String id;
  final String senderName;
  final String? senderAvatar;
  final String senderInitials;
  final String preview;
  final String time;
  final bool isUnread;
  final MessageType type;
  final Color avatarColor;
  final IconData? typeIcon;
  final bool canReply;

  const Message({
    required this.id,
    required this.senderName,
    this.senderAvatar,
    required this.senderInitials,
    required this.preview,
    required this.time,
    required this.isUnread,
    required this.type,
    required this.avatarColor,
    this.typeIcon,
    this.canReply = true,
  });
}

/// Messages screen with animated header, filter pills, and support FAB
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with TickerProviderStateMixin {
  // Scroll controller for header animation
  final ScrollController _scrollController = ScrollController();

  // Search state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _searchAnimationController;
  late Animation<double> _searchWidthAnimation;
  String _searchQuery = '';

  // Filter state
  MessageFilter _selectedFilter = MessageFilter.all;

  // Header scroll state
  double _scrollOffset = 0;
  static const double _maxScrollOffset = 50;

  // Dummy messages data
  final List<Message> _messages = [
    Message(
      id: '1',
      senderName: 'EXPO to WORLD',
      senderInitials: 'EW',
      preview:
          'Welcome to EXPO to WORLD! Your global gateway to authentic products.',
      time: '2 min ago',
      isUnread: true,
      type: MessageType.system,
      avatarColor: AppColors.themeRed,
      typeIcon: Icons.celebration_outlined,
      canReply: false,
    ),
    Message(
      id: '2',
      senderName: 'Order Update',
      senderInitials: 'OU',
      preview:
          'Your order #MIW-2024-0892 has been shipped! Track your package now.',
      time: '15 min ago',
      isUnread: true,
      type: MessageType.order,
      avatarColor: AppColors.blue500,
      typeIcon: Icons.local_shipping_outlined,
    ),
    Message(
      id: '3',
      senderName: 'Customer Support',
      senderInitials: 'CS',
      preview:
          'Thank you for reaching out! We have received your inquiry and will respond shortly.',
      time: '1 hour ago',
      isUnread: true,
      type: MessageType.support,
      avatarColor: AppColors.green500,
      typeIcon: Icons.support_agent_outlined,
    ),
    Message(
      id: '4',
      senderName: 'Flash Sale Alert',
      senderInitials: 'FS',
      preview:
          '🔥 30% OFF on all Made in Italy products! Limited time offer ends tonight.',
      time: '2 hours ago',
      isUnread: false,
      type: MessageType.promo,
      avatarColor: AppColors.exoticCoral,
      typeIcon: Icons.local_fire_department_outlined,
      canReply: false,
    ),
    Message(
      id: '5',
      senderName: 'Payment Confirmed',
      senderInitials: 'PC',
      preview:
          'Payment of ¥1,299.00 received successfully for order #MIW-2024-0892.',
      time: '3 hours ago',
      isUnread: false,
      type: MessageType.order,
      avatarColor: AppColors.green500,
      typeIcon: Icons.check_circle_outline,
    ),
    Message(
      id: '6',
      senderName: 'System Notification',
      senderInitials: 'SN',
      preview:
          'Your account verification is complete. Enjoy full access to all features!',
      time: '5 hours ago',
      isUnread: false,
      type: MessageType.system,
      avatarColor: AppColors.purple,
      typeIcon: Icons.verified_outlined,
      canReply: false,
    ),
    Message(
      id: '7',
      senderName: 'Review Request',
      senderInitials: 'RR',
      preview:
          'How was your Japanese Sake? Share your thoughts and earn 50 bonus points!',
      time: 'Yesterday',
      isUnread: false,
      type: MessageType.order,
      avatarColor: AppColors.yellow500,
      typeIcon: Icons.star_outline,
    ),
    Message(
      id: '8',
      senderName: 'New Collection',
      senderInitials: 'NC',
      preview:
          '✨ Discover the latest Made in France artisan collection. Shop now!',
      time: 'Yesterday',
      isUnread: false,
      type: MessageType.promo,
      avatarColor: AppColors.blue500,
      typeIcon: Icons.new_releases_outlined,
      canReply: false,
    ),
    Message(
      id: '9',
      senderName: 'Order Delivered',
      senderInitials: 'OD',
      preview:
          'Your order #MIW-2024-0850 has been delivered. Enjoy your products!',
      time: '2 days ago',
      isUnread: false,
      type: MessageType.order,
      avatarColor: AppColors.green500,
      typeIcon: Icons.inventory_2_outlined,
    ),
    Message(
      id: '10',
      senderName: 'Support Team',
      senderInitials: 'ST',
      preview:
          'Your inquiry about international shipping has been resolved. View details.',
      time: '3 days ago',
      isUnread: false,
      type: MessageType.support,
      avatarColor: AppColors.blue500,
      typeIcon: Icons.question_answer_outlined,
    ),
    Message(
      id: '11',
      senderName: 'Birthday Reward',
      senderInitials: 'BR',
      preview:
          '🎂 Happy Birthday! Claim your special 20% discount valid for 7 days.',
      time: '1 week ago',
      isUnread: false,
      type: MessageType.promo,
      avatarColor: AppColors.exoticCoral,
      typeIcon: Icons.cake_outlined,
      canReply: false,
    ),
    Message(
      id: '12',
      senderName: 'Back in Stock',
      senderInitials: 'BS',
      preview:
          'Great news! Swiss Chocolate Gift Set is available again. Order now!',
      time: '1 week ago',
      isUnread: false,
      type: MessageType.promo,
      avatarColor: AppColors.yellow500,
      typeIcon: Icons.inventory_outlined,
      canReply: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initSearchAnimation();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _initSearchAnimation() {
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchWidthAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    );
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset.clamp(0, _maxScrollOffset);
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    if (_isSearchExpanded) {
      _searchAnimationController.forward();
      // Auto-focus the search field when expanding
      _searchFocusNode.requestFocus();
      // Scroll to collapse header (hide Messages title, show pills)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _maxScrollOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      _searchFocusNode.unfocus();
      // Scroll back to expanded header
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  List<Message> get _filteredMessages {
    var messages = _messages;

    // Apply filter
    if (_selectedFilter != MessageFilter.all) {
      messages = messages.where((m) {
        switch (_selectedFilter) {
          case MessageFilter.unread:
            return m.isUnread;
          case MessageFilter.system:
            return m.type == MessageType.system;
          case MessageFilter.support:
            return m.type == MessageType.support;
          case MessageFilter.orders:
            return m.type == MessageType.order;
          case MessageFilter.all:
            return true;
        }
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      messages = messages.where((m) {
        return m.senderName.toLowerCase().contains(_searchQuery) ||
            m.preview.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return messages;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calculate header animation values
    final scrollProgress = (_scrollOffset / _maxScrollOffset).clamp(0.0, 1.0);
    final titleScale =
        1.0 -
        (scrollProgress * 0.4); // Scale from 1.0 to 0.6 (smaller when at top)
    final titleTranslateY =
        scrollProgress * 12; // Move up (legacy, may not be used)

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.neutralWhite,
      body: Stack(
        children: [
          // Main content with CustomScrollView
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky header
              SliverPersistentHeader(
                pinned: true,
                delegate: _MessagesHeaderDelegate(
                  statusBarHeight: statusBarHeight,
                  screenWidth: screenWidth,
                  isDark: isDark,
                  titleScale: titleScale,
                  titleTranslateY: titleTranslateY,
                  scrollProgress: scrollProgress,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                  isSearchExpanded: _isSearchExpanded,
                  searchAnimation: _searchWidthAnimation,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSearchToggle: _toggleSearch,
                ),
              ),

              // Messages list - minimal top padding for gap below filters
              SliverPadding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.xxs, // Minimal gap below filter pills
                  bottom: 150 + keyboardHeight, // Extra padding for FAB, bottom nav, and keyboard
                ),
                sliver: _filteredMessages.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState(isDark))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final message = _filteredMessages[index];
                          return _buildMessageItem(message, isDark);
                        }, childCount: _filteredMessages.length),
                      ),
              ),
            ],
          ),

          // Support FAB with floating panel
          Positioned(
            right: AppSpacing.lg,
            bottom: 120, // Higher up, well above bottom nav
            child: _buildSupportFab(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to message conversation screen
        context.push(
          RoutePaths.messageConversation,
          extra: {
            'messageId': message.id,
            'senderName': message.senderName,
            'senderInitials': message.senderInitials,
            'avatarColor': message.avatarColor,
            'typeIcon': message.typeIcon,
            'canReply': message.canReply,
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        // No dividers between messages
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar - square with rounded corners, larger size
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    message.avatarColor,
                    message.avatarColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: message.typeIcon != null
                    ? Icon(message.typeIcon, color: Colors.white, size: 28)
                    : Text(
                        message.senderInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          style: AppTypography.bodyMedium().copyWith(
                            fontWeight: message.isUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isDark
                                ? AppColors.neutralWhite
                                : AppColors.neutralBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        message.time,
                        style: AppTypography.caption().copyWith(
                          color: isDark
                              ? AppColors.neutralGray500
                              : AppColors.neutralGray400,
                        ),
                      ),
                      // Unread indicator dot on the right
                      if (message.isUnread) ...[
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.themeRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    message.preview,
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.neutralGray800
                  : AppColors.neutralGray100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 40,
              color: isDark
                  ? AppColors.neutralGray500
                  : AppColors.neutralGray400,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.messagesNoMessages,
            style: AppTypography.h4(
              color: isDark
                  ? AppColors.neutralGray400
                  : AppColors.neutralGray600,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            _searchQuery.isNotEmpty
                ? AppLocalizations.of(context)!.messagesTryDifferentSearch
                : AppLocalizations.of(context)!.messagesWillAppear,
            style: AppTypography.bodySmall().copyWith(
              color: isDark
                  ? AppColors.neutralGray500
                  : AppColors.neutralGray400,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the support FAB that navigates to support chat
  Widget _buildSupportFab(bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to support conversation screen (outside shell, no bottom nav)
        context.push(RoutePaths.supportChat);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.themeRed, AppColors.themeRedLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.themeRed.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.themeRed.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Custom header delegate for sticky header with animation
class _MessagesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double statusBarHeight;
  final double screenWidth;
  final bool isDark;
  final double titleScale;
  final double titleTranslateY;
  final double scrollProgress;
  final MessageFilter selectedFilter;
  final ValueChanged<MessageFilter> onFilterChanged;
  final bool isSearchExpanded;
  final Animation<double> searchAnimation;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchToggle;

  _MessagesHeaderDelegate({
    required this.statusBarHeight,
    required this.screenWidth,
    required this.isDark,
    required this.titleScale,
    required this.titleTranslateY,
    required this.scrollProgress,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isSearchExpanded,
    required this.searchAnimation,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchToggle,
  });

  // Expanded: title at row 2, collapsed: title moves up to search icon row
  static const double _searchRowTop = 16.0; // Below status bar (moved down from 8.0 to align with map)
  static const double _titleRowTop = 65.0; // Title initial position
  static const double _pillsRowTop =
      125.0; // Pills initial position (~20% more gap from 112)
  static const double _collapsedTitleTop =
      20.0; // Title moves to search row level (adjusted from 12.0)
  static const double _collapsedPillsTop = 86.0; // Pills move up (increased from 58 for better spacing from search)

  @override
  double get minExtent => statusBarHeight + 135; // Collapsed height

  @override
  double get maxExtent => statusBarHeight + 175; // Expanded height (increased for more gap)

  @override
  bool shouldRebuild(covariant _MessagesHeaderDelegate oldDelegate) {
    return oldDelegate.scrollProgress != scrollProgress ||
        oldDelegate.selectedFilter != selectedFilter ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isSearchExpanded != isSearchExpanded;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Show divider when scrolled
    final showDivider = shrinkOffset > 10;

    // Calculate animated positions
    final titleTop = lerpDouble(
      _titleRowTop,
      _collapsedTitleTop,
      scrollProgress,
    )!;
    final pillsTop = lerpDouble(
      _pillsRowTop,
      _collapsedPillsTop,
      scrollProgress,
    )!;

    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : AppColors.neutralWhite,
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Messages title (animates up on scroll) - hidden when search is expanded
            Positioned(
              top: statusBarHeight + titleTop,
              left: AppSpacing.lg,
              right: 60, // Leave room for search icon when collapsed
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSearchExpanded ? 0.0 : 1.0,
                child: Transform.scale(
                  scale: titleScale,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context)!.navMessages,
                    style: AppTypography.h1(
                      color: isDark
                          ? AppColors.neutralWhite
                          : AppColors.neutralBlack,
                    ),
                  ),
                ),
              ),
            ),

            // Filter pills (animate up with title)
            Positioned(
              top: statusBarHeight + pillsTop,
              left: 0,
              right: 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: MessageFilter.values.map((filter) {
                    final isSelected = filter == selectedFilter;
                    final l10n = AppLocalizations.of(context)!;
                    final filterLabel = switch (filter) {
                      MessageFilter.all => l10n.messagesFilterAll,
                      MessageFilter.unread => l10n.messagesFilterUnread,
                      MessageFilter.system => l10n.messagesFilterSystem,
                      MessageFilter.support => l10n.messagesFilterSupport,
                      MessageFilter.orders => l10n.messagesFilterOrders,
                    };
                    return Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterPill(
                        label: filterLabel,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => onFilterChanged(filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Search bar (top right) - placed last (top) so it's above title
            Positioned(
              top: statusBarHeight + _searchRowTop,
              right: AppSpacing.lg,
              child: _buildSearchWidget(),
            ),
          ],
        ),
      ),
    );
  }

  // Search widget - EXACT copy of map screen _buildAnimatedSearchBar style
  Widget _buildSearchWidget() {
    // Match map screen dimensions exactly
    const buttonSize = 48.0;
    const safeChildSize = 46.0;
    final expandedWidth = screenWidth - (AppSpacing.lg * 2);

    return AnimatedBuilder(
      animation: searchAnimation,
      builder: (context, child) {
        final animValue = searchAnimation.value;
        final currentWidth =
            buttonSize + (animValue * (expandedWidth - buttonSize));
        final isExpanded = animValue > 0.05;

        return Container(
          width: currentWidth,
          height: buttonSize,
          // Match map screen: enable clipping for round corners
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            // Match map screen: same background color for both states
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
          child: Row(
            children: [
              // Search input field (visible when expanded)
              if (isExpanded)
                Expanded(
                  child: Opacity(
                    opacity: animValue,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24, // Match map screen padding
                        right: AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTypography.bodyMedium(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.messagesSearchHint,
                          hintStyle: AppTypography.bodyMedium(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                ),

              // Search/Close icon button with rotation animation
              GestureDetector(
                onTap: onSearchToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: safeChildSize,
                  height: safeChildSize,
                  child: Center(
                    child: Padding(
                      // Match map screen: optical adjustment for magnifying glass icon
                      padding: EdgeInsets.only(
                        left: isSearchExpanded ? 0 : 1,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: Tween(
                              begin: 0.25,
                              end: 0.0,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isSearchExpanded
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          key: ValueKey(isSearchExpanded),
                          color: isSearchExpanded
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.6))
                              : AppColors.themeRed,
                          size: 24, // Match map screen icon size
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Filter pill widget - no bleeding shadow
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed
              : isDark
              ? AppColors.neutralGray800
              : AppColors.neutralGray100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.themeRed
                : isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium().copyWith(
            color: isSelected
                ? Colors.white
                : isDark
                ? AppColors.neutralGray400
                : AppColors.neutralGray600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
