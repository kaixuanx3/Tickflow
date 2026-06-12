import { describe, expect, it, vi } from 'vitest';
import {
  AlertEngine,
  conditionMet,
  shouldRearm,
  type AlertEngineRepo,
  type NotificationJob,
} from './alert-engine.js';
import type { Alert } from './alert-service.js';

const baseAlert = (over: Partial<Alert> = {}): Alert => ({
  id: 'a1',
  userId: 'u1',
  symbol: 'AAPL',
  ruleType: 'price_above',
  threshold: 300,
  kind: 'one_shot',
  status: 'active',
  triggerCount: 0,
  lastTriggeredAt: null,
  createdAt: new Date(0),
  ...over,
});

class MemoryEngineRepo implements AlertEngineRepo {
  constructor(public alerts: Alert[]) {}
  async liveBySymbol(symbol: string): Promise<Alert[]> {
    return this.alerts
      .filter((a) => a.symbol === symbol && a.status !== 'done')
      .map((a) => ({ ...a })); // snapshots, like rows from the DB
  }
  async markTriggered(
    id: string,
    expected: number,
    toStatus: 'done' | 'cooldown',
    at: Date,
  ): Promise<boolean> {
    const alert = this.alerts.find(
      (a) => a.id === id && a.status === 'active' && a.triggerCount === expected,
    );
    if (!alert) return false;
    alert.status = toStatus;
    alert.triggerCount += 1;
    alert.lastTriggeredAt = at;
    return true;
  }
  async rearm(id: string): Promise<boolean> {
    const alert = this.alerts.find((a) => a.id === id && a.status === 'cooldown');
    if (!alert) return false;
    alert.status = 'active';
    return true;
  }
  async countLive(symbol: string): Promise<number> {
    return this.alerts.filter((a) => a.symbol === symbol && a.status !== 'done').length;
  }
  async distinctLiveSymbols(): Promise<string[]> {
    return [...new Set(this.alerts.filter((a) => a.status !== 'done').map((a) => a.symbol))];
  }
}

const makeEngine = (alerts: Alert[], nowMs = 1_000_000) => {
  const repo = new MemoryEngineRepo(alerts);
  const enqueued: Array<{ jobId: string; job: NotificationJob }> = [];
  const subs = { add: vi.fn(async () => {}), remove: vi.fn(async () => {}) };
  const engine = new AlertEngine(
    repo,
    { enqueue: async (jobId, job) => void enqueued.push({ jobId, job }) },
    subs,
    { now: () => nowMs },
  );
  return { repo, enqueued, subs, engine };
};

describe('conditionMet', () => {
  it('price_above triggers at or above the threshold', () => {
    const alert = { ruleType: 'price_above' as const, threshold: 300 };
    expect(conditionMet(alert, 299.99)).toBe(false);
    expect(conditionMet(alert, 300)).toBe(true);
    expect(conditionMet(alert, 301)).toBe(true);
  });

  it('price_below triggers at or below the threshold', () => {
    const alert = { ruleType: 'price_below' as const, threshold: 200 };
    expect(conditionMet(alert, 200.01)).toBe(false);
    expect(conditionMet(alert, 200)).toBe(true);
  });
});

describe('shouldRearm', () => {
  const fifteenMin = 15 * 60_000;
  const triggered = (ruleType: 'price_above' | 'price_below') => ({
    ruleType,
    threshold: 300,
    lastTriggeredAt: new Date(0),
  });

  it('re-arms when price retreats ≥0.5% past an above-threshold', () => {
    const alert = triggered('price_above');
    expect(shouldRearm(alert, 298.51, 1000, 0.005, fifteenMin)).toBe(false); // -0.497%
    expect(shouldRearm(alert, 298.5, 1000, 0.005, fifteenMin)).toBe(true); // exactly -0.5%
  });

  it('re-arms when price retreats ≥0.5% past a below-threshold', () => {
    const alert = triggered('price_below');
    expect(shouldRearm(alert, 301.49, 1000, 0.005, fifteenMin)).toBe(false);
    expect(shouldRearm(alert, 301.5, 1000, 0.005, fifteenMin)).toBe(true);
  });

  it('re-arms after the cooldown elapses regardless of price', () => {
    const alert = triggered('price_above');
    expect(shouldRearm(alert, 305, fifteenMin - 1, 0.005, fifteenMin)).toBe(false);
    expect(shouldRearm(alert, 305, fifteenMin, 0.005, fifteenMin)).toBe(true);
  });
});

