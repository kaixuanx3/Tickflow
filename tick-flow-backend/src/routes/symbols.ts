import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { FinnhubClient, UpstreamError } from '../infrastructure/finnhub-rest.js';
import {
  DirectoryUnavailableError,
  type SymbolDirectoryService,
} from '../services/symbol-directory.js';
import { symbolSchema } from './symbol-schema.js';

const searchQuery = z.object({
  q: z.string().trim().min(1, 'q is required'),
});

const listQuery = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

const profileParams = z.object({ symbol: symbolSchema });

export function registerSymbolRoutes(
  app: FastifyInstance,
  finnhub: FinnhubClient,
  directory: SymbolDirectoryService,
): void {
  app.get('/symbols/search', async (req, reply) => {
    const parsed = searchQuery.safeParse(req.query);
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

  // paginated US symbol list for the Markets tab
  app.get('/symbols', async (req, reply) => {
    const parsed = listQuery.safeParse(req.query);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      return await directory.listPage(parsed.data.page);
    } catch (err) {
      if (err instanceof DirectoryUnavailableError) {
        return reply.code(502).send({ error: err.message });
      }
      throw err;
    }
  });

  app.get('/symbols/:symbol/profile', async (req, reply) => {
    const parsed = profileParams.safeParse(req.params);
    if (!parsed.success) {
      return reply.code(400).send({ error: z.prettifyError(parsed.error) });
    }
    try {
      const profile = await directory.profile(parsed.data.symbol.toUpperCase());
      if (!profile) return reply.code(404).send({ error: 'unknown symbol' });
      return profile;
    } catch (err) {
      if (err instanceof DirectoryUnavailableError) {
        return reply.code(502).send({ error: err.message });
      }
      throw err;
    }
  });
}
