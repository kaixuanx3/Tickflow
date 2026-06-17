import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/change_pill.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';

/// A "market overview" card: index label, live price, change pill and a
/// month sparkline. Backed by a real US ETF that proxies the index.
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
    final closes = candles.value?.candles.map((c) => c.c).toList() ?? const <double>[];
    final lineColor = (quote?.changePercent ?? 0) >= 0 ? market.gain : market.loss;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/symbol/${widget.symbol}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ChangePill(percent: quote?.changePercent),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                quote == null ? '—' : formatMoney(quote.price),
                style: tabularDigits(theme.textTheme.headlineSmall!)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: closes.length < 2
                    ? const SizedBox()
                    : Sparkline(values: closes, color: lineColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
