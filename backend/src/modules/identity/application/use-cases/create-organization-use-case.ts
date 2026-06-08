import { Result } from "../../../../shared/domain/result";
import { Membership } from "../../domain/entities/membership";
import { Organization } from "../../domain/entities/organization";
import {
  type MembershipRepository,
  type OrganizationRepository,
} from "../../domain/repositories/identity-repositories";
import { OrganizationName } from "../../domain/value-objects/organization-name";
import { RoleName } from "../../domain/value-objects/role-name";
import { type IdGenerator } from "../ports/id-generator";

export type CreateOrganizationInput = {
  ownerUserId: string;
  name: string;
};

export type CreateOrganizationOutput = {
  organization: Organization;
  membership: Membership;
};

export class CreateOrganizationUseCase {
  constructor(
    private readonly organizationRepository: OrganizationRepository,
    private readonly membershipRepository: MembershipRepository,
    private readonly idGenerator: IdGenerator,
  ) {}

  async execute(input: CreateOrganizationInput): Promise<Result<CreateOrganizationOutput, string>> {
    const name = OrganizationName.create(input.name);
    if (Result.isErr(name)) return name;

    const organization = Organization.create({
      id: this.idGenerator.generate(),
      name: name.value,
    });
    if (Result.isErr(organization)) return organization;

    const membership = Membership.create({
      id: this.idGenerator.generate(),
      userId: input.ownerUserId,
      organizationId: organization.value.id,
      role: RoleName.owner(),
    });
    if (Result.isErr(membership)) return membership;

    await this.organizationRepository.save(organization.value);
    await this.membershipRepository.save(membership.value);

    return Result.ok({
      organization: organization.value,
      membership: membership.value,
    });
  }
}
