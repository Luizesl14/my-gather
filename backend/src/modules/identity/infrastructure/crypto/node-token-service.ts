import { createHmac } from "node:crypto";

export type IdentityTokenPayload = {
  sub: string;
  email: string;
};

function base64url(value: string): string {
  return Buffer.from(value).toString("base64url");
}

export class NodeTokenService {
  constructor(private readonly secret: string) {}

  sign(payload: IdentityTokenPayload): string {
    const header = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
    const body = base64url(JSON.stringify(payload));
    const signature = createHmac("sha256", this.secret)
      .update(`${header}.${body}`)
      .digest("base64url");

    return `${header}.${body}.${signature}`;
  }

  verify(token: string): IdentityTokenPayload | null {
    const [header, body, signature] = token.split(".");
    if (!header || !body || !signature) return null;

    const expected = createHmac("sha256", this.secret)
      .update(`${header}.${body}`)
      .digest("base64url");
    if (expected !== signature) return null;

    try {
      return JSON.parse(Buffer.from(body, "base64url").toString("utf-8")) as IdentityTokenPayload;
    } catch {
      return null;
    }
  }
}
