import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { Tick } from '../services/tick-source.js';
import { FinnhubTickSource, type WsLike } from './finnhub-tick-source.js';

class FakeWs implements WsLike {
  readyState = 0; // CONNECTING
  sent: string[] = [];
  private handlers = new Map<string, Array<(arg?: unknown) => void>>();

  on(event: 'open' | 'close' | 'error', cb: () => void): void;
  on(event: 'message', cb: (raw: { toString(): string }) => void): void;
  on(event: string, cb: (raw: { toString(): string }) => void): void {
    const list = this.handlers.get(event) ?? [];
    list.push(cb as (arg?: unknown) => void);
    this.handlers.set(event, list);
  }

  send(data: string): void {
    this.sent.push(data);
  }

  close(): void {
    this.fire('close');
  }

  open(): void {
    this.readyState = 1;
    this.fire('open');
  }

  message(payload: object): void {
    this.fire('message', JSON.stringify(payload));
  }

  fire(event: string, arg?: unknown): void {
    for (const cb of this.handlers.get(event) ?? []) cb(arg);
  }
}

describe('FinnhubTickSource', () => {
  let sockets: FakeWs[];
  let source: FinnhubTickSource;

  const make = (): FinnhubTickSource => {
    sockets = [];
    source = new FinnhubTickSource('key', {
      wsFactory: () => {
        const ws = new FakeWs();
        sockets.push(ws);
        return ws;
      },
      baseDelayMs: 1000,
      maxDelayMs: 30_000,
      random: () => 1, // jitter pinned to max → delay equals the exponential value
    });
    return source;
  };

  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    source.close();
    vi.useRealTimers();
  });

  it('sends subscriptions made before the socket opened', () => {
    make();
    source.subscribe('AAPL');
    expect(sockets[0]!.sent).toEqual([]); // not open yet

    sockets[0]!.open();
    expect(sockets[0]!.sent).toEqual([JSON.stringify({ type: 'subscribe', symbol: 'AAPL' })]);
  });

  it('emits one tick per trade in a trade message', () => {
    make();
    sockets[0]!.open();
    const ticks: Tick[] = [];
    source.onTick((t) => ticks.push(t));

    sockets[0]!.message({
      type: 'trade',
      data: [
        { s: 'AAPL', p: 150.5, t: 1700000000000, v: 10 },
        { s: 'TSLA', p: 300.1, t: 1700000000001, v: 5 },
      ],
    });

    expect(ticks).toEqual([
      { symbol: 'AAPL', price: 150.5, ts: 1700000000000 },
      { symbol: 'TSLA', price: 300.1, ts: 1700000000001 },
    ]);
  });

  it('ignores pings and malformed payloads', () => {
    make();
    sockets[0]!.open();
    const ticks: Tick[] = [];
    source.onTick((t) => ticks.push(t));

    sockets[0]!.message({ type: 'ping' });
    sockets[0]!.fire('message', 'not json');

    expect(ticks).toEqual([]);
  });

  it('reconnects with exponential backoff and resubscribes', () => {
    make();
    source.subscribe('AAPL');
    sockets[0]!.open();

    sockets[0]!.close();
    expect(sockets).toHaveLength(1);
    vi.advanceTimersByTime(1000); // base delay (attempt 0)
    expect(sockets).toHaveLength(2);

    sockets[1]!.close();
    vi.advanceTimersByTime(1000); // attempt 1 → needs 2000ms
    expect(sockets).toHaveLength(2);
    vi.advanceTimersByTime(1000);
    expect(sockets).toHaveLength(3);

    sockets[2]!.open(); // successful reconnect resubscribes and resets backoff
    expect(sockets[2]!.sent).toEqual([JSON.stringify({ type: 'subscribe', symbol: 'AAPL' })]);

    sockets[2]!.close();
    vi.advanceTimersByTime(1000); // back to base delay
    expect(sockets).toHaveLength(4);
  });

  it('unsubscribe sends the message and is not resubscribed after reconnect', () => {
    make();
    source.subscribe('AAPL');
    source.subscribe('TSLA');
    sockets[0]!.open();
    source.unsubscribe('AAPL');

    expect(sockets[0]!.sent).toContain(JSON.stringify({ type: 'unsubscribe', symbol: 'AAPL' }));

    sockets[0]!.close();
    vi.advanceTimersByTime(1000);
    sockets[1]!.open();
    expect(sockets[1]!.sent).toEqual([JSON.stringify({ type: 'subscribe', symbol: 'TSLA' })]);
  });

  it('close() stops reconnect attempts', () => {
    make();
    sockets[0]!.open();
    source.close();
    vi.advanceTimersByTime(60_000);
    expect(sockets).toHaveLength(1);
  });
});
