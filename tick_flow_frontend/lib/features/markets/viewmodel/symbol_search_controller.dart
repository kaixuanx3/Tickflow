import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/markets/market_models.dart';
import '../../../data/markets/markets_repository.dart';

/// Debounced symbol search. Late responses for superseded queries are dropped.
class SymbolSearchController extends Notifier<AsyncValue<List<SymbolInfo>>> {
  Timer? _debounce;
  String _query = '';

  @override
  AsyncValue<List<SymbolInfo>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncData([]);
  }

  void onQueryChanged(String query) {
    final q = query.trim();
    if (q == _query) return;
    _query = q;
    _debounce?.cancel();
    if (q.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q));
  }

  void retry() {
    if (_query.isEmpty) return;
    state = const AsyncLoading();
    _run(_query);
  }

  Future<void> _run(String query) async {
    try {
      final results = await ref.read(marketsRepositoryProvider).search(query);
      if (!ref.mounted || query != _query) return;
      state = AsyncData(results);
    } catch (e, st) {
      if (!ref.mounted || query != _query) return;
      state = AsyncError(e, st);
    }
  }
}

final symbolSearchProvider = NotifierProvider.autoDispose<SymbolSearchController,
    AsyncValue<List<SymbolInfo>>>(SymbolSearchController.new);
