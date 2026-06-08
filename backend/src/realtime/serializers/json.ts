export function safeParseJson(payload: string): unknown | null {
  try {
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

export function serializeJson(payload: unknown): string {
  return JSON.stringify(payload);
}

