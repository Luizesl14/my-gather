import "dart:ui" as ui;

class MapImageCache {
  const MapImageCache({required this.tiles, required this.furniture});

  final Map<String, ui.Image> tiles;
  final Map<String, ui.Image> furniture;

  static const MapImageCache empty = MapImageCache(tiles: {}, furniture: {});
}
