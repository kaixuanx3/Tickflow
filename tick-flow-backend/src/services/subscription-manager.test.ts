import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemorySubscriptionStore } from '../repositories/subscription-store.js';
import { SubscriptionManager } from './subscription-manager.js';
import type { Tick, TickSource } from './tick-source.js';

class FakeTickSource implements TickSource {
  subscribed = new Set<string>();
  private listeners: Array<(t: Tick) => void> = [];
  subscribe(symbol: string): void {
    this.subscribed.add(symbol);
  }
  unsubscribe(symbol: string): void {
    this.subscribed.delete(symbol);
  }
  onTick(cb: (t: Tick) => void): void {
    this.listeners.push(cb);
  }
  emit(tick: Tick): void {
    for (const cb of this.listeners) cb(tick);
  }
}

const fakeQuotes = {
  getQuote: vi.fn(async (symbol: string) => ({ price: 123.45, ts: 1_000 })),
};

describe('SubscriptionManager', () => {
  let source: FakeTickSource;
  let manager: SubscriptionManager;
  let nowMs: number;

  const make = (cap: number): SubscriptionManager => {
    source = new FakeTickSource();
    nowMs = 0;
    fakeQuotes.getQuote.mockClear();
    manager = new SubscriptionManager(source, fakeQuotes, new MemorySubscriptionStore(), {
      cap,
      pollIntervalMs: 1000,
      now: () => ++nowMs, // strictly increasing → deterministic tie-breaks
    });
    return manager;
  };

  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    manager.close();
    vi.useRealTimers();
  });

  it('subscribes upstream on 0→1 and unsubscribes on 1→0', async () => {
    make(50);
    await manager.add('AAPL');
    expect(source.subscribed.has('AAPL')).toBe(true);

    await manager.add('AAPL'); // second client
    await manager.remove('AAPL');
    expect(source.subscribed.has('AAPL')).toBe(true); // still one ref left

    await manager.remove('AAPL');
    expect(source.subscribed.has('AAPL')).toBe(false);
  });

  it('relays streamed ticks unchanged', async () => {
    make(50);
    const ticks: Tick[] = [];
    manager.onTick((t) => ticks.push(t));
    await manager.add('AAPL');

    source.emit({ symbol: 'AAPL', price: 150, ts: 999 });

    expect(ticks).toEqual([{ symbol: 'AAPL', price: 150, ts: 999 }]);
  });

  it('evicts the lowest-refcount symbol to polling when at cap', async () => {
    make(2);
    await manager.add('AAPL');
    await manager.add('AAPL'); // 2 refs
    await manager.add('TSLA'); // 1 ref
    await manager.add('MSFT'); // cap exceeded → TSLA (lowest refs) evicted

    expect(source.subscribed.has('AAPL')).toBe(true);
    expect(source.subscribed.has('MSFT')).toBe(true);
    expect(source.subscribed.has('TSLA')).toBe(false);

    // evicted symbol still produces ticks — via REST polling, same shape
    const ticks: Tick[] = [];
    manager.onTick((t) => ticks.push(t));
    await vi.advanceTimersByTimeAsync(1000);
    expect(ticks).toEqual([{ symbol: 'TSLA', price: 123.45, ts: 1_000 }]);
    expect(fakeQuotes.getQuote).toHaveBeenCalledWith('TSLA');
  });

  it('breaks refcount ties by least recently touched', async () => {
    make(2);
    await manager.add('AAPL'); // touched first
    await manager.add('TSLA'); // touched later
    await manager.add('MSFT'); // tie on refs(1,1) → AAPL is LRU → evicted

    expect(source.subscribed.has('AAPL')).toBe(false);
    expect(source.subscribed.has('TSLA')).toBe(true);
    expect(source.subscribed.has('MSFT')).toBe(true);
  });

  it('stops polling when an evicted symbol loses its last subscriber', async () => {
    make(1);
    await manager.add('AAPL');
    await manager.add('TSLA'); // AAPL evicted to polling

    await manager.remove('AAPL');
    await vi.advanceTimersByTimeAsync(3000);
    expect(fakeQuotes.getQuote).not.toHaveBeenCalled();
  });

  it('promotes the most-referenced polled symbol when a slot frees', async () => {
    make(2);
    await manager.add('AAPL');
    await manager.add('TSLA');
    await manager.add('MSFT'); // AAPL evicted (LRU tie-break) → polling
    await manager.add('AAPL'); // AAPL now 2 refs, still polled
    expect(source.subscribed.has('AAPL')).toBe(false);

    await manager.remove('TSLA'); // slot frees → AAPL promoted

    expect(source.subscribed.has('AAPL')).toBe(true);
    expect(source.subscribed.has('MSFT')).toBe(true);
  });

  it('keeps polling alive across quote errors', async () => {
    make(1);
    await manager.add('AAPL');
    await manager.add('TSLA'); // AAPL → polling
    fakeQuotes.getQuote.mockRejectedValueOnce(new Error('rate limited'));

    const ticks: Tick[] = [];
    manager.onTick((t) => ticks.push(t));
    await vi.advanceTimersByTimeAsync(1000); // errors
    await vi.advanceTimersByTimeAsync(1000); // recovers

    expect(ticks).toHaveLength(1);
  });
});
