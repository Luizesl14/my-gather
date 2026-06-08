export type WorkspaceRecord = {
  id: string;
  organizationId: string;
  name: string;
  activeFloorId: string;
};

export type FloorRecord = {
  id: string;
  workspaceId: string;
  name: string;
  level: number;
};

export type OfficeMapPayload = {
  id: string;
  name: string;
  version: number;
  width: number;
  height: number;
  tileSize: number;
  assetPackId: string;
  spawn: { x: number; y: number; direction: string };
  layers: unknown[];
  collision: unknown[];
  interactiveZones: unknown[];
  rooms: unknown[];
  desks: unknown[];
};

export class InMemoryWorkspaceRepository {
  private readonly workspaces = new Map<string, WorkspaceRecord>();
  private readonly floors = new Map<string, FloorRecord>();

  createWorkspace(input: {
    id: string;
    organizationId: string;
    name: string;
    activeFloorId: string;
  }): WorkspaceRecord {
    const workspace = {
      id: input.id,
      organizationId: input.organizationId,
      name: input.name,
      activeFloorId: input.activeFloorId,
    };
    const floor = {
      id: input.activeFloorId,
      workspaceId: input.id,
      name: "Principal",
      level: 1,
    };

    this.workspaces.set(workspace.id, workspace);
    this.floors.set(floor.id, floor);

    return workspace;
  }

  listByOrganization(organizationId: string): WorkspaceRecord[] {
    return [...this.workspaces.values()].filter(
      (workspace) => workspace.organizationId === organizationId,
    );
  }

  findWorkspace(workspaceId: string): WorkspaceRecord | null {
    return this.workspaces.get(workspaceId) ?? null;
  }

  deleteWorkspace(workspaceId: string): void {
    this.workspaces.delete(workspaceId);
  }

  findActiveFloor(workspaceId: string): FloorRecord | null {
    const workspace = this.findWorkspace(workspaceId);
    if (!workspace) return null;

    return this.floors.get(workspace.activeFloorId) ?? null;
  }
}
