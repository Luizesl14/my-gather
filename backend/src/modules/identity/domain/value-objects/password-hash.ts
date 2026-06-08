import { Result } from "../../../../shared/domain/result";

export class PasswordHash {
  private constructor(readonly value: string) {}

  static create(value: string): Result<PasswordHash, string> {
    const normalized = value.trim();

    if (normalized.length < 20) {
      return Result.err("identity.password_hash.invalid_length");
    }

    return Result.ok(new PasswordHash(normalized));
  }
}
