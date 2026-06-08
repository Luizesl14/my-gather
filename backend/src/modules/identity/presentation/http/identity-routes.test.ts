import { afterEach, describe, expect, it } from "vitest";
import { type FastifyInstance } from "fastify";

import { buildApp } from "../../../../app";

async function createApp(): Promise<FastifyInstance> {
  const app = await buildApp({ jwtSecret: "test-secret" });
  await app.ready();
  return app;
}

describe("Identity REST routes", () => {
  let app: FastifyInstance | null = null;

  afterEach(async () => {
    await app?.close();
    app = null;
  });

  it("registra usuario sem retornar senha", async () => {
    app = await createApp();

    const response = await app.inject({
      method: "POST",
      url: "/auth/register",
      payload: {
        email: "ada@example.com",
        password: "secret123",
        displayName: "Ada",
      },
    });

    expect(response.statusCode).toBe(201);
    expect(response.json()).toEqual({
      user: {
        id: expect.any(String),
        email: "ada@example.com",
        displayName: "Ada",
        defaultAvatarId: "character-01",
      },
    });
    expect(response.body).not.toContain("password");
  });

  it("valida payload de register", async () => {
    app = await createApp();

    const response = await app.inject({
      method: "POST",
      url: "/auth/register",
      payload: {
        email: "invalid",
        password: "123",
        displayName: "",
      },
    });

    expect(response.statusCode).toBe(400);
    expect(response.json()).toEqual({
      error: {
        code: "validation.invalid_payload",
        message: "validation.invalid_payload",
      },
    });
  });

  it("faz login e retorna token", async () => {
    app = await createApp();

    await app.inject({
      method: "POST",
      url: "/auth/register",
      payload: {
        email: "ada@example.com",
        password: "secret123",
        displayName: "Ada",
      },
    });

    const response = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: {
        email: "ada@example.com",
        password: "secret123",
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      user: {
        id: expect.any(String),
        email: "ada@example.com",
        displayName: "Ada",
        defaultAvatarId: "character-01",
      },
      token: expect.any(String),
    });
  });

  it("retorna usuario autenticado em auth me", async () => {
    app = await createApp();

    await app.inject({
      method: "POST",
      url: "/auth/register",
      payload: {
        email: "ada@example.com",
        password: "secret123",
        displayName: "Ada",
      },
    });
    const login = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: {
        email: "ada@example.com",
        password: "secret123",
      },
    });
    const token = login.json<{ token: string }>().token;

    const response = await app.inject({
      method: "GET",
      url: "/auth/me",
      headers: {
        authorization: `Bearer ${token}`,
      },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      user: {
        id: expect.any(String),
        email: "ada@example.com",
        displayName: "Ada",
        defaultAvatarId: "character-01",
      },
    });
  });

  it("recusa credenciais invalidas", async () => {
    app = await createApp();

    const response = await app.inject({
      method: "POST",
      url: "/auth/login",
      payload: {
        email: "missing@example.com",
        password: "secret123",
      },
    });

    expect(response.statusCode).toBe(401);
    expect(response.json()).toEqual({
      error: {
        code: "identity.auth.invalid_credentials",
        message: "identity.auth.invalid_credentials",
      },
    });
  });
});
