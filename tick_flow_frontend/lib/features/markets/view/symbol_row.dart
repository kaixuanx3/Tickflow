import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';

/// List row for a symbol; requests its quote (debounced + batched) when it
/// first becomes visible. Reused by the markets list and search results.
class SymbolRow extends ConsumerStatefulWidget {
  const SymbolRow({super.key, required this.info, this.onTap});

  final SymbolInfo info;
  final VoidCallback? onTap;

  @override
  ConsumerState<SymbolRow> createState() => _SymbolRowState();
}

class _SymbolRowState extends ConsumerState<SymbolRow> {
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quotesProvider.notifier).request(widget.info.symbol);
      ref.read(symbolSubscriptionsProvider.notifier).retain(widget.info.symbol);
      _subscribed = true;
    });
  }

  @override
  void dispose() {
    if (_subscribed) {
      ref.read(symbolSubscriptionsProvider.notifier).release(widget.info.symbol);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final quote = ref.watch(quotesProvider.select((m) => m[widget.info.symbol]));

    return ListTile(
      onTap: widget.onTap,
      title: Text(widget.info.displaySymbol, style: theme.textTheme.titleSmall),
      subtitle: Text(
        widget.info.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: quote == null
          ? Text(
              '—',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : Column(
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
    );
  }
}
