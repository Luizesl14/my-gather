import { loadEnv } from "./env";

const env = loadEnv(process.env);

export const config = {
  databaseUrl: env.DATABASE_URL,
  redisUrl: env.REDIS_URL,
  jwtSecret: env.JWT_SECRET,
  apiPort: env.API_PORT,
  wsPort: env.WS_PORT,
} as const;

