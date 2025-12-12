import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Glassmorphism card widget for consistent styling
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius = AppSpacing.radiusXl,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkCardGradient
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  )
                : null,
            boxShadow: AppShadows.card(context),
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Elevated card with accent glow for dark mode
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? accentColor;

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.themeRed;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackgroundElevated : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          ...AppShadows.cardElevated(context),
          if (isDark)
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
