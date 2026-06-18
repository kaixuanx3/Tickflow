import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/top_movers.dart';

HoldingValuation holding(String symbol, double? gainLossPercent) =>
    HoldingValuation(
      id: symbol,
      symbol: symbol,
      qty: 1,
      buyPrice: 1,
      assetType: AssetType.stock,
      costBasis: 1,
      price: 1,
      marketValue: 1,
      gainLoss: gainLossPercent,
      gainLossPercent: gainLossPercent,
    );

void main() {
  test('picks best and worst by gain/loss %, ignoring unpriced', () {
    final m = topMovers([
      holding('A', 10),
      holding('B', -5),
      holding('C', null), // unpriced → ignored
      holding('D', 3),
    ])!;
    expect(m.best.symbol, 'A');
    expect(m.worst.symbol, 'B');
  });

  test('null when none are priced', () {
    expect(topMovers([holding('X', null)]), isNull);
  });
}
