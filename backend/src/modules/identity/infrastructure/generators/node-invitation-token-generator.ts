import { randomBytes } from "node:crypto";

import { type InvitationTokenGenerator } from "../../application/ports/invitation-token-generator";

export class NodeInvitationTokenGenerator implements InvitationTokenGenerator {
  generate(): string {
    return randomBytes(32).toString("base64url");
  }
}
