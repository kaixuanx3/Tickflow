import type { PrismaClient } from '@prisma/client';
import type { Alert, AlertInput, AlertPatch, AlertRepo } from '../services/alert-service.js';

export class PrismaAlertRepo implements AlertRepo {
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
}
