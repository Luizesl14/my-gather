import "dart:convert";
import "dart:ui" as ui;

import "package:flutter/services.dart";

import "map_image_cache.dart";
import "../map_editor/map_editor_state.dart";

class MapImageLoader {
  // Legacy tile IDs loaded from fixed paths (kept for backward compat)
  static const _legacyTileIds = [
    "floor-office-light",
    "floor-wood-light",
    "carpet-blue",
    "carpet-green",
    "wall-office",
    "glass-wall",
    "interactive-zone-blue",
  ];

  static const _legacyFurnitureIds = [
    "desk-wood",
    "chair-blue",
    "meeting-table-wood",
    "plant-pot",
    "sofa-blue",
    "cabinet-gray",
    "door-wood",
    "window-glass",
  ];

  static Future<MapImageCache> load() async {
    // Load scenary-pack and build map from all entries
    final packText = await rootBundle.loadString("assets/tilesets/scenary-pack.json");
    final packJson = jsonDecode(packText) as Map<String, dynamic>;
    final tiles = (packJson["tiles"] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ScenaryTile.fromJson)
        .toList(growable: false);

    final results = await Future.wait([
      _loadByIds(_legacyTileIds, "assets/tilesets"),
      _loadByIds(_legacyFurnitureIds, "assets/furniture"),
      _loadFromTiles(tiles),
    ]);

    return MapImageCache(
      tiles: {...results[0], ...results[1], ...results[2]},
      furniture: results[1],
    );
  }

  // Load all tiles from scenary-pack by their full asset path
  static Future<Map<String, ui.Image>> _loadFromTiles(
      List<ScenaryTile> tiles) async {
    final entries = await Future.wait(
      tiles.map((t) async {
        final img = await _loadOne(t.imagePath);
        return img != null ? MapEntry(t.id, img) : null;
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<String, ui.Image>>());
  }

  static Future<Map<String, ui.Image>> _loadByIds(
      List<String> ids, String basePath) async {
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
