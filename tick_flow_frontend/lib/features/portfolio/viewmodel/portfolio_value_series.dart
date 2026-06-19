import 'dart:collection';

import '../../../data/markets/market_models.dart';
import '../../../data/portfolio/portfolio_models.dart';

/// A reconstructed point: epoch-ms timestamp [t] and portfolio [value].
typedef ValuePoint = ({int t, double value});

/// Reconstructs the portfolio's value over time from each holding's daily
/// closes: value(t) = Σ qty × close_i(t), forward-filling a holding's last
/// known close on dates it has no candle (and back-filling its earliest close
/// for dates before its data starts). Holdings without candles are skipped;
/// returns the chronological series (empty when nothing has candles).
List<ValuePoint> reconstructValueSeries(
  List<HoldingValuation> holdings,
  Map<String, List<Candle>> candlesBySymbol,
) {
  final lots = <({double qty, List<Candle> candles})>[];
  final timeline = SplayTreeSet<int>();
  for (final h in holdings) {
    final candles = candlesBySymbol[h.symbol];
    if (candles == null || candles.isEmpty) continue;
    final sorted = [...candles]..sort((a, b) => a.t.compareTo(b.t));
    lots.add((qty: h.qty, candles: sorted));
    for (final c in sorted) {
      timeline.add(c.t);
    }
  }
  if (lots.isEmpty) return const [];
  return [
    for (final t in timeline)
      (
        t: t,
        value: lots.fold(0.0, (sum, lot) => sum + lot.qty * _closeAt(lot.candles, t)),
      ),
  ];
}

/// Last close at or before [t]; falls back to the earliest close.
double _closeAt(List<Candle> candles, int t) {
  var close = candles.first.c;
  for (final c in candles) {
    if (c.t > t) break;
    close = c.c;
  }
  return close;
}
