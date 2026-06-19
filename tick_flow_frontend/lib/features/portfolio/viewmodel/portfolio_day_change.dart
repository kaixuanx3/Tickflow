import '../../../data/markets/market_models.dart';
import '../../../data/portfolio/portfolio_models.dart';

typedef DayChange = ({double amount, double? percent});

/// Today's portfolio change vs yesterday's close, reconstructed from live
/// quotes — Σ qty × today's change, with Σ qty × prevClose as the percent base.
/// Holdings without a quote (e.g. crypto the vendor doesn't cover) are skipped;
/// returns null when no holding has a quote yet.
DayChange? portfolioDayChange(
  List<HoldingValuation> holdings,
  Map<String, Quote> quotes,
) {
  var amount = 0.0;
  var prevValue = 0.0;
  var any = false;
  for (final h in holdings) {
    final q = quotes[h.symbol];
    if (q == null) continue;
    any = true;
    amount += h.qty * q.change;
    prevValue += h.qty * q.prevClose;
  }
  if (!any) return null;
  return (amount: amount, percent: prevValue > 0 ? amount / prevValue * 100 : null);
}
