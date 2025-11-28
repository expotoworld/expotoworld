import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/store_type.dart';

class MapMarkerUtils {
  // ETW Store Type colors
  static const Color etwMegaColor = Color(0xFF9C27B0);    // Purple - ETWMega
  static const Color etwMarketColor = Color(0xFF673AB7);  // Deep Purple - ETWMarket
  static const Color etwToGoColor = Color(0xFF3F51B5);    // Indigo - ETWtoGO
  static const Color etwXpressColor = Color(0xFF2196F3);  // Blue - ETWXpress

  /// Chooses the correct icon for a given store type
  static IconData _getIconForStoreType(StoreType storeType) {
    switch (storeType) {
      case StoreType.etwMega:
        return Icons.business; // ETW Mega - large business icon
      case StoreType.etwMarket:
        return Icons.storefront; // ETW Market - storefront icon
      case StoreType.etwToGo:
        return Icons.local_convenience_store; // ETW to GO - convenience store
      case StoreType.etwXpress:
        return Icons.flash_on; // ETW Xpress - express/fast icon
    }
  }

  /// Gets the color for a specific store type
  static Color getStoreTypeColor(StoreType storeType) {
    switch (storeType) {
      case StoreType.etwMega:
        return etwMegaColor;
      case StoreType.etwMarket:
        return etwMarketColor;
      case StoreType.etwToGo:
        return etwToGoColor;
      case StoreType.etwXpress:
        return etwXpressColor;
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