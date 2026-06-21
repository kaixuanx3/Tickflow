// ─────────────────────────────────────────────────────────────────────────────
// PARKED FEATURE — "All stocks" browse (currently disabled).
//
// What it does: infinite-scroll browse of the FULL US symbol universe
// (GET /symbols, 50 per page, load-more on scroll). This was the original
// Markets list before it was redesigned into the Top gainers / Top losers /
// Most active movers tabs (see markets_movers.dart) — the movers tabs + the
// search bar replaced it.
//
// Kept commented-out (not deleted) in case a full-universe browse is wanted
// again later. To restore: uncomment this file AND
// test/markets_list_controller_test.dart, then wire `marketsListProvider` back
// into markets_screen.dart (a paginated SliverList that calls loadMore() near
// the end of the scroll).
// ─────────────────────────────────────────────────────────────────────────────

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/markets/market_models.dart';
import '../../../data/markets/markets_repository.dart';

class MarketsListState {
  const MarketsListState({
    required this.symbols,
    required this.total,
    required this.stale,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<SymbolInfo> symbols;
  final int total;
  final bool stale;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => symbols.length < total;

  MarketsListState copyWith({
    List<SymbolInfo>? symbols,
    int? total,
    bool? stale,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) =>
      MarketsListState(
        symbols: symbols ?? this.symbols,
        total: total ?? this.total,
        stale: stale ?? this.stale,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

class MarketsListController extends AsyncNotifier<MarketsListState> {
  int _page = 1;

  @override
  Future<MarketsListState> build() async {
    _page = 1;
    final page = await ref.watch(marketsRepositoryProvider).fetchSymbols(1);
    return MarketsListState(symbols: page.symbols, total: page.total, stale: page.stale);
  }

  /// Scroll-triggered. After a failure it stays parked until retried
  /// explicitly, so scroll events can't hammer a failing backend.
  Future<void> loadMore({bool retry = false}) async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    if (current.loadMoreFailed && !retry) return;

    state = AsyncData(current.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final next = await ref.read(marketsRepositoryProvider).fetchSymbols(_page + 1);
      if (!ref.mounted) return;
      _page++;
      state = AsyncData(current.copyWith(
        symbols: [...current.symbols, ...next.symbols],
        total: next.total,
        stale: next.stale,
        loadingMore: false,
        loadMoreFailed: false,
      ));
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }
}

final marketsListProvider =
    AsyncNotifierProvider<MarketsListController, MarketsListState>(MarketsListController.new);
*/
