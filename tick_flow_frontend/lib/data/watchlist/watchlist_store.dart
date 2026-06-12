import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'watchlist_repository.dart';

/// Starred symbols, shared across tabs (rows star-toggle, Favourites lists).
/// Toggles are optimistic: state flips immediately, reverts and rethrows if
/// the backend call fails.
class WatchlistController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async =>
      (await ref.watch(watchlistRepositoryProvider).fetch()).toSet();

  Future<void> toggle(String symbol) async {
    final current = state.value;
    if (current == null) return; // not loaded yet
    final repo = ref.read(watchlistRepositoryProvider);
    final isFavourite = current.contains(symbol);

    state = AsyncData(
      isFavourite ? ({...current}..remove(symbol)) : {...current, symbol},
    );
    try {
      isFavourite ? await repo.remove(symbol) : await repo.add(symbol);
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistController, Set<String>>(WatchlistController.new);
