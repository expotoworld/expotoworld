import 'package:flutter/material.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/store_model.dart';

/// Size of each breadcrumb node (square).
const double _kNodeSize = 48.0;

/// Border radius for the breadcrumb nodes.
const double _kNodeRadius = 10.0;

/// Maximum width for label text beneath nodes.
const double _kLabelMaxWidth = 72.0;

/// Visual state for a single breadcrumb node.
enum _NodeState { empty, active, filled }

/// Persistent predictive breadcrumbs for the 3-tier catalog hierarchy.
///
/// Displays three nodes (Category → Subcategory → Collection) connected by
/// short indicator lines.  Node appearance changes according to the browsing
/// progress:
///
/// * **Active** – red outline; the tier the user is currently browsing.
///   The tier-type label appears beneath the node.
/// * **Filled** – selected item's image displayed inside; solid border;
///   the selected item's name appears beneath the node; fully clickable.
/// * **Empty**  – grey dashed outline; not interactive.
class CatalogBreadcrumbs extends StatelessWidget {
  /// Current tier being browsed (1 = category, 2 = subcategory, 3 = collection).
  final int currentTier;

  /// The category selected at tier 1 (null when tier == 1).
  final MiniAppCategory? selectedCategory;

  /// The subcategory selected at tier 2 (null when tier <= 2).
  final MiniAppSubcategory? selectedSubcategory;

  /// Called when the user taps a filled (past) breadcrumb node.
  /// The [int] parameter is the tier number that was tapped.
  final ValueChanged<int> onTierTap;

  /// Localized tier labels (from AppLocalizations).
  final String categoryLabel;
  final String subcategoryLabel;
  final String collectionLabel;

  const CatalogBreadcrumbs({
    super.key,
    required this.currentTier,
    this.selectedCategory,
    this.selectedSubcategory,
    required this.onTierTap,
    required this.categoryLabel,
    required this.subcategoryLabel,
    required this.collectionLabel,
  });

  _NodeState _stateFor(int tier) {
    if (tier == currentTier) return _NodeState.active;
    if (tier < currentTier) return _NodeState.filled;
    return _NodeState.empty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // ── Tier 1: Category ──
          _BreadcrumbNode(
            nodeState: _stateFor(1),
            label: currentTier > 1
                ? (selectedCategory?.name ?? categoryLabel)
                : categoryLabel,
            imageUrl: currentTier > 1 ? selectedCategory?.imageUrl : null,
            onTap: (selectedCategory != null && currentTier != 1)
                ? () => onTierTap(1)
                : null,
          ),

          Expanded(child: _Connector(reached: currentTier > 1)),

          // ── Tier 2: Subcategory ──
          _BreadcrumbNode(
            nodeState: _stateFor(2),
            label: currentTier > 2
                ? (selectedSubcategory?.name ?? subcategoryLabel)
                : subcategoryLabel,
            imageUrl: currentTier > 2 ? selectedSubcategory?.imageUrl : null,
            onTap: (selectedSubcategory != null && currentTier != 2)
                ? () => onTierTap(2)
                : null,
          ),

          Expanded(child: _Connector(reached: currentTier > 2)),

          // ── Tier 3: Collection ──
          _BreadcrumbNode(
            nodeState: _stateFor(3),
            label: collectionLabel,
            imageUrl: null,
            onTap: null, // tier 3 is always current or empty in home
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A single breadcrumb node — rounded-square with an optional image and a
/// label underneath.
class _BreadcrumbNode extends StatelessWidget {
  final _NodeState nodeState;
  final String label;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _BreadcrumbNode({
    required this.nodeState,
    required this.label,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _kLabelMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Node shape ──
            SizedBox(
              width: _kNodeSize,
              height: _kNodeSize,
              child: _buildNodeShape(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            // ── Label ──
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: nodeState == _NodeState.active
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _labelColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeShape(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (nodeState) {
      // Red outline, faint red fill with a tier icon.
      case _NodeState.active:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kNodeRadius),
            border: Border.all(color: AppColors.themeRed, width: 2.0),
            color: AppColors.themeRed.withValues(alpha: 0.06),
          ),
          child: Center(
            child: Icon(
              Icons.grid_view_rounded,
              size: 20,
              color: AppColors.themeRed.withValues(alpha: 0.45),
            ),
          ),
        );

      // Selected item image with a thin solid border.
      case _NodeState.filled:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kNodeRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kNodeRadius - 1),
            child: _buildImage(isDark),
          ),
        );

      // Grey dashed border, no fill.
      case _NodeState.empty:
        return CustomPaint(
          painter: _DashedBorderPainter(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.15),
            strokeWidth: 1.5,
            radius: _kNodeRadius,
          ),
        );
    }
  }

  Widget _buildImage(bool isDark) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: _kNodeSize,
        height: _kNodeSize,
        errorBuilder: (_, __, ___) => _placeholder(isDark),
      );
    }
    return _placeholder(isDark);
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.themeRed.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.grid_view_rounded,
          size: 20,
          color: AppColors.themeRed.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Color _labelColor(BuildContext context) {
    switch (nodeState) {
      case _NodeState.active:
        return AppColors.themeRed;
      case _NodeState.filled:
        return AppColors.foreground(context);
      case _NodeState.empty:
        return AppColors.foregroundMuted(context);
    }
  }
}

/// Horizontal connector line between breadcrumb nodes.
///
/// Uses a solid red tint for reached tiers and a dashed grey line for
/// future (unreached) tiers.
class _Connector extends StatelessWidget {
  final bool reached;

  const _Connector({required this.reached});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Offset down to vertically align with the node centre
    // (compensates for the label text below the node).
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: reached
          ? Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.themeRed.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          : CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _DashedLinePainter(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.12),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

/// Paints a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    canvas.drawPath(_createDashedPath(path, 6, 4), paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}

/// Paints a horizontal dashed line.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashGap = 3.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashWidth).clamp(0, size.width), y),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => color != old.color;
}

/// Converts a [Path] into a dashed version.
Path _createDashedPath(Path source, double dashLen, double gapLen) {
  final result = Path();
  for (final metric in source.computeMetrics()) {
    double distance = 0;
    while (distance < metric.length) {
      final end = (distance + dashLen).clamp(0.0, metric.length);
      result.addPath(metric.extractPath(distance, end), Offset.zero);
      distance = end + gapLen;
    }
  }
  return result;
}
