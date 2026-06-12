import "dart:math" show pi;
import "dart:ui" as ui;

import "package:flutter/material.dart";

import "../../../../core/theme/app_colors.dart";
import "interaction_renderer.dart";
import "map_image_cache.dart";
import "office_map.dart";

class TileDef {
  const TileDef({
    required this.frameCols,
    required this.frameRows,
    required this.category,
    required this.collision,
  });
  final int frameCols;
  final int frameRows;
  final String category;
  final bool collision;
}

class MapRenderer extends CustomPainter {
  const MapRenderer({
    required this.map,
    required this.colors,
    required this.imageCache,
    required this.playerX,
    required this.playerY,
    required this.tileById,
    this.showCollisionDebug = false,
  });

  final OfficeMap map;
  final AppColors colors;
  final MapImageCache imageCache;
  final double playerX;
  final double playerY;
  final Map<String, TileDef> tileById;
  final bool showCollisionDebug;

  // Visual zoom — same approach as the editor's _scale.
  // At 2× the 30×20 map becomes 1920×1280px, requiring camera-follow.
  static const double kDisplayZoom = 2.0;
  static const double _cell = 32.0;

  // Camera offset in screen-pixel space (accounts for zoom).
  static Offset cameraOffset(Size viewport, OfficeMap map, double tileX, double tileY) {
    const scaledCell = _cell * kDisplayZoom;
    final mapW = map.width * scaledCell;
    final mapH = map.height * scaledCell;
    final px = (tileX + 0.5) * scaledCell;
    final py = (tileY + 0.5) * scaledCell;
    final double ox, oy;
    if (mapW <= viewport.width) {
      ox = (viewport.width - mapW) / 2;
    } else {
      ox = (viewport.width / 2 - px).clamp(viewport.width - mapW, 0.0);
    }
    if (mapH <= viewport.height) {
      oy = (viewport.height - mapH) / 2;
    } else {
      oy = (viewport.height / 2 - py).clamp(viewport.height - mapH, 0.0);
    }
    return Offset(ox, oy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final offset = cameraOffset(size, map, playerX, playerY);

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Translate then scale — identical to the editor's _CanvasPainter.
    // All tile/object coordinates below are in native 32 px space;
    // canvas.scale(kDisplayZoom) magnifies them on screen.
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(kDisplayZoom);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, map.width * _cell, map.height * _cell),
      Paint()..color = colors.app,
    );

    final imgPaint = Paint()..filterQuality = FilterQuality.medium;

    // Render in layer order: floor → walls → objects (matches editor layer order)
    for (final layerName in ["floor", "carpet", "walls", "objects"]) {
      final layer = map.layers.where((l) => l.name == layerName).firstOrNull;
      if (layer == null) continue;

      // Tiles (placed by the map editor) — Y-sorted for depth (higher Y = in front)
      final tiles = layerName == "floor"
          ? layer.tiles
          : (List<MapTile>.from(layer.tiles)..sort((a, b) => a.y.compareTo(b.y)));
      for (final tile in tiles) {
        _drawTile(canvas, tile, layerName, imageCache.tiles, imgPaint);
      }

      // Legacy MapObjects (default map furniture) — Y-sorted for depth
      final objects = List<MapObject>.from(layer.objects)
        ..sort((a, b) => a.y.compareTo(b.y));
      for (final obj in objects) {
        _drawObject(canvas, obj, imageCache.furniture, imgPaint);
      }
    }

    InteractionRenderer(colors).paint(canvas, map.interactiveZones, _cell);

    canvas.restore();

