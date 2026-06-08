import { randomUUID } from "node:crypto";

import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { type ZodSchema } from "zod";

import { loadDefaultOfficeMap } from "../../infrastructure/map/default-map-loader";
import { PrismaWorkspaceRepository } from "../../infrastructure/persistence/prisma-workspace-repository";
import {
  createWorkspaceBodySchema,
  organizationWorkspaceParamsSchema,
  updateMapBodySchema,
  workspaceParamsSchema,
} from "../schemas/workspace-schemas";

export type WorkspaceRoutesOptions = {
  repository?: PrismaWorkspaceRepository;
};

function sendError(reply: FastifyReply, statusCode: number, code: string) {
  return reply.status(statusCode).send({
    error: {
      code,
      message: code,
    },
  });
}

function parseBody<T>(schema: ZodSchema<T>, request: FastifyRequest, reply: FastifyReply): T | null {
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) {
    console.error("[parseBody] Zod errors:", JSON.stringify(parsed.error.issues, null, 2));
    sendError(reply, 400, "validation.invalid_payload");
    return null;
  }

  return parsed.data;
}

function parseParams<T>(
  schema: ZodSchema<T>,
  request: FastifyRequest,
  reply: FastifyReply,
): T | null {
  const parsed = schema.safeParse(request.params);
  if (!parsed.success) {
    sendError(reply, 400, "validation.invalid_params");
    return null;
  }

  return parsed.data;
}

export async function registerWorkspaceRoutes(
  app: FastifyInstance,
  options: WorkspaceRoutesOptions = {},
): Promise<void> {
  const repository = options.repository ?? new PrismaWorkspaceRepository();
  const defaultMap = loadDefaultOfficeMap();

  app.post("/organizations/:organizationId/workspaces", async (request, reply) => {
    const params = parseParams(organizationWorkspaceParamsSchema, request, reply);
    if (!params) return reply;

    const body = parseBody(createWorkspaceBodySchema, request, reply);
    if (!body) return reply;

    const workspace = await repository.createWorkspace({
      id: randomUUID(),
      organizationId: params.organizationId,
      name: body.name,
      activeFloorId: randomUUID(),
    });

    return reply.status(201).send({ workspace });
  });

  app.get("/organizations/:organizationId/workspaces", async (request, reply) => {
    const params = parseParams(organizationWorkspaceParamsSchema, request, reply);
    if (!params) return reply;
    return { workspaces: await repository.listByOrganization(params.organizationId) };
  });

  app.delete("/workspaces/:workspaceId", async (request, reply) => {
    const params = parseParams(workspaceParamsSchema, request, reply);
    if (!params) return reply;
    await repository.deleteWorkspace(params.workspaceId);
    return reply.status(204).send();
  });

  app.get("/workspaces/:workspaceId", async (request, reply) => {
    const params = parseParams(workspaceParamsSchema, request, reply);
    if (!params) return reply;
    const workspace = await repository.findWorkspace(params.workspaceId);
    if (!workspace) return sendError(reply, 404, "workspace.not_found");
    return { workspace };
  });

  app.get("/workspaces/:workspaceId/map", async (request, reply) => {
    const params = parseParams(workspaceParamsSchema, request, reply);
    if (!params) return reply;

    const [workspace, floor] = await Promise.all([
      repository.findWorkspace(params.workspaceId),
      repository.findActiveFloor(params.workspaceId),
    ]);
    if (!workspace || !floor) {
      return sendError(reply, 404, "workspace.not_found");
    }

    const saved = (await repository.findMap(params.workspaceId)) as Record<string, unknown> | null;
    const src = saved ?? defaultMap;

    return {
      id: (src as { id?: string }).id ?? defaultMap.id,
      version: defaultMap.version,
      width: src.width as number,
      height: src.height as number,
      tileSize: src.tileSize as number,
      assetPackId: src.assetPackId as string,
      spawn: defaultMap.spawn,
      layers: src.layers,
      collision: src.collision ?? [],
      interactiveZones: src.interactiveZones ?? [],
    };
  });

  app.put("/workspaces/:workspaceId/map", async (request, reply) => {
    const params = parseParams(workspaceParamsSchema, request, reply);
    if (!params) return reply;

    const body = parseBody(updateMapBodySchema, request, reply);
    if (!body) return reply;

    const workspace = await repository.findWorkspace(params.workspaceId);
    if (!workspace) return sendError(reply, 404, "workspace.not_found");

    await repository.updateMap(params.workspaceId, {
      width: body.width,
      height: body.height,
      tileSize: body.tileSize,
      assetPackId: body.assetPackId,
      spawn: body.spawn,
      layers: body.layers as object[],
      collision: body.collision as object[],
      interactiveZones: body.interactiveZones as object[],
    });

    return reply.status(204).send();
  });
}
