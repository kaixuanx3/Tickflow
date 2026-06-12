import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/markets/market_models.dart';
import '../../../data/markets/markets_repository.dart';

final profileProvider = FutureProvider.autoDispose.family<CompanyProfile, String>(
  (ref, symbol) => ref.watch(marketsRepositoryProvider).fetchProfile(symbol),
);

final candlesProvider = FutureProvider.autoDispose
    .family<CandleSeries, ({String symbol, CandleRange range})>(
  (ref, key) => ref.watch(marketsRepositoryProvider).fetchCandles(key.symbol, key.range),
);
