import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/core/formats.dart';

void main() {
  test('formatMoney renders 2dp and em-dash for null', () {
    expect(formatMoney(1234.5), r'$1,234.50');
    expect(formatMoney(null), '—');
  });

  test('formatPercent signs values and em-dashes null', () {
    expect(formatPercent(1.389), '+1.39%');
    expect(formatPercent(-2), '-2.00%');
    expect(formatPercent(null), '—');
  });

  test('formatSignedMoney always shows the sign', () {
    expect(formatSignedMoney(5), r'+$5.00');
    expect(formatSignedMoney(-4.88), r'-$4.88');
    expect(formatSignedMoney(null), '—');
  });

  test('formatQty trims trailing zeros', () {
    expect(formatQty(2), '2');
    expect(formatQty(0.5), '0.5');
    expect(formatQty(1234.5678), '1,234.5678');
  });

  test('formatMarketCapMillions treats input as millions', () {
    expect(formatMarketCapMillions(4342022.98), r'$4.34T');
    expect(formatMarketCapMillions(950), r'$950M');
    expect(formatMarketCapMillions(null), '—');
  });
}
