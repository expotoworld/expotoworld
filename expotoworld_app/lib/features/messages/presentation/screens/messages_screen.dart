import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Messages screen for notifications and communications
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
      body: Column(
        children: [
          // Status bar padding + title
          Container(
            padding: EdgeInsets.only(
              top: statusBarHeight + AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: AppTypography.h2(
                    color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.settings_outlined,
                  color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.neutralGray800
                  : AppColors.neutralGray100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.red500,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.neutralWhite,
              unselectedLabelColor:
                  isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
              labelStyle: AppTypography.labelMediumStyle,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Orders'),
                Tab(text: 'Promos'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllMessagesTab(isDark),
                _buildOrdersTab(isDark),
                _buildPromosTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllMessagesTab(bool isDark) {
    return ListView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: 120, // Extra padding for bottom nav bar
      ),
      children: [
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.local_shipping_outlined,
          iconColor: AppColors.blue500,
          title: 'Order Shipped',
          subtitle: 'Your order #MIW-2024-0892 has been shipped',
          time: '2 min ago',
          isUnread: true,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.discount_outlined,
          iconColor: AppColors.red500,
          title: 'Flash Sale Alert!',
          subtitle: 'Get 30% off on all Made in Italy products',
          time: '1 hour ago',
          isUnread: true,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.check_circle_outline,
          iconColor: AppColors.green500,
          title: 'Payment Confirmed',
          subtitle: 'Payment of ¥1,299.00 received successfully',
          time: '3 hours ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.stars_outlined,
          iconColor: AppColors.yellow500,
          title: 'Leave a Review',
          subtitle: 'How was your Japanese Sake? Share your thoughts!',
          time: 'Yesterday',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.campaign_outlined,
          iconColor: AppColors.exoticCoral,
          title: 'New Collection',
          subtitle: 'Discover the latest Made in France collection',
          time: '2 days ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.inventory_2_outlined,
          iconColor: AppColors.blue500,
          title: 'Back in Stock',
          subtitle: 'Swiss Chocolate Gift Set is available again!',
          time: '3 days ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.card_giftcard_outlined,
          iconColor: AppColors.exoticCoral,
          title: 'Birthday Reward',
          subtitle: 'Claim your special birthday discount!',
          time: '4 days ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.local_shipping_outlined,
          iconColor: AppColors.green500,
          title: 'Order Delivered',
          subtitle: 'Your order #MIW-2024-0850 has been delivered',
          time: '1 week ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.new_releases_outlined,
          iconColor: AppColors.yellow500,
          title: 'Limited Edition Alert',
          subtitle: 'Only 50 units available - Korean Ceramics Set',
          time: '1 week ago',
          isUnread: false,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildMessageCard(
          isDark: isDark,
          icon: Icons.support_agent_outlined,
          iconColor: AppColors.blue500,
          title: 'Support Response',
          subtitle: 'Your inquiry has been answered',
          time: '2 weeks ago',
          isUnread: false,
        ),
      ],
    );
  }

  Widget _buildOrdersTab(bool isDark) {
    return ListView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: 120, // Extra padding for bottom nav bar
      ),
      children: [
        _buildOrderCard(
          isDark: isDark,
          orderId: 'MIW-2024-0892',
          status: 'Shipped',
          statusColor: AppColors.blue500,
          itemCount: 3,
          totalAmount: '¥2,499.00',
          date: 'Nov 15, 2024',
        ),
        SizedBox(height: AppSpacing.sm),
        _buildOrderCard(
          isDark: isDark,
          orderId: 'MIW-2024-0891',
          status: 'Delivered',
          statusColor: AppColors.green500,
          itemCount: 1,
          totalAmount: '¥899.00',
          date: 'Nov 10, 2024',
        ),
        SizedBox(height: AppSpacing.sm),
        _buildOrderCard(
          isDark: isDark,
          orderId: 'MIW-2024-0889',
          status: 'Processing',
          statusColor: AppColors.yellow500,
          itemCount: 5,
          totalAmount: '¥4,199.00',
          date: 'Nov 8, 2024',
        ),
      ],
    );
  }

  Widget _buildPromosTab(bool isDark) {
    return ListView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: 120, // Extra padding for bottom nav bar
      ),
      children: [
        _buildPromoCard(
          isDark: isDark,
          title: 'EXPO2025 Special',
          description: 'Exclusive discounts for World Expo visitors',
          discount: '25% OFF',
          validUntil: 'Dec 31, 2025',
          backgroundColor: AppColors.red500,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildPromoCard(
          isDark: isDark,
          title: 'First Order Bonus',
          description: 'Welcome gift for new customers',
          discount: '¥100',
          validUntil: 'Valid once',
          backgroundColor: AppColors.blue500,
        ),
        SizedBox(height: AppSpacing.sm),
        _buildPromoCard(
          isDark: isDark,
          title: 'Weekend Flash Sale',
          description: 'Limited time offer on selected items',
          discount: '40% OFF',
          validUntil: 'This weekend',
          backgroundColor: AppColors.green500,
        ),
      ],
    );
  }

  Widget _buildMessageCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodyMedium().copyWith(
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: isDark
                              ? AppColors.neutralWhite
                              : AppColors.neutralBlack,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.red500,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall().copyWith(
                    color: isDark
                        ? AppColors.neutralGray400
                        : AppColors.neutralGray600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  time,
                  style: AppTypography.caption().copyWith(
                    color: isDark
                        ? AppColors.neutralGray500
                        : AppColors.neutralGray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required bool isDark,
    required String orderId,
    required String status,
    required Color statusColor,
    required int itemCount,
    required String totalAmount,
    required String date,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  status,
                  style: AppTypography.labelSmall().copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                '$itemCount items',
                style: AppTypography.bodySmall().copyWith(
                  color: isDark
                      ? AppColors.neutralGray400
                      : AppColors.neutralGray600,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                date,
                style: AppTypography.bodySmall().copyWith(
                  color: isDark
                      ? AppColors.neutralGray400
                      : AppColors.neutralGray600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.bodySmall().copyWith(
                  color: isDark
                      ? AppColors.neutralGray400
                      : AppColors.neutralGray600,
                ),
              ),
              Text(
                totalAmount,
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.red500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard({
    required bool isDark,
    required String title,
    required String description,
    required String discount,
    required String validUntil,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.neutralWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.neutralWhite.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.neutralWhite.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      validUntil,
                      style: AppTypography.caption().copyWith(
                        color: AppColors.neutralWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.neutralWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              discount,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.neutralWhite,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
