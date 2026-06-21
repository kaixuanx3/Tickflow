// ─────────────────────────────────────────────────────────────────────────────
// PARKED — tests for the "All stocks" browse controller, which is currently
// commented out (see lib/features/markets/viewmodel/markets_list_controller.dart).
// Uncomment this file together with that one to restore the browse feature.
// ─────────────────────────────────────────────────────────────────────────────

/*
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/data/markets/markets_repository.dart';
import 'package:tick_flow_app/features/markets/viewmodel/markets_list_controller.dart';

class FakeMarketsRepository implements MarketsRepository {
  FakeMarketsRepository({required this.total});

  final int total;
  bool failNext = false;
  final calls = <int>[];

  @override
  Future<SymbolPage> fetchSymbols(int page) async {
    calls.add(page);
    if (failNext) {
      failNext = false;
      throw const ApiException(502, 'vendor down');
    }
    final start = (page - 1) * 50;
    final count = math.max(0, math.min(50, total - start));
    return SymbolPage(
      symbols: [
        for (var i = 0; i < count; i++)
          SymbolInfo(
            symbol: 'S${start + i}',
            displaySymbol: 'S${start + i}',
            description: 'desc',
            type: 'Common Stock',
          ),
      ],
      page: page,
      pageSize: 50,
      total: total,
      stale: false,
    );
  }

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) async => const [];

  @override
  Future<List<SymbolInfo>> search(String query) => throw UnimplementedError();

  @override
  Future<CompanyProfile> fetchProfile(String symbol) => throw UnimplementedError();

  @override
  Future<CandleSeries> fetchCandles(String symbol, CandleRange range) =>
      throw UnimplementedError();
}

ProviderContainer makeContainer(FakeMarketsRepository repo) {
  final container = ProviderContainer(
    overrides: [marketsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('loads the first page', () async {
    final container = makeContainer(FakeMarketsRepository(total: 120));
    final state = await container.read(marketsListProvider.future);
    expect(state.symbols.length, 50);
    expect(state.hasMore, isTrue);
  });

  test('loadMore appends pages until total is reached', () async {
    final repo = FakeMarketsRepository(total: 120);
    final container = makeContainer(repo);
    final notifier = container.read(marketsListProvider.notifier);
    await container.read(marketsListProvider.future);

    await notifier.loadMore();
    expect(container.read(marketsListProvider).value!.symbols.length, 100);

    await notifier.loadMore();
    final state = container.read(marketsListProvider).value!;
    expect(state.symbols.length, 120);
    expect(state.hasMore, isFalse);

    await notifier.loadMore();
    expect(repo.calls, [1, 2, 3]); // no extra call once everything is loaded
  });

  test('failed loadMore keeps the list and parks until retried', () async {
    final repo = FakeMarketsRepository(total: 120);
    final container = makeContainer(repo);
    final notifier = container.read(marketsListProvider.notifier);
    await container.read(marketsListProvider.future);
    repo.failNext = true;

    await notifier.loadMore();
    var state = container.read(marketsListProvider).value!;
    expect(state.symbols.length, 50);
    expect(state.loadMoreFailed, isTrue);

    await notifier.loadMore(); // scroll-triggered, must be ignored while parked
    expect(repo.calls, [1, 2]);

    await notifier.loadMore(retry: true);
    state = container.read(marketsListProvider).value!;
    expect(state.symbols.length, 100);
    expect(state.loadMoreFailed, isFalse);
  });
}
*/

// No active tests — the suite above is parked with the controller it covers.
void main() {}
