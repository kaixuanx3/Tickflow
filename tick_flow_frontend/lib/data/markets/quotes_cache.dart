import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ws/tick_socket_service.dart';
import 'market_models.dart';
import 'markets_repository.dart';

/// Quote cache keyed by symbol. Rows call [request] as they become visible;
/// requests are debounced into one batched `/quotes` call (chunks of 50),
/// so scrolling the markets list never fans out per-row HTTP requests.
/// Live WS ticks are merged in via [applyTick].
class QuotesController extends Notifier<Map<String, Quote>> {
  final _pending = <String>{};
  final _requested = <String>{};
  Timer? _debounce;

  @override
  Map<String, Quote> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const {};
  }

  void request(String symbol) {
    if (_requested.contains(symbol)) return;
    _requested.add(symbol);
    _pending.add(symbol);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _flush);
  }

  void clear() {
    _pending.clear();
    _requested.clear();
    state = const {};
  }

  /// Merge a live tick into the cached snapshot. `delayed` flips to false —
  /// the price on screen is now live, not the delayed REST snapshot.
  void applyTick(Tick tick) {
    final q = state[tick.symbol];
    if (q == null) return;
    final change = tick.price - q.prevClose;
    state = {
      ...state,
      tick.symbol: Quote(
        symbol: q.symbol,
        price: tick.price,
        change: change,
        changePercent: q.prevClose == 0 ? 0 : change / q.prevClose * 100,
        high: math.max(q.high, tick.price),
        low: math.min(q.low, tick.price),
        open: q.open,
        prevClose: q.prevClose,
        ts: tick.ts,
        stale: false,
        delayed: false,
      ),
    };
  }

  Future<void> _flush() async {
    final batch = _pending.toList();
    _pending.clear();
    for (var i = 0; i < batch.length; i += 50) {
      final chunk = batch.sublist(i, math.min(i + 50, batch.length));
      try {
        final quotes = await ref.read(marketsRepositoryProvider).fetchQuotes(chunk);
        if (!ref.mounted) return;
        state = {...state, for (final q in quotes) q.symbol: q};
      } catch (_) {
        if (!ref.mounted) return;
        _requested.removeAll(chunk); // allow a later retry
      }
    }
  }
}

final quotesProvider =
    NotifierProvider<QuotesController, Map<String, Quote>>(QuotesController.new);
