import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/watchlist/watchlist_repository.dart';
import 'package:tick_flow_app/data/watchlist/watchlist_store.dart';

class FakeWatchlistRepository implements WatchlistRepository {
  FakeWatchlistRepository(this.server);

  final Set<String> server;
  bool fail = false;

  @override
  Future<List<String>> fetch() async => server.toList();

  @override
  Future<void> add(String symbol) async {
    if (fail) throw const ApiException(502, 'vendor down');
    server.add(symbol);
  }

  @override
  Future<void> remove(String symbol) async {
    if (fail) throw const ApiException(502, 'vendor down');
    server.remove(symbol);
  }
}

ProviderContainer makeContainer(FakeWatchlistRepository repo) {
  final container = ProviderContainer(
    overrides: [watchlistRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('loads the starred set', () async {
    final container = makeContainer(FakeWatchlistRepository({'AAPL'}));
    expect(await container.read(watchlistProvider.future), {'AAPL'});
  });

  test('toggle adds and removes optimistically', () async {
    final repo = FakeWatchlistRepository({'AAPL'});
    final container = makeContainer(repo);
    final notifier = container.read(watchlistProvider.notifier);
    await container.read(watchlistProvider.future);

    await notifier.toggle('TSLA');
    expect(container.read(watchlistProvider).value, {'AAPL', 'TSLA'});
    expect(repo.server, {'AAPL', 'TSLA'});

    await notifier.toggle('AAPL');
    expect(container.read(watchlistProvider).value, {'TSLA'});
    expect(repo.server, {'TSLA'});
  });

  test('failed toggle reverts and rethrows', () async {
    final repo = FakeWatchlistRepository({'AAPL'});
    final container = makeContainer(repo);
    final notifier = container.read(watchlistProvider.notifier);
    await container.read(watchlistProvider.future);

    repo.fail = true;
    await expectLater(notifier.toggle('TSLA'), throwsA(isA<ApiException>()));
    expect(container.read(watchlistProvider).value, {'AAPL'});
  });
}
