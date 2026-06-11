import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { QuoteService } from '../services/quote-service.js';

const querySchema = z.object({
  symbols: z
    .string()
    .min(1)
    .transform((s) =>
      [...new Set(s.split(',').map((sym) => sym.trim().toUpperCase()))].filter(Boolean),
    )
    .refine((syms) => syms.length >= 1 && syms.length <= 50, {
      message: 'between 1 and 50 symbols',
    }),
});

export function registerQuoteRoutes(app: FastifyInstance, quoteService: QuoteService): void {
  // GET /quotes?symbols=AAPL,TSLA — batched, cache-backed.
  // Unknown/unavailable symbols are simply absent from the response.
  app.get('/quotes', async (req, reply) => {
    const parsed = querySchema.safeParse(req.query);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    const quotes = await quoteService.getQuotes(parsed.data.symbols);
    return { quotes };
  });
}
