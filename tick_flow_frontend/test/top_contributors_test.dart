import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/top_contributors.dart';

HoldingValuation holding(String symbol, double? gainLoss) => HoldingValuation(
      id: symbol,
      symbol: symbol,
      qty: 1,
      buyPrice: 1,
      assetType: AssetType.stock,
      costBasis: 1,
      price: 1,
      marketValue: 1,
      gainLoss: gainLoss,
      gainLossPercent: gainLoss,
    );

void main() {
  test(r'picks top and bottom by gain/loss $, ignoring unpriced', () {
    final c = topContributors([
      holding('A', 1000),
      holding('B', -500),
      holding('C', null), // unpriced → ignored
      holding('D', 200),
    ])!;
    expect(c.top.symbol, 'A');
    expect(c.bottom.symbol, 'B');
  });

  test('null when none are priced', () {
    expect(topContributors([holding('X', null)]), isNull);
  });
}
