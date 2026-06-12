import { WebSocket } from 'ws';
import type { Tick, TickSource } from '../services/tick-source.js';

// The slice of `ws` we use — injectable for tests.
export interface WsLike {
  readyState: number;
  on(event: 'open' | 'close' | 'error', cb: () => void): void;
  on(event: 'message', cb: (raw: { toString(): string }) => void): void;
  send(data: string): void;
  close(): void;
}

export interface FinnhubTickSourceOptions {
  wsFactory?: () => WsLike;
  baseDelayMs?: number;
  maxDelayMs?: number;
  /** injectable for deterministic jitter in tests */
  random?: () => number;
}

const OPEN = 1; // WebSocket.OPEN

/**
 * ONE upstream WebSocket to Finnhub for the whole process. Reconnects with
 * exponential backoff + jitter and resubscribes all active symbols.
 */
export class FinnhubTickSource implements TickSource {
  private readonly factory: () => WsLike;
  private readonly baseDelayMs: number;
  private readonly maxDelayMs: number;
  private readonly random: () => number;
  private readonly desired = new Set<string>();
  private readonly listeners: Array<(tick: Tick) => void> = [];
  private ws: WsLike | null = null;
  private attempt = 0;
  private closed = false;
  private reconnectTimer: NodeJS.Timeout | null = null;

  constructor(apiKey: string, opts: FinnhubTickSourceOptions = {}) {
    this.factory =
      opts.wsFactory ?? (() => new WebSocket(`wss://ws.finnhub.io?token=${apiKey}`));
    this.baseDelayMs = opts.baseDelayMs ?? 1000;
    this.maxDelayMs = opts.maxDelayMs ?? 30_000;
    this.random = opts.random ?? Math.random;
    this.connect();
  }

  subscribe(symbol: string): void {
    if (this.desired.has(symbol)) return;
    this.desired.add(symbol);
    this.sendIfOpen({ type: 'subscribe', symbol });
  }

  unsubscribe(symbol: string): void {
    if (!this.desired.delete(symbol)) return;
    this.sendIfOpen({ type: 'unsubscribe', symbol });
  }

  onTick(cb: (tick: Tick) => void): void {
    this.listeners.push(cb);
  }

  close(): void {
    this.closed = true;
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.ws?.close();
  }

  private connect(): void {
    const ws = this.factory();
    this.ws = ws;
    ws.on('open', () => {
      this.attempt = 0;
      for (const symbol of this.desired) {
        ws.send(JSON.stringify({ type: 'subscribe', symbol }));
      }
    });
    ws.on('message', (raw) => this.onMessage(raw.toString()));
    ws.on('close', () => this.scheduleReconnect());
    ws.on('error', () => {
      /* 'close' follows and drives the reconnect */
    });
  }

  private scheduleReconnect(): void {
    if (this.closed || this.reconnectTimer) return;
    const exp = Math.min(this.maxDelayMs, this.baseDelayMs * 2 ** this.attempt);
    const delay = exp / 2 + this.random() * (exp / 2); // half fixed, half jitter
    this.attempt += 1;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
    this.reconnectTimer.unref();
  }

  private onMessage(raw: string): void {
    let msg: { type?: string; data?: Array<{ s: string; p: number; t: number }> };
    try {
      msg = JSON.parse(raw) as typeof msg;
    } catch {
      return; // not our problem; ignore
    }
    if (msg.type !== 'trade' || !Array.isArray(msg.data)) return; // e.g. {"type":"ping"}
    for (const trade of msg.data) {
      const tick: Tick = { symbol: trade.s, price: trade.p, ts: trade.t };
      for (const cb of this.listeners) cb(tick);
    }
  }

  private sendIfOpen(payload: object): void {
    if (this.ws && this.ws.readyState === OPEN) this.ws.send(JSON.stringify(payload));
  }
}
