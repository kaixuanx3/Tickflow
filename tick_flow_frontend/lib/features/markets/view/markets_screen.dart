import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_retry.dart';
import '../viewmodel/markets_list_controller.dart';
import '../viewmodel/quotes_controller.dart';
import 'symbol_row.dart';

class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Markets')),
      body: markets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(marketsListProvider),
        ),
        data: (state) => _SymbolList(state: state),
      ),
    );
  }
}

class _SymbolList extends ConsumerWidget {
  const _SymbolList({required this.state});

  final MarketsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final delayed = ref.watch(quotesProvider.select((m) => m.values.any((q) => q.delayed)));
    final caption = [
      if (delayed) 'Quotes delayed (free data tier)',
      if (state.stale) 'showing cached data',
    ].join(' · ');
    final hasHeader = caption.isNotEmpty;
    final hasFooter = state.hasMore || state.loadMoreFailed;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          ref.read(marketsListProvider.notifier).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () {
          ref.read(quotesProvider.notifier).clear();
          return ref.refresh(marketsListProvider.future);
        },
        child: ListView.builder(
          itemCount: (hasHeader ? 1 : 0) + state.symbols.length + (hasFooter ? 1 : 0),
          itemBuilder: (context, index) {
            var i = index;
            if (hasHeader) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    caption,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              i--;
            }
            if (i < state.symbols.length) {
              return SymbolRow(info: state.symbols[i]);
            }
            return _LoadMoreFooter(failed: state.loadMoreFailed);
          },
        ),
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
                child: const Text('Couldn\'t load more — tap to retry'),
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
