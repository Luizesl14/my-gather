import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { floorCreated, mapPublished } from "../events/workspace-events";
import { MapSize } from "../value-objects/map-size";
import { DeskAggregate } from "./desk-aggregate";
import { RoomAggregate } from "./room-aggregate";

export type FloorProps = {
  workspaceId: string;
  name: string;
  level: number;
  mapSize?: MapSize;
  rooms: RoomAggregate[];
  desks: DeskAggregate[];
};

export class FloorAggregate extends AggregateRoot<FloorProps> {
  private constructor(id: string, props: FloorProps) {
    super(id, props);
  }

  get hasPublishedMap(): boolean {
    return Boolean(this.props.mapSize);
  }

  static create(input: {
    id: string;
    workspaceId: string;
    name: string;
    level: number;
  }): Result<FloorAggregate, string> {
    if (!input.id.trim() || !input.workspaceId.trim() || !input.name.trim()) {
      return Result.err("workspace.floor.required_fields");
    }

    const floor = new FloorAggregate(input.id, {
      workspaceId: input.workspaceId,
      name: input.name.trim(),
      level: input.level,
      rooms: [],
      desks: [],
    });
    floor.addDomainEvent(floorCreated(floor.id));

    return Result.ok(floor);
  }

  publishMap(mapSize: MapSize): void {
    this.props.mapSize = mapSize;
    this.addDomainEvent(mapPublished(this.id));
  }

  addRoom(room: RoomAggregate): Result<void, string> {
    if (!this.props.mapSize) return Result.err("workspace.floor.map_required");
    if (!room.bounds.fitsInside(this.props.mapSize)) {
      return Result.err("workspace.room.outside_map");
    }

    this.props.rooms.push(room);
    return Result.ok(undefined);
  }

  addDesk(desk: DeskAggregate): Result<void, string> {
    if (!this.props.mapSize) return Result.err("workspace.floor.map_required");
    if (!desk.bounds.fitsInside(this.props.mapSize)) {
      return Result.err("workspace.desk.outside_map");
    }

    this.props.desks.push(desk);
    return Result.ok(undefined);
  }
}
