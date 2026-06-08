import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../data/workspace_service.dart";

// ─── Tile catalog ─────────────────────────────────────────────────────────────

class ScenaryTile {
  const ScenaryTile({
    required this.id,
    required this.path,
    required this.category,
    required this.label,
    required this.collision,
    this.sizeW = 1,
    this.sizeH = 1,
    this.frameCols = 1,
    this.frameRows = 1,
    this.isOverlay = false,
    this.acceptsOverlay = false,
  });

  final String id;
  final String path;
  final String category;
  final String label;
  final bool collision;
  final int sizeW;
  final int sizeH;
  final int frameCols;
  final int frameRows;
  final bool isOverlay;
  final bool acceptsOverlay;

  factory ScenaryTile.fromJson(Map<String, dynamic> j) {
    final size = j["size"] as Map<String, dynamic>?;
    final frames = j["frames"] as Map<String, dynamic>?;
    return ScenaryTile(
      id: j["id"] as String,
      path: j["path"] as String,
      category: j["category"] as String,
      label: j["label"] as String,
      collision: j["collision"] as bool,
      sizeW: (size?["w"] as int?) ?? 1,
      sizeH: (size?["h"] as int?) ?? 1,
      frameCols: (frames?["cols"] as int?) ?? 1,
      frameRows: (frames?["rows"] as int?) ?? 1,
      isOverlay: (j["isOverlay"] as bool?) ?? false,
      acceptsOverlay: (j["acceptsOverlay"] as bool?) ?? false,
    );
  }
}

// ─── Placed tile ──────────────────────────────────────────────────────────────

class PlacedTile {
  const PlacedTile({
    required this.id,
    required this.tileId,
    required this.x,
    required this.y,
    required this.layerName,
    this.rotation = 0,
    this.flipX = false,
    this.w = 1,
    this.h = 1,
    this.frameCol = 0,
    this.frameRow = 0,
    this.frameCols = 1,
    this.frameRows = 1,
    this.overlayId,
  });

  final String id;
  final String tileId;
  final int x;
  final int y;
  final String layerName; // "floor" | "walls" | "objects"
  final int rotation;     // 0, 90, 180, 270
  final bool flipX;
  final int w;            // grid cells wide
  final int h;            // grid cells tall
  final int frameCol;     // sprite sheet column (selected frame)
  final int frameRow;     // sprite sheet row (selected frame)
  final int frameCols;    // total columns in sprite sheet
  final int frameRows;    // total rows in sprite sheet
  final String? overlayId;

  bool hits(int gx, int gy) =>
      gx >= x && gx < x + w && gy >= y && gy < y + h;

  PlacedTile copyWith({
    int? x,
    int? y,
    int? rotation,
    bool? flipX,
    int? w,
    int? h,
    int? frameCol,
    int? frameRow,
    int? frameCols,
    int? frameRows,
    String? overlayId,
    bool clearOverlay = false,
  }) =>
      PlacedTile(
        id: id,
        tileId: tileId,
        x: x ?? this.x,
        y: y ?? this.y,
        layerName: layerName,
        rotation: rotation ?? this.rotation,
        flipX: flipX ?? this.flipX,
        w: w ?? this.w,
        h: h ?? this.h,
        frameCol: frameCol ?? this.frameCol,
        frameRow: frameRow ?? this.frameRow,
        frameCols: frameCols ?? this.frameCols,
        frameRows: frameRows ?? this.frameRows,
        overlayId: clearOverlay ? null : (overlayId ?? this.overlayId),
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{"tile": tileId, "x": x, "y": y};
    if (rotation != 0) m["rotation"] = rotation;
    if (flipX) m["flipX"] = true;
    if (w != 1 || layerName != "floor") m["w"] = w;
    if (h != 1 || layerName != "floor") m["h"] = h;
    if (frameCol != 0) m["frameCol"] = frameCol;
    if (frameRow != 0) m["frameRow"] = frameRow;
    if (frameCols > 1) m["frameCols"] = frameCols;
    if (frameRows > 1) m["frameRows"] = frameRows;
    if (overlayId != null) m["overlayId"] = overlayId;
    return m;
  }
}

// ─── Editor state ─────────────────────────────────────────────────────────────

class MapEditorData {
  const MapEditorData({
    required this.width,
    required this.height,
    required this.placedTiles,
    required this.activeLayer,
    required this.paletteTileW,
    required this.paletteTileH,
    required this.paletteTileLayer,
    required this.paletteTileFrameCols,
    required this.paletteTileFrameRows,
    required this.isSaving,
    required this.isDirty,
    this.selectedId,
    this.paletteSelectedId,
  });

