import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/partners_shell.dart';

/// Referrals screen for the Partners portal
class PartnersReferralsScreen extends StatelessWidget {
  const PartnersReferralsScreen({super.key});

  static const Color _partnerColor = Colors.indigo;

  @override
  Widget build(BuildContext context) {
    return PartnersShell(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _partnerColor,
          title: Text('My Referrals', style: AppTypography.h4(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text('No Referrals Yet', style: AppTypography.h3()),
                const SizedBox(height: 8),
                Text(
                  'Your referrals will appear here once people sign up using your link',
                  style: AppTypography.bodyMedium(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
