import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/partners_shell.dart';

/// Commissions screen for the Partners portal
class PartnersCommissionsScreen extends StatelessWidget {
  const PartnersCommissionsScreen({super.key});

  static const Color _partnerColor = Colors.indigo;

  @override
  Widget build(BuildContext context) {
    return PartnersShell(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _partnerColor,
          title: Text('Commissions', style: AppTypography.h4(color: Colors.white)),
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
                  child: Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text('No Commissions Yet', style: AppTypography.h3()),
                const SizedBox(height: 8),
                Text(
                  'Your commission history will appear here',
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
