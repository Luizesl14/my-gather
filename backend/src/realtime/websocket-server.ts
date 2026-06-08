import { createServer, type IncomingMessage } from "node:http";
import { randomUUID } from "node:crypto";
import WebSocket, { WebSocketServer } from "ws";

import { ConnectionRegistry } from "./connection-registry";
import { pingEventSchema, pongEvent } from "./events/ping";
import { safeParseJson, serializeJson } from "./serializers/json";

export type WebsocketServerDeps = {
  registry?: ConnectionRegistry;
};

export type WebsocketServerOptions = {
  port: number;
  deps?: WebsocketServerDeps;
};

export type RunningWebsocketServer = {
  registry: ConnectionRegistry;
  stop(): Promise<void>;
};

function getTokenFromRequest(request: IncomingMessage): string | null {
  const url = request.url ?? "";
  const queryIndex = url.indexOf("?");
  if (queryIndex === -1) return null;
  const query = new URLSearchParams(url.slice(queryIndex + 1));
  return query.get("token");
}

export async function startWebsocketServer(
  options: WebsocketServerOptions,
): Promise<RunningWebsocketServer> {
  const registry = options.deps?.registry ?? new ConnectionRegistry();
  const server = createServer();

  const wss = new WebSocketServer({ server, path: "/ws" });

  wss.on("connection", (socket: WebSocket, request: IncomingMessage) => {
    const connectionId = randomUUID();
    const token = getTokenFromRequest(request);

    const connection = {
      info: {
        id: connectionId,
        userId: token ? "placeholder-auth" : "anonymous",
        connectedAt: new Date(),
      },
      socket,
    };

    registry.add(connection);

    socket.on("message", (data) => {
      const text = typeof data === "string" ? data : data.toString("utf-8");
      const parsed = safeParseJson(text);
      if (!parsed) return;

      const pingParsed = pingEventSchema.safeParse(parsed);
      if (pingParsed.success) {
        socket.send(serializeJson(pongEvent));
      }
    });

    socket.on("close", () => {
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
      for (const client of wss.clients) {
        client.close();
      }

      await new Promise<void>((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      });
    },
  };
}

