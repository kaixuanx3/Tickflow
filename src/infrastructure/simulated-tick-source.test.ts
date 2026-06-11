import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { Tick } from '../services/tick-source.js';
import { SimulatedTickSource } from './simulated-tick-source.js';

describe('SimulatedTickSource', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  function collect(source: SimulatedTickSource): Tick[] {
    const ticks: Tick[] = [];
    source.onTick((t) => ticks.push(t));
    return ticks;
  }

  it('emits ticks only for subscribed symbols', () => {
    const source = new SimulatedTickSource({ intervalMs: 100, seed: 1 });
    const ticks = collect(source);

    source.subscribe('AAPL');
    vi.advanceTimersByTime(300);

    expect(ticks).toHaveLength(3);
    expect(ticks.every((t) => t.symbol === 'AAPL')).toBe(true);
  });

  it('stops emitting after unsubscribe', () => {
    const source = new SimulatedTickSource({ intervalMs: 100, seed: 1 });
    const ticks = collect(source);

    source.subscribe('AAPL');
    vi.advanceTimersByTime(200);
    source.unsubscribe('AAPL');
    vi.advanceTimersByTime(500);

    expect(ticks).toHaveLength(2);
  });

  it('is deterministic for the same seed', () => {
    const run = (): number[] => {
      const source = new SimulatedTickSource({ intervalMs: 100, seed: 42 });
      const ticks = collect(source);
      source.subscribe('TSLA');
      vi.advanceTimersByTime(1000);
      return ticks.map((t) => t.price);
    };

    const a = run();
    const b = run();
    expect(a).toHaveLength(10);
    expect(a).toEqual(b);
  });

  it('random-walks within the configured volatility per tick', () => {
    const volatility = 0.01;
    const source = new SimulatedTickSource({ intervalMs: 100, seed: 7, volatility });
    const ticks = collect(source);

    source.subscribe('MSFT');
    vi.advanceTimersByTime(5000);

    let prev = 100; // default basePrice
    for (const tick of ticks) {
      const move = Math.abs(tick.price - prev) / prev;
      expect(move).toBeLessThanOrEqual(volatility + 0.0001); // rounding slack
      expect(tick.price).toBeGreaterThan(0);
      prev = tick.price;
    }
  });

  it('walks each subscribed symbol independently', () => {
    const source = new SimulatedTickSource({ intervalMs: 100, seed: 9 });
    const ticks = collect(source);

    source.subscribe('AAPL');
    source.subscribe('TSLA');
    vi.advanceTimersByTime(100);

    expect(ticks.map((t) => t.symbol).sort()).toEqual(['AAPL', 'TSLA']);
  });
});
