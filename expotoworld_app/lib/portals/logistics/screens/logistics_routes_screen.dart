import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/logistics_shell.dart';

/// Routes screen for the Logistics portal
class LogisticsRoutesScreen extends StatelessWidget {
  const LogisticsRoutesScreen({super.key});

  static const Color _logisticsColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return LogisticsShell(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _logisticsColor,
          title: Text('Routes', style: AppTypography.h4(color: Colors.white)),
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
                  child: Icon(Icons.route, size: 64, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                Text('No Routes', style: AppTypography.h3()),
                const SizedBox(height: 8),
                Text(
                  'Your delivery routes will appear here',
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
