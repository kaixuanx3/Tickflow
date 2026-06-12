import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/data/markets/markets_repository.dart';
import 'package:tick_flow_app/data/markets/quotes_cache.dart';
import 'package:tick_flow_app/data/ws/tick_socket_service.dart';

class RecordingMarketsRepository implements MarketsRepository {
  final batches = <List<String>>[];
  bool fail = false;

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async {
    batches.add(symbols);
    if (fail) throw const ApiException(502, 'vendor down');
    return [
      for (final s in symbols)
        Quote(
          symbol: s,
          price: 1,
          change: 0,
          changePercent: 0,
          high: 1,
          low: 1,
          open: 1,
          prevClose: 1,
          ts: 0,
          stale: false,
          delayed: true,
        ),
    ];
  }

  @override
  Future<SymbolPage> fetchSymbols(int page) => throw UnimplementedError();

  @override
  Future<List<SymbolInfo>> search(String query) => throw UnimplementedError();

  @override
  Future<CompanyProfile> fetchProfile(String symbol) => throw UnimplementedError();

  @override
  Future<CandleSeries> fetchCandles(String symbol, CandleRange range) =>
      throw UnimplementedError();
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  late RecordingMarketsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = RecordingMarketsRepository();
    container = ProviderContainer(
      overrides: [marketsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('debounces requests into one batched call', () async {
    final notifier = container.read(quotesProvider.notifier);
    notifier.request('AAPL');
    notifier.request('TSLA');
    notifier.request('MSFT');
    await settle();

    expect(repo.batches, hasLength(1));
    expect(repo.batches.single, unorderedEquals(['AAPL', 'TSLA', 'MSFT']));
    expect(container.read(quotesProvider).keys, hasLength(3));
  });

  test('does not refetch already requested symbols', () async {
    final notifier = container.read(quotesProvider.notifier);
    notifier.request('AAPL');
    await settle();
    notifier.request('AAPL');
    await settle();

    expect(repo.batches, hasLength(1));
  });

  test('chunks batches of more than 50 symbols', () async {
    final notifier = container.read(quotesProvider.notifier);
    for (var i = 0; i < 60; i++) {
      notifier.request('S$i');
    }
    await settle();

    expect(repo.batches, hasLength(2));
    expect(repo.batches.first, hasLength(50));
    expect(repo.batches.last, hasLength(10));
  });

  test('failed batch can be requested again', () async {
    repo.fail = true;
    final notifier = container.read(quotesProvider.notifier);
    notifier.request('AAPL');
    await settle();
    expect(container.read(quotesProvider), isEmpty);

    repo.fail = false;
    notifier.request('AAPL');
    await settle();
    expect(container.read(quotesProvider)['AAPL'], isNotNull);
  });

  test('applyTick updates price, change, extremes and drops delayed', () async {
    final notifier = container.read(quotesProvider.notifier);
    notifier.request('AAPL');
    await settle();

    notifier.applyTick(const Tick(symbol: 'AAPL', price: 2, ts: 99));

    final q = container.read(quotesProvider)['AAPL']!;
    expect(q.price, 2);
    expect(q.change, 1);
    expect(q.changePercent, 100);
    expect(q.high, 2); // new session high
    expect(q.low, 1);
    expect(q.ts, 99);
    expect(q.delayed, isFalse);
    expect(q.stale, isFalse);
  });

  test('applyTick ignores symbols not in the cache', () {
    container.read(quotesProvider.notifier).applyTick(
          const Tick(symbol: 'GHOST', price: 5, ts: 1),
        );
    expect(container.read(quotesProvider), isEmpty);
  });
}
