import { randomUUID } from "node:crypto";

import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { type ZodSchema, z } from "zod";

import { Result } from "../../../../shared/domain/result";
import { SystemClock } from "../../application/ports/clock";
import { AcceptInvitationUseCase } from "../../application/use-cases/accept-invitation-use-case";
import { CreateOrganizationUseCase } from "../../application/use-cases/create-organization-use-case";
import { InviteMemberUseCase } from "../../application/use-cases/invite-member-use-case";
import { LoginUserUseCase } from "../../application/use-cases/login-user-use-case";
import { RegisterUserUseCase } from "../../application/use-cases/register-user-use-case";
import { User } from "../../domain/entities/user";
import { PrismaIdentityRepositories } from "../../infrastructure/persistence/prisma-identity-repositories";
import { NodePasswordHasher } from "../../infrastructure/crypto/node-password-hasher";
import { NodeTokenService } from "../../infrastructure/crypto/node-token-service";
import { NodeIdGenerator } from "../../infrastructure/generators/node-id-generator";
import { NodeInvitationTokenGenerator } from "../../infrastructure/generators/node-invitation-token-generator";
import { PrismaWorkspaceRepository } from "../../../workspace/infrastructure/persistence/prisma-workspace-repository";
import {
  acceptInvitationParamsSchema,
  createOrganizationBodySchema,
  inviteMemberBodySchema,
  loginBodySchema,
  organizationParamsSchema,
  registerBodySchema,
} from "../schemas/identity-schemas";

export type IdentityRoutesOptions = {
  jwtSecret: string;
};

type AuthenticatedRequest = FastifyRequest & { user: User };

const updateAvatarBodySchema = z.object({ avatarId: z.string().min(1) });

function sendError(reply: FastifyReply, statusCode: number, code: string) {
  return reply.status(statusCode).send({ error: { code, message: code } });
}

function parseBody<T>(schema: ZodSchema<T>, request: FastifyRequest, reply: FastifyReply): T | null {
  const parsed = schema.safeParse(request.body);
  if (!parsed.success) { sendError(reply, 400, "validation.invalid_payload"); return null; }
  return parsed.data;
}

function parseParams<T>(schema: ZodSchema<T>, request: FastifyRequest, reply: FastifyReply): T | null {
  const parsed = schema.safeParse(request.params);
  if (!parsed.success) { sendError(reply, 400, "validation.invalid_params"); return null; }
  return parsed.data;
}

function userDto(user: User, avatarId = "character-01") {
  return {
    id: user.id,
    email: user.email.value,
    displayName: user.displayName.value,
    defaultAvatarId: avatarId,
  };
}

