import type { NotificationJob } from './alert-engine.js';

export interface NotificationRecord {
  id: string;
  symbol: string;
  message: string;
  price: number;
  createdAt: Date;
}

export interface NotificationRepo {
  /** keyed by jobId — a retried BullMQ job must not duplicate the feed entry */
  createIfAbsent(data: {
    jobId: string;
    userId: string;
    alertId: string;
    symbol: string;
    message: string;
    price: number;
  }): Promise<void>;
  listByUser(userId: string, limit: number): Promise<NotificationRecord[]>;
}

export interface PushTokenRepo {
  register(userId: string, token: string): Promise<void>;
  tokensForUser(userId: string): Promise<string[]>;
  removeTokens(tokens: string[]): Promise<void>;
}

export interface PushSender {
  send(
    tokens: string[],
    notification: { title: string; body: string },
  ): Promise<{ invalidTokens: string[] }>;
}

export interface NotificationPrefsRepo {
  /** false → the user muted push; the in-app feed entry is still written. */
  isPushEnabled(userId: string): Promise<boolean>;
}

export function formatAlertMessage(job: NotificationJob): { title: string; body: string } {
  const direction = job.ruleType === 'price_above' ? 'above' : 'below';
  return {
    title: `${job.symbol} price alert`,
    body: `${job.symbol} is ${direction} $${job.threshold} (now $${job.price})`,
  };
}

/** Serves the REST feed + device registration. */
export class NotificationService {
  constructor(
    private readonly notifications: NotificationRepo,
    private readonly pushTokens: PushTokenRepo,
  ) {}

  list(userId: string, limit = 50): Promise<NotificationRecord[]> {
    return this.notifications.listByUser(userId, limit);
  }

  registerDevice(userId: string, token: string): Promise<void> {
    return this.pushTokens.register(userId, token);
  }
}

/** Runs inside the BullMQ worker: in-app feed entry + FCM push. */
export class NotificationDelivery {
  constructor(
    private readonly notifications: NotificationRepo,
    private readonly pushTokens: PushTokenRepo,
    private readonly sender: PushSender,
    private readonly prefs: NotificationPrefsRepo,
  ) {}

  async deliver(job: NotificationJob): Promise<void> {
    const { title, body } = formatAlertMessage(job);
    await this.notifications.createIfAbsent({
      jobId: `alert-${job.alertId}-trigger-${job.triggerCount}`,
      userId: job.userId,
      alertId: job.alertId,
      symbol: job.symbol,
      message: body,
      price: job.price,
    });

    // Feed entry is always recorded above; only the push respects the mute.
    if (!(await this.prefs.isPushEnabled(job.userId))) return;
    const tokens = await this.pushTokens.tokensForUser(job.userId);
    if (tokens.length === 0) return;
    const { invalidTokens } = await this.sender.send(tokens, { title, body });
    if (invalidTokens.length > 0) await this.pushTokens.removeTokens(invalidTokens);
  }
}
