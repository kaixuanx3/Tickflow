export interface Lot {
  symbol: string;
  qty: number;
  buyPrice: number;
}

// Generic so callers keep extra fields (id, assetType, …) on valued holdings.
export type HoldingValuation<T extends Lot = Lot> = T & {
  costBasis: number;
  price: number | null; // null = no quote available right now
  marketValue: number | null;
  gainLoss: number | null;
  gainLossPercent: number | null;
};

export interface PortfolioSummary<T extends Lot = Lot> {
  holdings: HoldingValuation<T>[];
  totalValue: number;
  totalCost: number; // cost basis of PRICED holdings only, so gain/loss is consistent
  totalGainLoss: number;
  totalGainLossPercent: number | null; // null when priced cost is 0
  allocation: Array<{ symbol: string; value: number; percent: number }>;
  incomplete: boolean; // true if any holding had no price
}

const round2 = (n: number): number => Math.round(n * 100) / 100;

export function summarize<T extends Lot>(
  lots: T[],
  prices: Map<string, number>,
): PortfolioSummary<T> {
  const holdings: HoldingValuation<T>[] = lots.map((lot) => {
    const costBasis = round2(lot.qty * lot.buyPrice);
    const price = prices.get(lot.symbol) ?? null;
    if (price === null) {
      return { ...lot, costBasis, price, marketValue: null, gainLoss: null, gainLossPercent: null };
    }
    const marketValue = round2(lot.qty * price);
    const gainLoss = round2(marketValue - costBasis);
    return {
      ...lot,
      costBasis,
      price,
      marketValue,
      gainLoss,
      gainLossPercent: costBasis > 0 ? round2((gainLoss / costBasis) * 100) : null,
    };
  });

  const priced = holdings.filter(
    (h): h is HoldingValuation<T> & { marketValue: number } => h.marketValue !== null,
  );
  const totalValue = round2(priced.reduce((sum, h) => sum + h.marketValue, 0));
  const totalCost = round2(priced.reduce((sum, h) => sum + h.costBasis, 0));
  const totalGainLoss = round2(totalValue - totalCost);

  const valueBySymbol = new Map<string, number>();
  for (const h of priced) {
    valueBySymbol.set(h.symbol, (valueBySymbol.get(h.symbol) ?? 0) + h.marketValue);
  }
  const allocation = [...valueBySymbol.entries()]
    .map(([symbol, value]) => ({
      symbol,
      value: round2(value),
      percent: totalValue > 0 ? round2((value / totalValue) * 100) : 0,
    }))
    .sort((a, b) => b.value - a.value);

  return {
    holdings,
    totalValue,
    totalCost,
    totalGainLoss,
    totalGainLossPercent:
      totalCost > 0 ? round2((totalGainLoss / totalCost) * 100) : priced.length > 0 ? null : 0,
    allocation,
    incomplete: priced.length < holdings.length,
  };
}
