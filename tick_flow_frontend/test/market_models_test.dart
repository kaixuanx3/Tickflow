import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';

void main() {
  test('CompanyProfile parses a full payload', () {
    final p = CompanyProfile.fromJson(const {
      'symbol': 'AAPL',
      'name': 'Apple Inc',
      'exchange': 'NASDAQ',
      'currency': 'USD',
      'country': 'US',
      'marketCap': 4342022.98,
      'ipo': '1980-12-12',
      'logo': 'https://example.com/logo.png',
      'website': 'https://www.apple.com/',
      'industry': 'Technology',
      'stale': false,
    });
    expect(p.name, 'Apple Inc');
    expect(p.marketCapMillions, closeTo(4342022.98, 0.01));
  });

  test('CompanyProfile tolerates missing optional fields', () {
    final p = CompanyProfile.fromJson(const {'symbol': 'XYZ'});
    expect(p.name, 'XYZ'); // falls back to the symbol
    expect(p.marketCapMillions, isNull);
    expect(p.logo, isNull);
    expect(p.stale, isFalse);
  });

  test('CandleSeries parses candles with epoch-ms timestamps', () {
    final s = CandleSeries.fromJson(const {
      'symbol': 'AAPL',
      'range': '1W',
      'stale': true,
      'candles': [
        {'t': 1780617600000, 'o': 312.86, 'h': 315.17, 'l': 307.15, 'c': 307.34, 'v': 65310502},
      ],
    });
    expect(s.stale, isTrue);
    expect(s.candles.single.time.year, 2026);
    expect(s.candles.single.h, 315.17);
  });

  test('SymbolInfo falls back to symbol for displaySymbol', () {
    final info = SymbolInfo.fromJson(const {'symbol': 'TSLA'});
    expect(info.displaySymbol, 'TSLA');
    expect(info.description, '');
  });
}
