import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { deskAssigned } from "../events/workspace-events";
import { MapRect } from "../value-objects/map-rect";

export type DeskProps = {
  floorId: string;
  label: string;
  bounds: MapRect;
  assignedUserId?: string;
};

export class DeskAggregate extends AggregateRoot<DeskProps> {
  private constructor(id: string, props: DeskProps) {
    super(id, props);
  }

  get bounds(): MapRect {
    return this.props.bounds;
  }

  static create(input: {
    id: string;
    floorId: string;
    label: string;
    bounds: MapRect;
    assignedUserId?: string;
  }): Result<DeskAggregate, string> {
    if (!input.id.trim() || !input.floorId.trim() || !input.label.trim()) {
      return Result.err("workspace.desk.required_fields");
    }

    const desk = new DeskAggregate(input.id, {
      floorId: input.floorId,
      label: input.label.trim(),
      bounds: input.bounds,
      assignedUserId: input.assignedUserId,
    });

    if (input.assignedUserId) {
      desk.addDomainEvent(deskAssigned(desk.id));
    }

    return Result.ok(desk);
  }
}
