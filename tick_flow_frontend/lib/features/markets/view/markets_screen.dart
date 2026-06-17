import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/error_retry.dart';
import '../../../data/markets/quotes_cache.dart';
import '../viewmodel/markets_list_controller.dart';
import 'overview_card.dart';
import 'symbol_row.dart';

// US ETFs that proxy the major indices (real indices aren't on the free tier).
const _overview = [
  (symbol: 'SPY', label: 'S&P 500'),
  (symbol: 'QQQ', label: 'Nasdaq 100'),
  (symbol: 'DIA', label: 'Dow Jones'),
];

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: markets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(marketsListProvider),
        ),
        data: (state) => _MarketsBody(state: state),
      ),
    );
  }
}

class _MarketsBody extends ConsumerWidget {
  const _MarketsBody({required this.state});

  final MarketsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delayed = ref.watch(quotesProvider.select((m) => m.values.any((q) => q.delayed)));
    final hints = [
      if (delayed) 'Delayed',
      if (state.stale) 'Cached',
    ].join(' · ');
    final hasFooter = state.hasMore || state.loadMoreFailed;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400) {
          ref.read(marketsListProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () {
          ref.read(quotesProvider.notifier).clear();
          return ref.refresh(marketsListProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Market Overview',
                trailing: 'Live · ${DateFormat('MMM d').format(DateTime.now())}',
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 152,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _overview.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final o = _overview[i];
                    return SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.78,
                      child: OverviewCard(symbol: o.symbol, label: o.label),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'All stocks',
                trailing: hints.isEmpty ? null : hints,
              ),
            ),
            SliverList.builder(
              itemCount: state.symbols.length,
              itemBuilder: (context, i) {
                final info = state.symbols[i];
                return SymbolRow(
                  info: info,
                  onTap: () => context.push('/symbol/${info.symbol}'),
                );
              },
            ),
            if (hasFooter)
              SliverToBoxAdapter(child: _LoadMoreFooter(failed: state.loadMoreFailed)),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends ConsumerWidget {
  const _LoadMoreFooter({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: failed
            ? TextButton(
                onPressed: () =>
                    ref.read(marketsListProvider.notifier).loadMore(retry: true),
                child: const Text("Couldn't load more — tap to retry"),
              )
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }
}
