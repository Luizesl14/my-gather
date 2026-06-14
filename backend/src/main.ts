import "dotenv/config";

import { buildApp } from "./app";
import { config } from "./shared/infrastructure/config/config";
import { startWebsocketServer } from "./realtime/websocket-server";

async function main() {
  const app = await buildApp({ jwtSecret: config.jwtSecret });
  const wsServer = await startWebsocketServer({ port: config.wsPort, jwtSecret: config.jwtSecret });

  await app.listen({ port: config.apiPort, host: "0.0.0.0" });
  app.log.info({ apiPort: config.apiPort }, "backend_started");
  app.log.info({ wsPort: config.wsPort }, "websocket_started");

  const shutdown = async () => {
    await wsServer.stop();
    await app.close();
  };

  process.once("SIGINT", () => {
    shutdown().catch((error) => app.log.error(error));
  });

  process.once("SIGTERM", () => {
    shutdown().catch((error) => app.log.error(error));
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
