import { Entity } from "../../../../shared/domain/entity";
import { Result } from "../../../../shared/domain/result";
import { RoleName } from "../value-objects/role-name";

export type MembershipProps = {
  userId: string;
  organizationId: string;
  role: RoleName;
  joinedAt: Date;
};

export class Membership extends Entity<MembershipProps> {
  private constructor(id: string, props: MembershipProps) {
    super(id, props);
  }

  get userId(): string {
    return this.props.userId;
  }

  get organizationId(): string {
    return this.props.organizationId;
  }

  get role(): RoleName {
    return this.props.role;
  }

  get joinedAt(): Date {
    return this.props.joinedAt;
  }

  static create(input: {
    id: string;
    userId: string;
    organizationId: string;
    role: RoleName;
    joinedAt?: Date;
  }): Result<Membership, string> {
    if (!input.id.trim() || !input.userId.trim() || !input.organizationId.trim()) {
      return Result.err("identity.membership.required_ids");
    }

    return Result.ok(
      new Membership(input.id, {
        userId: input.userId,
        organizationId: input.organizationId,
        role: input.role,
        joinedAt: input.joinedAt ?? new Date(),
      }),
    );
  }
}
