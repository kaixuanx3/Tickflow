import type { Tick, TickSource } from '../services/tick-source.js';

export interface SimulatedTickSourceOptions {
  /** ms between tick rounds (every subscribed symbol ticks each round) */
  intervalMs?: number;
  /** max fractional price move per tick, e.g. 0.002 = ±0.2% */
  volatility?: number;
  /** fallback starting price when a symbol can't be seeded from a real quote */
  basePrice?: number;
  /** seed the RNG for deterministic tests */
  seed?: number;
  /**
   * Optional anchor: the real current price for a symbol, fetched once when it
   * is first subscribed. The random walk starts there instead of [basePrice],
   * so change% (computed downstream against the real prevClose) reads
   * realistically — small greens and reds, not −80% (which is what a flat
   * ~$100 walk produces against a real prevClose). Returns null / rejects →
   * fall back to [basePrice]. A symbol does NOT tick until its seed resolves,
   * so it never emits a bogus basePrice tick first.
   */
  seedPrice?: (symbol: string) => Promise<number | null>;
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
 *
 * With [SimulatedTickSourceOptions.seedPrice] each symbol's walk is anchored to
 * its real price; without it (unit tests) every symbol starts at basePrice.
 */
export class SimulatedTickSource implements TickSource {
  private readonly intervalMs: number;
  private readonly volatility: number;
  private readonly basePrice: number;
  private readonly seedPrice: ((symbol: string) => Promise<number | null>) | undefined;
  private readonly rand: () => number;
  private readonly prices = new Map<string, number>();
  private readonly pending = new Set<string>(); // subscribed, awaiting its seed
  private readonly listeners: Array<(tick: Tick) => void> = [];
  private timer: NodeJS.Timeout | null = null;

  constructor(opts: SimulatedTickSourceOptions = {}) {
    this.intervalMs = opts.intervalMs ?? 1000;
    this.volatility = opts.volatility ?? 0.002;
    this.basePrice = opts.basePrice ?? 100;
    this.seedPrice = opts.seedPrice;
    this.rand = mulberry32(opts.seed ?? Date.now());
  }

  subscribe(symbol: string): void {
    if (this.prices.has(symbol) || this.pending.has(symbol)) return;
    const seed = this.seedPrice;
    // No seeder (e.g. unit tests): start synchronously at basePrice.
    if (!seed) {
      this.activate(symbol, this.basePrice);
      return;
    }
    // Seed from the real quote first; hold off ticking until it resolves.
    this.pending.add(symbol);
    void seed(symbol)
      .then((price) => this.onSeeded(symbol, price))
      .catch(() => this.onSeeded(symbol, null));
  }

  unsubscribe(symbol: string): void {
    this.pending.delete(symbol); // cancel an in-flight seed
    this.prices.delete(symbol);
    if (this.prices.size === 0 && this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  onTick(cb: (tick: Tick) => void): void {
    this.listeners.push(cb);
  }

  private onSeeded(symbol: string, price: number | null): void {
    if (!this.pending.delete(symbol)) return; // unsubscribed while seeding
    this.activate(symbol, price && price > 0 ? price : this.basePrice);
  }

  private activate(symbol: string, price: number): void {
    this.prices.set(symbol, Math.round(price * 100) / 100);
    if (!this.timer) {
      this.timer = setInterval(() => this.emitRound(), this.intervalMs);
      this.timer.unref();
    }
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
