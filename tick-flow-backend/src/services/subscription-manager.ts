import type { Tick, TickSource } from './tick-source.js';
import type { SymbolSubscriptions } from '../ws/tick-ws-server.js';

// Refcounts + last-touched live here (Redis in prod, memory in tests).
export interface SubscriptionStore {
  /** clear all state — called once at boot so a crashed run can't leak refcounts */
  reset(): Promise<void>;
  incr(symbol: string): Promise<number>;
  /** floored at 0; reaching 0 removes the entry */
  decr(symbol: string): Promise<number>;
  touch(symbol: string, ts: number): Promise<void>;
  snapshot(): Promise<Map<string, { refs: number; touched: number }>>;
}

interface QuotesPort {
  getQuote(symbol: string): Promise<{ price: number; ts: number } | null>;
}

export interface SubscriptionManagerOptions {
  /** Finnhub free WS streams ~50 symbols concurrently */
  cap?: number;
  /** REST polling cadence for overflow symbols (15–30s per CLAUDE.md) */
  pollIntervalMs?: number;
  now?: () => number;
}

/**
 * Enforces the upstream symbol cap. Symbols beyond the cap fall back to REST
 * polling through the quote cache and are emitted through the SAME onTick
 * path with the identical message shape — downstream can't tell the difference.
 *
 * Eviction at cap: lowest refcount, tie-broken by least recently touched.
 * When a streamed slot frees up, the most-referenced polled symbol is promoted.
 */
export class SubscriptionManager implements SymbolSubscriptions {
  private readonly cap: number;
  private readonly pollIntervalMs: number;
  private readonly now: () => number;
  private readonly streamed = new Set<string>();
  private readonly polled = new Set<string>();
  private readonly listeners: Array<(tick: Tick) => void> = [];
  private pollTimer: NodeJS.Timeout | null = null;

  constructor(
    private readonly tickSource: TickSource,
    private readonly quotes: QuotesPort,
    private readonly store: SubscriptionStore,
    opts: SubscriptionManagerOptions = {},
  ) {
    this.cap = opts.cap ?? 50;
    this.pollIntervalMs = opts.pollIntervalMs ?? 20_000;
    this.now = opts.now ?? Date.now;
    tickSource.onTick((tick) => this.emit(tick));
  }

  onTick(cb: (tick: Tick) => void): void {
    this.listeners.push(cb);
  }

  async add(symbol: string): Promise<void> {
    const refs = await this.store.incr(symbol);
    await this.store.touch(symbol, this.now());
    if (refs > 1) return; // already streamed or polled

    if (this.streamed.size < this.cap) {
      this.stream(symbol);
      return;
    }
    const victim = await this.pickEvictee();
    if (victim) {
      this.unstream(victim);
      this.startPolling(victim);
    }
    this.stream(symbol);
  }

  async remove(symbol: string): Promise<void> {
    const refs = await this.store.decr(symbol);
    if (refs > 0) return;

    if (this.streamed.has(symbol)) {
      this.unstream(symbol);
      await this.promoteOne();
    } else {
      this.stopPolling(symbol);
    }
  }

  close(): void {
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.pollTimer = null;
  }

  private async pickEvictee(): Promise<string | null> {
    const snapshot = await this.store.snapshot();
    let victim: { symbol: string; refs: number; touched: number } | null = null;
    for (const symbol of this.streamed) {
      const meta = snapshot.get(symbol) ?? { refs: 0, touched: 0 };
      if (
        !victim ||
        meta.refs < victim.refs ||
        (meta.refs === victim.refs && meta.touched < victim.touched)
      ) {
        victim = { symbol, ...meta };
      }
    }
    return victim?.symbol ?? null;
  }

  private async promoteOne(): Promise<void> {
    if (this.polled.size === 0 || this.streamed.size >= this.cap) return;
    const snapshot = await this.store.snapshot();
    let best: { symbol: string; refs: number; touched: number } | null = null;
    for (const symbol of this.polled) {
      const meta = snapshot.get(symbol) ?? { refs: 0, touched: 0 };
      if (
        !best ||
        meta.refs > best.refs ||
        (meta.refs === best.refs && meta.touched > best.touched)
      ) {
        best = { symbol, ...meta };
      }
    }
    if (!best) return;
    this.stopPolling(best.symbol);
    this.stream(best.symbol);
  }

  private stream(symbol: string): void {
    this.streamed.add(symbol);
    this.tickSource.subscribe(symbol);
  }

  private unstream(symbol: string): void {
    this.streamed.delete(symbol);
    this.tickSource.unsubscribe(symbol);
  }

  private startPolling(symbol: string): void {
    this.polled.add(symbol);
    if (!this.pollTimer) {
      this.pollTimer = setInterval(() => void this.pollOnce(), this.pollIntervalMs);
      this.pollTimer.unref();
    }
  }

  private stopPolling(symbol: string): void {
    this.polled.delete(symbol);
    if (this.polled.size === 0 && this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  private async pollOnce(): Promise<void> {
    for (const symbol of this.polled) {
      try {
        const quote = await this.quotes.getQuote(symbol);
        if (quote) this.emit({ symbol, price: quote.price, ts: quote.ts });
      } catch {
        // poll again next round; quote cache already absorbs upstream failures
      }
    }
  }

  private emit(tick: Tick): void {
    for (const cb of this.listeners) cb(tick);
  }
}
