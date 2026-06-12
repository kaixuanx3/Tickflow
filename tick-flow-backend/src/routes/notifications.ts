import type { FastifyInstance, preHandlerAsyncHookHandler } from 'fastify';
import { z } from 'zod';
import type { NotificationService } from '../services/notifications.js';

const deviceBody = z.object({ token: z.string().min(1).max(4096) });

export function registerNotificationRoutes(
  app: FastifyInstance,
  notifications: NotificationService,
  authGuard: preHandlerAsyncHookHandler,
): void {
  // triggered-alert feed, newest first
  app.get('/notifications', { preHandler: authGuard }, async (req) => {
    return { notifications: await notifications.list(req.userId) };
  });

  // FCM device token registration (called by the app after login / token refresh)
  app.post('/devices', { preHandler: authGuard }, async (req, reply) => {
    const parsed = deviceBody.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    await notifications.registerDevice(req.userId, parsed.data.token);
    return reply.code(204).send();
  });
}
