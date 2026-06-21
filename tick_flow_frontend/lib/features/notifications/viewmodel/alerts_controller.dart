import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/alerts/alert_models.dart';
import '../../../data/alerts/alerts_repository.dart';

class AlertsController extends AsyncNotifier<List<Alert>> {
  @override
  Future<List<Alert>> build() => ref.watch(alertsRepositoryProvider).fetch();

  Future<void> createAlert({
    required String symbol,
    required AlertRuleType ruleType,
    required double threshold,
    required AlertKind kind,
  }) async {
    await ref.read(alertsRepositoryProvider).create(
          symbol: symbol,
          ruleType: ruleType,
          threshold: threshold,
          kind: kind,
        );
    await _reload();
  }

  Future<void> updateAlert(String id, {double? threshold, AlertKind? kind}) async {
    await ref.read(alertsRepositoryProvider).update(id, threshold: threshold, kind: kind);
    await _reload();
  }

  Future<void> rearm(String id) async {
    await ref.read(alertsRepositoryProvider).update(id, reactivate: true);
    await _reload();
  }

  /// Pause an active/cooldown alert so the engine stops watching it.
  Future<void> pause(String id) async {
    await ref.read(alertsRepositoryProvider).pause(id);
    await _reload();
  }

  Future<void> removeAlert(String id) async {
    await ref.read(alertsRepositoryProvider).remove(id);
    await _reload();
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final alertsProvider =
    AsyncNotifierProvider<AlertsController, List<Alert>>(AlertsController.new);
