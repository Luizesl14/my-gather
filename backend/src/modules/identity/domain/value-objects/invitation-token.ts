import { Result } from "../../../../shared/domain/result";

export class InvitationToken {
  private constructor(readonly value: string) {}

  static create(value: string): Result<InvitationToken, string> {
    const normalized = value.trim();

    if (normalized.length < 16 || normalized.length > 160) {
      return Result.err("identity.invitation_token.invalid_length");
    }

    return Result.ok(new InvitationToken(normalized));
  }
}
