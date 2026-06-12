import type { PrismaClient } from '@prisma/client';
import type { AlertEngineRepo } from '../services/alert-engine.js';
import type { Alert, AlertInput, AlertPatch, AlertRepo } from '../services/alert-service.js';

const LIVE = ['active', 'cooldown'] as const;

export class PrismaAlertRepo implements AlertRepo, AlertEngineRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async list(userId: string): Promise<Alert[]> {
    return this.prisma.alert.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
  }

  async create(userId: string, data: AlertInput): Promise<Alert> {
    return this.prisma.alert.create({ data: { userId, ...data } });
  }

  async update(userId: string, id: string, patch: AlertPatch): Promise<Alert | null> {
    const data = Object.fromEntries(
      Object.entries(patch).filter(([, v]) => v !== undefined),
    );
    const { count } = await this.prisma.alert.updateMany({ where: { id, userId }, data });
    if (count === 0) return null;
    return this.prisma.alert.findUnique({ where: { id } });
  }

  async remove(userId: string, id: string): Promise<Alert | null> {
    const alert = await this.prisma.alert.findFirst({ where: { id, userId } });
    if (!alert) return null;
    await this.prisma.alert.delete({ where: { id } });
    return alert;
  }

  // ── AlertEngineRepo ──────────────────────────────────────────────

  async liveBySymbol(symbol: string): Promise<Alert[]> {
    return this.prisma.alert.findMany({ where: { symbol, status: { in: [...LIVE] } } });
  }

  async markTriggered(
    id: string,
    expectedTriggerCount: number,
    toStatus: 'done' | 'cooldown',
    at: Date,
  ): Promise<boolean> {
    // CAS on (status, triggerCount): concurrent evaluations can't double-trigger
    const { count } = await this.prisma.alert.updateMany({
      where: { id, status: 'active', triggerCount: expectedTriggerCount },
      data: { status: toStatus, triggerCount: { increment: 1 }, lastTriggeredAt: at },
    });
    return count === 1;
  }

  async rearm(id: string): Promise<boolean> {
    const { count } = await this.prisma.alert.updateMany({
      where: { id, status: 'cooldown' },
      data: { status: 'active' },
    });
    return count === 1;
  }

  async countLive(symbol: string): Promise<number> {
    return this.prisma.alert.count({ where: { symbol, status: { in: [...LIVE] } } });
  }

  async distinctLiveSymbols(): Promise<string[]> {
    const rows = await this.prisma.alert.findMany({
      where: { status: { in: [...LIVE] } },
      distinct: ['symbol'],
      select: { symbol: true },
    });
    return rows.map((r) => r.symbol);
  }
}
