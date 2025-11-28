import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.displayName ?? AppLocalizations.of(context)!.valuedUser;
        final userEmail = user?.email ?? 'user.name@email.com';
        const userAvatarUrl = 'https://i.pravatar.cc/96';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: AppTextStyles.majorHeader,
        ),
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Settings
            },
            icon: const Icon(
              Icons.settings,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: CachedNetworkImage(
                        imageUrl: userAvatarUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.lightRed,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.themeRed,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.lightRed,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.themeRed,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+41791234567',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    
                    // Edit button
                    IconButton(
                      onPressed: () {
                        // Edit profile
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Menu Items
            _buildMenuSection(AppLocalizations.of(context)!.orderManagementSection, [
              _buildMenuItem(Icons.shopping_bag, AppLocalizations.of(context)!.myOrders, () {}),
              _buildMenuItem(Icons.favorite, AppLocalizations.of(context)!.myFavorites, () {}),
              _buildMenuItem(Icons.history, AppLocalizations.of(context)!.browsingHistory, () {}),
            ]),

            const SizedBox(height: 16),

            _buildMenuSection(AppLocalizations.of(context)!.accountSettings, [
              _buildMenuItem(Icons.location_on, AppLocalizations.of(context)!.shippingAddress, () {}),
              _buildMenuItem(Icons.payment, AppLocalizations.of(context)!.paymentMethods, () {}),
              _buildMenuItem(Icons.security, AppLocalizations.of(context)!.accountSecurity, () {}),
            ]),

            const SizedBox(height: 16),

            _buildMenuSection(AppLocalizations.of(context)!.helpAndSupport, [
              _buildMenuItem(Icons.help, AppLocalizations.of(context)!.helpCenter, () {}),
              _buildMenuItem(Icons.feedback, AppLocalizations.of(context)!.feedback, () {}),
              _buildMenuItem(Icons.info, AppLocalizations.of(context)!.aboutUs, () {}),
            ]),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleLogout(context, authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightRed,
                  foregroundColor: AppColors.themeRed,
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.themeRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.confirmLogout,
            style: AppTextStyles.cardTitle,
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutConfirmMessage,
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authProvider.logout();
              },
              child: Text(
                AppLocalizations.of(context)!.exit,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Card(
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.secondaryText,
      ),
      title: Text(
        title,
        style: AppTextStyles.body,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.secondaryText,
      ),
      onTap: onTap,
    );
  }
}
