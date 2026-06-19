import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/portfolio_day_change.dart';

HoldingValuation holding(String symbol, double qty) => HoldingValuation(
      id: symbol,
      symbol: symbol,
      qty: qty,
      buyPrice: 1,
      assetType: AssetType.stock,
      costBasis: 1,
      price: 1,
      marketValue: 1,
      gainLoss: 0,
      gainLossPercent: 0,
    );

Quote quote(String symbol, {required double change, required double prevClose}) =>
    Quote(
      symbol: symbol,
      price: prevClose + change,
      change: change,
      changePercent: 0,
      high: 0,
      low: 0,
      open: 0,
      prevClose: prevClose,
      ts: 0,
      stale: false,
      delayed: false,
    );

void main() {
  test('aggregates qty x today change and the percent base', () {
    final holdings = [holding('AAPL', 2), holding('NVDA', 3)];
    final quotes = {
      'AAPL': quote('AAPL', change: 1.0, prevClose: 100), // +$2 over $200 prev
      'NVDA': quote('NVDA', change: -2.0, prevClose: 50), // -$6 over $150 prev
    };
    final day = portfolioDayChange(holdings, quotes)!;
    expect(day.amount, closeTo(-4, 1e-9));
    expect(day.percent, closeTo(-4 / 350 * 100, 1e-9));
  });

  test('skips holdings without a quote', () {
    final holdings = [holding('AAPL', 2), holding('ETH', 5)];
    final quotes = {'AAPL': quote('AAPL', change: 1.0, prevClose: 100)};
    final day = portfolioDayChange(holdings, quotes)!;
    expect(day.amount, closeTo(2, 1e-9));
    expect(day.percent, closeTo(1, 1e-9)); // 2 / 200 * 100
  });

  test('returns null when no holding has a quote', () {
    expect(portfolioDayChange([holding('ETH', 5)], const {}), isNull);
  });
}
