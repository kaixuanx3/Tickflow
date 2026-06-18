import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/symbol_logo.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';
import '../viewmodel/portfolio_value_series.dart';
import '../viewmodel/top_movers.dart';
import 'allocation_card.dart';

/// Pushed from the Portfolio tab's "Analytics" link. Holds the portfolio's
/// charts and breakdowns — an estimated value chart and the allocation donut.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          message: '$e',
          onRetry: () => ref.invalidate(portfolioProvider),
        ),
        data: (s) => s.holdings.isEmpty
            ? const _EmptyAnalytics()
            : ListView(
                children: [
                  const SizedBox(height: 12),
                  _TopMoversCard(holdings: s.holdings),
                  const SizedBox(height: 4),
                  _ValueChart(holdings: s.holdings),
                  const SizedBox(height: 12),
                  AllocationCard(summary: s),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

/// Chart range tabs. 1D ≈ a week of daily bars and ALL caps at one year on the
/// free data tier, so both reuse existing candle ranges.
enum _ChartRange {
  d1('1D', CandleRange.d1),
  w1('1W', CandleRange.w1),
  m1('1M', CandleRange.m1),
  y1('1Y', CandleRange.y1),
  all('ALL', CandleRange.y1);

  const _ChartRange(this.label, this.candle);
  final String label;
  final CandleRange candle;
}

/// Estimated portfolio value over time, reconstructed client-side from each
/// holding's daily closes (no backend support for portfolio history). Rendered
/// edge-to-edge (not in a card) so the chart reads big.
class _ValueChart extends ConsumerStatefulWidget {
  const _ValueChart({required this.holdings});

  final List<HoldingValuation> holdings;

  @override
  ConsumerState<_ValueChart> createState() => _ValueChartState();
}

class _ValueChartState extends ConsumerState<_ValueChart> {
  _ChartRange _range = _ChartRange.m1;

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estimated value'),
        content: const Text(
          "This line reconstructs your value from each holding's daily closing "
          "prices (today's quantities). Holdings without price history — crypto "
          "and some ETFs the data provider doesn't cover — aren't included, so "
          "it can differ from your Total value.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;

    final candlesBySymbol = <String, List<Candle>>{};
    var loading = false;
    for (final h in widget.holdings) {
      final async =
          ref.watch(candlesProvider((symbol: h.symbol, range: _range.candle)));
      if (async.isLoading) loading = true;
      final candles = async.value?.candles;
      if (candles != null && candles.isNotEmpty) {
        candlesBySymbol[h.symbol] = candles;
      }
    }
    final values = reconstructValueSeries(widget.holdings, candlesBySymbol);

    final Widget chart;
    if (values.length >= 2) {
      chart = _line(values, market);
    } else if (loading) {
      chart = const Center(child: CircularProgressIndicator());
    } else {
      chart = Center(
        child: Text(
          'Chart unavailable',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row holds the title + the ⓘ (no card needed).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Portfolio value', style: theme.textTheme.labelLarge),
              ),
              InkWell(
                onTap: _showInfo,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.info_outline,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 240, child: chart), // full-width, edge-to-edge
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Estimated from daily closes',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_ChartRange>(
              segments: [
                for (final r in _ChartRange.values)
                  ButtonSegment(value: r, label: Text(r.label)),
              ],
              selected: {_range},
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(List<double> values, MarketColors market) {
    final color = values.last >= values.first ? market.gain : market.loss;
    var minY = values.first;
    var maxY = values.first;
    for (final v in values) {
      minY = math.min(minY, v);
      maxY = math.max(maxY, v);
    }
    final pad = (maxY - minY) * 0.08 + 1; // headroom; +1 guards a flat line
    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: false,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: color.withValues(alpha: 0.14)),
          ),
        ],
      ),
    );
  }
}

/// Best and worst performer by total gain/loss %, side by side.
class _TopMoversCard extends StatelessWidget {
  const _TopMoversCard({required this.holdings});

  final List<HoldingValuation> holdings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movers = topMovers(holdings);
    if (movers == null) return const SizedBox.shrink();
    final single = movers.best.id == movers.worst.id;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top movers', style: theme.textTheme.labelLarge),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _MoverCell(holding: movers.best, label: 'Best')),
                  if (!single) ...[
                    const VerticalDivider(width: 24),
                    Expanded(
                      child: _MoverCell(holding: movers.worst, label: 'Worst'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoverCell extends StatelessWidget {
  const _MoverCell({required this.holding, required this.label});

  final HoldingValuation holding;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final h = holding;
    final color = (h.gainLoss ?? 0) >= 0 ? market.gain : market.loss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SymbolLogo(symbol: h.symbol, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                h.symbol,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          formatPercent(h.gainLossPercent),
          style: tabularDigits(theme.textTheme.titleMedium!)
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 1),
        Text(
          formatSignedMoney(h.gainLoss),
          style: tabularDigits(theme.textTheme.bodySmall!).copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Add holdings to see your analytics.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
