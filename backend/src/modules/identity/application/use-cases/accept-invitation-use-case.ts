import { Result } from "../../../../shared/domain/result";
import { Membership } from "../../domain/entities/membership";
import {
  type InvitationRepository,
  type MembershipRepository,
} from "../../domain/repositories/identity-repositories";
import { InvitationToken } from "../../domain/value-objects/invitation-token";
import { type Clock } from "../ports/clock";
import { type IdGenerator } from "../ports/id-generator";

export type AcceptInvitationInput = {
  token: string;
  userId: string;
};

export type AcceptInvitationOutput = {
  membership: Membership;
};

export class AcceptInvitationUseCase {
  constructor(
    private readonly invitationRepository: InvitationRepository,
    private readonly membershipRepository: MembershipRepository,
    private readonly idGenerator: IdGenerator,
    private readonly clock: Clock,
  ) {}

  async execute(input: AcceptInvitationInput): Promise<Result<AcceptInvitationOutput, string>> {
    const token = InvitationToken.create(input.token);
    if (Result.isErr(token)) return token;

    const invitation = await this.invitationRepository.findByToken(token.value);
    if (!invitation) {
      return Result.err("identity.invitation.not_found");
    }

    const existingMembership = await this.membershipRepository.findByUserAndOrganization(
      input.userId,
      invitation.organizationId,
    );
    if (existingMembership) {
      return Result.err("identity.membership.already_exists");
    }

    const accepted = invitation.accept(this.clock.now());
    if (Result.isErr(accepted)) return accepted;

    const membership = Membership.create({
      id: this.idGenerator.generate(),
      userId: input.userId,
      organizationId: invitation.organizationId,
      role: invitation.role,
    });
    if (Result.isErr(membership)) return membership;

    await this.invitationRepository.save(invitation);
    await this.membershipRepository.save(membership.value);

    return Result.ok({ membership: membership.value });
  }
}
