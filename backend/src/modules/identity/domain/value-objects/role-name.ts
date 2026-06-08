import { Result } from "../../../../shared/domain/result";

export const roleNames = ["owner", "admin", "member"] as const;

export type RoleNameValue = (typeof roleNames)[number];

export class RoleName {
  private constructor(readonly value: RoleNameValue) {}

  static owner(): RoleName {
    return new RoleName("owner");
  }

  static admin(): RoleName {
    return new RoleName("admin");
  }

  static member(): RoleName {
    return new RoleName("member");
  }

  static create(value: string): Result<RoleName, string> {
    if (!roleNames.includes(value as RoleNameValue)) {
      return Result.err("identity.role.invalid");
    }

    return Result.ok(new RoleName(value as RoleNameValue));
  }
}
