import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { workspaceCreated } from "../events/workspace-events";
import { FloorAggregate } from "./floor-aggregate";

export type WorkspaceProps = {
  organizationId: string;
  name: string;
  activeFloorId?: string;
  floors: FloorAggregate[];
};

export class WorkspaceAggregate extends AggregateRoot<WorkspaceProps> {
  private constructor(id: string, props: WorkspaceProps) {
    super(id, props);
  }

  get hasActiveMap(): boolean {
    const activeFloor = this.props.floors.find((floor) => floor.id === this.props.activeFloorId);
    return Boolean(activeFloor?.hasPublishedMap);
  }

  static create(input: {
    id: string;
    organizationId: string;
    name: string;
  }): Result<WorkspaceAggregate, string> {
    if (!input.id.trim() || !input.organizationId.trim() || !input.name.trim()) {
      return Result.err("workspace.workspace.required_fields");
    }

    const workspace = new WorkspaceAggregate(input.id, {
      organizationId: input.organizationId,
      name: input.name.trim(),
      floors: [],
    });
    workspace.addDomainEvent(workspaceCreated(workspace.id));

    return Result.ok(workspace);
  }

  addFloor(floor: FloorAggregate): void {
    this.props.floors.push(floor);
    this.props.activeFloorId ??= floor.id;
  }
}
