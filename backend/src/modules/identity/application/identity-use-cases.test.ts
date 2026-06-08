import { describe, expect, it } from "vitest";

import { Result } from "../../../shared/domain/result";
import { Invitation } from "../domain/entities/invitation";
import { Membership } from "../domain/entities/membership";
import { Organization } from "../domain/entities/organization";
import { User } from "../domain/entities/user";
import {
  type InvitationRepository,
  type MembershipRepository,
  type OrganizationRepository,
  type UserRepository,
} from "../domain/repositories/identity-repositories";
import { DisplayName } from "../domain/value-objects/display-name";
import { Email } from "../domain/value-objects/email";
import { InvitationToken } from "../domain/value-objects/invitation-token";
import { PasswordHash } from "../domain/value-objects/password-hash";
import { RoleName } from "../domain/value-objects/role-name";
import { type Clock } from "./ports/clock";
import { type IdGenerator } from "./ports/id-generator";
import { type InvitationTokenGenerator } from "./ports/invitation-token-generator";
import { type PasswordHasher } from "./ports/password-hasher";
import { AcceptInvitationUseCase } from "./use-cases/accept-invitation-use-case";
import { CreateOrganizationUseCase } from "./use-cases/create-organization-use-case";
import { InviteMemberUseCase } from "./use-cases/invite-member-use-case";
import { LoginUserUseCase } from "./use-cases/login-user-use-case";
import { RegisterUserUseCase } from "./use-cases/register-user-use-case";

function unwrap<T>(result: Result<T, string>): T {
  if (Result.isErr(result)) {
    throw new Error(result.error);
  }

  return result.value;
}

class FakeIdGenerator implements IdGenerator {
  private index = 0;

  constructor(private readonly ids: string[]) {}

  generate(): string {
    const id = this.ids[this.index];
    this.index += 1;
    return id ?? `generated-${this.index}`;
  }
}

class FakeClock implements Clock {
  constructor(private readonly value: Date) {}

  now(): Date {
    return this.value;
  }
}

class FakeTokenGenerator implements InvitationTokenGenerator {
  constructor(private readonly token: string) {}

  generate(): string {
    return this.token;
  }
}

class FakePasswordHasher implements PasswordHasher {
  async hash(plainPassword: string): Promise<string> {
    return `hashed-password-value-${plainPassword}`;
  }

  async verify(plainPassword: string, passwordHash: string): Promise<boolean> {
    return passwordHash === `hashed-password-value-${plainPassword}`;
  }
}

class InMemoryUserRepository implements UserRepository {
  readonly users = new Map<string, User>();

  async findByEmail(email: Email): Promise<User | null> {
    return [...this.users.values()].find((user) => user.email.value === email.value) ?? null;
  }

  async save(user: User): Promise<void> {
    this.users.set(user.id, user);
  }
}

class InMemoryOrganizationRepository implements OrganizationRepository {
  readonly organizations = new Map<string, Organization>();

  async save(organization: Organization): Promise<void> {
    this.organizations.set(organization.id, organization);
  }
}

class InMemoryMembershipRepository implements MembershipRepository {
  readonly memberships = new Map<string, Membership>();

  async findByUserAndOrganization(
    userId: string,
    organizationId: string,
  ): Promise<Membership | null> {
    return (
      [...this.memberships.values()].find(
        (membership) =>
          membership.userId === userId && membership.organizationId === organizationId,
      ) ?? null
    );
  }

  async save(membership: Membership): Promise<void> {
    this.memberships.set(membership.id, membership);
  }
}

class InMemoryInvitationRepository implements InvitationRepository {
  readonly invitations = new Map<string, Invitation>();

  async findByToken(token: InvitationToken): Promise<Invitation | null> {
    return (
      [...this.invitations.values()].find(
        (invitation) => invitation.token.value === token.value,
      ) ?? null
    );
  }

  async save(invitation: Invitation): Promise<void> {
    this.invitations.set(invitation.id, invitation);
  }
}

