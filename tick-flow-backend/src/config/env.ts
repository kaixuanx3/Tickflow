import { z } from 'zod';

// Only vars needed by the current build stage. FMP_API_KEY joins with candles.
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  TICK_SOURCE: z.enum(['sim', 'finnhub']),
  REDIS_URL: z.string().min(1),
  DATABASE_URL: z.string().min(1),
  FINNHUB_API_KEY: z.string().min(1),
  JWT_SECRET: z.string().min(1),
  // optional: /auth/google returns 503 until this is configured
  GOOGLE_CLIENT_ID: z.string().min(1).optional(),
  // optional: FCM pushes are logged instead of sent until this is configured
  FIREBASE_SERVICE_ACCOUNT_PATH: z.string().min(1).optional(),
  // optional: /symbols/:symbol/candles returns 503 until this is configured
  FMP_API_KEY: z.string().min(1).optional(),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    console.error(`Invalid environment:\n${z.prettifyError(result.error)}`);
    process.exit(1);
  }
  return result.data;
}
