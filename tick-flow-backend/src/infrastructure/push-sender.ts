import { cert, initializeApp } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';
import type { PushSender } from '../services/notifications.js';

const GONE_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

export class FcmPushSender implements PushSender {
  private readonly messaging: Messaging;

  constructor(serviceAccountPath: string) {
    this.messaging = getMessaging(initializeApp({ credential: cert(serviceAccountPath) }));
  }

  async send(
    tokens: string[],
    notification: { title: string; body: string },
  ): Promise<{ invalidTokens: string[] }> {
    const res = await this.messaging.sendEachForMulticast({ tokens, notification });
    const invalidTokens = res.responses.flatMap((r, i) =>
      !r.success && r.error && GONE_TOKEN_CODES.has(r.error.code) ? [tokens[i]!] : [],
    );
    return { invalidTokens };
  }
}

/** Stand-in until a Firebase service account is configured: log instead of push. */
export class LogPushSender implements PushSender {
  async send(
    tokens: string[],
    notification: { title: string; body: string },
  ): Promise<{ invalidTokens: string[] }> {
    console.log(`[push:noop] to ${tokens.length} device(s): ${notification.title} — ${notification.body}`);
    return { invalidTokens: [] };
  }
}
