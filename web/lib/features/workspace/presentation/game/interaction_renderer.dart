import "package:flutter/material.dart";

import "../../../../core/theme/app_colors.dart";
import "office_map.dart";

class InteractionRenderer {
  const InteractionRenderer(this.colors);

  final AppColors colors;

  void paint(Canvas canvas, List<MapZone> zones, double tileSize) {
    final paint = Paint()
      ..color = colors.focus.withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final zone in zones) {
      final rect = Rect.fromLTWH(
        zone.x * tileSize,
        zone.y * tileSize,
        zone.width * tileSize,
        zone.height * tileSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(tileSize * 0.18)),
        paint,
      );
    }
  }
}
