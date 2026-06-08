import { describe, expect, it } from "vitest";

import { Result } from "./result";

describe("Result", () => {
  it("representa sucesso", () => {
    const result = Result.ok(123);
    expect(Result.isOk(result)).toBe(true);
    expect(result).toEqual({ ok: true, value: 123 });
  });

  it("representa erro", () => {
    const result = Result.err("x");
    expect(Result.isErr(result)).toBe(true);
    expect(result).toEqual({ ok: false, error: "x" });
  });
});