    // Debug overlay drawn in screen space (after restore, no clip/transform issues).
    if (showCollisionDebug) _drawCollisionDebug(canvas, size, offset);
  }

  void _drawCollisionDebug(Canvas canvas, Size size, Offset camOffset) {
    const s = kDisplayZoom;
    final blockPaint = Paint()..color = const Color(0xAAFF2222);
    final passPaint  = Paint()..color = const Color(0xAA22FF88);
    final border     = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Converts tile-grid coords → screen coords.
    Rect tileRect(double tx, double ty, double tw, double th) => Rect.fromLTWH(
          camOffset.dx + tx * _cell * s,
          camOffset.dy + ty * _cell * s,
          tw * _cell * s,
          th * _cell * s,
        );

    for (final layer in map.layers) {
      final isFloor = layer.name == "floor";
      for (final tile in layer.tiles) {
        final isColliding   = map.collidingTileIds.contains(tile.tile);
        final isPassthrough = map.passthroughTileIds.contains(tile.tile);
        final hasColRect    = tile.colRect != null;
        if (!isColliding && !isPassthrough && !hasColRect) continue;

        final Rect rect;
        if (tile.colRect != null) {
          // Exact drawn rect — matches the pixel-precise canOccupy test.
          final cr = tile.colRect!;
          rect = tileRect(cr.x / map.tileSize, cr.y / map.tileSize,
              cr.w / map.tileSize, cr.h / map.tileSize);
        } else if (isFloor) {
          rect = tileRect(tile.x.toDouble(), tile.y.toDouble(),
              tile.w.toDouble(), tile.h.toDouble());
        } else {
          // Exact pixel bounds — matches the pixel-precise canOccupy test.
          rect = tileRect(tile.x / map.tileSize, tile.y / map.tileSize,
              tile.w / map.tileSize, tile.h / map.tileSize);
        }
        canvas.drawRect(rect, isPassthrough ? passPaint : blockPaint);
        canvas.drawRect(rect, border);
      }

      for (final obj in layer.objects) {
        if (!OfficeMap.blockingAssetIds.contains(obj.asset)) continue;
        final tr = map.objectTileRect(obj);
        final rect = tileRect(tr.left, tr.top, tr.width, tr.height);
        canvas.drawRect(rect, blockPaint);
        canvas.drawRect(rect, border);
      }
    }

    // Player feet hitbox (blue) — collision happens when this touches red.
    // Must mirror OfficeMap.canOccupy: central 10px wide, bottom 10px of tile.
    final feetBox = Rect.fromLTWH(
      camOffset.dx + (playerX * _cell + 11) * s,
      camOffset.dy + (playerY * _cell + 22) * s,
      10 * s,
      10 * s,
    );
    canvas.drawRect(feetBox, Paint()..color = const Color(0xAA2196F3));
    canvas.drawRect(feetBox, border);

    // Indicator square — always visible in top-left corner to confirm debug is ON.
    canvas.drawRect(
      const Rect.fromLTWH(4, 4, 16, 16),
      Paint()..color = const Color(0xFFFF0000),
    );
  }

  // Identical to _CanvasPainter._drawPlaced from map_editor_page.dart.
  // Uses tileById (ScenaryTile definitions) for frameCols/frameRows/category —
  // never the values stored in the JSON tile, which may be stale or missing.
  // layerName drives coord mode: "floor" = grid units; all others = pixel units
  // (non-floor tiles are normalized to pixel units in MapTile.fromJson).
  void _drawTile(
    Canvas canvas,
    MapTile tile,
    String layerName,
    Map<String, ui.Image> images,
    Paint imgPaint,
  ) {
    final def = tileById[tile.tile];
    final cols = def?.frameCols ?? tile.frameCols;
    final rows = def?.frameRows ?? tile.frameRows;
    final category = def?.category ?? "";

    // Floor layer stores tile coords (x=0,1,2…); everything else is pixel coords.
    final isFloor = layerName == "floor";
    final fullRect = isFloor
        ? Rect.fromLTWH(tile.x * _cell, tile.y * _cell, tile.w * _cell, tile.h * _cell)
        : Rect.fromLTWH(tile.x.toDouble(), tile.y.toDouble(), tile.w.toDouble(), tile.h.toDouble());

    final img = images[tile.tile];
    if (img == null) {
      canvas.drawRect(fullRect, Paint()..color = _fallbackColor(tile.tile));
      return;
    }

    final frameW = img.width / cols;
    final frameH = img.height / rows;
    final src = Rect.fromLTWH(tile.frameCol * frameW, tile.frameRow * frameH, frameW, frameH);

    // Walls/doors/windows: contain-fit to preserve proportions.
    final rect = (category == "wall" || category == "door" || category == "window")
        ? _containFit(frameW, frameH, fullRect)
        : fullRect;

    if (tile.rotation != 0 || tile.flipX) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      if (tile.rotation != 0) canvas.rotate(tile.rotation * pi / 180);
      if (tile.flipX) canvas.scale(-1.0, 1.0);
      canvas.drawImageRect(
        img,
        src,
        Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
        imgPaint,
      );
      canvas.restore();
    } else {
      canvas.drawImageRect(img, src, rect, imgPaint);
    }
  }

  // Legacy support for MapObjects in the default map (furniture/ folder).
  void _drawObject(
    Canvas canvas,
    MapObject obj,
    Map<String, ui.Image> furniture,
    Paint imgPaint,
  ) {
    final img = furniture[obj.asset];
    if (img == null) return;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(obj.x * _cell, obj.y * _cell, img.width.toDouble(), img.height.toDouble()),
      imgPaint,
    );
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

  Color _fallbackColor(String tileId) => switch (tileId) {
        "floor-office-light" || "grayish-floor" || "granite-flor-with" => colors.orange.withValues(alpha: 0.3),
        "carpet-blue" || "gray-mat" => colors.brandPrimary.withValues(alpha: 0.4),
        "carpet-green" || "yellowed-mat" => colors.green.withValues(alpha: 0.4),
        "wall-office" || "wooden-wall" || "iron-wall" => colors.panelMuted,
        "glass-wall" || "blindex" => colors.cyan.withValues(alpha: 0.3),
        _ => colors.app,
      };

  @override
  bool shouldRepaint(covariant MapRenderer oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.colors != colors ||
        oldDelegate.imageCache != imageCache ||
        oldDelegate.tileById != tileById ||
        oldDelegate.playerX != playerX ||
        oldDelegate.playerY != playerY ||
        oldDelegate.showCollisionDebug != showCollisionDebug;
  }
}
