import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { AccessToken, RoomServiceClient, TrackType } from "livekit-server-sdk";

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

  // Server-side mute: mutes a participant's microphone for EVERYONE in the room.
  app.post<{ Params: { workspaceId: string } }>(
    "/workspaces/:workspaceId/livekit/mute",
    async (request: FastifyRequest<{ Params: { workspaceId: string } }>, reply: FastifyReply) => {
      const { url, apiKey, apiSecret } = config.livekit;
      if (!url || !apiKey || !apiSecret) {
        return reply.status(503).send({
          error: { code: "livekit.not_configured", message: "livekit.not_configured" },
        });
      }
      const raw = bearerToken(request);
      if (!(raw && tokenService.verify(raw))) {
        return reply.status(401).send({
          error: { code: "auth.unauthorized", message: "auth.unauthorized" },
        });
      }

      const { workspaceId } = request.params;
      const body = request.body as { identity?: string; muted?: boolean } | undefined;
      if (!body?.identity) {
        return reply.status(400).send({
          error: { code: "validation.invalid_payload", message: "validation.invalid_payload" },
        });
      }
      const muted = body.muted ?? true;

      const httpUrl = url.replace(/^wss:/, "https:").replace(/^ws:/, "http:");
      const svc = new RoomServiceClient(httpUrl, apiKey, apiSecret);
      try {
        const participant = await svc.getParticipant(workspaceId, body.identity);
        const audioTracks = participant.tracks.filter((t) => t.type === TrackType.AUDIO);
        await Promise.all(
          audioTracks.map((t) =>
            svc.mutePublishedTrack(workspaceId, body.identity!, t.sid, muted),
          ),
        );
        return reply.send({ ok: true, muted });
      } catch (error) {
        request.log.error(error);
        return reply.status(502).send({
          error: { code: "livekit.mute_failed", message: "livekit.mute_failed" },
        });
      }
    },
  );
}