describe('AlertEngine', () => {
  it('triggers a one_shot alert: DONE, idempotent job id, symbol released', async () => {
    const { repo, enqueued, subs, engine } = makeEngine([baseAlert()]);

    await engine.onSymbolTouched('AAPL'); // engine tracks the symbol
    await engine.evaluate({ symbol: 'AAPL', price: 301, ts: 123 });

    expect(repo.alerts[0]).toMatchObject({ status: 'done', triggerCount: 1 });
    expect(enqueued).toHaveLength(1);
    expect(enqueued[0]!.jobId).toBe('alert-a1-trigger-1');
    expect(enqueued[0]!.job).toMatchObject({ symbol: 'AAPL', price: 301, triggerCount: 1 });
    expect(subs.remove).toHaveBeenCalledWith('AAPL'); // no more live alerts on AAPL
  });

  it('triggers a re_arm alert into COOLDOWN and keeps the symbol tracked', async () => {
    const { repo, subs, engine } = makeEngine([baseAlert({ kind: 're_arm' })]);

    await engine.onSymbolTouched('AAPL');
    await engine.evaluate({ symbol: 'AAPL', price: 301, ts: 123 });

    expect(repo.alerts[0]!.status).toBe('cooldown');
    expect(subs.remove).not.toHaveBeenCalled();
  });

  it('does not trigger when the condition is unmet', async () => {
    const { repo, enqueued, engine } = makeEngine([baseAlert()]);

    await engine.evaluate({ symbol: 'AAPL', price: 299, ts: 123 });

    expect(repo.alerts[0]!.status).toBe('active');
    expect(enqueued).toHaveLength(0);
  });

  it('cannot double-send on duplicate evaluation (check-and-set)', async () => {
    const { enqueued, engine } = makeEngine([baseAlert({ kind: 're_arm' })]);

    // both evaluations read the alert as active (stale snapshot race)
    await Promise.all([
      engine.evaluate({ symbol: 'AAPL', price: 301, ts: 1 }),
      engine.evaluate({ symbol: 'AAPL', price: 302, ts: 2 }),
    ]);

    expect(enqueued).toHaveLength(1);
  });

  it('re-arms a cooldown alert on hysteresis and can trigger again with a new job id', async () => {
    const alert = baseAlert({ kind: 're_arm' });
    const { repo, enqueued, engine } = makeEngine([alert]);

    await engine.evaluate({ symbol: 'AAPL', price: 301, ts: 1 }); // trigger #1
    expect(repo.alerts[0]!.status).toBe('cooldown');

    await engine.evaluate({ symbol: 'AAPL', price: 298, ts: 2 }); // -0.66% → re-arm
    expect(repo.alerts[0]!.status).toBe('active');

    await engine.evaluate({ symbol: 'AAPL', price: 301, ts: 3 }); // trigger #2
    expect(enqueued.map((e) => e.jobId)).toEqual(['alert-a1-trigger-1', 'alert-a1-trigger-2']);
  });

  it('start() subscribes every symbol that already has live alerts', async () => {
    const { subs, engine } = makeEngine([
      baseAlert(),
      baseAlert({ id: 'a2', symbol: 'TSLA' }),
      baseAlert({ id: 'a3', symbol: 'NVDA', status: 'done' }),
    ]);

    const callbacks: Array<(t: { symbol: string; price: number; ts: number }) => void> = [];
    await engine.start({ onTick: (cb) => callbacks.push(cb) });

    expect(subs.add).toHaveBeenCalledWith('AAPL');
    expect(subs.add).toHaveBeenCalledWith('TSLA');
    expect(subs.add).not.toHaveBeenCalledWith('NVDA');
    expect(callbacks).toHaveLength(1); // evaluation hooked into the tick feed
  });

  it('onSymbolTouched subscribes new symbols and releases dead ones', async () => {
    const { repo, subs, engine } = makeEngine([baseAlert()]);

    await engine.onSymbolTouched('AAPL');
    expect(subs.add).toHaveBeenCalledTimes(1);
    await engine.onSymbolTouched('AAPL'); // already tracked → no double add
    expect(subs.add).toHaveBeenCalledTimes(1);

    repo.alerts[0]!.status = 'done'; // e.g. alert deleted/finished
    await engine.onSymbolTouched('AAPL');
    expect(subs.remove).toHaveBeenCalledWith('AAPL');
  });
});
