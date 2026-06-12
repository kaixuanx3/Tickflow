import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../data/markets/market_models.dart';
import '../viewmodel/quotes_controller.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(quotesProvider.notifier).request(widget.info.symbol);
    });
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
