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
import { Email } from "../../domain/value-objects/email";
import { InvitationToken } from "../../domain/value-objects/invitation-token";

export class InMemoryIdentityRepositories
  implements UserRepository, OrganizationRepository, MembershipRepository, InvitationRepository
{
  readonly users = new Map<string, User>();
  readonly organizations = new Map<string, Organization>();
  readonly memberships = new Map<string, Membership>();
  readonly invitations = new Map<string, Invitation>();

  async findByEmail(email: Email): Promise<User | null> {
    return [...this.users.values()].find((user) => user.email.value === email.value) ?? null;
  }

  async save(userOrOrganizationOrMembershipOrInvitation: User): Promise<void>;
  async save(userOrOrganizationOrMembershipOrInvitation: Organization): Promise<void>;
  async save(userOrOrganizationOrMembershipOrInvitation: Membership): Promise<void>;
  async save(userOrOrganizationOrMembershipOrInvitation: Invitation): Promise<void>;
  async save(entity: User | Organization | Membership | Invitation): Promise<void> {
    if (entity instanceof User) {
      this.users.set(entity.id, entity);
      return;
    }

    if (entity instanceof Organization) {
      this.organizations.set(entity.id, entity);
      return;
    }

    if (entity instanceof Membership) {
      this.memberships.set(entity.id, entity);
      return;
    }

    this.invitations.set(entity.id, entity);
  }

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

  async findByToken(token: InvitationToken): Promise<Invitation | null> {
    return (
      [...this.invitations.values()].find(
        (invitation) => invitation.token.value === token.value,
      ) ?? null
    );
  }

  listOrganizations(): Organization[] {
    return [...this.organizations.values()];
  }

  findOrganizationById(id: string): Organization | null {
    return this.organizations.get(id) ?? null;
  }

  findUserById(id: string): User | null {
    return this.users.get(id) ?? null;
  }
}
