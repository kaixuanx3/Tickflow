import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/markets/market_models.dart';
import 'package:tick_flow_app/data/markets/markets_repository.dart';
import 'package:tick_flow_app/features/markets/viewmodel/symbol_search_controller.dart';

class SearchFakeRepository implements MarketsRepository {
  final queries = <String>[];
  bool fail = false;

  @override
  Future<List<SymbolInfo>> search(String query) async {
    queries.add(query);
    if (fail) throw const ApiException(502, 'vendor down');
    return [
      SymbolInfo(
        symbol: query.toUpperCase(),
        displaySymbol: query.toUpperCase(),
        description: 'match',
        type: 'Common Stock',
      ),
    ];
  }

  @override
  Future<SymbolPage> fetchSymbols(int page) => throw UnimplementedError();

  @override
  Future<List<Quote>> fetchQuotes(List<String> symbols) => throw UnimplementedError();
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  late SearchFakeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = SearchFakeRepository();
    container = ProviderContainer(
      overrides: [marketsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Keep the autoDispose provider alive for the duration of the test.
    container.listen(symbolSearchProvider, (_, _) {});
  });

  test('debounces keystrokes into one search call', () async {
    final notifier = container.read(symbolSearchProvider.notifier);
    notifier.onQueryChanged('a');
    notifier.onQueryChanged('ap');
    notifier.onQueryChanged('app');
    expect(container.read(symbolSearchProvider).isLoading, isTrue);
    await settle();

    expect(repo.queries, ['app']);
    expect(container.read(symbolSearchProvider).value!.single.symbol, 'APP');
  });

  test('clearing the query resets to empty without a call', () async {
    final notifier = container.read(symbolSearchProvider.notifier);
    notifier.onQueryChanged('app');
    notifier.onQueryChanged('');
    await settle();

    expect(repo.queries, isEmpty);
    expect(container.read(symbolSearchProvider).value, isEmpty);
  });

  test('errors surface and retry recovers', () async {
    repo.fail = true;
    final notifier = container.read(symbolSearchProvider.notifier);
    notifier.onQueryChanged('tsla');
    await settle();
    expect(container.read(symbolSearchProvider).hasError, isTrue);

    repo.fail = false;
    notifier.retry();
    await settle();
    expect(container.read(symbolSearchProvider).value!.single.symbol, 'TSLA');
  });
}
