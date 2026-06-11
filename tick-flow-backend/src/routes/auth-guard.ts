import type { preHandlerAsyncHookHandler } from 'fastify';
import type { AuthService } from '../services/auth-service.js';

declare module 'fastify' {
  interface FastifyRequest {
    userId: string; // set by the auth guard; only read it on guarded routes
  }
}

export function makeAuthGuard(authService: AuthService): preHandlerAsyncHookHandler {
  return async (req, reply) => {
    const header = req.headers.authorization;
    const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;
    const verified = token ? authService.verifyToken(token) : null;
    if (!verified) {
      return reply.code(401).send({ error: 'unauthorized' });
    }
    req.userId = verified.userId;
  };
}
