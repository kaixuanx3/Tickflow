import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_retry.dart';
import '../../../data/markets/market_models.dart';
import '../viewmodel/markets_movers.dart';
import 'overview_card.dart';
import 'symbol_row.dart';

// US ETFs that proxy the major indices (real indices aren't on the free tier).
const _overview = [
  (symbol: 'SPY', label: 'S&P 500'),
  (symbol: 'QQQ', label: 'Nasdaq 100'),
  (symbol: 'DIA', label: 'Dow Jones'),
];

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  MoverTab _tab = MoverTab.gainers;

  @override
  Widget build(BuildContext context) {
    final movers = ref.watch(moversProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Markets')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(moversProvider.future),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: _OverviewCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: _MoverTabs(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            movers.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorRetry(
                    message: '$e',
                    onRetry: () => ref.invalidate(moversProvider),
                  ),
                ),
              ),
              data: (quotes) {
                final ranked = rankMovers(quotes, _tab);
                if (ranked.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No data right now')),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: ranked.length,
                  itemBuilder: (context, i) {
                    final symbol = ranked[i].symbol;
                    return SymbolRow(
                      info: SymbolInfo(
                        symbol: symbol,
                        displaySymbol: symbol,
                        description: '',
                        type: '',
                      ),
                      onTap: () => context.push('/symbol/$symbol'),
                    );
                  },
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }
}

/// Tappable search field that opens the full search screen.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/search'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  'Search US stocks',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control for Top gainers / Top losers / Most active.
class _MoverTabs extends StatelessWidget {
  const _MoverTabs({required this.selected, required this.onChanged});

  final MoverTab selected;
  final ValueChanged<MoverTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (final t in MoverTab.values)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: t == selected
                        ? BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Text(
                      t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t == selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            t == selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Snap (page-by-page) carousel of the market-overview cards. Holds its own
/// controller so a quote update repaint doesn't reset the scroll position.
class _OverviewCarousel extends StatefulWidget {
  const _OverviewCarousel();

  @override
  State<_OverviewCarousel> createState() => _OverviewCarouselState();
}

class _OverviewCarouselState extends State<_OverviewCarousel> {
  final _controller = PageController(viewportFraction: 0.46);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: _overview.length,
        itemBuilder: (context, i) {
          final o = _overview[i];
          return Padding(
            padding: EdgeInsets.fromLTRB(i == 0 ? 16 : 5, 0, 5, 0),
            child: OverviewCard(symbol: o.symbol, label: o.label),
          );
        },
      ),
    );
  }
}
