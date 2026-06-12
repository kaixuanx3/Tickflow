import { describe, expect, it } from 'vitest';
import { summarize } from './portfolio-math.js';

const lot = (symbol: string, qty: number, buyPrice: number) => ({ symbol, qty, buyPrice });

describe('summarize', () => {
  it('values a single priced holding', () => {
    const summary = summarize([lot('AAPL', 10, 100)], new Map([['AAPL', 150]]));

    expect(summary.holdings).toEqual([
      {
        symbol: 'AAPL',
        qty: 10,
        buyPrice: 100,
        costBasis: 1000,
        price: 150,
        marketValue: 1500,
        gainLoss: 500,
        gainLossPercent: 50,
      },
    ]);
    expect(summary.totalValue).toBe(1500);
    expect(summary.totalCost).toBe(1000);
    expect(summary.totalGainLoss).toBe(500);
    expect(summary.totalGainLossPercent).toBe(50);
    expect(summary.incomplete).toBe(false);
  });

  it('handles losses and rounds money to 2dp', () => {
    const summary = summarize([lot('TSLA', 3, 333.333)], new Map([['TSLA', 300.005]]));

    const h = summary.holdings[0]!;
    expect(h.costBasis).toBe(1000); // 3 * 333.333 = 999.999 → 2dp
    expect(h.marketValue).toBe(900.02); // 3 * 300.005 = 900.015 → 2dp
    expect(h.gainLoss).toBe(-99.98);
    expect(summary.totalGainLoss).toBe(-99.98);
  });

  it('aggregates multiple lots of the same symbol in allocation', () => {
    const summary = summarize(
      [lot('AAPL', 10, 100), lot('AAPL', 5, 120), lot('TSLA', 2, 200)],
      new Map([
        ['AAPL', 200],
        ['TSLA', 500],
      ]),
    );

    // AAPL value 15*200=3000, TSLA 2*500=1000, total 4000
    expect(summary.totalValue).toBe(4000);
    expect(summary.allocation).toEqual([
      { symbol: 'AAPL', value: 3000, percent: 75 },
      { symbol: 'TSLA', value: 1000, percent: 25 },
    ]);
  });

  it('excludes unpriced holdings from totals and flags the summary incomplete', () => {
    const summary = summarize(
      [lot('AAPL', 10, 100), lot('MYSTERY', 5, 50)],
      new Map([['AAPL', 150]]),
    );

    const mystery = summary.holdings.find((h) => h.symbol === 'MYSTERY')!;
    expect(mystery.costBasis).toBe(250); // cost is always known
    expect(mystery.price).toBeNull();
    expect(mystery.marketValue).toBeNull();
    expect(mystery.gainLoss).toBeNull();
    expect(mystery.gainLossPercent).toBeNull();

    expect(summary.totalValue).toBe(1500);
    expect(summary.totalCost).toBe(1000); // only priced holdings count toward totals
    expect(summary.incomplete).toBe(true);
    expect(summary.allocation.map((a) => a.symbol)).toEqual(['AAPL']);
  });

  it('returns zeros for an empty portfolio', () => {
    const summary = summarize([], new Map());

    expect(summary).toEqual({
      holdings: [],
      totalValue: 0,
      totalCost: 0,
      totalGainLoss: 0,
      totalGainLossPercent: 0,
      allocation: [],
      incomplete: false,
    });
  });

  it('guards division by zero on free shares (buyPrice 0)', () => {
    const summary = summarize([lot('FREE', 10, 0)], new Map([['FREE', 5]]));

    const h = summary.holdings[0]!;
    expect(h.gainLoss).toBe(50);
    expect(h.gainLossPercent).toBeNull(); // undefined % on zero cost
    expect(summary.totalGainLossPercent).toBeNull();
  });

  it('sorts allocation by value descending', () => {
    const summary = summarize(
      [lot('A', 1, 1), lot('B', 1, 1), lot('C', 1, 1)],
      new Map([
        ['A', 10],
        ['B', 30],
        ['C', 20],
      ]),
    );

    expect(summary.allocation.map((a) => a.symbol)).toEqual(['B', 'C', 'A']);
  });
});
