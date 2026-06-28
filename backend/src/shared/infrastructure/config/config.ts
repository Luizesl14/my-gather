import { loadEnv } from "./env";

const env = loadEnv(process.env);

export const config = {
  databaseUrl: env.DATABASE_URL,
  redisUrl: env.REDIS_URL,
  jwtSecret: env.JWT_SECRET,
  apiPort: env.API_PORT,
  wsPort: env.WS_PORT,
  livekit: {
    url: env.LIVEKIT_URL,
    apiKey: env.LIVEKIT_API_KEY,
    apiSecret: env.LIVEKIT_API_SECRET,
  },
} as const;

