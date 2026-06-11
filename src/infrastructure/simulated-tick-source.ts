import type { Tick, TickSource } from '../services/tick-source.js';

export interface SimulatedTickSourceOptions {
  /** ms between tick rounds (every subscribed symbol ticks each round) */
  intervalMs?: number;
  /** max fractional price move per tick, e.g. 0.002 = ±0.2% */
  volatility?: number;
  /** starting price for every symbol */
  basePrice?: number;
  /** seed the RNG for deterministic tests */
  seed?: number;
}

// Deterministic PRNG (mulberry32) so tests can assert exact price sequences.
function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Fake tick feed: random walk per symbol. Exists because US market hours are
 * 9:30pm–4am MYT — without it the feed is dead during Malaysian daytime.
 */
export class SimulatedTickSource implements TickSource {
  private readonly intervalMs: number;
  private readonly volatility: number;
  private readonly basePrice: number;
  private readonly rand: () => number;
  private readonly prices = new Map<string, number>();
  private readonly listeners: Array<(tick: Tick) => void> = [];
  private timer: NodeJS.Timeout | null = null;

  constructor(opts: SimulatedTickSourceOptions = {}) {
    this.intervalMs = opts.intervalMs ?? 1000;
    this.volatility = opts.volatility ?? 0.002;
    this.basePrice = opts.basePrice ?? 100;
    this.rand = mulberry32(opts.seed ?? Date.now());
  }

  subscribe(symbol: string): void {
    if (this.prices.has(symbol)) return;
    this.prices.set(symbol, this.basePrice);
    if (!this.timer) {
      this.timer = setInterval(() => this.emitRound(), this.intervalMs);
      this.timer.unref();
    }
  }

  unsubscribe(symbol: string): void {
    this.prices.delete(symbol);
    if (this.prices.size === 0 && this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  onTick(cb: (tick: Tick) => void): void {
    this.listeners.push(cb);
  }

  private emitRound(): void {
    const ts = Date.now();
    for (const [symbol, price] of this.prices) {
      const move = (this.rand() - 0.5) * 2 * this.volatility;
      const next = Math.max(0.01, Math.round(price * (1 + move) * 100) / 100);
      this.prices.set(symbol, next);
      const tick: Tick = { symbol, price: next, ts };
      for (const cb of this.listeners) cb(tick);
    }
  }
}
