import "dart:math" show pi;
import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../../core/theme/app_colors.dart";
import "office_map.dart";

class TileRenderer {
  const TileRenderer(this.colors, this.images);

  final AppColors colors;
  final Map<String, ui.Image> images;

  // Mirrors _CanvasPainter._drawPlaced from the editor:
  //   floor tiles  → grid cell coords (x * tileSize)
  //   walls/objects → pixel coords saved by editor (x * scale, where scale = tileSize/32)
  void paint(Canvas canvas, MapTile tile, double tileSize, String layerName) {
    final isFloor = layerName == "floor";
    final scale = tileSize / 32;

    final fullRect = isFloor
        ? Rect.fromLTWH(
            tile.x * tileSize,
            tile.y * tileSize,
            tile.w * tileSize,
            tile.h * tileSize,
          )
        : Rect.fromLTWH(
            tile.x * scale,
            tile.y * scale,
            tile.w * scale,
            tile.h * scale,
          );

    final image = images[tile.tile];
    if (image == null) {
      canvas.drawRect(fullRect, Paint()..color = _fallbackColor(tile.tile));
      return;
    }

    final frameW = image.width / tile.frameCols;
    final frameH = image.height / tile.frameRows;
    final src = Rect.fromLTWH(
      tile.frameCol * frameW,
      tile.frameRow * frameH,
      frameW,
      frameH,
    );

    // Walls use contain-fit (preserves proportions); floor and objects fill the rect
    final rect = layerName == "walls"
        ? _containFit(frameW, frameH, fullRect)
        : fullRect;

    final imgPaint = Paint()..filterQuality = FilterQuality.medium;

    if (tile.rotation != 0 || tile.flipX) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      if (tile.rotation != 0) canvas.rotate(tile.rotation * pi / 180);
      if (tile.flipX) canvas.scale(-1.0, 1.0);
      canvas.drawImageRect(
        image,
        src,
        Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
        imgPaint,
      );
      canvas.restore();
    } else {
      canvas.drawImageRect(image, src, rect, imgPaint);
    }
  }

  static Rect _containFit(double srcW, double srcH, Rect dst) {
    final srcAspect = srcW / srcH;
    final dstAspect = dst.width / dst.height;
    final double w, h;
    if (srcAspect > dstAspect) {
      w = dst.width;
      h = dst.width / srcAspect;
    } else {
      h = dst.height;
      w = dst.height * srcAspect;
    }
    return Rect.fromCenter(center: dst.center, width: w, height: h);
  }

  Color _fallbackColor(String tileId) {
    return switch (tileId) {
      "floor-wood-light" => colors.orange.withValues(alpha: 0.58),
      "carpet-blue" => colors.brandPrimary.withValues(alpha: 0.62),
      "carpet-green" => colors.green.withValues(alpha: 0.62),
      "wall-office" => colors.panelMuted,
      "glass-wall" => colors.cyan.withValues(alpha: 0.35),
      _ => colors.app,
    };
  }
}
