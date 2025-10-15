import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DecorativeBackdrop extends StatelessWidget {
  const DecorativeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -1.0), // Top center
            radius: 1.0,
            colors: [
              AppColors.themeRed.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
