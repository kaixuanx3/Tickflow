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

  test('formatMarketCapMillions treats input as millions', () {
    expect(formatMarketCapMillions(4342022.98), r'$4.34T');
    expect(formatMarketCapMillions(950), r'$950M');
    expect(formatMarketCapMillions(null), '—');
  });
}
