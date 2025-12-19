import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/logistics_shell.dart';

/// Profile/Settings screen for the Logistics portal
class LogisticsProfileScreen extends StatelessWidget {
  const LogisticsProfileScreen({super.key});

  static const Color _logisticsColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return LogisticsShell(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _logisticsColor,
          title: Text('Profile', style: AppTypography.h4(color: Colors.white)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildSettingsSection('Operations', [
                _buildSettingsTile(Icons.warehouse_outlined, 'Warehouse Info', 'Coming soon'),
                _buildSettingsTile(Icons.local_shipping_outlined, 'Fleet Management', 'Coming soon'),
                _buildSettingsTile(Icons.area_chart_outlined, 'Coverage Areas', 'Coming soon'),
              ]),
              const SizedBox(height: 16),
              _buildSettingsSection('Account', [
                _buildSettingsTile(Icons.notifications_outlined, 'Notifications', 'Coming soon'),
                _buildSettingsTile(Icons.help_outline, 'Help & Support', 'Coming soon'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _logisticsColor.withValues(alpha: 0.1),
            child: Icon(Icons.local_shipping, size: 32, color: _logisticsColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3PL Provider Name', style: AppTypography.h4()),
                const SizedBox(height: 4),
                Text('Logistics Account', style: AppTypography.bodySmall(color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelLarge(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: _logisticsColor),
      title: Text(title, style: AppTypography.bodyMedium()),
      subtitle: Text(subtitle, style: AppTypography.labelSmall(color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
