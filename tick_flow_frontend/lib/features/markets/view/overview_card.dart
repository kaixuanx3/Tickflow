import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';

/// Compact "market overview" card for the horizontal carousel: index label,
/// live price, change % and a small month sparkline. Backed by a US ETF proxy.
/// Sized by its parent (a fixed-height carousel cell).
class OverviewCard extends ConsumerStatefulWidget {
  const OverviewCard({super.key, required this.symbol, required this.label});

  final String symbol;
  final String label;

  @override
  ConsumerState<OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends ConsumerState<OverviewCard> {
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
    final candles =
        ref.watch(candlesProvider((symbol: widget.symbol, range: CandleRange.m1)));
    final changeColor =
        (quote?.changePercent ?? 0) >= 0 ? market.gain : market.loss;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/symbol/${widget.symbol}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quote == null ? '—' : formatMoney(quote.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tabularDigits(theme.textTheme.titleLarge!)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 1),
              Text(
                quote == null ? '—' : formatPercent(quote.changePercent),
                style: tabularDigits(theme.textTheme.bodySmall!).copyWith(
                  color: quote == null
                      ? theme.colorScheme.onSurfaceVariant
                      : changeColor,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: candles.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (series) {
                    final closes = series.candles.map((c) => c.c).toList();
                    if (closes.length < 2) return const SizedBox.shrink();
                    final color =
                        closes.last >= closes.first ? market.gain : market.loss;
                    return Sparkline(values: closes, color: color);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
