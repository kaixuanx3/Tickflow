import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/allocation.dart';

HoldingValuation holding(String symbol, AssetType type, double? marketValue) =>
    HoldingValuation(
      id: symbol,
      symbol: symbol,
      qty: 1,
      buyPrice: 1,
      assetType: type,
      costBasis: 1,
      price: marketValue,
      marketValue: marketValue,
      gainLoss: null,
      gainLossPercent: null,
    );

void main() {
  final summary = PortfolioSummary(
    holdings: [
      holding('AAPL', AssetType.stock, 300),
      holding('VOO', AssetType.etf, 100),
      holding('BTC', AssetType.crypto, null), // unpriced — must be excluded
    ],
    totalValue: 400,
    totalCost: 2,
    totalGainLoss: 398,
    totalGainLossPercent: null,
    allocation: const [
      AllocationSlice(symbol: 'AAPL', value: 300, percent: 75),
      AllocationSlice(symbol: 'VOO', value: 100, percent: 25),
    ],
    incomplete: true,
  );

  test('holding mode passes the backend allocation through', () {
    final slices = allocationSlices(summary, AllocationMode.holding);
    expect(slices.map((s) => s.label), ['AAPL', 'VOO']);
    expect(slices.first.percent, 75);
  });

  test('asset-type mode groups backend market values and skips unpriced', () {
    final slices = allocationSlices(summary, AllocationMode.assetType);
    expect(slices.map((s) => s.label), ['Stock', 'ETF']);
    expect(slices[0].value, 300);
    expect(slices[0].percent, 75);
    expect(slices[1].percent, 25);
  });

  test('condenseSlices folds the tail into Other', () {
    final many = [
      for (var i = 0; i < 8; i++)
        DonutSlice(label: 'S$i', value: (8 - i).toDouble(), percent: 10),
    ];
    final condensed = condenseSlices(many, max: 6);
    expect(condensed, hasLength(6));
    expect(condensed.last.label, 'Other');
    expect(condensed.last.value, 3 + 2 + 1); // S5 + S6 + S7
    expect(condensed.last.percent, 30);
  });

  test('condenseSlices leaves short lists alone', () {
    final two = [
      const DonutSlice(label: 'A', value: 1, percent: 50),
      const DonutSlice(label: 'B', value: 1, percent: 50),
    ];
    expect(condenseSlices(two), same(two));
  });
}
