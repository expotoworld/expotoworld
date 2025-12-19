import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/partners_shell.dart';

/// Dashboard screen for the Partners portal
class PartnersDashboardScreen extends StatelessWidget {
  const PartnersDashboardScreen({super.key});

  static const Color _partnerColor = Colors.indigo;

  @override
  Widget build(BuildContext context) {
    return PartnersShell(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _partnerColor,
          title: Text('Partner Dashboard', style: AppTypography.h4(color: Colors.white)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEarningsCard(),
                const SizedBox(height: 24),
                Text('Performance', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                Text('Recent Referrals', style: AppTypography.h4()),
                const SizedBox(height: 12),
                _buildEmptyState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_partnerColor, _partnerColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Earnings', style: AppTypography.bodySmall(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('\$0.00', style: AppTypography.h1(color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('🤝 Partner Program', style: AppTypography.bodySmall(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Referrals', '0', Icons.people_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Conversions', '0', Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rate', '0%', Icons.trending_up)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
        children: [
          Icon(icon, color: _partnerColor, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h3()),
          Text(title, style: AppTypography.labelSmall(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No referrals yet', style: AppTypography.bodyMedium(color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            'Share your referral link to start earning',
            style: AppTypography.labelSmall(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
