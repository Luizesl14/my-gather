import type WebSocket from "ws";

export type ConnectionInfo = {
  id: string;
  userId: string;
  connectedAt: Date;
};

export type Connection = {
  info: ConnectionInfo;
  socket: WebSocket;
};

export class ConnectionRegistry {
  private readonly connections = new Map<string, Connection>();

  add(connection: Connection): void {
    this.connections.set(connection.info.id, connection);
  }

  remove(connectionId: string): void {
    this.connections.delete(connectionId);
  }

  get(connectionId: string): Connection | undefined {
    return this.connections.get(connectionId);
  }

  size(): number {
    return this.connections.size;
  }
}

