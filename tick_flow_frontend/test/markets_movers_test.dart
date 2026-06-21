import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/features/markets/viewmodel/markets_movers.dart';

Quote q(String symbol, double changePercent) => Quote(
      symbol: symbol,
      price: 1,
      change: 0,
      changePercent: changePercent,
      high: 0,
      low: 0,
      open: 0,
      prevClose: 0,
      ts: 0,
      stale: false,
      delayed: false,
    );

void main() {
  // All three are in moversUniverse.
  final quotes = {'AAPL': q('AAPL', 5), 'MSFT': q('MSFT', -8), 'NVDA': q('NVDA', 2)};

  test('gainers rank by % descending', () {
    expect(rankMovers(quotes, MoverTab.gainers).map((x) => x.symbol).toList(),
        ['AAPL', 'NVDA', 'MSFT']);
  });

  test('losers rank by % ascending', () {
    expect(rankMovers(quotes, MoverTab.losers).map((x) => x.symbol).toList(),
        ['MSFT', 'NVDA', 'AAPL']);
  });

  test('active ranks by absolute % (biggest move first)', () {
    expect(rankMovers(quotes, MoverTab.active).map((x) => x.symbol).first, 'MSFT');
  });
}
