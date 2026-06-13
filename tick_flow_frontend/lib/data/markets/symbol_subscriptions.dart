import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ref-counted set of symbols that should stream live ticks. Visible widgets
/// (list rows, the detail screen) retain on mount and release on dispose, so
/// the WS subscription set always matches what's on screen.
class SymbolSubscriptions extends Notifier<Set<String>> {
  final _counts = <String, int>{};

  @override
  Set<String> build() => const {};

  void retain(String symbol) {
    final count = (_counts[symbol] ?? 0) + 1;
    _counts[symbol] = count;
    if (count == 1) state = {...state, symbol};
  }

  void release(String symbol) {
    final count = _counts[symbol];
    if (count == null) return;
    if (count <= 1) {
      _counts.remove(symbol);
      state = {...state}..remove(symbol);
    } else {
      _counts[symbol] = count - 1;
    }
  }
}

final symbolSubscriptionsProvider =
    NotifierProvider<SymbolSubscriptions, Set<String>>(SymbolSubscriptions.new);
