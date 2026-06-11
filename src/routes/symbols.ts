import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { FinnhubClient, UpstreamError } from '../infrastructure/finnhub-rest.js';

const querySchema = z.object({
  q: z.string().trim().min(1, 'q is required'),
});

export function registerSymbolRoutes(app: FastifyInstance, finnhub: FinnhubClient): void {
  app.get('/symbols/search', async (req, reply) => {
    const parsed = querySchema.safeParse(req.query);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      const results = await finnhub.searchSymbols(parsed.data.q);
      return { results };
    } catch (err) {
      if (err instanceof UpstreamError) {
        return reply.code(502).send({ error: 'symbol search unavailable' });
      }
      throw err;
    }
  });
}
