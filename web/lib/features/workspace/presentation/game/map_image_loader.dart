import "dart:ui" as ui;

import "package:flutter/services.dart";

import "map_image_cache.dart";

class MapImageLoader {
  static const _tileIds = [
    "floor-office-light",
    "floor-wood-light",
    "carpet-blue",
    "carpet-green",
    "wall-office",
    "glass-wall",
    "interactive-zone-blue",
  ];

  static const _furnitureIds = [
    "desk-wood",
    "chair-blue",
    "meeting-table-wood",
    "plant-pot",
    "sofa-blue",
    "cabinet-gray",
    "door-wood",
    "window-glass",
  ];

  static const _scenaryIds = [
    "granite-flor-with",
    "grayish-floor",
    "iron-floor",
    "yellowed-floor",
    "scenario",
    "gray-mat",
    "yellowed-mat",
    "half-wall",
    "mini-wall",
    "small-wall",
    "long-wall",
    "iron-wall",
    "iron-wall-left",
    "iron-wall-rigth",
    "iron-medium-wall",
    "iron-medium-small",
    "wooden-wall",
    "wooden-wall-left",
    "wooden-wall-rigth",
    "wooden-medium-wall",
    "wooden-medium-small",
    "iron-dor",
    "iron-portal",
    "wooden-door",
    "wooden-portal",
    "blindex",
    "window-one",
    "window-one-block",
    "window-tree-block",
    "chair-black",
    "chair-blue",
    "chair-green",
    "meeting-table",
    "work-table",
    "materiais",
  ];

  static Future<MapImageCache> load() async {
    final results = await Future.wait([
      _loadAll(_tileIds, "assets/tilesets"),
      _loadAll(_furnitureIds, "assets/furniture"),
      _loadAll(_scenaryIds, "assets/tilesets/scenary"),
    ]);
    return MapImageCache(
      tiles: {...results[0], ...results[2]},
      furniture: results[1],
    );
  }

  static Future<Map<String, ui.Image>> _loadAll(
    List<String> ids,
    String basePath,
  ) async {
    final entries = await Future.wait(
      ids.map((id) async {
        final img = await _loadOne("$basePath/$id.png");
        return img != null ? MapEntry(id, img) : null;
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<String, ui.Image>>());
  }

  static Future<ui.Image?> _loadOne(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
