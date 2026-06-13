import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/api/api_client.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';
import '../../../data/watchlist/watchlist_store.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: watchlist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(watchlistProvider),
        ),
        data: (symbols) {
          if (symbols.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_border,
                        size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Nothing starred yet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Star a symbol in Markets and it shows up here with a live price.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          final sorted = symbols.toList()..sort();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(watchlistProvider.future),
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) => _FavouriteRow(symbol: sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FavouriteRow extends ConsumerStatefulWidget {
  const _FavouriteRow({required this.symbol});

  final String symbol;

  @override
  ConsumerState<_FavouriteRow> createState() => _FavouriteRowState();
}

class _FavouriteRowState extends ConsumerState<_FavouriteRow> {
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quotesProvider.notifier).request(widget.symbol);
      ref.read(symbolSubscriptionsProvider.notifier).retain(widget.symbol);
      _subscribed = true;
    });
  }

  @override
  void dispose() {
    if (_subscribed) {
      ref.read(symbolSubscriptionsProvider.notifier).release(widget.symbol);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final quote = ref.watch(quotesProvider.select((m) => m[widget.symbol]));

    return Dismissible(
      key: ValueKey(widget.symbol),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) async {
        try {
          await ref.read(watchlistProvider.notifier).toggle(widget.symbol);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is ApiException ? e.message : 'Could not remove ${widget.symbol}',
              ),
            ),
          );
        }
      },
      child: ListTile(
        onTap: () => context.push('/symbol/${widget.symbol}'),
        title: Text(widget.symbol, style: theme.textTheme.titleSmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Sparkline(symbol: widget.symbol),
            const SizedBox(width: 16),
            if (quote == null)
              Text(
                '—',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(quote.price),
                    style: tabularDigits(theme.textTheme.bodyLarge!)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatPercent(quote.changePercent),
                    style: tabularDigits(theme.textTheme.bodySmall!).copyWith(
                      color: quote.changePercent >= 0 ? market.gain : market.loss,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Last-month daily closes; colored by overall trend. Quietly absent while
/// loading or on error — the row stays usable without it.
class _Sparkline extends ConsumerWidget {
  const _Sparkline({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = Theme.of(context).extension<MarketColors>()!;
    final candles =
        ref.watch(candlesProvider((symbol: symbol, range: CandleRange.m1)));

    return SizedBox(
      width: 84,
      height: 30,
      child: candles.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (series) {
          final closes = series.candles.map((c) => c.c).toList();
          if (closes.length < 2) return const SizedBox.shrink();
          final color = closes.last >= closes.first ? market.gain : market.loss;
          return LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < closes.length; i++)
                      FlSpot(i.toDouble(), closes[i]),
                  ],
                  color: color,
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
