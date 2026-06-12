import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/markets/symbol_subscriptions.dart';

void main() {
  late ProviderContainer container;
  late SymbolSubscriptions subs;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    subs = container.read(symbolSubscriptionsProvider.notifier);
  });

  test('retain adds a symbol once regardless of count', () {
    subs.retain('AAPL');
    subs.retain('AAPL');
    subs.retain('TSLA');
    expect(container.read(symbolSubscriptionsProvider), {'AAPL', 'TSLA'});
  });

  test('release removes only when the last holder lets go', () {
    subs.retain('AAPL');
    subs.retain('AAPL');

    subs.release('AAPL');
    expect(container.read(symbolSubscriptionsProvider), {'AAPL'});

    subs.release('AAPL');
    expect(container.read(symbolSubscriptionsProvider), isEmpty);
  });

  test('releasing an unknown symbol is a no-op', () {
    subs.release('GHOST');
    expect(container.read(symbolSubscriptionsProvider), isEmpty);
  });
}
