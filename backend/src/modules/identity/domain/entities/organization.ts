import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { organizationCreated } from "../events/identity-events";
import { OrganizationName } from "../value-objects/organization-name";

export type OrganizationProps = {
  name: OrganizationName;
  createdAt: Date;
};

export class Organization extends AggregateRoot<OrganizationProps> {
  private constructor(id: string, props: OrganizationProps) {
    super(id, props);
  }

  get name(): OrganizationName {
    return this.props.name;
  }

  static create(input: {
    id: string;
    name: OrganizationName;
    createdAt?: Date;
  }): Result<Organization, string> {
    if (!input.id.trim()) {
      return Result.err("identity.organization.id_required");
    }

    const organization = new Organization(input.id, {
      name: input.name,
      createdAt: input.createdAt ?? new Date(),
    });

    organization.addDomainEvent(organizationCreated(organization.id));

    return Result.ok(organization);
  }
}
