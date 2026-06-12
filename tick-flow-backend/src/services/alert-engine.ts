import type { Alert } from './alert-service.js';
import type { Tick } from './tick-source.js';
import type { SymbolSubscriptions } from '../ws/tick-ws-server.js';

export function conditionMet(alert: Pick<Alert, 'ruleType' | 'threshold'>, price: number): boolean {
  return alert.ruleType === 'price_above' ? price >= alert.threshold : price <= alert.threshold;
}

/** Re-arm when price retreats ≥hysteresis past the threshold, or the cooldown elapsed. */
export function shouldRearm(
  alert: Pick<Alert, 'ruleType' | 'threshold' | 'lastTriggeredAt'>,
  price: number,
  now: number,
  hysteresisPct: number,
  cooldownMs: number,
): boolean {
  if (alert.lastTriggeredAt && now - alert.lastTriggeredAt.getTime() >= cooldownMs) return true;
  if (alert.ruleType === 'price_above') return price <= alert.threshold * (1 - hysteresisPct);
  return price >= alert.threshold * (1 + hysteresisPct);
}

export interface AlertEngineRepo {
  /** alerts evaluated on every tick: status active or cooldown for this symbol */
  liveBySymbol(symbol: string): Promise<Alert[]>;
  /**
   * Check-and-set ACTIVE → done|cooldown with triggerCount = expected + 1.
   * Returns false if another evaluation got there first.
   */
  markTriggered(
    id: string,
    expectedTriggerCount: number,
    toStatus: 'done' | 'cooldown',
    at: Date,
  ): Promise<boolean>;
  /** cooldown → active; false if it wasn't in cooldown */
  rearm(id: string): Promise<boolean>;
  countLive(symbol: string): Promise<number>;
  distinctLiveSymbols(): Promise<string[]>;
}

export interface NotificationJob {
  userId: string;
  alertId: string;
  symbol: string;
  ruleType: Alert['ruleType'];
  threshold: number;
  price: number;
  ts: number;
  triggerCount: number;
}

export interface NotificationEnqueuer {
  /** jobId is the idempotency key: alert:{id}:trigger:{count} */
  enqueue(jobId: string, job: NotificationJob): Promise<void>;
}

export interface AlertEngineOptions {
  hysteresisPct?: number;
  cooldownMs?: number;
  now?: () => number;
}

/**
 * Evaluates every tick (streamed or polled — it can't tell) against live
 * alerts. Holds one subscription per symbol with live alerts so ticks flow
 * even when no WS client watches that symbol.
 */
export class AlertEngine {
  private readonly hysteresisPct: number;
  private readonly cooldownMs: number;
  private readonly now: () => number;
  private readonly tracked = new Set<string>();

  constructor(
    private readonly repo: AlertEngineRepo,
    private readonly enqueuer: NotificationEnqueuer,
    private readonly subscriptions: SymbolSubscriptions,
    opts: AlertEngineOptions = {},
  ) {
    this.hysteresisPct = opts.hysteresisPct ?? 0.005;
    this.cooldownMs = opts.cooldownMs ?? 15 * 60_000;
    this.now = opts.now ?? Date.now;
  }

  async start(tickFeed: { onTick(cb: (tick: Tick) => void): void }): Promise<void> {
    for (const symbol of await this.repo.distinctLiveSymbols()) {
      this.tracked.add(symbol);
      await this.subscriptions.add(symbol);
    }
    tickFeed.onTick((tick) => void this.evaluate(tick));
  }

  /** AlertService calls this after any alert CRUD touching the symbol. */
  async onSymbolTouched(symbol: string): Promise<void> {
    const live = await this.repo.countLive(symbol);
    if (live > 0 && !this.tracked.has(symbol)) {
      this.tracked.add(symbol);
      await this.subscriptions.add(symbol);
    } else if (live === 0 && this.tracked.has(symbol)) {
      this.tracked.delete(symbol);
      await this.subscriptions.remove(symbol);
    }
  }

  async evaluate(tick: Tick): Promise<void> {
    let alerts: Alert[];
    try {
      alerts = await this.repo.liveBySymbol(tick.symbol);
    } catch {
      return; // DB hiccup: skip this tick, the next one re-evaluates
    }
    for (const alert of alerts) {
      try {
        if (alert.status === 'active' && conditionMet(alert, tick.price)) {
          await this.trigger(alert, tick);
        } else if (
          alert.status === 'cooldown' &&
          shouldRearm(alert, tick.price, this.now(), this.hysteresisPct, this.cooldownMs)
        ) {
          await this.repo.rearm(alert.id);
        }
      } catch (err) {
        // never let one alert break evaluation of the others
        console.error(`[alert-engine] evaluating alert ${alert.id}:`, (err as Error).message);
      }
    }
  }

  private async trigger(alert: Alert, tick: Tick): Promise<void> {
    const toStatus = alert.kind === 'one_shot' ? 'done' : 'cooldown';
    const won = await this.repo.markTriggered(
      alert.id,
      alert.triggerCount,
      toStatus,
      new Date(this.now()),
    );
    if (!won) return; // a concurrent evaluation triggered it — exactly-once preserved

    const triggerCount = alert.triggerCount + 1;
    // BullMQ forbids ':' in custom job ids, hence '-' separators
    await this.enqueuer.enqueue(`alert-${alert.id}-trigger-${triggerCount}`, {
      userId: alert.userId,
      alertId: alert.id,
      symbol: alert.symbol,
      ruleType: alert.ruleType,
      threshold: alert.threshold,
      price: tick.price,
      ts: tick.ts,
      triggerCount,
    });
    if (toStatus === 'done') await this.onSymbolTouched(alert.symbol);
  }
}
