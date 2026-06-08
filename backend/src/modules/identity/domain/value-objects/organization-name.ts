import { Result } from "../../../../shared/domain/result";

export class OrganizationName {
  private constructor(readonly value: string) {}

  static create(value: string): Result<OrganizationName, string> {
    const normalized = value.trim();

    if (normalized.length < 2 || normalized.length > 100) {
      return Result.err("identity.organization_name.invalid_length");
    }

    return Result.ok(new OrganizationName(normalized));
  }
}
