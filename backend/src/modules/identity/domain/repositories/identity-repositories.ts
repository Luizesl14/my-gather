import { Invitation } from "../entities/invitation";
import { Membership } from "../entities/membership";
import { Organization } from "../entities/organization";
import { User } from "../entities/user";
import { Email } from "../value-objects/email";
import { InvitationToken } from "../value-objects/invitation-token";

export interface UserRepository {
  findByEmail(email: Email): Promise<User | null>;
  save(user: User): Promise<void>;
}

export interface OrganizationRepository {
  save(organization: Organization): Promise<void>;
}

export interface MembershipRepository {
  findByUserAndOrganization(userId: string, organizationId: string): Promise<Membership | null>;
  save(membership: Membership): Promise<void>;
}

export interface InvitationRepository {
  findByToken(token: InvitationToken): Promise<Invitation | null>;
  save(invitation: Invitation): Promise<void>;
}
