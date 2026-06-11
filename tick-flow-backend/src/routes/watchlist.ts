import type { FastifyInstance, preHandlerAsyncHookHandler } from 'fastify';
import { z } from 'zod';
import type { WatchlistService } from '../services/watchlist-service.js';

const symbolSchema = z
  .string()
  .trim()
  .regex(/^[a-zA-Z0-9.\-]{1,12}$/, 'invalid symbol');

const bodySchema = z.object({ symbol: symbolSchema });
const paramsSchema = z.object({ symbol: symbolSchema });

export function registerWatchlistRoutes(
  app: FastifyInstance,
  watchlist: WatchlistService,
  authGuard: preHandlerAsyncHookHandler,
): void {
  app.get('/watchlist', { preHandler: authGuard }, async (req) => {
    const items = await watchlist.list(req.userId);
    return { items };
  });

  app.post('/watchlist', { preHandler: authGuard }, async (req, reply) => {
    const parsed = bodySchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    const item = await watchlist.add(req.userId, parsed.data.symbol);
    return reply.code(201).send({ item });
  });

  app.delete('/watchlist/:symbol', { preHandler: authGuard }, async (req, reply) => {
    const parsed = paramsSchema.safeParse(req.params);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    await watchlist.remove(req.userId, parsed.data.symbol);
    return reply.code(204).send();
  });
}
