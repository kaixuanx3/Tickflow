enum AssetType {
  stock,
  etf,
  crypto;

  String get label => switch (this) {
        stock => 'Stock',
        etf => 'ETF',
        crypto => 'Crypto',
      };
}

/// A holding as returned inside /portfolio/summary: the stored lot plus the
/// backend's valuation. Nulls mean "no quote available right now".
class HoldingValuation {
  const HoldingValuation({
    required this.id,
    required this.symbol,
    required this.qty,
    required this.buyPrice,
    required this.assetType,
    required this.costBasis,
    required this.price,
    required this.marketValue,
    required this.gainLoss,
    required this.gainLossPercent,
  });

  factory HoldingValuation.fromJson(Map<String, dynamic> json) => HoldingValuation(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        qty: (json['qty'] as num).toDouble(),
        buyPrice: (json['buyPrice'] as num).toDouble(),
        assetType:
            AssetType.values.asNameMap()[json['assetType']] ?? AssetType.stock,
        costBasis: (json['costBasis'] as num).toDouble(),
        price: (json['price'] as num?)?.toDouble(),
        marketValue: (json['marketValue'] as num?)?.toDouble(),
        gainLoss: (json['gainLoss'] as num?)?.toDouble(),
        gainLossPercent: (json['gainLossPercent'] as num?)?.toDouble(),
      );

  final String id;
  final String symbol;
  final double qty;
  final double buyPrice;
  final AssetType assetType;
  final double costBasis;
  final double? price;
  final double? marketValue;
  final double? gainLoss;
  final double? gainLossPercent;
}

class AllocationSlice {
  const AllocationSlice({required this.symbol, required this.value, required this.percent});

  factory AllocationSlice.fromJson(Map<String, dynamic> json) => AllocationSlice(
        symbol: json['symbol'] as String,
        value: (json['value'] as num).toDouble(),
        percent: (json['percent'] as num).toDouble(),
      );

  final String symbol;
  final double value;
  final double percent;
}

class PortfolioSummary {
  const PortfolioSummary({
    required this.holdings,
    required this.totalValue,
    required this.totalCost,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.allocation,
    required this.incomplete,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) => PortfolioSummary(
        holdings: (json['holdings'] as List)
            .map((h) => HoldingValuation.fromJson(h as Map<String, dynamic>))
            .toList(),
        totalValue: (json['totalValue'] as num).toDouble(),
        totalCost: (json['totalCost'] as num).toDouble(),
        totalGainLoss: (json['totalGainLoss'] as num).toDouble(),
        totalGainLossPercent: (json['totalGainLossPercent'] as num?)?.toDouble(),
        allocation: (json['allocation'] as List)
            .map((a) => AllocationSlice.fromJson(a as Map<String, dynamic>))
            .toList(),
        incomplete: json['incomplete'] as bool? ?? false,
      );

  final List<HoldingValuation> holdings;
  final double totalValue;
  final double totalCost;
  final double totalGainLoss;
  final double? totalGainLossPercent;
  final List<AllocationSlice> allocation;
  final bool incomplete;
}
