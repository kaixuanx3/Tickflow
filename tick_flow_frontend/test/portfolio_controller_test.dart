import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_models.dart';
import 'package:tick_flow_app/data/portfolio/portfolio_repository.dart';
import 'package:tick_flow_app/features/portfolio/viewmodel/portfolio_controller.dart';

const _emptySummary = PortfolioSummary(
  holdings: [],
  totalValue: 0,
  totalCost: 0,
  totalGainLoss: 0,
  totalGainLossPercent: null,
  allocation: [],
  incomplete: false,
);

class FakePortfolioRepository implements PortfolioRepository {
  int summaryCalls = 0;
  bool failMutations = false;
  final added = <String>[];
  final updated = <String>[];
  final removed = <String>[];

  @override
  Future<PortfolioSummary> fetchSummary() async {
    summaryCalls++;
    return _emptySummary;
  }

  @override
  Future<void> add({
    required String symbol,
    required double qty,
    required double buyPrice,
    required AssetType assetType,
  }) async {
    if (failMutations) throw const ApiException(502, 'vendor down');
    added.add(symbol);
  }

  @override
  Future<void> update(String id, {double? qty, double? buyPrice, AssetType? assetType}) async {
    if (failMutations) throw const ApiException(404, 'holding not found');
    updated.add(id);
  }

  @override
  Future<void> remove(String id) async {
    if (failMutations) throw const ApiException(404, 'holding not found');
    removed.add(id);
  }
}

(ProviderContainer, FakePortfolioRepository) make() {
  final repo = FakePortfolioRepository();
  final container = ProviderContainer(
    overrides: [portfolioRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return (container, repo);
}

void main() {
  test('build loads the summary once', () async {
    final (container, repo) = make();
    await container.read(portfolioProvider.future);
    expect(repo.summaryCalls, 1);
  });

  test('addHolding posts then re-fetches the summary', () async {
    final (container, repo) = make();
    await container.read(portfolioProvider.future);

    await container.read(portfolioProvider.notifier).addHolding(
          symbol: 'AAPL',
          qty: 2,
          buyPrice: 100,
          assetType: AssetType.stock,
        );

    expect(repo.added, ['AAPL']);
    expect(repo.summaryCalls, 2);
  });

  test('updateHolding and removeHolding re-fetch too', () async {
    final (container, repo) = make();
    await container.read(portfolioProvider.future);
    final notifier = container.read(portfolioProvider.notifier);

    await notifier.updateHolding('h1', qty: 3);
    await notifier.removeHolding('h1');

    expect(repo.updated, ['h1']);
    expect(repo.removed, ['h1']);
    expect(repo.summaryCalls, 3);
  });

  test('failed mutation rethrows and does not re-fetch', () async {
    final (container, repo) = make();
    await container.read(portfolioProvider.future);
    repo.failMutations = true;

    await expectLater(
      container.read(portfolioProvider.notifier).addHolding(
            symbol: 'AAPL',
            qty: 1,
            buyPrice: 1,
            assetType: AssetType.stock,
          ),
      throwsA(isA<ApiException>()),
    );
    expect(repo.summaryCalls, 1);
  });
}
