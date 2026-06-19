import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/portfolio_value_series.dart';

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

Candle candle(int t, double close) =>
    Candle(t: t, o: close, h: close, l: close, c: close, v: 0);

void main() {
  test('sums qty x close per date, forward-filling missing dates', () {
    final holdings = [holding('AAA', 2), holding('BBB', 3)];
    final candles = {
      'AAA': [candle(1, 10), candle(2, 20)],
      'BBB': [candle(1, 100)], // no t=2 → forward-fill 100
    };
    final series = reconstructValueSeries(holdings, candles);
    expect(series.map((p) => p.t).toList(), [1, 2]);
    // t=1: 2*10 + 3*100 = 320 ; t=2: 2*20 + 3*100 = 340
    expect(series.map((p) => p.value).toList(), [320, 340]);
  });

  test('skips holdings without candles; empty when none have data', () {
    expect(reconstructValueSeries([holding('X', 1)], const {}), isEmpty);
    final mixed = reconstructValueSeries(
      [holding('A', 1), holding('NO', 9)],
      {
        'A': [candle(1, 5), candle(2, 7)],
      },
    );
    expect(mixed.map((p) => p.value).toList(), [5, 7]); // 'NO' skipped
  });
}
