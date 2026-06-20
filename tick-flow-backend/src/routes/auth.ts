import type { FastifyInstance, preHandlerAsyncHookHandler } from 'fastify';
import { z } from 'zod';
import {
  AuthService,
  EmailTakenError,
  InvalidCredentialsError,
  PasswordNotSetError,
  type GoogleTokenVerifier,
} from '../services/auth-service.js';

const credentialsSchema = z.object({
  email: z.email(),
  password: z.string().min(8, 'password must be at least 8 characters'),
});

const googleSchema = z.object({ idToken: z.string().min(1) });

const profilePatchSchema = z.object({
  name: z.string().trim().max(60, 'name must be 60 characters or fewer').optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'enter your current password'),
  newPassword: z.string().min(8, 'new password must be at least 8 characters'),
});

export function registerAuthRoutes(
  app: FastifyInstance,
  authService: AuthService,
  googleVerifier: GoogleTokenVerifier | null,
  authGuard: preHandlerAsyncHookHandler,
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

  app.get('/auth/me', { preHandler: authGuard }, async (req, reply) => {
    const profile = await authService.getProfile(req.userId);
    if (!profile) return reply.code(404).send({ error: 'account not found' });
    return profile;
  });

  app.patch('/auth/me', { preHandler: authGuard }, async (req, reply) => {
    const parsed = profilePatchSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    return authService.updateProfile(req.userId, parsed.data);
  });

  app.post('/auth/change-password', { preHandler: authGuard }, async (req, reply) => {
    const parsed = changePasswordSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      await authService.changePassword(
        req.userId,
        parsed.data.currentPassword,
        parsed.data.newPassword,
      );
      return reply.code(204).send();
    } catch (err) {
      if (err instanceof InvalidCredentialsError) {
        return reply.code(401).send({ error: 'current password is incorrect' });
      }
      if (err instanceof PasswordNotSetError) {
        return reply.code(409).send({ error: err.message });
      }
      throw err;
    }
  });

  // Delete the authenticated account and all its data (cascade). Idempotent.
  app.delete('/auth/me', { preHandler: authGuard }, async (req, reply) => {
    await authService.deleteAccount(req.userId);
    return reply.code(204).send();
  });
}
