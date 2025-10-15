import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/store_type.dart';

class MapMarkerUtils {
  // Hex color codes as specified
  static const Color retailStoreColor = Color(0xFF520EE6);
  static const Color unmannedStoreColor = Color(0xFF2196F3);
  static const Color unmannedWarehouseColor = Color(0xFF4CAF50);
  static const Color exhibitionStoreColor = Color(0xFFFFD556);
  static const Color exhibitionMallColor = Color(0xFFF38900);
  static const Color groupBuyingColor = Color(0xFF076200);

  /// Chooses the correct icon for a given store type
  static IconData _getIconForStoreType(StoreType storeType) {
    switch (storeType) {
      case StoreType.retailStore:
        return Icons.shopping_cart; // Retail Store Icon
      case StoreType.unmannedStore:
        return Icons.store; // Shop/Store Icon
      case StoreType.unmannedWarehouse:
        return Icons.warehouse; // Warehouse Icon
      case StoreType.exhibitionStore:
        return Icons.shopping_bag; // Store/Shopping Bag Icon
      case StoreType.exhibitionMall:
        return Icons.domain; // Mall/Big Building Icon
      case StoreType.groupBuying:
        return Icons.group; // Group Buying Icon
    }
  }

  /// Gets the color for a specific store type
  static Color getStoreTypeColor(StoreType storeType) {
    switch (storeType) {
      case StoreType.retailStore:
        return retailStoreColor;
      case StoreType.unmannedStore:
        return unmannedStoreColor;
      case StoreType.unmannedWarehouse:
        return unmannedWarehouseColor;
      case StoreType.exhibitionStore:
        return exhibitionStoreColor;
      case StoreType.exhibitionMall:
        return exhibitionMallColor;
      case StoreType.groupBuying:
        return groupBuyingColor;
    }
  }

  /// Creates a custom marker by drawing a background shape and an icon on a canvas.
  static Future<BitmapDescriptor> _createMarkerWithIcon({
    required Color backgroundColor,
    required IconData iconData,
    double size = 100.0,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final double width = size;
    final double height = size * 1.2; // Make it taller for the teardrop shape
    final double radius = width / 2;

    // Path for the pin body
    final path = Path();
    path.moveTo(radius, height); // Start at the bottom tip
    path.quadraticBezierTo(0, height * 0.7, 0, radius); // Bottom-left curve
    path.arcTo(Rect.fromCircle(center: Offset(radius, radius), radius: radius), 3.14, 3.14, false); // Top semi-circle
    path.quadraticBezierTo(width, height * 0.7, radius, height); // Bottom-right curve
    path.close();

    // Draw the background shape
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawPath(path, backgroundPaint);

    // Prepare to draw the icon
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6, // Icon size is relative to the circle part
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );

    // Layout and paint the icon in the center of the circular part
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (width - iconPainter.width) / 2,
        (height - iconPainter.height) / 2.5, // Adjust vertical position for the teardrop shape
      ),
    );

    // Convert canvas to image
    final image = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    // Use the new, non-deprecated method name
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// **Main function to get a marker for a store type**
  static Future<BitmapDescriptor> getStoreMarkerIcon(StoreType storeType) async {
    final color = getStoreTypeColor(storeType);
    final icon = _getIconForStoreType(storeType);

    return await _createMarkerWithIcon(
      backgroundColor: color,
      iconData: icon,
      size: 35.0, // A reasonable size for the markers
    );
  }
}