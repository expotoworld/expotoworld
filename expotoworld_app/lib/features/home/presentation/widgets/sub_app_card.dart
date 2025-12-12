import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Sub-app card for the 2x2 grid
class SubAppCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String storeName;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SubAppCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.storeName,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<SubAppCard> createState() => _SubAppCardState();
}

class _SubAppCardState extends State<SubAppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap ?? () {
        // TODO: NEED TO FULLY IMPLEMENT - Navigate to sub-app
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0)
          ..translate(0.0, _isPressed ? 2.0 : 0.0),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBackgroundElevated.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isDark
                ? widget.color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? widget.color.withValues(alpha: _isPressed ? 0.1 : 0.15)
                  : Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.08),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  widget.icon,
                  size: AppSpacing.iconLg,
                  color: widget.color,
                ),
              ),
              
              const Spacer(),
              
              // Title
              Row(
                children: [
                  Text(
                    'EXPO ',
                    style: AppTypography.h4(
                      color: AppColors.foreground(context),
                    ),
                  ),
                  Text(
                    widget.title,
                    style: AppTypography.h4(
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              // Subtitle
              Text(
                widget.subtitle,
                style: AppTypography.caption(
                  color: AppColors.foregroundMuted(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
