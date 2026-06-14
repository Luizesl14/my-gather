import type WebSocket from "ws";

export type ConnectionInfo = {
  id: string;
  userId: string;
  displayName: string;
  characterId: string;
  connectedAt: Date;
  workspaceId: string | null;
  floorId: string | null;
  x: number;
  y: number;
  direction: string;
  motionState: string;
  presenceStatus: string;
};

export type Connection = {
  info: ConnectionInfo;
  socket: WebSocket;
};

export class ConnectionRegistry {
  private readonly connections = new Map<string, Connection>();
  private readonly userIndex = new Map<string, string>(); // userId → connectionId
  private readonly workspaceIndex = new Map<string, Set<string>>(); // workspaceId → connectionId[]

  add(connection: Connection): void {
    const existingId = this.userIndex.get(connection.info.userId);
    if (existingId && existingId !== connection.info.id) this.remove(existingId);
    this.connections.set(connection.info.id, connection);
    this.userIndex.set(connection.info.userId, connection.info.id);
  }

  remove(connectionId: string): void {
    const connection = this.connections.get(connectionId);
    if (!connection) return;
    this.userIndex.delete(connection.info.userId);
    if (connection.info.workspaceId) {
      this._leaveWorkspaceIndex(connectionId, connection.info.workspaceId);
    }
    this.connections.delete(connectionId);
  }

  get(connectionId: string): Connection | undefined {
    return this.connections.get(connectionId);
  }

  getByUserId(userId: string): Connection | undefined {
    const id = this.userIndex.get(userId);
    return id ? this.connections.get(id) : undefined;
  }

  joinWorkspace(connectionId: string, workspaceId: string, floorId: string): void {
    const conn = this.connections.get(connectionId);
    if (!conn) return;
    if (conn.info.workspaceId) this._leaveWorkspaceIndex(connectionId, conn.info.workspaceId);
    conn.info.workspaceId = workspaceId;
    conn.info.floorId = floorId;
    if (!this.workspaceIndex.has(workspaceId)) this.workspaceIndex.set(workspaceId, new Set());
    this.workspaceIndex.get(workspaceId)!.add(connectionId);
  }

  leaveWorkspace(connectionId: string): string | null {
    const conn = this.connections.get(connectionId);
    if (!conn || !conn.info.workspaceId) return null;
    const workspaceId = conn.info.workspaceId;
    this._leaveWorkspaceIndex(connectionId, workspaceId);
    conn.info.workspaceId = null;
    conn.info.floorId = null;
    return workspaceId;
  }

  getWorkspaceMembers(workspaceId: string): Connection[] {
    const ids = this.workspaceIndex.get(workspaceId);
    if (!ids) return [];
    return [...ids].map((id) => this.connections.get(id)).filter(Boolean) as Connection[];
  }

  broadcast(workspaceId: string, payload: string, excludeConnectionId?: string): void {
    for (const conn of this.getWorkspaceMembers(workspaceId)) {
      if (conn.info.id === excludeConnectionId) continue;
      if (conn.socket.readyState === 1) conn.socket.send(payload);
    }
  }

  sendToUser(userId: string, payload: string): boolean {
    const conn = this.getByUserId(userId);
    if (!conn || conn.socket.readyState !== 1) return false;
    conn.socket.send(payload);
    return true;
  }

  updatePosition(connectionId: string, x: number, y: number, direction: string, motionState: string): void {
    const conn = this.connections.get(connectionId);
    if (!conn) return;
    conn.info.x = x;
    conn.info.y = y;
    conn.info.direction = direction;
    conn.info.motionState = motionState;
  }

  size(): number {
    return this.connections.size;
  }

  private _leaveWorkspaceIndex(connectionId: string, workspaceId: string): void {
    const set = this.workspaceIndex.get(workspaceId);
    if (!set) return;
    set.delete(connectionId);
    if (set.size === 0) this.workspaceIndex.delete(workspaceId);
  }
}
