import { createHash, randomBytes, timingSafeEqual } from "node:crypto";

import { type PasswordHasher } from "../../application/ports/password-hasher";

export class NodePasswordHasher implements PasswordHasher {
  async hash(plainPassword: string): Promise<string> {
    const salt = randomBytes(16).toString("hex");
    const digest = createHash("sha256").update(`${salt}:${plainPassword}`).digest("hex");
    return `sha256:${salt}:${digest}`;
  }

  async verify(plainPassword: string, passwordHash: string): Promise<boolean> {
    const [, salt, digest] = passwordHash.split(":");
    if (!salt || !digest) return false;

    const expected = createHash("sha256").update(`${salt}:${plainPassword}`).digest("hex");
    return timingSafeEqual(Buffer.from(digest), Buffer.from(expected));
  }
}
