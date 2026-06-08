import { afterEach, describe, expect, it } from "vitest";
import { type FastifyInstance } from "fastify";

import { buildApp } from "../../../../app";

async function createApp(): Promise<FastifyInstance> {
  const app = await buildApp({ jwtSecret: "test-secret" });
  await app.ready();
  return app;
}

describe("Workspace REST routes", () => {
  let app: FastifyInstance | null = null;

  afterEach(async () => {
    await app?.close();
    app = null;
  });

  it("cria e lista workspaces por organizacao", async () => {
    app = await createApp();

    const created = await app.inject({
      method: "POST",
      url: "/organizations/org-1/workspaces",
      payload: {
        name: "Escritorio Principal",
      },
    });

    expect(created.statusCode).toBe(201);
    expect(created.json()).toEqual({
      workspace: {
        id: expect.any(String),
        organizationId: "org-1",
        name: "Escritorio Principal",
        activeFloorId: expect.any(String),
      },
    });

    const listed = await app.inject({
      method: "GET",
      url: "/organizations/org-1/workspaces",
    });

    expect(listed.statusCode).toBe(200);
    expect(listed.json()).toEqual({
      workspaces: [
        {
          id: expect.any(String),
          organizationId: "org-1",
          name: "Escritorio Principal",
          activeFloorId: expect.any(String),
        },
      ],
    });
  });

  it("retorna mapa renderizavel do workspace", async () => {
    app = await createApp();

    const created = await app.inject({
      method: "POST",
      url: "/organizations/org-1/workspaces",
      payload: {
        name: "Escritorio Principal",
      },
    });
    const workspaceId = created.json<{ workspace: { id: string } }>().workspace.id;

    const response = await app.inject({
      method: "GET",
      url: `/workspaces/${workspaceId}/map`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      workspace: {
        id: workspaceId,
        organizationId: "org-1",
        name: "Escritorio Principal",
        activeFloorId: expect.any(String),
      },
      floor: {
        id: expect.any(String),
        workspaceId,
        name: "Principal",
        level: 1,
      },
      map: {
        id: "office-default",
        version: 1,
        width: 28,
        height: 18,
        tileSize: 32,
      },
      layers: expect.any(Array),
      collision: expect.any(Array),
      rooms: expect.arrayContaining([
        expect.objectContaining({ id: "room-alpha" }),
      ]),
      desks: expect.arrayContaining([
        expect.objectContaining({ id: "desk-ana" }),
        expect.objectContaining({ id: "desk-luiz" }),
      ]),
      interactiveZones: expect.arrayContaining([
        expect.objectContaining({ id: "zone-room-alpha" }),
      ]),
      assetPackId: "office-default-v1",
    });
  });

  it("retorna 404 para workspace inexistente", async () => {
    app = await createApp();

    const response = await app.inject({
      method: "GET",
      url: "/workspaces/missing/map",
    });

    expect(response.statusCode).toBe(404);
    expect(response.json()).toEqual({
      error: {
        code: "workspace.not_found",
        message: "workspace.not_found",
      },
    });
  });
});
