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

enum CandleRange {
  d1('1D'),
  w1('1W'),
  m1('1M'),
  y1('1Y');

  const CandleRange(this.api);

  final String api;
}

class CompanyProfile {
  const CompanyProfile({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.currency,
    required this.country,
    required this.marketCapMillions,
    required this.ipo,
    required this.logo,
    required this.website,
    required this.industry,
    required this.stale,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        symbol: json['symbol'] as String,
        name: json['name'] as String? ?? json['symbol'] as String,
        exchange: json['exchange'] as String?,
        currency: json['currency'] as String?,
        country: json['country'] as String?,
        // Finnhub delivers market cap in MILLIONS of USD.
        marketCapMillions: (json['marketCap'] as num?)?.toDouble(),
        ipo: json['ipo'] as String?,
        logo: json['logo'] as String?,
        website: json['website'] as String?,
        industry: json['industry'] as String?,
        stale: json['stale'] as bool? ?? false,
      );

  final String symbol;
  final String name;
  final String? exchange;
  final String? currency;
  final String? country;
  final double? marketCapMillions;
  final String? ipo;
  final String? logo;
  final String? website;
  final String? industry;
  final bool stale;
}

class Candle {
  const Candle({
    required this.t,
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    required this.v,
  });

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
        t: json['t'] as int,
        o: (json['o'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
        l: (json['l'] as num).toDouble(),
        c: (json['c'] as num).toDouble(),
        v: (json['v'] as num? ?? 0).toDouble(),
      );

  final int t; // epoch milliseconds
  final double o;
  final double h;
  final double l;
  final double c;
  final double v;

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(t);
}

class CandleSeries {
  const CandleSeries({
    required this.symbol,
    required this.range,
    required this.stale,
    required this.candles,
  });

  factory CandleSeries.fromJson(Map<String, dynamic> json) => CandleSeries(
        symbol: json['symbol'] as String,
        range: json['range'] as String,
        stale: json['stale'] as bool? ?? false,
        candles: (json['candles'] as List)
            .map((c) => Candle.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  final String symbol;
  final String range;
  final bool stale;
  final List<Candle> candles;
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
