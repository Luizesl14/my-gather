import "package:flutter_test/flutter_test.dart";

import "package:love_robot_web/features/workspace/presentation/game/office_map.dart";

void main() {
  // Map 10×10. A work-table at pixel (96,96) size 64×64 (cells 3-4 × 3-4),
  // with a custom colRect covering ONLY the top half: (96,96) 64×32.
  OfficeMap mapWithColRect() => const OfficeMap(
        id: "t",
        width: 10,
        height: 10,
        tileSize: 32,
        spawn: MapSpawn(x: 0, y: 0, direction: "front"),
        layers: [
          MapLayer(
            name: "objects",
            tiles: [
              MapTile(
                tile: "work-table",
                x: 96, y: 96, w: 64, h: 64,
                colRect: MapColRect(x: 96, y: 96, w: 64, h: 32),
              ),
            ],
            objects: [],
          ),
        ],
        interactiveZones: [],
        collidingTileIds: {"work-table"},
      );

  test("colRect bloqueia apenas a area desenhada, nao o componente inteiro", () {
    final map = mapWithColRect();

    // Center of cell (3,3) = px(112,112) — inside colRect → blocked.
    expect(map.canOccupy(3, 3), isFalse);
    expect(map.canOccupy(4, 3), isFalse);

    // Cells (3,4)/(4,4) are the table's bottom half — NOT in colRect → free.
    expect(map.canOccupy(3, 4), isTrue);
    expect(map.canOccupy(4, 4), isTrue);

    // Adjacent cells outside the table → free.
    expect(map.canOccupy(2, 3), isTrue);
    expect(map.canOccupy(5, 3), isTrue);
    expect(map.canOccupy(3, 2), isTrue);
  });

  test("toda a area marcada bloqueia: pes do avatar nao sobrepoem o rect", () {
    // colRect starting at px 95: the avatar's feet hitbox (central 16px of the
    // tile) may not overlap any part of the drawn rect.
    const map = OfficeMap(
      id: "t2",
      width: 10,
      height: 10,
      tileSize: 32,
      spawn: MapSpawn(x: 0, y: 0, direction: "front"),
      layers: [
        MapLayer(
          name: "objects",
          tiles: [
            MapTile(
              tile: "work-table",
              x: 96, y: 96, w: 64, h: 64,
              colRect: MapColRect(x: 95, y: 96, w: 65, h: 32),
            ),
          ],
          objects: [],
        ),
      ],
      interactiveZones: [],
      collidingTileIds: {"work-table"},
    );

    // Avatar at (2,3): feet box px[72..88) stops short of the rect at 95 → free.
    expect(map.canOccupy(2, 3), isTrue);
    // Avatar at (2.5,3): feet box px[88..104) overlaps the rect → blocked.
    expect(map.canOccupy(2.5, 3), isFalse);
    // Fully inside the rect → blocked.
    expect(map.canOccupy(3, 3), isFalse);
  });

  test("tile sem colRect continua bloqueando bounds inteiros", () {
    const map = OfficeMap(
      id: "t3",
      width: 10,
      height: 10,
      tileSize: 32,
      spawn: MapSpawn(x: 0, y: 0, direction: "front"),
      layers: [
        MapLayer(
          name: "objects",
          tiles: [
            MapTile(tile: "work-table", x: 96, y: 96, w: 64, h: 64),
          ],
          objects: [],
        ),
      ],
      interactiveZones: [],
      collidingTileIds: {"work-table"},
    );

    expect(map.canOccupy(3, 3), isFalse);
    expect(map.canOccupy(4, 4), isFalse);
    expect(map.canOccupy(2, 3), isTrue);
  });
}