describe("Identity use cases", () => {
  it("registra usuario novo", async () => {
    const users = new InMemoryUserRepository();
    const useCase = new RegisterUserUseCase(
      users,
      new FakePasswordHasher(),
      new FakeIdGenerator(["user-1"]),
    );

    const result = await useCase.execute({
      email: "ada@example.com",
      password: "secret",
      displayName: "Ada",
    });

    expect(Result.isOk(result)).toBe(true);
    expect(users.users.get("user-1")?.email.value).toBe("ada@example.com");
  });

  it("nao registra email duplicado", async () => {
    const users = new InMemoryUserRepository();
    const useCase = new RegisterUserUseCase(
      users,
      new FakePasswordHasher(),
      new FakeIdGenerator(["user-1", "user-2"]),
    );

    await useCase.execute({
      email: "ada@example.com",
      password: "secret",
      displayName: "Ada",
    });
    const duplicated = await useCase.execute({
      email: "ada@example.com",
      password: "secret",
      displayName: "Ada",
    });

    expect(duplicated).toEqual({
      ok: false,
      error: "identity.user.email_already_registered",
    });
  });

  it("faz login com credenciais validas", async () => {
    const users = new InMemoryUserRepository();
    const hasher = new FakePasswordHasher();
    const register = new RegisterUserUseCase(users, hasher, new FakeIdGenerator(["user-1"]));
    const login = new LoginUserUseCase(users, hasher);

    await register.execute({
      email: "ada@example.com",
      password: "secret",
      displayName: "Ada",
    });
    const result = await login.execute({
      email: "ada@example.com",
      password: "secret",
    });

    expect(Result.isOk(result)).toBe(true);
  });

  it("recusa login com senha invalida", async () => {
    const users = new InMemoryUserRepository();
    const hasher = new FakePasswordHasher();
    const register = new RegisterUserUseCase(users, hasher, new FakeIdGenerator(["user-1"]));
    const login = new LoginUserUseCase(users, hasher);

    await register.execute({
      email: "ada@example.com",
      password: "secret",
      displayName: "Ada",
    });
    const result = await login.execute({
      email: "ada@example.com",
      password: "wrong",
    });

    expect(result).toEqual({
      ok: false,
      error: "identity.auth.invalid_credentials",
    });
  });

  it("cria organizacao com membership owner", async () => {
    const organizations = new InMemoryOrganizationRepository();
    const memberships = new InMemoryMembershipRepository();
    const useCase = new CreateOrganizationUseCase(
      organizations,
      memberships,
      new FakeIdGenerator(["org-1", "membership-1"]),
    );

    const result = await useCase.execute({
      ownerUserId: "user-1",
      name: "Love Robot",
    });

    expect(Result.isOk(result)).toBe(true);
    expect(organizations.organizations.get("org-1")?.name.value).toBe("Love Robot");
    expect(memberships.memberships.get("membership-1")?.organizationId).toBe("org-1");
  });

  it("cria convite com token e expiracao", async () => {
    const invitations = new InMemoryInvitationRepository();
    const useCase = new InviteMemberUseCase(
      invitations,
      new FakeIdGenerator(["invitation-1"]),
      new FakeTokenGenerator("invitation-token-value"),
      new FakeClock(new Date("2026-06-04T12:00:00.000Z")),
    );

    const result = await useCase.execute({
      organizationId: "org-1",
      email: "dev@example.com",
      role: "admin",
      invitedById: "user-1",
    });

    expect(Result.isOk(result)).toBe(true);
    expect(invitations.invitations.get("invitation-1")?.token.value).toBe(
      "invitation-token-value",
    );
  });

  it("aceita convite e cria membership", async () => {
    const invitations = new InMemoryInvitationRepository();
    const memberships = new InMemoryMembershipRepository();
    const invitation = unwrap(
      Invitation.create({
        id: "invitation-1",
        organizationId: "org-1",
        email: unwrap(Email.create("dev@example.com")),
        token: unwrap(InvitationToken.create("invitation-token-value")),
        role: RoleName.admin(),
        invitedById: "user-1",
        createdAt: new Date("2026-06-04T12:00:00.000Z"),
        expiresAt: new Date("2026-06-05T12:00:00.000Z"),
      }),
    );

    await invitations.save(invitation);

    const useCase = new AcceptInvitationUseCase(
      invitations,
      memberships,
      new FakeIdGenerator(["membership-1"]),
      new FakeClock(new Date("2026-06-04T13:00:00.000Z")),
    );

    const result = await useCase.execute({
      token: "invitation-token-value",
      userId: "user-2",
    });

    expect(Result.isOk(result)).toBe(true);
    expect(memberships.memberships.get("membership-1")?.organizationId).toBe("org-1");
  });
});
