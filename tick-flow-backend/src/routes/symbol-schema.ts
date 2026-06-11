import { z } from 'zod';

// Shared by watchlist + portfolio routes; covers tickers like BRK.B
export const symbolSchema = z
  .string()
  .trim()
  .regex(/^[a-zA-Z0-9.\-]{1,12}$/, 'invalid symbol');
