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

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final portfolioProvider =
    AsyncNotifierProvider<PortfolioController, PortfolioSummary>(PortfolioController.new);
