import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/change_pill.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/symbol_logo.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/markets/quotes_cache.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';
import '../viewmodel/portfolio_day_change.dart';
import 'holding_sheet.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _editing = false;
  final _quotesRequested = <String>{};

  /// Lazily pull a quote per holding so the card can show today's change.
  void _ensureQuotes(List<HoldingValuation> holdings) {
    final missing = <String>[];
    for (final h in holdings) {
      if (_quotesRequested.add(h.symbol)) missing.add(h.symbol);
    }
    if (missing.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(quotesProvider.notifier);
      for (final s in missing) {
        notifier.request(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        data: (s) {
          if (s.holdings.isEmpty) return const _EmptyPortfolio();
          final holdings = s.holdings; // backend returns them in saved order
          _ensureQuotes(holdings);
          final dayChange =
              portfolioDayChange(holdings, ref.watch(quotesProvider));
          final canReorder = holdings.length >= 2;
          final editing = _editing && canReorder;
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(portfolioProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _TotalsCard(summary: s, dayChange: dayChange)),
                if (s.incomplete)
                  const SliverToBoxAdapter(child: _IncompleteBanner()),
                SliverToBoxAdapter(
                  child: _HoldingsHeader(
                    editing: editing,
                    canReorder: canReorder,
                    onToggle: () => setState(() => _editing = !_editing),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: DecoratedSliver(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),
                        SliverReorderableList(
                          itemCount: holdings.length,
                          onReorder: (oldIndex, newIndex) {
                            final ids = holdings.map((h) => h.id).toList();
                            if (newIndex > oldIndex) newIndex -= 1;
                            ids.insert(newIndex, ids.removeAt(oldIndex));
                            ref.read(portfolioProvider.notifier).reorder(ids);
                          },
                          itemBuilder: (context, i) => _ReorderableHolding(
                            key: ValueKey(holdings[i].id),
                            holding: holdings[i],
                            index: i,
                            editing: editing,
                            showDivider: i > 0,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 6)),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: 80)), // FAB clearance
              ],
            ),
          );
        },
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
  const _TotalsCard({required this.summary, this.dayChange});

  final PortfolioSummary summary;
  final DayChange? dayChange;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total value',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/analytics'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Analytics',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(summary.totalValue),
              style: tabularDigits(theme.textTheme.headlineMedium!)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            if (dayChange != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    formatSignedMoney(dayChange!.amount),
                    style: tabularDigits(theme.textTheme.bodyLarge!).copyWith(
                      color: dayChange!.amount >= 0 ? market.gain : market.loss,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChangePill(percent: dayChange!.percent, compact: true),
                  const SizedBox(width: 8),
                  Text(
                    'today',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
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
                        'Total gain / loss',
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

/// "Holdings" section header with the Edit / Done reorder toggle. Edit mode
/// reveals per-row drag handles (long-press also works in either mode).
class _HoldingsHeader extends StatelessWidget {
  const _HoldingsHeader({
    required this.editing,
    required this.canReorder,
    required this.onToggle,
  });

  final bool editing;
  final bool canReorder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Text(
            'Holdings',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (editing)
            Text(
              'Drag to reorder',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          if (canReorder)
            TextButton(
              onPressed: onToggle,
              child: Text(editing ? 'Done' : 'Edit'),
            ),
        ],
      ),
    );
  }
}

/// One reorderable holding: a top divider (except the first) plus the row, the
/// whole thing long-press-draggable. A normal tap still opens the edit sheet.
class _ReorderableHolding extends StatelessWidget {
  const _ReorderableHolding({
    super.key,
    required this.holding,
    required this.index,
    required this.editing,
    required this.showDivider,
  });

  final HoldingValuation holding;
  final int index;
  final bool editing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Column(
        children: [
          if (showDivider)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant,
            ),
          _HoldingRow(holding: holding, index: index, editing: editing),
        ],
      ),
    );
  }
}

class _HoldingRow extends ConsumerWidget {
  const _HoldingRow({
    required this.holding,
    required this.index,
    required this.editing,
  });

  final HoldingValuation holding;
  final int index;
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final h = holding;

    final profile = ref.watch(profileProvider(h.symbol)).value;
    // CompanyProfile.name falls back to the symbol, so only show a real name.
    final name =
        (profile != null && profile.name != h.symbol) ? profile.name : null;
    final unit = h.assetType == AssetType.crypto ? 'Units' : 'Shares';

    final priced = h.gainLoss != null;
    final gainColor = priced
        ? (h.gainLoss! >= 0 ? market.gain : market.loss)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => showHoldingSheet(context, existing: h),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            _HoldingLogo(
              symbol: h.symbol,
              isEtf: h.assetType == AssetType.etf,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.symbol,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (name != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 1),
                  Text(
                    '${formatQty(h.qty)} $unit, Avg. ${formatMoney(h.buyPrice)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPercent(h.gainLossPercent),
                  style: tabularDigits(theme.textTheme.titleSmall!)
                      .copyWith(color: gainColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'Current ',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: formatMoney(h.price),
                        style: tabularDigits(theme.textTheme.bodySmall!).copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatSignedMoney(h.gainLoss),
                  style: tabularDigits(theme.textTheme.bodySmall!)
                      .copyWith(color: gainColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (editing) ...[
              const SizedBox(width: 4),
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular company/fund logo (shared [SymbolLogo]); ETFs get a small "ETF"
/// badge pinned to the bottom edge.
class _HoldingLogo extends StatelessWidget {
  const _HoldingLogo({required this.symbol, required this.isEtf});

  final String symbol;
  final bool isEtf;

  @override
  Widget build(BuildContext context) {
    final avatar = SymbolLogo(symbol: symbol, size: 44);
    if (!isEtf) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        avatar,
        const Positioned(bottom: -5, child: _EtfBadge()),
      ],
    );
  }
}

class _EtfBadge extends StatelessWidget {
  const _EtfBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(5),
        // Surface-coloured ring separates the badge from the logo and row.
        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
      ),
      child: Text(
        'ETF',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
