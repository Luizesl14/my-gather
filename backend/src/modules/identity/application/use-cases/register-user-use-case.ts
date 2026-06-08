import { Result } from "../../../../shared/domain/result";
import { User } from "../../domain/entities/user";
import { type UserRepository } from "../../domain/repositories/identity-repositories";
import { DisplayName } from "../../domain/value-objects/display-name";
import { Email } from "../../domain/value-objects/email";
import { PasswordHash } from "../../domain/value-objects/password-hash";
import { type IdGenerator } from "../ports/id-generator";
import { type PasswordHasher } from "../ports/password-hasher";

export type RegisterUserInput = {
  email: string;
  password: string;
  displayName: string;
};

export type RegisterUserOutput = {
  user: User;
};

export class RegisterUserUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly passwordHasher: PasswordHasher,
    private readonly idGenerator: IdGenerator,
  ) {}

  async execute(input: RegisterUserInput): Promise<Result<RegisterUserOutput, string>> {
    const email = Email.create(input.email);
    if (Result.isErr(email)) return email;

    const displayName = DisplayName.create(input.displayName);
    if (Result.isErr(displayName)) return displayName;

    const existing = await this.userRepository.findByEmail(email.value);
    if (existing) {
      return Result.err("identity.user.email_already_registered");
    }

    const hashedPassword = await this.passwordHasher.hash(input.password);
    const passwordHash = PasswordHash.create(hashedPassword);
    if (Result.isErr(passwordHash)) return passwordHash;

    const user = User.register({
      id: this.idGenerator.generate(),
      email: email.value,
      passwordHash: passwordHash.value,
      displayName: displayName.value,
    });
    if (Result.isErr(user)) return user;

    await this.userRepository.save(user.value);

    return Result.ok({ user: user.value });
  }
}
