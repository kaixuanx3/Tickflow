import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick_flow_app/data/alerts/alert_models.dart';
import 'package:tick_flow_app/data/alerts/alerts_repository.dart';
import 'package:tick_flow_app/data/api/api_client.dart';
import 'package:tick_flow_app/features/notifications/viewmodel/alerts_controller.dart';

class FakeAlertsRepository implements AlertsRepository {
  int fetches = 0;
  bool failMutations = false;
  final created = <String>[];
  final updates = <(String, double?, AlertKind?, bool)>[];
  final removed = <String>[];

  @override
  Future<List<Alert>> fetch() async {
    fetches++;
    return const [];
  }

  @override
  Future<void> create({
    required String symbol,
    required AlertRuleType ruleType,
    required double threshold,
    required AlertKind kind,
  }) async {
    if (failMutations) throw const ApiException(502, 'vendor down');
    created.add(symbol);
  }

  @override
  Future<void> update(
    String id, {
    double? threshold,
    AlertKind? kind,
    bool reactivate = false,
  }) async {
    if (failMutations) throw const ApiException(404, 'alert not found');
    updates.add((id, threshold, kind, reactivate));
  }

  @override
  Future<void> remove(String id) async {
    if (failMutations) throw const ApiException(404, 'alert not found');
    removed.add(id);
  }
}

(ProviderContainer, FakeAlertsRepository) make() {
  final repo = FakeAlertsRepository();
  final container = ProviderContainer(
    overrides: [alertsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return (container, repo);
}

void main() {
  test('createAlert posts then re-fetches', () async {
    final (container, repo) = make();
    await container.read(alertsProvider.future);

    await container.read(alertsProvider.notifier).createAlert(
          symbol: 'AAPL',
          ruleType: AlertRuleType.priceAbove,
          threshold: 200,
          kind: AlertKind.oneShot,
        );

    expect(repo.created, ['AAPL']);
    expect(repo.fetches, 2);
  });

  test('rearm patches status only and re-fetches', () async {
    final (container, repo) = make();
    await container.read(alertsProvider.future);

    await container.read(alertsProvider.notifier).rearm('a1');

    expect(repo.updates.single, ('a1', null, null, true));
    expect(repo.fetches, 2);
  });

  test('updateAlert patches threshold and kind', () async {
    final (container, repo) = make();
    await container.read(alertsProvider.future);

    await container
        .read(alertsProvider.notifier)
        .updateAlert('a1', threshold: 150, kind: AlertKind.reArm);

    expect(repo.updates.single, ('a1', 150.0, AlertKind.reArm, false));
  });

  test('failed mutation rethrows without re-fetching', () async {
    final (container, repo) = make();
    await container.read(alertsProvider.future);
    repo.failMutations = true;

    await expectLater(
      container.read(alertsProvider.notifier).removeAlert('a1'),
      throwsA(isA<ApiException>()),
    );
    expect(repo.fetches, 1);
  });
}
