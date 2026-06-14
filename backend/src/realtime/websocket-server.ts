import { createServer, type IncomingMessage } from "node:http";
import { randomUUID } from "node:crypto";
import WebSocket, { WebSocketServer } from "ws";

import { NodeTokenService } from "../modules/identity/infrastructure/crypto/node-token-service";
import { ConnectionRegistry } from "./connection-registry";
import { pingEventSchema, pongEvent } from "./events/ping";
import {
  avatarMoveSchema,
  avatarStopSchema,
  presenceStatusChangeSchema,
  workspaceJoinSchema,
  rosterPayload,
  userJoinedPayload,
  userLeftPayload,
  avatarMovedPayload,
  presenceStatusChangedPayload,
} from "./events/presence-events";
import {
  callInviteEventSchema,
  callAcceptEventSchema,
  callDeclineEventSchema,
  callEndEventSchema,
  rtcSignalEventSchema,
  callIncomingEvent,
  callAcceptedEvent,
  callDeclinedEvent,
  callEndedEvent,
  rtcSignalRelayEvent,
} from "./events/room-events";
import { safeParseJson, serializeJson } from "./serializers/json";

export type WebsocketServerDeps = {
  registry?: ConnectionRegistry;
};

export type WebsocketServerOptions = {
  port: number;
  jwtSecret: string;
  deps?: WebsocketServerDeps;
};

export type RunningWebsocketServer = {
  registry: ConnectionRegistry;
  stop(): Promise<void>;
};

function getTokenFromRequest(request: IncomingMessage): string | null {
  const url = request.url ?? "";
  const q = url.indexOf("?");
  if (q === -1) return null;
  return new URLSearchParams(url.slice(q + 1)).get("token");
}

export async function startWebsocketServer(
  options: WebsocketServerOptions,
): Promise<RunningWebsocketServer> {
  const registry = options.deps?.registry ?? new ConnectionRegistry();
  const tokenService = new NodeTokenService(options.jwtSecret);
  const server = createServer();
  const wss = new WebSocketServer({ server, path: "/ws" });

  wss.on("connection", (socket: WebSocket, request: IncomingMessage) => {
    const connectionId = randomUUID();
    const rawToken = getTokenFromRequest(request);
    const payload = rawToken ? tokenService.verify(rawToken) : null;

    if (!payload) {
      socket.close(4001, "unauthorized");
      return;
    }

    const conn = {
      info: {
        id: connectionId,
        userId: payload.sub,
        displayName: (payload as Record<string, string>)["displayName"] ?? payload.email,
        characterId: "character-01",
        connectedAt: new Date(),
        workspaceId: null as string | null,
        floorId: null as string | null,
        x: 1,
        y: 1,
        direction: "front",
        motionState: "idle",
        presenceStatus: "available",
      },
      socket,
    };

    registry.add(conn);

    socket.on("message", (data) => {
      const text = typeof data === "string" ? data : data.toString("utf-8");
      const parsed = safeParseJson(text);
      if (!parsed || typeof parsed !== "object") return;

      const type = (parsed as Record<string, unknown>)["type"];

      if (pingEventSchema.safeParse(parsed).success) {
        socket.send(serializeJson(pongEvent));
        return;
      }

      if (type === "workspace:join") {
        const ev = workspaceJoinSchema.safeParse(parsed);
        if (!ev.success) return;
        const { workspaceId, floorId = "main", characterId = "character-01" } = ev.data;
        conn.info.characterId = characterId;
        registry.joinWorkspace(connectionId, workspaceId, floorId);

        const members = registry
          .getWorkspaceMembers(workspaceId)
          .filter((c) => c.info.id !== connectionId)
          .map((c) => ({
            userId: c.info.userId,
            displayName: c.info.displayName,
            characterId: c.info.characterId,
            x: c.info.x,
            y: c.info.y,
            direction: c.info.direction,
            motionState: c.info.motionState,
            presenceStatus: c.info.presenceStatus,
          }));

        socket.send(rosterPayload(members));
        registry.broadcast(
          workspaceId,
          userJoinedPayload(conn.info.userId, conn.info.displayName, conn.info.characterId, conn.info.x, conn.info.y, conn.info.direction, conn.info.motionState, conn.info.presenceStatus),
          connectionId,
        );
        return;
      }

      if (type === "workspace:leave") {
        const wsId = registry.leaveWorkspace(connectionId);
        if (wsId) registry.broadcast(wsId, userLeftPayload(conn.info.userId));
        return;
      }

      if (type === "avatar:move") {
        const ev = avatarMoveSchema.safeParse(parsed);
        if (!ev.success || !conn.info.workspaceId) return;
        const { x, y, direction, motionState } = ev.data;
        registry.updatePosition(connectionId, x, y, direction, motionState);
        registry.broadcast(conn.info.workspaceId, avatarMovedPayload(conn.info.userId, x, y, direction, motionState), connectionId);
        return;
      }

      if (type === "avatar:stop") {
        const ev = avatarStopSchema.safeParse(parsed);
        if (!ev.success || !conn.info.workspaceId) return;
        const { x, y, direction } = ev.data;
        registry.updatePosition(connectionId, x, y, direction, "idle");
        registry.broadcast(conn.info.workspaceId, avatarMovedPayload(conn.info.userId, x, y, direction, "idle"), connectionId);
        return;
      }

      if (type === "presence:status.change") {
        const ev = presenceStatusChangeSchema.safeParse(parsed);
        if (!ev.success || !conn.info.workspaceId) return;
        const { status, emoji = null, text = null } = ev.data;
        conn.info.presenceStatus = status;
        registry.broadcast(conn.info.workspaceId, presenceStatusChangedPayload(conn.info.userId, status, emoji, text), connectionId);
        return;
      }

      if (type === "rtc:signal") {
        const ev = rtcSignalEventSchema.safeParse(parsed);
        if (!ev.success) return;
        const target = registry.getByUserId(ev.data.toUserId);
        if (!target || target.info.workspaceId !== conn.info.workspaceId) return;
        target.socket.send(serializeJson(rtcSignalRelayEvent(conn.info.userId, ev.data.data)));
        return;
      }

      if (type === "call:invite") {
        const ev = callInviteEventSchema.safeParse(parsed);
        if (!ev.success) return;
        registry.sendToUser(ev.data.toUserId, serializeJson(callIncomingEvent(conn.info.userId, conn.info.displayName, ev.data.mode)));
        return;
      }

      if (type === "call:accept") {
        const ev = callAcceptEventSchema.safeParse(parsed);
        if (!ev.success) return;
        registry.sendToUser(ev.data.toUserId, serializeJson(callAcceptedEvent(conn.info.userId, ev.data.mode)));
        return;
      }

      if (type === "call:decline") {
        const ev = callDeclineEventSchema.safeParse(parsed);
        if (!ev.success) return;
        registry.sendToUser(ev.data.toUserId, serializeJson(callDeclinedEvent(conn.info.userId)));
        return;
      }

      if (type === "call:end") {
        const ev = callEndEventSchema.safeParse(parsed);
        if (!ev.success) return;
        registry.sendToUser(ev.data.toUserId, serializeJson(callEndedEvent(conn.info.userId)));
        return;
      }
    });

    socket.on("close", () => {
      if (conn.info.workspaceId) {
        registry.broadcast(conn.info.workspaceId, userLeftPayload(conn.info.userId), connectionId);
      }
      registry.remove(connectionId);
    });
  });

  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(options.port, "0.0.0.0", () => resolve());
  });

  return {
    registry,
    async stop() {
      for (const client of wss.clients) client.close();
      await new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
    },
  };
}