export async function registerIdentityRoutes(
  app: FastifyInstance,
  options: IdentityRoutesOptions,
): Promise<void> {
  const repositories = new PrismaIdentityRepositories();
  const workspaceRepository = new PrismaWorkspaceRepository();
  const idGenerator = new NodeIdGenerator();
  const passwordHasher = new NodePasswordHasher();
  const tokenGenerator = new NodeInvitationTokenGenerator();
  const clock = new SystemClock();
  const tokenService = new NodeTokenService(options.jwtSecret);

  const registerUser = new RegisterUserUseCase(repositories, passwordHasher, idGenerator);
  const loginUser = new LoginUserUseCase(repositories, passwordHasher);
  const createOrganization = new CreateOrganizationUseCase(repositories, repositories, idGenerator);
  const inviteMember = new InviteMemberUseCase(repositories, idGenerator, tokenGenerator, clock);
  const acceptInvitation = new AcceptInvitationUseCase(repositories, repositories, idGenerator, clock);

  async function authenticate(request: FastifyRequest, reply: FastifyReply): Promise<User | null> {
    const authorization = request.headers.authorization;
    const token = authorization?.startsWith("Bearer ") ? authorization.slice(7) : null;
    if (!token) { sendError(reply, 401, "auth.unauthorized"); return null; }
    const payload = tokenService.verify(token);
    if (!payload) { sendError(reply, 401, "auth.unauthorized"); return null; }
    const user = await repositories.findUserById(payload.sub);
    if (!user) { sendError(reply, 401, "auth.unauthorized"); return null; }
    (request as AuthenticatedRequest).user = user;
    return user;
  }

  app.post("/auth/register", async (request, reply) => {
    const body = parseBody(registerBodySchema, request, reply);
    if (!body) return reply;
    const result = await registerUser.execute(body);
    if (Result.isErr(result)) return sendError(reply, 400, result.error);
    const avatarId = await repositories.getAvatarId(result.value.user.id);
    return reply.status(201).send({ user: userDto(result.value.user, avatarId) });
  });

  app.post("/auth/login", async (request, reply) => {
    const body = parseBody(loginBodySchema, request, reply);
    if (!body) return reply;
    const result = await loginUser.execute(body);
    if (Result.isErr(result)) return sendError(reply, 401, result.error);
    const avatarId = await repositories.getAvatarId(result.value.user.id);
    return {
      user: userDto(result.value.user, avatarId),
      token: tokenService.sign({ sub: result.value.user.id, email: result.value.user.email.value }),
    };
  });

  app.post("/auth/logout", async () => ({ ok: true }));

  app.get("/auth/me", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const avatarId = await repositories.getAvatarId(user.id);
    return { user: userDto(user, avatarId) };
  });

  app.put("/auth/me/avatar", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const body = parseBody(updateAvatarBodySchema, request, reply);
    if (!body) return reply;
    await repositories.updateAvatar(user.id, body.avatarId);
    return { ok: true, avatarId: body.avatarId };
  });

  app.post("/organizations", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const body = parseBody(createOrganizationBodySchema, request, reply);
    if (!body) return reply;
    const result = await createOrganization.execute({ ownerUserId: user.id, name: body.name });
    if (Result.isErr(result)) return sendError(reply, 400, result.error);

    const org = result.value.organization;
    const workspaceId = randomUUID();
    const floorId = randomUUID();
    const workspace = await workspaceRepository.createWorkspace({
      id: workspaceId,
      organizationId: org.id,
      name: "Escritório Principal",
      activeFloorId: floorId,
    });

    return reply.status(201).send({
      organization: { id: org.id, name: org.name.value },
      workspace: { id: workspace.id, name: workspace.name },
    });
  });

  app.get("/organizations", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const organizations = await repositories.listOrganizations();
    return { organizations: organizations.map((o) => ({ id: o.id, name: o.name.value })) };
  });

  app.get("/organizations/:id", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const params = parseParams(organizationParamsSchema, request, reply);
    if (!params) return reply;
    const organization = await repositories.findOrganizationById(params.id);
    if (!organization) return sendError(reply, 404, "identity.organization.not_found");
    return { organization: { id: organization.id, name: organization.name.value } };
  });

  app.post("/organizations/:id/invitations", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const params = parseParams(organizationParamsSchema, request, reply);
    if (!params) return reply;
    const body = parseBody(inviteMemberBodySchema, request, reply);
    if (!body) return reply;
    const result = await inviteMember.execute({
      organizationId: params.id,
      email: body.email,
      role: body.role,
      invitedById: user.id,
    });
    if (Result.isErr(result)) return sendError(reply, 400, result.error);
    return reply.status(201).send({
      invitation: { id: result.value.invitation.id, token: result.value.invitation.token.value },
    });
  });

  app.post("/invitations/:token/accept", async (request, reply) => {
    const user = await authenticate(request, reply);
    if (!user) return reply;
    const params = parseParams(acceptInvitationParamsSchema, request, reply);
    if (!params) return reply;
    const result = await acceptInvitation.execute({ token: params.token, userId: user.id });
    if (Result.isErr(result)) return sendError(reply, 400, result.error);
    return { membership: { id: result.value.membership.id, organizationId: result.value.membership.organizationId } };
  });
}
