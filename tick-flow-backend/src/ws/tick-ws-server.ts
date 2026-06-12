import type { Server } from 'node:http';
import { WebSocket, WebSocketServer } from 'ws';
import { z } from 'zod';
import { symbolSchema } from '../routes/symbol-schema.js';
import type { AuthService } from '../services/auth-service.js';
import type { Tick } from '../services/tick-source.js';

// Protocol (CLAUDE.md): first message must be auth within the timeout, token is
// NEVER read from the URL query string. Then subscribe/unsubscribe; server
// pushes ticks only for symbols this client subscribed to.
const clientMessage = z.discriminatedUnion('type', [
  z.object({ type: z.literal('auth'), token: z.string().min(1) }),
  z.object({ type: z.literal('subscribe'), symbols: z.array(symbolSchema).min(1).max(50) }),
  z.object({ type: z.literal('unsubscribe'), symbols: z.array(symbolSchema).min(1).max(50) }),
]);

/** What the hub asks of subscription management; per client-subscription, not per symbol. */
export interface SymbolSubscriptions {
  add(symbol: string): Promise<void>;
  remove(symbol: string): Promise<void>;
}

interface ClientState {
  userId: string;
  symbols: Set<string>;
}

const CLOSE_UNAUTHORIZED = 4401;

export class TickWsServer {
  private readonly wss: WebSocketServer;
  private readonly clients = new Map<WebSocket, ClientState>();
  private readonly bySymbol = new Map<string, Set<WebSocket>>();

  constructor(
    server: Server,
    private readonly authService: AuthService,
    private readonly subscriptions: SymbolSubscriptions,
    tickFeed: { onTick(cb: (tick: Tick) => void): void },
    private readonly authTimeoutMs = 5000,
  ) {
    this.wss = new WebSocketServer({ server, path: '/ws' });
    this.wss.on('connection', (ws) => this.onConnection(ws));
    tickFeed.onTick((tick) => this.fanOut(tick));
  }

  close(): void {
    for (const ws of this.clients.keys()) ws.close(1001, 'server shutting down');
    this.wss.close();
  }

  private onConnection(ws: WebSocket): void {
    const authTimer = setTimeout(() => ws.close(CLOSE_UNAUTHORIZED, 'auth timeout'), this.authTimeoutMs);

    ws.on('message', (raw) => {
      // RawData is Buffer | ArrayBuffer | Buffer[]; ws delivers Buffer by default
      void this.onMessage(ws, (raw as Buffer).toString('utf8'), authTimer);
    });
    ws.on('close', () => {
      clearTimeout(authTimer);
      void this.onDisconnect(ws);
    });
    ws.on('error', () => ws.close());
  }

  private async onMessage(ws: WebSocket, raw: string, authTimer: NodeJS.Timeout): Promise<void> {
    let msg: z.infer<typeof clientMessage>;
    try {
      msg = clientMessage.parse(JSON.parse(raw));
    } catch {
      if (!this.clients.has(ws)) return ws.close(CLOSE_UNAUTHORIZED, 'expected auth');
      return this.send(ws, { type: 'error', error: 'invalid message' });
    }

    const state = this.clients.get(ws);
    if (!state) {
      if (msg.type !== 'auth') return ws.close(CLOSE_UNAUTHORIZED, 'expected auth');
      const verified = this.authService.verifyToken(msg.token);
      if (!verified) return ws.close(CLOSE_UNAUTHORIZED, 'invalid token');
      clearTimeout(authTimer);
      this.clients.set(ws, { userId: verified.userId, symbols: new Set() });
      return this.send(ws, { type: 'auth_ok' });
    }

    if (msg.type === 'auth') return this.send(ws, { type: 'error', error: 'already authed' });

    const symbols = msg.symbols.map((s) => s.toUpperCase());
    if (msg.type === 'subscribe') {
      for (const symbol of symbols) {
        if (state.symbols.has(symbol)) continue;
        state.symbols.add(symbol);
        this.indexAdd(symbol, ws);
        await this.subscriptions.add(symbol);
      }
      return this.send(ws, { type: 'subscribed', symbols: [...state.symbols] });
    }

    for (const symbol of symbols) {
      if (!state.symbols.delete(symbol)) continue;
      this.indexRemove(symbol, ws);
      await this.subscriptions.remove(symbol);
    }
    return this.send(ws, { type: 'subscribed', symbols: [...state.symbols] });
  }

  private async onDisconnect(ws: WebSocket): Promise<void> {
    const state = this.clients.get(ws);
    if (!state) return;
    this.clients.delete(ws);
    for (const symbol of state.symbols) {
      this.indexRemove(symbol, ws);
      await this.subscriptions.remove(symbol);
    }
  }

  private fanOut(tick: Tick): void {
    const targets = this.bySymbol.get(tick.symbol);
    if (!targets?.size) return;
    const msg = JSON.stringify({ type: 'tick', symbol: tick.symbol, price: tick.price, ts: tick.ts });
    for (const ws of targets) {
      if (ws.readyState === WebSocket.OPEN) ws.send(msg);
    }
  }

  private indexAdd(symbol: string, ws: WebSocket): void {
    let set = this.bySymbol.get(symbol);
    if (!set) {
      set = new Set();
      this.bySymbol.set(symbol, set);
    }
    set.add(ws);
  }

  private indexRemove(symbol: string, ws: WebSocket): void {
    const set = this.bySymbol.get(symbol);
    if (!set) return;
    set.delete(ws);
    if (set.size === 0) this.bySymbol.delete(symbol);
  }

  private send(ws: WebSocket, payload: object): void {
    if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(payload));
  }
}
