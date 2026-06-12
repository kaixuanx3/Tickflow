import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';
import 'holding_sheet.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add holding',
        onPressed: () => showHoldingSheet(context),
        child: const Icon(Icons.add),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(portfolioProvider),
        ),
        data: (s) => s.holdings.isEmpty
            ? const _EmptyPortfolio()
            : RefreshIndicator(
                onRefresh: () => ref.refresh(portfolioProvider.future),
                child: ListView(
                  children: [
                    _TotalsCard(summary: s),
                    if (s.incomplete) const _IncompleteBanner(),
                    for (final h in s.holdings) _HoldingRow(holding: h),
                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No holdings yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Add what you own — quantity and buy price — and Tickflow '
              'tracks value and gain/loss for you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showHoldingSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add your first holding'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final gainColor = summary.totalGainLoss >= 0 ? market.gain : market.loss;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total value',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(summary.totalValue),
              style: tabularDigits(theme.textTheme.headlineMedium!)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatMoney(summary.totalCost),
                        style: tabularDigits(theme.textTheme.bodyLarge!),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gain / loss',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatSignedMoney(summary.totalGainLoss)} '
                        '(${formatPercent(summary.totalGainLossPercent)})',
                        style: tabularDigits(theme.textTheme.bodyLarge!)
                            .copyWith(color: gainColor),
                      ),
                    ],
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

class _IncompleteBanner extends StatelessWidget {
  const _IncompleteBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some holdings have no live price right now — totals exclude them.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends ConsumerWidget {
  const _HoldingRow({required this.holding});

  final HoldingValuation holding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final h = holding;
    final gainColor = (h.gainLoss ?? 0) >= 0 ? market.gain : market.loss;

    return ListTile(
      onTap: () => showHoldingSheet(context, existing: h),
      title: Row(
        children: [
          Text(h.symbol, style: theme.textTheme.titleSmall),
          if (h.assetType != AssetType.stock) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                h.assetType.label.toUpperCase(),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${formatQty(h.qty)} × ${formatMoney(h.buyPrice)} · cost ${formatMoney(h.costBasis)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMoney(h.marketValue),
            style: tabularDigits(theme.textTheme.bodyLarge!)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            h.gainLoss == null
                ? '—'
                : '${formatSignedMoney(h.gainLoss)} (${formatPercent(h.gainLossPercent)})',
            style: tabularDigits(theme.textTheme.bodySmall!).copyWith(
              color: h.gainLoss == null
                  ? theme.colorScheme.onSurfaceVariant
                  : gainColor,
            ),
          ),
        ],
      ),
    );
  }
}
