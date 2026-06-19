import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/change_pill.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../core/widgets/symbol_logo.dart';
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
              padding: const EdgeInsets.symmetric(vertical: 4),
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

  Future<void> _remove() async {
    try {
      await ref.read(watchlistProvider.notifier).toggle(widget.symbol);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : 'Could not remove ${widget.symbol}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = ref.watch(quotesProvider.select((m) => m[widget.symbol]));

    return Dismissible(
      key: ValueKey(widget.symbol),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(),
      // Rounded red reveal aligned to the card's margin/shape.
      background: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/symbol/${widget.symbol}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                SymbolLogo(symbol: widget.symbol),
                const SizedBox(width: 12),
                Text(
                  widget.symbol,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                // Sparkline centred in the slack between the symbol and price.
                Expanded(
                  child: Center(child: _RowSparkline(symbol: widget.symbol)),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      quote == null ? '—' : formatMoney(quote.price),
                      style: tabularDigits(theme.textTheme.bodyLarge!)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    ChangePill(percent: quote?.changePercent, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Last-month daily closes, coloured by overall trend. Reserves space so the
/// price column stays aligned even when there's no chart data.
class _RowSparkline extends ConsumerWidget {
  const _RowSparkline({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = Theme.of(context).extension<MarketColors>()!;
    final candles =
        ref.watch(candlesProvider((symbol: symbol, range: CandleRange.m1)));
    final closes = candles.value?.candles.map((c) => c.c).toList() ?? const <double>[];
    if (closes.length < 2) return const SizedBox(width: 72, height: 32);
    final color = closes.last >= closes.first ? market.gain : market.loss;
    return SizedBox(
      width: 72,
      child: Sparkline(values: closes, color: color, height: 32),
    );
  }
}
