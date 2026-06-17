import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/change_pill.dart';
import '../../../core/widgets/star_button.dart';
import '../../../core/widgets/symbol_logo.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/markets/symbol_subscriptions.dart';

/// Card-style list row: avatar, symbol + name, price, change pill, star.
/// Requests its quote (debounced + batched) and subscribes to live ticks
/// while visible. Reused by the markets list and search results.
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
    final quote = ref.watch(quotesProvider.select((m) => m[widget.info.symbol]));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              SymbolLogo(symbol: widget.info.symbol),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.info.displaySymbol,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (widget.info.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.info.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
              StarButton(symbol: widget.info.symbol),
            ],
          ),
        ),
      ),
    );
  }
}
