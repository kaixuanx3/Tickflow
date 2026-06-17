import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/portfolio/portfolio_models.dart';
import '../../../data/portfolio/portfolio_repository.dart';

/// All valuation comes from /portfolio/summary — the app never recomputes
/// portfolio math. Every mutation therefore re-fetches the summary.
class PortfolioController extends AsyncNotifier<PortfolioSummary> {
  @override
  Future<PortfolioSummary> build() => ref.watch(portfolioRepositoryProvider).fetchSummary();

  Future<void> addHolding({
    required String symbol,
    required double qty,
    required double buyPrice,
    required AssetType assetType,
  }) async {
    await ref.read(portfolioRepositoryProvider).add(
          symbol: symbol,
          qty: qty,
          buyPrice: buyPrice,
          assetType: assetType,
        );
    await _reload();
  }

  Future<void> updateHolding(
    String id, {
    double? qty,
    double? buyPrice,
    AssetType? assetType,
  }) async {
    await ref
        .read(portfolioRepositoryProvider)
        .update(id, qty: qty, buyPrice: buyPrice, assetType: assetType);
    await _reload();
  }

  Future<void> removeHolding(String id) async {
    await ref.read(portfolioRepositoryProvider).remove(id);
    await _reload();
  }

  /// Manual reorder: optimistically reorder the in-memory holdings (so the list
  /// doesn't flicker), then persist. On failure, fall back to the server order.
  Future<void> reorder(List<String> orderedIds) async {
    final current = state.value;
    if (current == null) return;
    final byId = {for (final h in current.holdings) h.id: h};
    final reordered = [
      for (final id in orderedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final included = orderedIds.toSet();
    for (final h in current.holdings) {
      if (!included.contains(h.id)) reordered.add(h);
    }
    state = AsyncData(PortfolioSummary(
      holdings: reordered,
      totalValue: current.totalValue,
      totalCost: current.totalCost,
      totalGainLoss: current.totalGainLoss,
      totalGainLossPercent: current.totalGainLossPercent,
      allocation: current.allocation,
      incomplete: current.incomplete,
    ));
    try {
      await ref.read(portfolioRepositoryProvider).reorder(orderedIds);
    } catch (_) {
      await _reload();
    }
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final portfolioProvider =
    AsyncNotifierProvider<PortfolioController, PortfolioSummary>(PortfolioController.new);
