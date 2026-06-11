import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import {
  AuthService,
  EmailTakenError,
  InvalidCredentialsError,
  type GoogleTokenVerifier,
} from '../services/auth-service.js';

const credentialsSchema = z.object({
  email: z.email(),
  password: z.string().min(8, 'password must be at least 8 characters'),
});

const googleSchema = z.object({ idToken: z.string().min(1) });

export function registerAuthRoutes(
  app: FastifyInstance,
  authService: AuthService,
  googleVerifier: GoogleTokenVerifier | null,
): void {
  app.post('/auth/register', async (req, reply) => {
    const parsed = credentialsSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      const result = await authService.register(parsed.data.email, parsed.data.password);
      return reply.code(201).send(result);
    } catch (err) {
      if (err instanceof EmailTakenError) {
        return reply.code(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.post('/auth/login', async (req, reply) => {
    const parsed = credentialsSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      return await authService.login(parsed.data.email, parsed.data.password);
    } catch (err) {
      if (err instanceof InvalidCredentialsError) {
        return reply.code(401).send({ error: err.message });
      }
      throw err;
    }
  });

  app.post('/auth/google', async (req, reply) => {
    if (!googleVerifier) {
      return reply.code(503).send({ error: 'google sign-in not configured' });
    }
    const parsed = googleSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      return await authService.loginWithGoogle(parsed.data.idToken, googleVerifier);
    } catch (err) {
      if (err instanceof InvalidCredentialsError) {
        return reply.code(401).send({ error: 'invalid google token' });
      }
      throw err;
    }
  });
}
