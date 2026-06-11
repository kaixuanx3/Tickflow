import { z } from 'zod';

// Only vars needed by the current build stage. DATABASE_URL joins in week 2
// (Prisma), FMP_API_KEY in week 5 (candles).
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  TICK_SOURCE: z.enum(['sim', 'finnhub']),
  REDIS_URL: z.string().min(1),
  FINNHUB_API_KEY: z.string().min(1),
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
