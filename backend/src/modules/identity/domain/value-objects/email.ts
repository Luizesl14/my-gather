import { Result } from "../../../../shared/domain/result";

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export class Email {
  private constructor(readonly value: string) {}

  static create(value: string): Result<Email, string> {
    const normalized = value.trim().toLowerCase();

    if (!emailRegex.test(normalized)) {
      return Result.err("identity.email.invalid");
    }

    return Result.ok(new Email(normalized));
  }
}
