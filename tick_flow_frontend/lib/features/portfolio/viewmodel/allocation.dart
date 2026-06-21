import '../../../data/portfolio/portfolio_models.dart';

enum AllocationMode { holding, assetType }

class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.percent,
    this.assetType,
    this.isOther = false,
  });

  final String label;
  final double value;
  final double percent;

  /// Set in assetType mode so the view can localize the label.
  final AssetType? assetType;

  /// The condensed tail slice — the view localizes it ("Other").
  final bool isOther;
}

/// Presentation grouping only — every value here was computed by the backend
/// (allocation slices / per-holding marketValue). Unpriced holdings are
/// excluded, matching how the backend builds its allocation.
List<DonutSlice> allocationSlices(PortfolioSummary summary, AllocationMode mode) {
  switch (mode) {
    case AllocationMode.holding:
      return [
        for (final a in summary.allocation)
          DonutSlice(label: a.symbol, value: a.value, percent: a.percent),
      ];
    case AllocationMode.assetType:
      // assetType is per lot, so group the lots' backend market values.
      final totals = <AssetType, double>{};
      var total = 0.0;
      for (final h in summary.holdings) {
        final mv = h.marketValue;
        if (mv == null) continue;
        totals[h.assetType] = (totals[h.assetType] ?? 0) + mv;
        total += mv;
      }
      final slices = [
        for (final e in totals.entries)
          DonutSlice(
            label: e.key.label,
            value: e.value,
            percent: total > 0 ? e.value / total * 100 : 0,
            assetType: e.key,
          ),
      ]..sort((a, b) => b.value.compareTo(a.value));
      return slices;
  }
}

/// Keeps the donut readable: at most [max] slices, the tail folded into
/// "Other". Input is assumed sorted descending (both sources are).
List<DonutSlice> condenseSlices(List<DonutSlice> slices, {int max = 6}) {
  if (slices.length <= max) return slices;
  final kept = slices.take(max - 1).toList();
  final rest = slices.skip(max - 1);
  var value = 0.0;
  var percent = 0.0;
  for (final s in rest) {
    value += s.value;
    percent += s.percent;
  }
  return [...kept, DonutSlice(label: 'Other', value: value, percent: percent, isOther: true)];
}
