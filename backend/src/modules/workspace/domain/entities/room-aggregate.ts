import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { roomCreated } from "../events/workspace-events";
import { MapRect } from "../value-objects/map-rect";

export type RoomProps = {
  floorId: string;
  name: string;
  bounds: MapRect;
};

export class RoomAggregate extends AggregateRoot<RoomProps> {
  private constructor(id: string, props: RoomProps) {
    super(id, props);
  }

  get bounds(): MapRect {
    return this.props.bounds;
  }

  static create(input: {
    id: string;
    floorId: string;
    name: string;
    bounds: MapRect;
  }): Result<RoomAggregate, string> {
    if (!input.id.trim() || !input.floorId.trim() || !input.name.trim()) {
      return Result.err("workspace.room.required_fields");
    }

    const room = new RoomAggregate(input.id, {
      floorId: input.floorId,
      name: input.name.trim(),
      bounds: input.bounds,
    });
    room.addDomainEvent(roomCreated(room.id));

    return Result.ok(room);
  }
}