  final int width;
  final int height;
  final Map<String, PlacedTile> placedTiles;
  final String activeLayer;
  final int paletteTileW;
  final int paletteTileH;
  final String paletteTileLayer;
  final int paletteTileFrameCols;
  final int paletteTileFrameRows;
  final bool isSaving;
  final bool isDirty;
  final String? selectedId;
  final String? paletteSelectedId;

  PlacedTile? get selectedTile =>
      selectedId != null ? placedTiles[selectedId] : null;

  MapEditorData copyWith({
    int? width,
    int? height,
    Map<String, PlacedTile>? placedTiles,
    String? activeLayer,
    int? paletteTileW,
    int? paletteTileH,
    String? paletteTileLayer,
    int? paletteTileFrameCols,
    int? paletteTileFrameRows,
    bool? isSaving,
    bool? isDirty,
    String? selectedId,
    bool clearSelectedId = false,
    String? paletteSelectedId,
    bool clearPaletteSelected = false,
  }) =>
      MapEditorData(
        width: width ?? this.width,
        height: height ?? this.height,
        placedTiles: placedTiles ?? this.placedTiles,
        activeLayer: activeLayer ?? this.activeLayer,
        paletteTileW: paletteTileW ?? this.paletteTileW,
        paletteTileH: paletteTileH ?? this.paletteTileH,
        paletteTileLayer: paletteTileLayer ?? this.paletteTileLayer,
        paletteTileFrameCols: paletteTileFrameCols ?? this.paletteTileFrameCols,
        paletteTileFrameRows: paletteTileFrameRows ?? this.paletteTileFrameRows,
        isSaving: isSaving ?? this.isSaving,
        isDirty: isDirty ?? this.isDirty,
        selectedId: clearSelectedId ? null : (selectedId ?? this.selectedId),
        paletteSelectedId: clearPaletteSelected
            ? null
            : (paletteSelectedId ?? this.paletteSelectedId),
      );

