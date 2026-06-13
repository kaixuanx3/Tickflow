import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';

void main() {
  test('parses a summary with priced and unpriced holdings', () {
    final s = PortfolioSummary.fromJson(const {
      'holdings': [
        {
          'id': 'h1',
          'symbol': 'AAPL',
          'qty': 2,
          'buyPrice': 100,
          'assetType': 'stock',
          'createdAt': '2026-06-01T00:00:00.000Z',
          'costBasis': 200,
          'price': 150,
          'marketValue': 300,
          'gainLoss': 100,
          'gainLossPercent': 50,
        },
        {
          'id': 'h2',
          'symbol': 'MYSTERY',
          'qty': 1,
          'buyPrice': 10,
          'assetType': 'crypto',
          'costBasis': 10,
          'price': null,
          'marketValue': null,
          'gainLoss': null,
          'gainLossPercent': null,
        },
      ],
      'totalValue': 300,
      'totalCost': 200,
      'totalGainLoss': 100,
      'totalGainLossPercent': 50,
      'allocation': [
        {'symbol': 'AAPL', 'value': 300, 'percent': 100},
      ],
      'incomplete': true,
    });

    expect(s.holdings, hasLength(2));
    expect(s.holdings[0].gainLossPercent, 50);
    expect(s.holdings[1].assetType, AssetType.crypto);
    expect(s.holdings[1].marketValue, isNull);
    expect(s.allocation.single.percent, 100);
    expect(s.incomplete, isTrue);
  });

  test('unknown assetType falls back to stock', () {
    final h = HoldingValuation.fromJson(const {
      'id': 'h3',
      'symbol': 'X',
      'qty': 1,
      'buyPrice': 1,
      'assetType': 'bond',
      'costBasis': 1,
      'price': null,
      'marketValue': null,
      'gainLoss': null,
      'gainLossPercent': null,
    });
    expect(h.assetType, AssetType.stock);
  });
}
