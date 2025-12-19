import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/logistics_shell.dart';

/// Dashboard screen for the Logistics (3PL) portal
class LogisticsDashboardScreen extends StatelessWidget {
  const LogisticsDashboardScreen({super.key});

  static const Color _logisticsColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return LogisticsShell(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _logisticsColor,
          title: Text('Dashboard', style: AppTypography.h4(color: Colors.white)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(),
                const SizedBox(height: 24),
                Text('Today\'s Overview', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                Text('Quick Actions', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_logisticsColor, _logisticsColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Shipments', style: AppTypography.bodySmall(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('0', style: AppTypography.h1(color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('🚚 Logistics Mode', style: AppTypography.bodySmall(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Pending', '0', Icons.pending_outlined, Colors.orange),
        _buildStatCard('In Transit', '0', Icons.local_shipping_outlined, Colors.blue),
        _buildStatCard('Delivered', '0', Icons.check_circle_outline, Colors.green),
        _buildStatCard('Returns', '0', Icons.replay_outlined, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTypography.h3()),
              Text(title, style: AppTypography.labelSmall(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildActionButton('Scan Package', Icons.qr_code_scanner, () {})),
        const SizedBox(width: 12),
        Expanded(child: _buildActionButton('View Routes', Icons.route, () {})),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: _logisticsColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: _logisticsColor, size: 28),
              const SizedBox(height: 8),
              Text(label, style: AppTypography.bodySmall(color: _logisticsColor)),
            ],
          ),
        ),
      ),
    );
  }
}
