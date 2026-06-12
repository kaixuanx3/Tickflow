import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { CandlesUnavailableError, type CandleService } from '../services/candle-service.js';
import { symbolSchema } from './symbol-schema.js';

const paramsSchema = z.object({ symbol: symbolSchema });
const querySchema = z.object({ range: z.enum(['1D', '1W', '1M', '1Y']).default('1D') });

export function registerCandleRoutes(
  app: FastifyInstance,
  candleService: CandleService | null,
): void {
  app.get('/symbols/:symbol/candles', async (req, reply) => {
    if (!candleService) {
      return reply.code(503).send({ error: 'candles not configured (FMP_API_KEY missing)' });
    }
    const params = paramsSchema.safeParse(req.params);
    const query = querySchema.safeParse(req.query);
    if (!params.success || !query.success) {
      const error = !params.success
        ? z.prettifyError(params.error)
        : z.prettifyError((query as { error: z.ZodError }).error);
      return reply.code(400).send({ error });
    }
    try {
      return await candleService.getCandles(params.data.symbol.toUpperCase(), query.data.range);
    } catch (err) {
      if (err instanceof CandlesUnavailableError) {
        return reply.code(502).send({ error: err.message });
      }
      throw err;
    }
  });
}
