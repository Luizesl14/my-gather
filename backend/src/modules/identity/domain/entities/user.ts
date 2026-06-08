import { AggregateRoot } from "../../../../shared/domain/aggregate-root";
import { Result } from "../../../../shared/domain/result";
import { userRegistered } from "../events/identity-events";
import { DisplayName } from "../value-objects/display-name";
import { Email } from "../value-objects/email";
import { PasswordHash } from "../value-objects/password-hash";

export type UserProps = {
  email: Email;
  passwordHash: PasswordHash;
  displayName: DisplayName;
  createdAt: Date;
};

export class User extends AggregateRoot<UserProps> {
  private constructor(id: string, props: UserProps) {
    super(id, props);
  }

  get email(): Email {
    return this.props.email;
  }

  get displayName(): DisplayName {
    return this.props.displayName;
  }

  get passwordHash(): PasswordHash {
    return this.props.passwordHash;
  }

  static register(input: {
    id: string;
    email: Email;
    passwordHash: PasswordHash;
    displayName: DisplayName;
    createdAt?: Date;
  }): Result<User, string> {
    if (!input.id.trim()) {
      return Result.err("identity.user.id_required");
    }

    const user = new User(input.id, {
      email: input.email,
      passwordHash: input.passwordHash,
      displayName: input.displayName,
      createdAt: input.createdAt ?? new Date(),
    });

    user.addDomainEvent(userRegistered(user.id));

    return Result.ok(user);
  }
}
