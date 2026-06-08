import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { invitationAccepted, invitationCreated } from "../events/identity-events";
import { Email } from "../value-objects/email";
import { InvitationToken } from "../value-objects/invitation-token";
import { RoleName } from "../value-objects/role-name";

export type InvitationProps = {
  organizationId: string;
  email: Email;
  token: InvitationToken;
  role: RoleName;
  invitedById: string;
  expiresAt: Date;
  acceptedAt?: Date;
  createdAt: Date;
};

export class Invitation extends AggregateRoot<InvitationProps> {
  private constructor(id: string, props: InvitationProps) {
    super(id, props);
  }

  get acceptedAt(): Date | undefined {
    return this.props.acceptedAt;
  }

  get organizationId(): string {
    return this.props.organizationId;
  }

  get token(): InvitationToken {
    return this.props.token;
  }

  get role(): RoleName {
    return this.props.role;
  }

  get email(): Email {
    return this.props.email;
  }

  get invitedById(): string {
    return this.props.invitedById;
  }

  get expiresAt(): Date {
    return this.props.expiresAt;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }

  static create(input: {
    id: string;
    organizationId: string;
    email: Email;
    token: InvitationToken;
    role: RoleName;
    invitedById: string;
    expiresAt: Date;
    createdAt?: Date;
  }): Result<Invitation, string> {
    if (!input.id.trim() || !input.organizationId.trim() || !input.invitedById.trim()) {
      return Result.err("identity.invitation.required_ids");
    }

    const createdAt = input.createdAt ?? new Date();

    if (input.expiresAt.getTime() <= createdAt.getTime()) {
      return Result.err("identity.invitation.expiration_must_be_future");
    }

    const invitation = new Invitation(input.id, {
      organizationId: input.organizationId,
      email: input.email,
      token: input.token,
      role: input.role,
      invitedById: input.invitedById,
      expiresAt: input.expiresAt,
      createdAt,
    });

    invitation.addDomainEvent(invitationCreated(invitation.id));

    return Result.ok(invitation);
  }

  accept(acceptedAt = new Date()): Result<void, string> {
    if (this.props.acceptedAt) {
      return Result.err("identity.invitation.already_accepted");
    }

    if (this.props.expiresAt.getTime() <= acceptedAt.getTime()) {
      return Result.err("identity.invitation.expired");
    }

    this.props.acceptedAt = acceptedAt;
    this.addDomainEvent(invitationAccepted(this.id, acceptedAt));

    return Result.ok(undefined);
  }
}
