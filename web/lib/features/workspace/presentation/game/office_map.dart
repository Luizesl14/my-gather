import "dart:convert";
import "dart:math" show max;

import "package:flutter/services.dart";

class OfficeMap {
  const OfficeMap({
    required this.id,
    required this.width,
    required this.height,
    required this.tileSize,
    required this.spawn,
    required this.layers,
    required this.interactiveZones,
    required this.collidingTileIds,
    this.passthroughTileIds = const {},
  });

  final String id;
  final int width;
  final int height;
  final int tileSize;
  final MapSpawn spawn;
  final List<MapLayer> layers;
  final List<MapZone> interactiveZones;
  final Set<String> collidingTileIds;
  // Tiles that override wall collision (portals/doors placed on top of walls).
  final Set<String> passthroughTileIds;

  static Future<OfficeMap> loadDefault(
    Set<String> collidingTileIds, {
    Set<String> passthroughTileIds = const {},
  }) async {
    final text = await rootBundle.loadString("assets/maps/office-default.json");
    final json = jsonDecode(text) as Map<String, dynamic>;
    return OfficeMap._fromJson(json, collidingTileIds, passthroughTileIds);
  }

  factory OfficeMap.fromApiJson(
    Map<String, dynamic> json,
    Set<String> collidingTileIds, {
    Set<String> passthroughTileIds = const {},
  }) =>
      OfficeMap._fromJson(json, collidingTileIds, passthroughTileIds);

