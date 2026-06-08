import { Result } from "../../../../shared/domain/result";

export class DisplayName {
  private constructor(readonly value: string) {}

  static create(value: string): Result<DisplayName, string> {
    const normalized = value.trim();

    if (normalized.length < 2 || normalized.length > 80) {
      return Result.err("identity.display_name.invalid_length");
    }

    return Result.ok(new DisplayName(normalized));
  }
}
