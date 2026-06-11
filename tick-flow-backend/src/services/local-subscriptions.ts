import type { TickSource } from './tick-source.js';
import type { SymbolSubscriptions } from '../ws/tick-ws-server.js';

/**
 * Plain refcounting over a TickSource: first client subscribing a symbol
 * subscribes upstream, last one leaving unsubscribes. The SubscriptionManager
 * (50-symbol cap, eviction, polling fallback) replaces this.
 */
export class LocalSubscriptions implements SymbolSubscriptions {
  private readonly refs = new Map<string, number>();

  constructor(private readonly tickSource: TickSource) {}

  async add(symbol: string): Promise<void> {
    const refs = (this.refs.get(symbol) ?? 0) + 1;
    this.refs.set(symbol, refs);
    if (refs === 1) this.tickSource.subscribe(symbol);
  }

  async remove(symbol: string): Promise<void> {
    const refs = (this.refs.get(symbol) ?? 0) - 1;
    if (refs > 0) {
      this.refs.set(symbol, refs);
      return;
    }
    this.refs.delete(symbol);
    this.tickSource.unsubscribe(symbol);
  }
}
