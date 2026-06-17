import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/holding_order.dart';

HoldingValuation h(String id) => HoldingValuation(
      id: id,
      symbol: id,
      qty: 1,
      buyPrice: 1,
      assetType: AssetType.stock,
      costBasis: 1,
      price: 1,
      marketValue: 1,
      gainLoss: 0,
      gainLossPercent: 0,
    );

List<String> ids(List<HoldingValuation> hs) => hs.map((e) => e.id).toList();

void main() {
  // Backend returns newest-first (createdAt desc); 'qqq' is the newest.
  final incoming = [h('qqq'), h('eth'), h('nvda'), h('aapl')];

  test('no saved order: newest sinks to the bottom (oldest first)', () {
    expect(ids(orderedHoldings(incoming, const [])),
        ['aapl', 'nvda', 'eth', 'qqq']);
  });

  test('applies the saved order verbatim', () {
    final order = ['aapl', 'qqq', 'nvda', 'eth'];
    expect(ids(orderedHoldings(incoming, order)), order);
  });

  test('a freshly added holding (not in the saved order) goes to the bottom', () {
    final order = ['aapl', 'qqq', 'nvda', 'eth']; // saved before tsla existed
    final withNew = [h('tsla'), ...incoming]; // tsla arrives newest-first
    expect(ids(orderedHoldings(withNew, order)),
        ['aapl', 'qqq', 'nvda', 'eth', 'tsla']);
  });

  test('stale ids in the saved order are ignored', () {
    final order = ['gone', 'aapl', 'qqq', 'nvda', 'eth'];
    expect(ids(orderedHoldings(incoming, order)),
        ['aapl', 'qqq', 'nvda', 'eth']);
  });
}
