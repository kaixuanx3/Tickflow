import type { FastifyInstance, preHandlerAsyncHookHandler } from 'fastify';
import { z } from 'zod';
import type { PortfolioService } from '../services/portfolio-service.js';
import { symbolSchema } from './symbol-schema.js';

const holdingBody = z.object({
  symbol: symbolSchema,
  qty: z.number().positive(),
  buyPrice: z.number().nonnegative(),
  assetType: z.enum(['stock', 'etf', 'crypto']).default('stock'),
});

const patchBody = z
  .object({
    qty: z.number().positive(),
    buyPrice: z.number().nonnegative(),
    assetType: z.enum(['stock', 'etf', 'crypto']),
  })
  .partial()
  .refine((p) => Object.keys(p).length > 0, { message: 'no fields to update' });

const idParams = z.object({ id: z.string().min(1) });

export function registerPortfolioRoutes(
  app: FastifyInstance,
  portfolio: PortfolioService,
  authGuard: preHandlerAsyncHookHandler,
): void {
  app.get('/portfolio/holdings', { preHandler: authGuard }, async (req) => {
    return { holdings: await portfolio.list(req.userId) };
  });

  app.post('/portfolio/holdings', { preHandler: authGuard }, async (req, reply) => {
    const parsed = holdingBody.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    const holding = await portfolio.add(req.userId, parsed.data);
    return reply.code(201).send({ holding });
  });

  app.put('/portfolio/holdings/:id', { preHandler: authGuard }, async (req, reply) => {
    const params = idParams.safeParse(req.params);
    const body = patchBody.safeParse(req.body);
    if (!params.success || !body.success) {
      const error = !params.success
        ? z.prettifyError(params.error)
        : z.prettifyError((body as { error: z.ZodError }).error);
      return reply.code(400).send({ error });
    }
    const holding = await portfolio.update(req.userId, params.data.id, body.data);
    if (!holding) return reply.code(404).send({ error: 'holding not found' });
    return { holding };
  });

  app.delete('/portfolio/holdings/:id', { preHandler: authGuard }, async (req, reply) => {
    const params = idParams.safeParse(req.params);
    if (!params.success) {
      return reply.code(400).send({ error: z.prettifyError(params.error) });
    }
    const removed = await portfolio.remove(req.userId, params.data.id);
    if (!removed) return reply.code(404).send({ error: 'holding not found' });
    return reply.code(204).send();
  });

  app.get('/portfolio/summary', { preHandler: authGuard }, async (req) => {
    return await portfolio.summary(req.userId);
  });
}