  static MapEditorData empty(int w, int h) => MapEditorData(
        width: w,
        height: h,
        placedTiles: const {},
        activeLayer: "floor",
        paletteTileW: 1,
        paletteTileH: 1,
        paletteTileLayer: "floor",
        paletteTileFrameCols: 1,
        paletteTileFrameRows: 1,
        isSaving: false,
        isDirty: false,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

int _nextId = 0;
String _genId() => "pt_${_nextId++}";

String _layerForCategory(String category) => switch (category) {
      "floor" || "mat" => "floor",
      "wall" || "door" || "window" => "walls",
      "furniture" => "objects",
      _ => "floor",
    };

String _editorLayerFromBackend(String name) => switch (name) {
      "walls" || "wall" => "walls",
      "objects" || "object" => "objects",
      _ => "floor",
    };

class MapEditorNotifier extends StateNotifier<MapEditorData> {
  MapEditorNotifier(this._service, this._workspaceId, MapEditorData initial)
      : super(initial);

  final WorkspaceService _service;
  final String _workspaceId;

  // ─ Layer ─

  void setActiveLayer(String layer) {
    state = state.copyWith(
      activeLayer: layer,
      clearSelectedId: true,
      clearPaletteSelected: true,
    );
  }

  // ─ Palette ─

  void selectPaletteTile(
      String tileId, int sizeW, int sizeH, String category,
      {int frameCols = 1, int frameRows = 1}) {
    final layer = _layerForCategory(category);
    // Non-floor tiles: store pixel dimensions (sizeN * 32) so placement is pixel-accurate
    final pw = layer != "floor" ? sizeW * 32 : sizeW;
    final ph = layer != "floor" ? sizeH * 32 : sizeH;
    state = state.copyWith(
      paletteSelectedId: tileId,
      paletteTileW: pw,
      paletteTileH: ph,
      paletteTileLayer: layer,
      paletteTileFrameCols: frameCols,
      paletteTileFrameRows: frameRows,
      clearSelectedId: true,
    );
  }

  void clearPaletteSelection() {
    state = state.copyWith(clearPaletteSelected: true);
  }

  // ─ Canvas interaction ─

  // [gx,gy] = grid cell coords (for floor/walls)
  // [px,py] = canvas pixel coords (for objects)
  void tapCanvas(int gx, int gy, {int px = 0, int py = 0}) {
    final paletteId = state.paletteSelectedId;

    if (paletteId != null) {
      final layer = state.paletteTileLayer;
      final w = state.paletteTileW;
      final h = state.paletteTileH;
      final updated = Map<String, PlacedTile>.from(state.placedTiles);
      final id = _genId();

      if (layer != "floor") {
        // Free pixel placement — clamp to map bounds
        final maxPx = state.width * 32;
        final maxPy = state.height * 32;
        final cpx = px.clamp(0, (maxPx - w).clamp(0, maxPx));
        final cpy = py.clamp(0, (maxPy - h).clamp(0, maxPy));
        updated[id] = PlacedTile(
            id: id, tileId: paletteId, x: cpx, y: cpy, layerName: layer, w: w, h: h,
            frameCols: state.paletteTileFrameCols,
            frameRows: state.paletteTileFrameRows);
        // Auto-select after placing so handles appear immediately
        state = state.copyWith(
            placedTiles: updated, isDirty: true,
            clearPaletteSelected: true, selectedId: id);
      } else {
        // Grid placement (floor only) — replace overlapping tiles on same layer
        if (gx < 0 || gy < 0 || gx >= state.width || gy >= state.height) return;
        if (gx + w > state.width || gy + h > state.height) return;
        updated.removeWhere((_, t) {
          if (t.layerName != layer) return false;
          return t.x < gx + w && t.x + t.w > gx && t.y < gy + h && t.y + t.h > gy;
        });
        updated[id] = PlacedTile(
            id: id, tileId: paletteId, x: gx, y: gy, layerName: layer, w: w, h: h,
            frameCols: state.paletteTileFrameCols,
            frameRows: state.paletteTileFrameRows);
        state = state.copyWith(placedTiles: updated, isDirty: true);
      }
      return;
    }

    // Selection mode
    PlacedTile? hit;
    if (state.activeLayer != "floor") {
      // Pixel hit test — keep last (topmost rendered) match
      for (final t in state.placedTiles.values) {
        if (t.layerName == state.activeLayer &&
            px >= t.x && px < t.x + t.w &&
            py >= t.y && py < t.y + t.h) {
          hit = t;
        }
      }
    } else {
      if (gx < 0 || gy < 0 || gx >= state.width || gy >= state.height) return;
      for (final t in state.placedTiles.values) {
        if (t.layerName == state.activeLayer && t.hits(gx, gy)) {
          hit = t;
          break;
        }
      }
    }

    if (hit != null) {
      state = state.copyWith(selectedId: hit.id, clearPaletteSelected: true);
    } else {
      state = state.copyWith(clearSelectedId: true, clearPaletteSelected: true);
    }
  }

  // ─ Manipulation ─

  void movePlaced(String id, int x, int y) {
    final tile = state.placedTiles[id];
    if (tile == null) return;
    final isFloor = tile.layerName == "floor";
    final maxX = isFloor ? state.width - tile.w : state.width * 32 - tile.w;
    final maxY = isFloor ? state.height - tile.h : state.height * 32 - tile.h;
    final nx = x.clamp(0, maxX.clamp(0, isFloor ? state.width : state.width * 32));
    final ny = y.clamp(0, maxY.clamp(0, isFloor ? state.height : state.height * 32));
    if (tile.x == nx && tile.y == ny) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    if (isFloor) {
      // Grid tiles: remove displaced tiles on same layer
      updated.removeWhere((k, t) {
        if (k == id || t.layerName != tile.layerName) return false;
        return t.x < nx + tile.w && t.x + t.w > nx && t.y < ny + tile.h && t.y + t.h > ny;
      });
    }
    updated[id] = tile.copyWith(x: nx, y: ny);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void rotatePlaced(String id) {
    final tile = state.placedTiles[id];
    if (tile == null) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    updated[id] = tile.copyWith(rotation: (tile.rotation + 90) % 360);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void flipPlaced(String id) {
    final tile = state.placedTiles[id];
    if (tile == null) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    updated[id] = tile.copyWith(flipX: !tile.flipX);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void resizePlaced(String id, int w, int h) {
    final tile = state.placedTiles[id];
    if (tile == null) return;
    final isFloor = tile.layerName == "floor";
    final minSize = isFloor ? 1 : 32;
    final maxW = isFloor ? state.width - tile.x : state.width * 32 - tile.x;
    final maxH = isFloor ? state.height - tile.y : state.height * 32 - tile.y;
    final newW = w.clamp(minSize, maxW.clamp(minSize, isFloor ? state.width : state.width * 32));
    final newH = h.clamp(minSize, maxH.clamp(minSize, isFloor ? state.height : state.height * 32));
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    if (isFloor) {
      updated.removeWhere((k, t) {
        if (k == id || t.layerName != tile.layerName) return false;
        return t.x < tile.x + newW && t.x + t.w > tile.x &&
               t.y < tile.y + newH && t.y + t.h > tile.y;
      });
    }
    updated[id] = tile.copyWith(w: newW, h: newH);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void nextFrame(String id, int maxCol, int maxRow) {
    final tile = state.placedTiles[id];
    if (tile == null || (maxCol <= 1 && maxRow <= 1)) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    var col = tile.frameCol + 1;
    var row = tile.frameRow;
    if (col >= maxCol) { col = 0; row = (row + 1) % maxRow; }
    updated[id] = tile.copyWith(frameCol: col, frameRow: row);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void prevFrame(String id, int maxCol, int maxRow) {
    final tile = state.placedTiles[id];
    if (tile == null || (maxCol <= 1 && maxRow <= 1)) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    var col = tile.frameCol - 1;
    var row = tile.frameRow;
    if (col < 0) { col = maxCol - 1; row = (row - 1 + maxRow) % maxRow; }
    updated[id] = tile.copyWith(frameCol: col, frameRow: row);
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void setOverlay(String id, String? overlayId) {
    final tile = state.placedTiles[id];
    if (tile == null) return;
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    updated[id] = tile.copyWith(
      overlayId: overlayId,
      clearOverlay: overlayId == null,
    );
    state = state.copyWith(placedTiles: updated, isDirty: true);
  }

  void deletePlaced(String id) {
    final updated = Map<String, PlacedTile>.from(state.placedTiles);
    updated.remove(id);
    state = state.copyWith(
      placedTiles: updated,
      clearSelectedId: true,
      isDirty: true,
    );
  }

  void clearAll() {
    state = state.copyWith(
      placedTiles: const {},
      clearSelectedId: true,
      clearPaletteSelected: true,
      isDirty: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedId: true,
      clearPaletteSelected: true,
    );
  }

  void loadFromApiData(WorkspaceMapData data) {
    final placed = <String, PlacedTile>{};
    for (final layer in data.layers) {
      final layerName = layer["name"] as String? ?? "floor";
      final editorLayer = _editorLayerFromBackend(layerName);
      final tiles = layer["tiles"] as List<dynamic>? ?? [];
      for (final t in tiles) {
        final tile = t as Map<String, dynamic>;
        final id = _genId();
        // Non-floor tiles store pixel dims; floor tiles store cell counts.
        // Old saved data used grid cell coords for walls/objects (w=1,2,3...).
        // Detect old data: non-floor tile where w < 16 → multiply all by 32.
        final rawW = (tile["w"] as int?) ?? (editorLayer != "floor" ? 1 : 1);
        final rawH = (tile["h"] as int?) ?? 1;
        final isOldGridCoords = editorLayer != "floor" && rawW < 16;
        final scale = isOldGridCoords ? 32 : 1;
        placed[id] = PlacedTile(
          id: id,
          tileId: tile["tile"] as String,
          x: (tile["x"] as int) * scale,
          y: (tile["y"] as int) * scale,
          layerName: editorLayer,
          rotation: (tile["rotation"] as int?) ?? 0,
          flipX: (tile["flipX"] as bool?) ?? false,
          w: rawW * scale,
          h: rawH * scale,
          frameCol: (tile["frameCol"] as int?) ?? 0,
          frameRow: (tile["frameRow"] as int?) ?? 0,
          frameCols: (tile["frameCols"] as int?) ?? 1,
          frameRows: (tile["frameRows"] as int?) ?? 1,
          overlayId: tile["overlayId"] as String?,
        );
      }
    }
    state = MapEditorData(
      width: data.width,
      height: data.height,
      placedTiles: placed,
      activeLayer: "floor",
      paletteTileW: 1,
      paletteTileH: 1,
      paletteTileLayer: "floor",
      paletteTileFrameCols: 1,
      paletteTileFrameRows: 1,
      isSaving: false,
      isDirty: false,
    );
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    try {
      final tiles = state.placedTiles.values;
      final floorTiles =
          tiles.where((t) => t.layerName == "floor").map((t) => t.toJson()).toList();
      final wallTiles =
          tiles.where((t) => t.layerName == "walls").map((t) => t.toJson()).toList();
      final objectTiles =
          tiles.where((t) => t.layerName == "objects").map((t) => t.toJson()).toList();

      await _service.saveMap(
        _workspaceId,
        WorkspaceMapData(
          id: _workspaceId,
          width: state.width,
          height: state.height,
          tileSize: 32,
          assetPackId: "office-scenary-v1",
          spawn: const {"x": 1, "y": 1, "direction": "front"},
          layers: [
            {"name": "floor", "tiles": floorTiles, "objects": <dynamic>[]},
            {"name": "walls", "tiles": wallTiles, "objects": <dynamic>[]},
            {"name": "objects", "tiles": objectTiles, "objects": <dynamic>[]},
          ],
          interactiveZones: [],
        ),
      );
      state = state.copyWith(isSaving: false, isDirty: false);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final mapEditorProvider = StateNotifierProvider.autoDispose
    .family<MapEditorNotifier, MapEditorData, (String workspaceId, String token)>(
  (ref, args) {
    final service = WorkspaceService(args.$2);
    return MapEditorNotifier(
      service,
      args.$1,
      MapEditorData.empty(30, 20),
    );
  },
);
