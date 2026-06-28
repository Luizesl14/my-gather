import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { AccessToken } from "livekit-server-sdk";

import { config } from "../../../../shared/infrastructure/config/config";
import { NodeTokenService } from "../../../identity/infrastructure/crypto/node-token-service";

export type LivekitRoutesOptions = {
  jwtSecret: string;
};

function bearerToken(request: FastifyRequest): string | null {
  const header = request.headers["authorization"];
  if (!header) return null;
  const [scheme, value] = header.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !value) return null;
  return value;
}

export async function registerLivekitRoutes(
  app: FastifyInstance,
  options: LivekitRoutesOptions,
): Promise<void> {
  const tokenService = new NodeTokenService(options.jwtSecret);

  // Mints a LiveKit access token so the authenticated user can join the SFU
  // room for their workspace. One room per workspace; proximity is handled
  // client-side via selective subscription.
  app.post<{ Params: { workspaceId: string } }>(
    "/workspaces/:workspaceId/livekit-token",
    async (request: FastifyRequest<{ Params: { workspaceId: string } }>, reply: FastifyReply) => {
      const { url, apiKey, apiSecret } = config.livekit;
      if (!url || !apiKey || !apiSecret) {
        return reply.status(503).send({
          error: { code: "livekit.not_configured", message: "livekit.not_configured" },
        });
      }

      const raw = bearerToken(request);
      const payload = raw ? tokenService.verify(raw) : null;
      if (!payload) {
        return reply.status(401).send({
          error: { code: "auth.unauthorized", message: "auth.unauthorized" },
        });
      }

      const { workspaceId } = request.params;
      const displayName =
        (payload as Record<string, string>)["displayName"] ?? payload.email;

      const at = new AccessToken(apiKey, apiSecret, {
        identity: payload.sub,
        name: displayName,
      });
      at.addGrant({
        roomJoin: true,
        room: workspaceId,
        canPublish: true,
        canSubscribe: true,
      });

      const token = await at.toJwt();
      return reply.send({ token, url });
    },
  );
}
