import { Result } from "../../../../shared/domain/result";
import { User } from "../../domain/entities/user";
import { type UserRepository } from "../../domain/repositories/identity-repositories";
import { Email } from "../../domain/value-objects/email";
import { type PasswordHasher } from "../ports/password-hasher";

export type LoginUserInput = {
  email: string;
  password: string;
};

export type LoginUserOutput = {
  user: User;
};

export class LoginUserUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly passwordHasher: PasswordHasher,
  ) {}

  async execute(input: LoginUserInput): Promise<Result<LoginUserOutput, string>> {
    const email = Email.create(input.email);
    if (Result.isErr(email)) return email;

    const user = await this.userRepository.findByEmail(email.value);
    if (!user) {
      return Result.err("identity.auth.invalid_credentials");
    }

    const isValidPassword = await this.passwordHasher.verify(input.password, user.passwordHash.value);
    if (!isValidPassword) {
      return Result.err("identity.auth.invalid_credentials");
    }

    return Result.ok({ user });
  }
}