  static OfficeMap _fromJson(
    Map<String, dynamic> json,
    Set<String> collidingTileIds,
    Set<String> passthroughTileIds,
  ) =>
      OfficeMap(
        id: json["id"] as String,
        width: json["width"] as int,
        height: json["height"] as int,
        tileSize: json["tileSize"] as int,
        spawn: MapSpawn.fromJson(json["spawn"] as Map<String, dynamic>),
        layers: (json["layers"] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(MapLayer.fromJson)
            .toList(growable: false),
        interactiveZones: (json["interactiveZones"] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(MapZone.fromJson)
            .toList(growable: false),
        collidingTileIds: collidingTileIds,
        passthroughTileIds: passthroughTileIds,
      );

  bool canOccupyTile(int tileX, int tileY) {
    if (tileX < 0 || tileY < 0 || tileX >= width || tileY >= height) return false;

    bool blocked = false;
    bool hasPassthrough = false;

    for (final layer in layers) {
      final isFloorLayer = layer.name == "floor";
      for (final tile in layer.tiles) {
        final bool atPosition;
        if (isFloorLayer) {
          atPosition = tile.x == tileX && tile.y == tileY;
        } else {
          final gx = tile.x ~/ tileSize;
          final gy = tile.y ~/ tileSize;
          final gw = max(1, tile.w ~/ tileSize);
          final gh = max(1, tile.h ~/ tileSize);
          atPosition = tileX >= gx && tileX < gx + gw && tileY >= gy && tileY < gy + gh;
        }
        if (!atPosition) continue;
        // Passthrough tiles (portals/doors) override wall collision.
        if (passthroughTileIds.contains(tile.tile)) hasPassthrough = true;
        if (collidingTileIds.contains(tile.tile)) blocked = true;
      }
      for (final object in layer.objects) {
        if (_blockingAssetIds.contains(object.asset) &&
            _objectOccupiesTile(object, tileX, tileY)) {
          blocked = true;
        }
      }
    }

    if (hasPassthrough) return true;
    return !blocked;
  }

  bool _objectOccupiesTile(MapObject object, int tileX, int tileY) {
    final bounds = _objectBounds(object);
    return tileX >= bounds.left &&
        tileX < bounds.right &&
        tileY >= bounds.top &&
        tileY < bounds.bottom;
  }

  _TileBounds _objectBounds(MapObject object) {
    // Sizes derived from actual sprite pixel dimensions ÷ 32.
    final size = switch (object.asset) {
      "desk-wood"           => const _TileSize(width: 2, height: 1.5),   // 64×48px
      "meeting-table-wood"  => const _TileSize(width: 3, height: 1.75),  // 96×56px
      "sofa-blue"           => const _TileSize(width: 2, height: 1.5),   // 64×48px
      "window-glass"        => const _TileSize(width: 2, height: 1),     // 64×32px
      _                     => const _TileSize(width: 1, height: 1),
    };

    return _TileBounds(
      left: object.x,
      top: object.y,
      right: object.x + size.width,
      bottom: object.y + size.height,
    );
  }

  static const Set<String> _blockingAssetIds = {
    "desk-wood",
    "meeting-table-wood",
    "sofa-blue",
    "cabinet-gray",
    "window-glass",
    "door-wood",
    "chair-blue",
    "chair-black",
    "chair-green",
  };
}

class MapSpawn {
  const MapSpawn({
    required this.x,
    required this.y,
    required this.direction,
  });

  final int x;
  final int y;
  final String direction;

  factory MapSpawn.fromJson(Map<String, dynamic> json) {
    return MapSpawn(
      x: json["x"] as int,
      y: json["y"] as int,
      direction: json["direction"] as String,
    );
  }
}

class MapLayer {
  const MapLayer({
    required this.name,
    required this.tiles,
    required this.objects,
  });

  final String name;
  final List<MapTile> tiles;
  final List<MapObject> objects;

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    final name = json["name"] as String;
    final isFloorLayer = name == "floor";
    return MapLayer(
      name: name,
      tiles: ((json["tiles"] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((t) => MapTile.fromJson(t, isFloorLayer: isFloorLayer))
          .toList(growable: false),
      objects: ((json["objects"] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(MapObject.fromJson)
          .toList(growable: false),
    );
  }
}

class MapTile {
  const MapTile({
    required this.tile,
    required this.x,
    required this.y,
    this.w = 1,
    this.h = 1,
    this.rotation = 0,
    this.flipX = false,
    this.frameCol = 0,
    this.frameRow = 0,
    this.frameCols = 1,
    this.frameRows = 1,
  });

  final String tile;
  final int x;
  final int y;
  final int w;
  final int h;
  final int rotation;
  final bool flipX;
  final int frameCol;
  final int frameRow;
  final int frameCols;
  final int frameRows;

  factory MapTile.fromJson(Map<String, dynamic> json, {bool isFloorLayer = false}) {
    final rawW = (json["w"] as int?) ?? 1;
    final rawH = (json["h"] as int?) ?? 1;
    // Old maps store wall/object tiles in grid units (w=1,2,3...).
    // New editor maps store them in pixel units (w=32,64,...).
    // Mirror the editor's detection: non-floor tiles with w < 16 are old grid format.
    final isOldGridCoords = !isFloorLayer && rawW < 16;
    final scale = isOldGridCoords ? 32 : 1;
    return MapTile(
      tile: json["tile"] as String,
      x: (json["x"] as int) * scale,
      y: (json["y"] as int) * scale,
      w: rawW * scale,
      h: rawH * scale,
      rotation: (json["rotation"] as int?) ?? 0,
      flipX: (json["flipX"] as bool?) ?? false,
      frameCol: (json["frameCol"] as int?) ?? 0,
      frameRow: (json["frameRow"] as int?) ?? 0,
      frameCols: (json["frameCols"] as int?) ?? 1,
      frameRows: (json["frameRows"] as int?) ?? 1,
    );
  }
}

class MapObject {
  const MapObject({
    required this.id,
    required this.asset,
    required this.x,
    required this.y,
    required this.layer,
  });

  final String id;
  final String asset;
  final int x;
  final int y;
  final int layer;

  factory MapObject.fromJson(Map<String, dynamic> json) {
    return MapObject(
      id: json["id"] as String,
      asset: json["asset"] as String,
      x: json["x"] as int,
      y: json["y"] as int,
      layer: json["layer"] as int,
    );
  }
}

class MapZone {
  const MapZone({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final int x;
  final int y;
  final int width;
  final int height;

  factory MapZone.fromJson(Map<String, dynamic> json) {
    return MapZone(
      id: json["id"] as String,
      x: json["x"] as int,
      y: json["y"] as int,
      width: json["w"] as int,
      height: json["h"] as int,
    );
  }
}

class _TileBounds {
  const _TileBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final double right;
  final double bottom;
}

class _TileSize {
  const _TileSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}
