import type { PrismaClient } from '@prisma/client';
import type { WatchlistItem, WatchlistRepo } from '../services/watchlist-service.js';

export class PrismaWatchlistRepo implements WatchlistRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async list(userId: string): Promise<WatchlistItem[]> {
    return this.prisma.watchlistItem.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { symbol: true, createdAt: true },
    });
  }

  async upsert(userId: string, symbol: string): Promise<WatchlistItem> {
    return this.prisma.watchlistItem.upsert({
      where: { userId_symbol: { userId, symbol } },
      create: { userId, symbol },
      update: {},
      select: { symbol: true, createdAt: true },
    });
  }

  async remove(userId: string, symbol: string): Promise<void> {
    await this.prisma.watchlistItem.deleteMany({ where: { userId, symbol } });
  }
}
