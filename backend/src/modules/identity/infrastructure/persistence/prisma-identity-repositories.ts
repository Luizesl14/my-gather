import { prisma } from "../../../../shared/infrastructure/database/prisma-client";
import { Result } from "../../../../shared/domain/result";
import { Invitation } from "../../domain/entities/invitation";
import { Membership } from "../../domain/entities/membership";
import { Organization } from "../../domain/entities/organization";
import { User } from "../../domain/entities/user";
import {
  type InvitationRepository,
  type MembershipRepository,
  type OrganizationRepository,
  type UserRepository,
} from "../../domain/repositories/identity-repositories";
import { DisplayName } from "../../domain/value-objects/display-name";
import { Email } from "../../domain/value-objects/email";
import { InvitationToken } from "../../domain/value-objects/invitation-token";
import { OrganizationName } from "../../domain/value-objects/organization-name";
import { PasswordHash } from "../../domain/value-objects/password-hash";
import { RoleName } from "../../domain/value-objects/role-name";

function unwrap<T>(result: Result<T, string>, context: string): T {
  if (!Result.isOk(result)) throw new Error(`${context}: ${result.error}`);
  return result.value;
}

export class PrismaIdentityRepositories
  implements UserRepository, OrganizationRepository, MembershipRepository, InvitationRepository
{
  async findByEmail(email: Email): Promise<User | null> {
    const row = await prisma.user.findUnique({ where: { email: email.value } });
    return row ? this._toUser(row) : null;
  }

  async save(entity: User | Organization | Membership | Invitation): Promise<void> {
    if (entity instanceof User) {
      await prisma.user.upsert({
        where: { id: entity.id },
        create: {
          id: entity.id,
          email: entity.email.value,
          passwordHash: entity.passwordHash.value,
          displayName: entity.displayName.value,
          avatarId: "character-01",
        },
        update: {
          email: entity.email.value,
          passwordHash: entity.passwordHash.value,
          displayName: entity.displayName.value,
        },
      });
      return;
    }

    if (entity instanceof Organization) {
      await prisma.organization.upsert({
        where: { id: entity.id },
        create: { id: entity.id, name: entity.name.value },
        update: { name: entity.name.value },
      });
      return;
    }

    if (entity instanceof Membership) {
      await prisma.membership.upsert({
        where: {
          userId_organizationId: {
            userId: entity.userId,
            organizationId: entity.organizationId,
          },
        },
        create: {
          id: entity.id,
          userId: entity.userId,
          organizationId: entity.organizationId,
          role: entity.role.value,
          joinedAt: entity.joinedAt,
        },
        update: { role: entity.role.value },
      });
      return;
    }

    if (entity instanceof Invitation) {
      await prisma.invitation.upsert({
        where: { id: entity.id },
        create: {
          id: entity.id,
          organizationId: entity.organizationId,
          email: entity.email.value,
          token: entity.token.value,
          role: entity.role.value,
          invitedById: entity.invitedById,
          expiresAt: entity.expiresAt,
          acceptedAt: entity.acceptedAt,
          createdAt: entity.createdAt,
        },
        update: { acceptedAt: entity.acceptedAt },
      });
    }
  }

  async findByUserAndOrganization(userId: string, organizationId: string): Promise<Membership | null> {
    const row = await prisma.membership.findUnique({
      where: { userId_organizationId: { userId, organizationId } },
    });
    return row ? this._toMembership(row) : null;
  }

  async listOrganizationMembers(
    organizationId: string,
  ): Promise<Array<{ userId: string; displayName: string; role: string; avatarId: string }>> {
    const rows = await prisma.membership.findMany({
      where: { organizationId },
      include: { user: { select: { displayName: true, avatarId: true } } },
      orderBy: { joinedAt: "asc" },
    });
    return rows.map((r) => ({
      userId: r.userId,
      displayName: r.user.displayName,
      role: r.role,
      avatarId: r.user.avatarId,
    }));
  }

  async findByToken(token: InvitationToken): Promise<Invitation | null> {
    const row = await prisma.invitation.findUnique({ where: { token: token.value } });
    return row ? this._toInvitation(row) : null;
  }

  async listOrganizations(): Promise<Organization[]> {
    const rows = await prisma.organization.findMany({ orderBy: { createdAt: "asc" } });
    return rows.map((r) => this._toOrganization(r));
  }

  async findOrganizationById(id: string): Promise<Organization | null> {
    const row = await prisma.organization.findUnique({ where: { id } });
    return row ? this._toOrganization(row) : null;
  }

  async findUserById(id: string): Promise<User | null> {
    const row = await prisma.user.findUnique({ where: { id } });
    return row ? this._toUser(row) : null;
  }

  async updateAvatar(userId: string, avatarId: string): Promise<void> {
    await prisma.user.update({ where: { id: userId }, data: { avatarId } });
  }

  async getAvatarId(userId: string): Promise<string> {
    const row = await prisma.user.findUnique({
      where: { id: userId },
      select: { avatarId: true },
    });
    return row?.avatarId ?? "character-01";
  }

  private _toUser(row: {
    id: string;
    email: string;
    passwordHash: string;
    displayName: string;
    createdAt: Date;
  }): User {
    return unwrap(
      User.register({
        id: row.id,
        email: unwrap(Email.create(row.email), "Email"),
        passwordHash: unwrap(PasswordHash.create(row.passwordHash), "PasswordHash"),
        displayName: unwrap(DisplayName.create(row.displayName), "DisplayName"),
        createdAt: row.createdAt,
      }),
      "User.register",
    );
  }

  private _toOrganization(row: { id: string; name: string; createdAt: Date }): Organization {
    return unwrap(
      Organization.create({
        id: row.id,
        name: unwrap(OrganizationName.create(row.name), "OrganizationName"),
        createdAt: row.createdAt,
      }),
      "Organization.create",
    );
  }

  private _toMembership(row: {
    id: string;
    userId: string;
    organizationId: string;
    role: string;
    joinedAt: Date;
  }): Membership {
    return unwrap(
      Membership.create({
        id: row.id,
        userId: row.userId,
        organizationId: row.organizationId,
        role: unwrap(RoleName.create(row.role), "RoleName"),
        joinedAt: row.joinedAt,
      }),
      "Membership.create",
    );
  }

  private _toInvitation(row: {
    id: string;
    organizationId: string;
    email: string;
    token: string;
    role: string;
    invitedById: string;
    expiresAt: Date;
    acceptedAt: Date | null;
    createdAt: Date;
  }): Invitation {
    return unwrap(
      Invitation.create({
        id: row.id,
        organizationId: row.organizationId,
        email: unwrap(Email.create(row.email), "Email"),
        token: unwrap(InvitationToken.create(row.token), "InvitationToken"),
        role: unwrap(RoleName.create(row.role), "RoleName"),
        invitedById: row.invitedById,
        expiresAt: row.expiresAt,
        createdAt: row.createdAt,
      }),
      "Invitation.create",
    );
  }
}
