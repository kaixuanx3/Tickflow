import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme_mode.dart';
import '../../../data/portfolio/portfolio_models.dart';

/// The user's manual holding order, persisted on-device (shared_preferences).
/// The backend has no order field, so this never leaves the device/browser.
class HoldingOrderController extends Notifier<List<String>> {
  static const _key = 'portfolio_order';

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  void save(List<String> ids) {
    state = ids;
    ref.read(sharedPreferencesProvider).setStringList(_key, ids);
  }
}

final holdingOrderProvider =
    NotifierProvider<HoldingOrderController, List<String>>(
        HoldingOrderController.new);

/// Applies the saved [order] to [holdings]. Holdings not in [order] (freshly
/// added) sink to the bottom, newest last — so new holdings appear at the end.
/// Incoming holdings are newest-first (backend `createdAt desc`).
List<HoldingValuation> orderedHoldings(
  List<HoldingValuation> holdings,
  List<String> order,
) {
  final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
  final known = [
    for (final h in holdings)
      if (rank.containsKey(h.id)) h,
  ]..sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
  final fresh = [
    for (final h in holdings)
      if (!rank.containsKey(h.id)) h,
  ].reversed.toList();
  return [...known, ...fresh];
}
