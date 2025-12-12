import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Profile screen with user info, settings, and preferences
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom header with title
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
                    'Profile',
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
            // Profile header
            _buildProfileHeader(context, isDark),
              SizedBox(height: AppSpacing.lg),
              // Stats row
              _buildStatsRow(isDark),
              SizedBox(height: AppSpacing.lg),
              // Settings sections
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Preferences', isDark),
                    SizedBox(height: AppSpacing.sm),
                    _buildThemeToggle(context, ref, themeMode, isDark),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildSectionTitle('Account', isDark),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Name, email, phone',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.location_on_outlined,
                      title: 'Shipping Addresses',
                      subtitle: '2 addresses saved',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Cards, Alipay, WeChat Pay',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildSectionTitle('Orders & Support', isDark),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.receipt_long_outlined,
                      title: 'Order History',
                      subtitle: 'View all past orders',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      subtitle: '12 items saved',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.headset_mic_outlined,
                      title: 'Customer Support',
                      subtitle: 'Get help with your orders',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildSectionTitle('About', isDark),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.info_outline,
                      title: 'About Made in World',
                      subtitle: 'Version 1.0.0',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildSettingsTile(
                      isDark: isDark,
                      icon: Icons.description_outlined,
                      title: 'Terms & Privacy',
                      subtitle: 'Legal information',
                      onTap: () {},
                    ),
                    SizedBox(height: AppSpacing.xl),
                    // Logout button
                    _buildLogoutButton(isDark),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GlassCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.red500, AppColors.red400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red500.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'JD',
                  style: TextStyle(
                    color: AppColors.neutralWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Doe',
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark
                          ? AppColors.neutralWhite
                          : AppColors.neutralBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    'john.doe@example.com',
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.yellow500, AppColors.yellow400],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars,
                          size: 14,
                          color: AppColors.neutralWhite,
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        Text(
                          'Gold Member',
                          style: AppTypography.labelSmall().copyWith(
                            color: AppColors.neutralWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Edit button
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.edit_outlined,
                color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.shopping_bag_outlined,
              value: '23',
              label: 'Orders',
              color: AppColors.blue500,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.star_outline,
              value: '1,280',
              label: 'Points',
              color: AppColors.yellow500,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              isDark: isDark,
              icon: Icons.local_offer_outlined,
              value: '5',
              label: 'Coupons',
              color: AppColors.green500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassCard(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.caption().copyWith(
              color: isDark
                  ? AppColors.neutralGray400
                  : AppColors.neutralGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return GlassCard(
      padding: EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusXl,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.exoticPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              color: AppColors.exoticPurple,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: AppTypography.bodyMedium().copyWith(
                    color: isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  themeMode == ThemeMode.dark
                      ? 'On'
                      : themeMode == ThemeMode.light
                          ? 'Off'
                          : 'System',
                  style: AppTypography.bodySmall().copyWith(
                    color: isDark
                        ? AppColors.neutralGray400
                        : AppColors.neutralGray600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
            activeColor: AppColors.red500,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.radiusXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.neutralGray800
                      : AppColors.neutralGray100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: isDark
                      ? AppColors.neutralGray300
                      : AppColors.neutralGray700,
                  size: 22,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium().copyWith(
                        color: isDark
                            ? AppColors.neutralWhite
                            : AppColors.neutralBlack,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall().copyWith(
                        color: isDark
                            ? AppColors.neutralGray400
                            : AppColors.neutralGray600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.neutralGray500
                    : AppColors.neutralGray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red500,
          side: const BorderSide(color: AppColors.red500),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}
