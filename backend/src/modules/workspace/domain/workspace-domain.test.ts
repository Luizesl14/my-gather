import { describe, expect, it } from "vitest";

import { Result } from "../../../shared/domain/result";
import { DeskAggregate } from "./entities/desk-aggregate";
import { FloorAggregate } from "./entities/floor-aggregate";
import { RoomAggregate } from "./entities/room-aggregate";
import { WorkspaceAggregate } from "./entities/workspace-aggregate";
import { MapRect } from "./value-objects/map-rect";
import { MapSize } from "./value-objects/map-size";

function unwrap<T>(result: Result<T, string>): T {
  if (Result.isErr(result)) {
    throw new Error(result.error);
  }

  return result.value;
}

describe("Workspace domain", () => {
  it("impede sala fora do mapa", () => {
    const floor = unwrap(
      FloorAggregate.create({
        id: "floor-1",
        workspaceId: "workspace-1",
        name: "Principal",
        level: 1,
      }),
    );
    floor.publishMap(unwrap(MapSize.create({ width: 20, height: 10, tileSize: 32 })));
    const room = unwrap(
      RoomAggregate.create({
        id: "room-1",
        floorId: "floor-1",
        name: "Sala",
        bounds: unwrap(MapRect.create({ x: 18, y: 2, width: 4, height: 4 })),
      }),
    );

    const result = floor.addRoom(room);

    expect(result).toEqual({
      ok: false,
      error: "workspace.room.outside_map",
    });
  });

  it("impede mesa fora do mapa", () => {
    const floor = unwrap(
      FloorAggregate.create({
        id: "floor-1",
        workspaceId: "workspace-1",
        name: "Principal",
        level: 1,
      }),
    );
    floor.publishMap(unwrap(MapSize.create({ width: 20, height: 10, tileSize: 32 })));
    const desk = unwrap(
      DeskAggregate.create({
        id: "desk-1",
        floorId: "floor-1",
        label: "Mesa 1",
        bounds: unwrap(MapRect.create({ x: 2, y: 9, width: 3, height: 2 })),
      }),
    );

    const result = floor.addDesk(desk);

    expect(result).toEqual({
      ok: false,
      error: "workspace.desk.outside_map",
    });
  });

  it("valida workspace com mapa ativo", () => {
    const workspace = unwrap(
      WorkspaceAggregate.create({
        id: "workspace-1",
        organizationId: "org-1",
        name: "Escritorio",
      }),
    );
    const floor = unwrap(
      FloorAggregate.create({
        id: "floor-1",
        workspaceId: "workspace-1",
        name: "Principal",
        level: 1,
      }),
    );
    floor.publishMap(unwrap(MapSize.create({ width: 20, height: 10, tileSize: 32 })));

    workspace.addFloor(floor);

    expect(workspace.hasActiveMap).toBe(true);
    expect(workspace.getDomainEvents()).toEqual([
      expect.objectContaining({
        eventName: "workspace.workspace_created",
        aggregateId: "workspace-1",
      }),
    ]);
  });

  it("permite sala e mesa dentro do mapa", () => {
    const floor = unwrap(
      FloorAggregate.create({
        id: "floor-1",
        workspaceId: "workspace-1",
        name: "Principal",
        level: 1,
      }),
    );
    floor.publishMap(unwrap(MapSize.create({ width: 20, height: 10, tileSize: 32 })));
    const room = unwrap(
      RoomAggregate.create({
        id: "room-1",
        floorId: "floor-1",
        name: "Sala",
        bounds: unwrap(MapRect.create({ x: 2, y: 2, width: 4, height: 4 })),
      }),
    );
    const desk = unwrap(
      DeskAggregate.create({
        id: "desk-1",
        floorId: "floor-1",
        label: "Mesa 1",
        bounds: unwrap(MapRect.create({ x: 8, y: 2, width: 2, height: 2 })),
      }),
    );

    expect(Result.isOk(floor.addRoom(room))).toBe(true);
    expect(Result.isOk(floor.addDesk(desk))).toBe(true);
  });
});
