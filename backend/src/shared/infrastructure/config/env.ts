import { z } from "zod";

export const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().min(1),
  JWT_SECRET: z.string().min(1),
  API_PORT: z.coerce.number().int().positive(),
  WS_PORT: z.coerce.number().int().positive(),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(processEnv: NodeJS.ProcessEnv): Env {
  const parsed = envSchema.safeParse(processEnv);

  if (!parsed.success) {
    const message = parsed.error.issues
      .map((issue: z.ZodIssue) => `${issue.path.join(".")}: ${issue.message}`)
      .join(", ");
    throw new Error(`ENV inválido: ${message}`);
  }

  return parsed.data;
}
