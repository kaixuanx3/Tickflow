import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/markets/market_models.dart';
import '../../../data/markets/markets_repository.dart';

/// Curated universe of well-known US large-caps for the movers lists. UAT
/// approximation — movers are ranked within this set, not the whole market
/// (the backend has no movers feed and the free quote tier has no volume).
const moversUniverse = <String>[
  'AAPL', 'MSFT', 'NVDA', 'GOOGL', 'AMZN', 'META', 'TSLA', 'AMD', 'NFLX', 'AVGO',
  'INTC', 'CSCO', 'QCOM', 'TXN', 'ORCL', 'CRM', 'ADBE', 'PYPL', 'UBER', 'SHOP',
  'JPM', 'BAC', 'WFC', 'GS', 'MS', 'V', 'MA', 'KO', 'PEP', 'MCD',
  'DIS', 'NKE', 'WMT', 'COST', 'XOM', 'CVX', 'PFE', 'JNJ', 'BA', 'CAT',
];

enum MoverTab {
  gainers('Top gainers'),
  losers('Top losers'),
  active('Most active');

  const MoverTab(this.label);
  final String label;
}

/// One snapshot of the universe's quotes, used to rank the movers. Kept
/// separate from the live quote cache so the row order stays stable (rows still
/// show live prices); pull-to-refresh re-ranks.
final moversProvider = FutureProvider.autoDispose<Map<String, Quote>>((ref) async {
  final quotes = await ref.watch(marketsRepositoryProvider).fetchQuotes(moversUniverse);
  return {for (final q in quotes) q.symbol: q};
});

/// Ranks the universe quotes for [tab]: gainers by %↓, losers by %↑, "active"
/// by |%|↓ (no volume on the free tier, so this stands in for volume).
List<Quote> rankMovers(Map<String, Quote> quotes, MoverTab tab, {int limit = 20}) {
  final list = [
    for (final s in moversUniverse)
      if (quotes[s] != null) quotes[s]!,
  ];
  switch (tab) {
    case MoverTab.gainers:
      list.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    case MoverTab.losers:
      list.sort((a, b) => a.changePercent.compareTo(b.changePercent));
    case MoverTab.active:
      list.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
  }
  return list.take(limit).toList();
}
