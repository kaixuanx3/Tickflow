import '../../../data/portfolio/portfolio_models.dart';

/// Top and bottom contributors to total P/L — the holdings that added and
/// subtracted the most dollars (by gain/loss, not %). Unpriced holdings (no
/// gain/loss) are ignored; returns null when none are priced.
({HoldingValuation top, HoldingValuation bottom})? topContributors(
  List<HoldingValuation> holdings,
) {
  HoldingValuation? top;
  HoldingValuation? bottom;
  for (final h in holdings) {
    final g = h.gainLoss;
    if (g == null) continue;
    if (top == null || g > top.gainLoss!) top = h;
    if (bottom == null || g < bottom.gainLoss!) bottom = h;
  }
  if (top == null || bottom == null) return null;
  return (top: top, bottom: bottom);
}
