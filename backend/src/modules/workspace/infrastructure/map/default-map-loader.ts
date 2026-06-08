import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { type OfficeMapPayload } from "../persistence/in-memory-workspace-repository";

export function loadDefaultOfficeMap(): OfficeMapPayload {
  const path = resolve(process.cwd(), "../web/assets/maps/office-default.json");
  return JSON.parse(readFileSync(path, "utf-8")) as OfficeMapPayload;
}
