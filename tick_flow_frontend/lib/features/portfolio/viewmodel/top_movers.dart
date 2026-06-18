import '../../../data/portfolio/portfolio_models.dart';

/// Best and worst holdings by total gain/loss %. Unpriced holdings (no
/// gain/loss) are ignored; returns null when none are priced.
({HoldingValuation best, HoldingValuation worst})? topMovers(
  List<HoldingValuation> holdings,
) {
  HoldingValuation? best;
  HoldingValuation? worst;
  for (final h in holdings) {
    final p = h.gainLossPercent;
    if (p == null) continue;
    if (best == null || p > best.gainLossPercent!) best = h;
    if (worst == null || p < worst.gainLossPercent!) worst = h;
  }
  if (best == null || worst == null) return null;
  return (best: best, worst: worst);
}
