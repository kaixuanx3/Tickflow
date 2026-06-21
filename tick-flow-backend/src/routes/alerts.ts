import type { FastifyInstance, preHandlerAsyncHookHandler } from 'fastify';
import { z } from 'zod';
import type { AlertService } from '../services/alert-service.js';
import { symbolSchema } from './symbol-schema.js';

const createBody = z.object({
  symbol: symbolSchema,
  ruleType: z.enum(['price_above', 'price_below']),
  threshold: z.number().positive(),
  kind: z.enum(['one_shot', 're_arm']).default('one_shot'),
});

const patchBody = z
  .object({
    threshold: z.number().positive(),
    kind: z.enum(['one_shot', 're_arm']),
    status: z.enum(['active', 'paused']), // re-arm/resume (active) or pause; the engine owns the rest
  })
  .partial()
  .refine((p) => Object.keys(p).length > 0, { message: 'no fields to update' });

const idParams = z.object({ id: z.string().min(1) });

export function registerAlertRoutes(
  app: FastifyInstance,
  alerts: AlertService,
  authGuard: preHandlerAsyncHookHandler,
): void {
  app.get('/alerts', { preHandler: authGuard }, async (req) => {
    return { alerts: await alerts.list(req.userId) };
  });

  app.post('/alerts', { preHandler: authGuard }, async (req, reply) => {
    const parsed = createBody.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    const alert = await alerts.create(req.userId, parsed.data);
    return reply.code(201).send({ alert });
  });

  app.put('/alerts/:id', { preHandler: authGuard }, async (req, reply) => {
    const params = idParams.safeParse(req.params);
    const body = patchBody.safeParse(req.body);
    if (!params.success || !body.success) {
      const error = !params.success
        ? z.prettifyError(params.error)
        : z.prettifyError((body as { error: z.ZodError }).error);
      return reply.code(400).send({ error });
    }
    const alert = await alerts.update(req.userId, params.data.id, body.data);
    if (!alert) return reply.code(404).send({ error: 'alert not found' });
    return { alert };
  });

  app.delete('/alerts/:id', { preHandler: authGuard }, async (req, reply) => {
    const params = idParams.safeParse(req.params);
    if (!params.success) {
      return reply.code(400).send({ error: z.prettifyError(params.error) });
    }
    const removed = await alerts.remove(req.userId, params.data.id);
    if (!removed) return reply.code(404).send({ error: 'alert not found' });
    return reply.code(204).send();
  });
}
