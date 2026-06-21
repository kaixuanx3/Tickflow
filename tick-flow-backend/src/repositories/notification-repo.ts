import type { PrismaClient } from '@prisma/client';
import type {
  NotificationPrefsRepo,
  NotificationRecord,
  NotificationRepo,
  PushTokenRepo,
} from '../services/notifications.js';

export class PrismaNotificationRepo implements NotificationRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async createIfAbsent(data: {
    jobId: string;
    userId: string;
    alertId: string;
    symbol: string;
    message: string;
    price: number;
  }): Promise<void> {
    await this.prisma.notification.upsert({
      where: { jobId: data.jobId },
      create: data,
      update: {}, // already delivered once — keep the original
    });
  }

  async listByUser(userId: string, limit: number): Promise<NotificationRecord[]> {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      select: { id: true, symbol: true, message: true, price: true, createdAt: true },
    });
  }
}

export class PrismaNotificationPrefsRepo implements NotificationPrefsRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async isPushEnabled(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { pushEnabled: true },
    });
    // Missing user (race with deletion) → nothing to push to; treat as muted.
    return user?.pushEnabled ?? false;
  }
}

export class PrismaPushTokenRepo implements PushTokenRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async register(userId: string, token: string): Promise<void> {
    // tokens can move between accounts on the same device — last login wins
    await this.prisma.pushToken.upsert({
      where: { token },
      create: { token, userId },
      update: { userId },
    });
  }

  async tokensForUser(userId: string): Promise<string[]> {
    const rows = await this.prisma.pushToken.findMany({ where: { userId } });
    return rows.map((r) => r.token);
  }

  async removeTokens(tokens: string[]): Promise<void> {
    await this.prisma.pushToken.deleteMany({ where: { token: { in: tokens } } });
  }
}
