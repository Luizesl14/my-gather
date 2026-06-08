import { describe, expect, it } from "vitest";

import { Result } from "../../../shared/domain/result";
import { Invitation } from "./entities/invitation";
import { Organization } from "./entities/organization";
import { User } from "./entities/user";
import { DisplayName } from "./value-objects/display-name";
import { Email } from "./value-objects/email";
import { InvitationToken } from "./value-objects/invitation-token";
import { OrganizationName } from "./value-objects/organization-name";
import { PasswordHash } from "./value-objects/password-hash";
import { RoleName } from "./value-objects/role-name";

function unwrap<T>(result: Result<T, string>): T {
  if (Result.isErr(result)) {
    throw new Error(result.error);
  }

  return result.value;
}

describe("Identity domain", () => {
  it("falha com email invalido", () => {
    const result = Email.create("email-invalido");

    expect(Result.isErr(result)).toBe(true);
    expect(result).toEqual({
      ok: false,
      error: "identity.email.invalid",
    });
  });

  it("registra usuario valido com evento de dominio", () => {
    const user = unwrap(
      User.register({
        id: "user-1",
        email: unwrap(Email.create("ADA@EXAMPLE.COM")),
        passwordHash: unwrap(PasswordHash.create("hashed-password-value-123")),
        displayName: unwrap(DisplayName.create("Ada")),
      }),
    );

    expect(user.email.value).toBe("ada@example.com");
    expect(user.displayName.value).toBe("Ada");
    expect(user.getDomainEvents()).toEqual([
      expect.objectContaining({
        eventName: "identity.user_registered",
        aggregateId: "user-1",
      }),
    ]);
  });

  it("falha com nome de organizacao invalido", () => {
    const result = OrganizationName.create(" ");

    expect(Result.isErr(result)).toBe(true);
    expect(result).toEqual({
      ok: false,
      error: "identity.organization_name.invalid_length",
    });
  });

  it("cria organizacao valida com evento de dominio", () => {
    const organization = unwrap(
      Organization.create({
        id: "org-1",
        name: unwrap(OrganizationName.create("Love Robot")),
      }),
    );

    expect(organization.name.value).toBe("Love Robot");
    expect(organization.getDomainEvents()).toEqual([
      expect.objectContaining({
        eventName: "identity.organization_created",
        aggregateId: "org-1",
      }),
    ]);
  });

  it("nao aceita convite expirado", () => {
    const invitation = unwrap(
      Invitation.create({
        id: "invitation-1",
        organizationId: "org-1",
        email: unwrap(Email.create("dev@example.com")),
        token: unwrap(InvitationToken.create("token-with-enough-size")),
        role: RoleName.member(),
        invitedById: "user-1",
        createdAt: new Date("2026-06-04T12:00:00.000Z"),
        expiresAt: new Date("2026-06-05T12:00:00.000Z"),
      }),
    );

    const result = invitation.accept(new Date("2026-06-06T12:00:00.000Z"));

    expect(Result.isErr(result)).toBe(true);
    expect(result).toEqual({
      ok: false,
      error: "identity.invitation.expired",
    });
  });

  it("aceita convite valido uma unica vez", () => {
    const invitation = unwrap(
      Invitation.create({
        id: "invitation-1",
        organizationId: "org-1",
        email: unwrap(Email.create("dev@example.com")),
        token: unwrap(InvitationToken.create("token-with-enough-size")),
        role: RoleName.admin(),
        invitedById: "user-1",
        createdAt: new Date("2026-06-04T12:00:00.000Z"),
        expiresAt: new Date("2026-06-05T12:00:00.000Z"),
      }),
    );

    const accepted = invitation.accept(new Date("2026-06-04T13:00:00.000Z"));
    const acceptedAgain = invitation.accept(new Date("2026-06-04T14:00:00.000Z"));

    expect(Result.isOk(accepted)).toBe(true);
    expect(Result.isErr(acceptedAgain)).toBe(true);
    expect(invitation.acceptedAt).toEqual(new Date("2026-06-04T13:00:00.000Z"));
    expect(invitation.getDomainEvents()).toEqual([
      expect.objectContaining({
        eventName: "identity.invitation_created",
        aggregateId: "invitation-1",
      }),
      expect.objectContaining({
        eventName: "identity.invitation_accepted",
        aggregateId: "invitation-1",
      }),
    ]);
  });
});
