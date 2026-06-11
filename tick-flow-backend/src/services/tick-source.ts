// One live price update for one symbol. Everything downstream (cache, fan-out,
// alerts) consumes TickSource and cannot tell which implementation is running.
export interface Tick {
  symbol: string;
  price: number;
  ts: number; // epoch ms
}

export interface TickSource {
  subscribe(symbol: string): void;
  unsubscribe(symbol: string): void;
  onTick(cb: (tick: Tick) => void): void;
}
