import { randomUUID } from "node:crypto";
import cors from "@fastify/cors";
import Fastify, {
  type FastifyInstance,
  type FastifyReply,
  type FastifyRequest,
} from "fastify";

import { registerIdentityRoutes } from "./modules/identity/presentation/http/identity-routes";
import { registerWorkspaceRoutes } from "./modules/workspace/presentation/http/workspace-routes";

export type BuildAppOptions = {
  jwtSecret?: string;
};

export async function buildApp(options: BuildAppOptions = {}): Promise<FastifyInstance> {
  const app = Fastify({
    logger: true,
    genReqId: () => randomUUID(),
  });

  await app.register(cors, {
    origin: true,
    methods: ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  });

  app.get("/health", async () => {
    return { status: "ok" };
  });

  app.setErrorHandler(async (error: Error, _request: FastifyRequest, reply: FastifyReply) => {
    app.log.error(error);
    return reply.status(500).send({ message: "internal_error" });
  });

  await registerIdentityRoutes(app, {
    jwtSecret: options.jwtSecret ?? "dev-only-test-secret",
  });
  await registerWorkspaceRoutes(app);

  return app;
}
