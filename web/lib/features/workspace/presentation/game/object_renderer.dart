import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../../core/theme/app_colors.dart";
import "office_map.dart";

class ObjectRenderer {
  const ObjectRenderer(this.colors, this.images);

  final AppColors colors;
  final Map<String, ui.Image> images;

  void paint(Canvas canvas, MapObject object, double tileSize) {
    final image = images[object.asset];
    if (image != null) {
      final scale = tileSize / 32;
      final drawRect = Rect.fromLTWH(
        object.x * tileSize,
        object.y * tileSize,
        image.width * scale,
        image.height * scale,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        drawRect,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      _paintFallback(canvas, object, tileSize);
    }
  }

  void _paintFallback(Canvas canvas, MapObject object, double tileSize) {
    final size = _objectSize(object.asset, tileSize);
    final rect = Rect.fromLTWH(
      object.x * tileSize,
      object.y * tileSize,
      size.width,
      size.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(tileSize * 0.14));

    canvas.drawRRect(rrect, Paint()..color = _objectColor(object.asset));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = colors.borderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Size _objectSize(String assetId, double tileSize) {
    return switch (assetId) {
      "desk-wood" => Size(tileSize * 2, tileSize * 1.35),
      "meeting-table-wood" => Size(tileSize * 3, tileSize * 1.75),
      "sofa-blue" => Size(tileSize * 2, tileSize * 1.35),
      "window-glass" => Size(tileSize * 2, tileSize),
      _ => Size(tileSize, tileSize),
    };
  }

  Color _objectColor(String assetId) {
    return switch (assetId) {
      "chair-blue" => colors.brandPrimary.withValues(alpha: 0.72),
      "sofa-blue" => colors.brandSecondary.withValues(alpha: 0.72),
      "plant-pot" => colors.green,
      "cabinet-gray" => colors.textMuted,
      "door-wood" => colors.orange,
      "window-glass" => colors.cyan.withValues(alpha: 0.54),
      _ => colors.orange.withValues(alpha: 0.72),
    };
  }
}
