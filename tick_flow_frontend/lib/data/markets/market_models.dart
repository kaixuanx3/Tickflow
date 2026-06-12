class SymbolInfo {
  const SymbolInfo({
    required this.symbol,
    required this.displaySymbol,
    required this.description,
    required this.type,
  });

  factory SymbolInfo.fromJson(Map<String, dynamic> json) => SymbolInfo(
        symbol: json['symbol'] as String,
        displaySymbol: json['displaySymbol'] as String? ?? json['symbol'] as String,
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );

  final String symbol;
  final String displaySymbol;
  final String description;
  final String type;
}

class SymbolPage {
  const SymbolPage({
    required this.symbols,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.stale,
  });

  factory SymbolPage.fromJson(Map<String, dynamic> json) => SymbolPage(
        symbols: (json['symbols'] as List)
            .map((s) => SymbolInfo.fromJson(s as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
        stale: json['stale'] as bool? ?? false,
      );

  final List<SymbolInfo> symbols;
  final int page;
  final int pageSize;
  final int total;
  final bool stale;
}

class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.open,
    required this.prevClose,
    required this.ts,
    required this.stale,
    required this.delayed,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        symbol: json['symbol'] as String,
        price: (json['price'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        changePercent: (json['changePercent'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        open: (json['open'] as num).toDouble(),
        prevClose: (json['prevClose'] as num).toDouble(),
        ts: json['ts'] as int,
        stale: json['stale'] as bool? ?? false,
        delayed: json['delayed'] as bool? ?? false,
      );

  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double prevClose;
  final int ts;
  final bool stale;
  final bool delayed;
}
