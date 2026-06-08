import { Result } from "../../../../shared/domain/result";
import { Invitation } from "../../domain/entities/invitation";
import { type InvitationRepository } from "../../domain/repositories/identity-repositories";
import { Email } from "../../domain/value-objects/email";
import { InvitationToken } from "../../domain/value-objects/invitation-token";
import { RoleName } from "../../domain/value-objects/role-name";
import { type Clock } from "../ports/clock";
import { type IdGenerator } from "../ports/id-generator";
import { type InvitationTokenGenerator } from "../ports/invitation-token-generator";

const invitationTtlMs = 7 * 24 * 60 * 60 * 1000;

export type InviteMemberInput = {
  organizationId: string;
  email: string;
  role: string;
  invitedById: string;
};

export type InviteMemberOutput = {
  invitation: Invitation;
};

export class InviteMemberUseCase {
  constructor(
    private readonly invitationRepository: InvitationRepository,
    private readonly idGenerator: IdGenerator,
    private readonly tokenGenerator: InvitationTokenGenerator,
    private readonly clock: Clock,
  ) {}

  async execute(input: InviteMemberInput): Promise<Result<InviteMemberOutput, string>> {
    const email = Email.create(input.email);
    if (Result.isErr(email)) return email;

    const role = RoleName.create(input.role);
    if (Result.isErr(role)) return role;

    const token = InvitationToken.create(this.tokenGenerator.generate());
    if (Result.isErr(token)) return token;

    const createdAt = this.clock.now();
    const invitation = Invitation.create({
      id: this.idGenerator.generate(),
      organizationId: input.organizationId,
      email: email.value,
      token: token.value,
      role: role.value,
      invitedById: input.invitedById,
      createdAt,
      expiresAt: new Date(createdAt.getTime() + invitationTtlMs),
    });
    if (Result.isErr(invitation)) return invitation;

    await this.invitationRepository.save(invitation.value);

    return Result.ok({ invitation: invitation.value });
  }
}
