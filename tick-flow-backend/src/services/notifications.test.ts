import { describe, expect, it, vi } from 'vitest';
import type { NotificationJob } from './alert-engine.js';
import {
  NotificationDelivery,
  formatAlertMessage,
  type NotificationRecord,
  type NotificationRepo,
  type PushSender,
  type PushTokenRepo,
} from './notifications.js';

const job = (over: Partial<NotificationJob> = {}): NotificationJob => ({
  userId: 'u1',
  alertId: 'a1',
  symbol: 'AAPL',
  ruleType: 'price_above',
  threshold: 300,
  price: 301.5,
  ts: 1_000,
  triggerCount: 1,
  ...over,
});

class MemoryNotificationRepo implements NotificationRepo {
  created: Array<{ jobId: string; userId: string; message: string }> = [];
  async createIfAbsent(data: {
    jobId: string;
    userId: string;
    alertId: string;
    symbol: string;
    message: string;
    price: number;
  }): Promise<void> {
    if (this.created.some((n) => n.jobId === data.jobId)) return;
    this.created.push(data);
  }
  async listByUser(): Promise<NotificationRecord[]> {
    return [];
  }
}

const tokenRepo = (tokens: string[]): PushTokenRepo & { removed: string[] } => {
  const removed: string[] = [];
  return {
    removed,
    register: vi.fn(async () => {}),
    tokensForUser: async () => tokens,
    removeTokens: async (t) => void removed.push(...t),
  };
};

describe('formatAlertMessage', () => {
  it('describes above and below alerts', () => {
    expect(formatAlertMessage(job())).toEqual({
      title: 'AAPL price alert',
      body: 'AAPL is above $300 (now $301.5)',
    });
    expect(formatAlertMessage(job({ ruleType: 'price_below', price: 295 })).body).toBe(
      'AAPL is below $300 (now $295)',
    );
  });
});

describe('NotificationDelivery', () => {
  it('writes the in-app feed entry and pushes to all device tokens', async () => {
    const notifications = new MemoryNotificationRepo();
    const tokens = tokenRepo(['t1', 't2']);
    const sender: PushSender = { send: vi.fn(async () => ({ invalidTokens: [] })) };
    const delivery = new NotificationDelivery(notifications, tokens, sender);

    await delivery.deliver(job());

    expect(notifications.created).toHaveLength(1);
    expect(notifications.created[0]).toMatchObject({
      jobId: 'alert-a1-trigger-1',
      userId: 'u1',
    });
    expect(sender.send).toHaveBeenCalledWith(['t1', 't2'], {
      title: 'AAPL price alert',
      body: 'AAPL is above $300 (now $301.5)',
    });
  });

  it('a retried job does not duplicate the feed entry', async () => {
    const notifications = new MemoryNotificationRepo();
    const sender: PushSender = { send: vi.fn(async () => ({ invalidTokens: [] })) };
    const delivery = new NotificationDelivery(notifications, tokenRepo([]), sender);

    await delivery.deliver(job());
    await delivery.deliver(job()); // BullMQ retry after a partial failure

    expect(notifications.created).toHaveLength(1);
  });

  it('skips the push when the user has no devices', async () => {
    const sender: PushSender = { send: vi.fn(async () => ({ invalidTokens: [] })) };
    const delivery = new NotificationDelivery(new MemoryNotificationRepo(), tokenRepo([]), sender);

    await delivery.deliver(job());

    expect(sender.send).not.toHaveBeenCalled();
  });

  it('prunes tokens FCM reports as gone', async () => {
    const tokens = tokenRepo(['live', 'dead']);
    const sender: PushSender = { send: async () => ({ invalidTokens: ['dead'] }) };
    const delivery = new NotificationDelivery(new MemoryNotificationRepo(), tokens, sender);

    await delivery.deliver(job());

    expect(tokens.removed).toEqual(['dead']);
  });
});
