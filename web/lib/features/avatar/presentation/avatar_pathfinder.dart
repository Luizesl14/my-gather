import "dart:collection";

import "../../workspace/presentation/game/office_map.dart";

/// A* path search over the tile grid, reusing the same collision check the
/// manual movement uses ([OfficeMap.canOccupyTile]). Returns the list of tile
/// coordinates to walk through, starting AFTER the start tile and ending at the
/// goal (inclusive). Returns an empty list if no path exists.
///
/// 4-connected (no diagonals) so each segment maps cleanly to one of the
/// up/down/left/right walk directions.
class AvatarPathfinder {
  static const int _maxExpansions = 20000;

  static List<({int x, int y})> findPath(
    OfficeMap map,
    int startX,
    int startY,
    int goalX,
    int goalY,
  ) {
    if (startX == goalX && startY == goalY) return const [];
    if (!map.canOccupyTile(goalX, goalY)) return const [];

    int key(int x, int y) => y * map.width + x;
    final start = key(startX, startY);
    final goal = key(goalX, goalY);

    final open = HashMap<int, int>(); // node -> fScore
    final cameFrom = HashMap<int, int>();
    final gScore = HashMap<int, int>()..[start] = 0;
    open[start] = _heuristic(startX, startY, goalX, goalY);

    var expansions = 0;
    while (open.isNotEmpty) {
      if (++expansions > _maxExpansions) return const [];

      // Pick the open node with the lowest fScore.
      int current = open.keys.first;
      int bestF = open[current]!;
      for (final entry in open.entries) {
        if (entry.value < bestF) {
          bestF = entry.value;
          current = entry.key;
        }
      }
      if (current == goal) return _reconstruct(cameFrom, current, map.width);
      open.remove(current);

      final cx = current % map.width;
      final cy = current ~/ map.width;
      final g = gScore[current]!;

      for (final (nx, ny) in [
        (cx + 1, cy),
        (cx - 1, cy),
        (cx, cy + 1),
        (cx, cy - 1),
      ]) {
        if (nx < 0 || ny < 0 || nx >= map.width || ny >= map.height) continue;
        if (!map.canOccupyTile(nx, ny)) continue;
        final nKey = key(nx, ny);
        final tentative = g + 1;
        if (tentative < (gScore[nKey] ?? 1 << 30)) {
          cameFrom[nKey] = current;
          gScore[nKey] = tentative;
          open[nKey] = tentative + _heuristic(nx, ny, goalX, goalY);
        }
      }
    }
    return const [];
  }

  static int _heuristic(int ax, int ay, int bx, int by) =>
      (ax - bx).abs() + (ay - by).abs();

  static List<({int x, int y})> _reconstruct(
    Map<int, int> cameFrom,
    int current,
    int width,
  ) {
    final path = <({int x, int y})>[];
    int? node = current;
    while (node != null) {
      path.add((x: node % width, y: node ~/ width));
      node = cameFrom[node];
    }
    final reversed = path.reversed.toList();
    // Drop the start tile — caller is already standing there.
    return reversed.length <= 1 ? const [] : reversed.sublist(1);
  }
}
