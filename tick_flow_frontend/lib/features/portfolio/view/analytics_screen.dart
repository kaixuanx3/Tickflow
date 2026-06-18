import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';
import '../viewmodel/portfolio_value_series.dart';
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
                  const SizedBox(height: 8),
                  _ValueChartCard(holdings: s.holdings),
                  AllocationCard(summary: s),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

/// Estimated portfolio value over time, reconstructed client-side from each
/// holding's daily closes (no backend support for portfolio history).
class _ValueChartCard extends ConsumerStatefulWidget {
  const _ValueChartCard({required this.holdings});

  final List<HoldingValuation> holdings;

  @override
  ConsumerState<_ValueChartCard> createState() => _ValueChartCardState();
}

class _ValueChartCardState extends ConsumerState<_ValueChartCard> {
  CandleRange _range = CandleRange.m1;

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
          ref.watch(candlesProvider((symbol: h.symbol, range: _range)));
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

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Portfolio value', style: theme.textTheme.labelLarge),
                ),
                InkWell(
                  onTap: _showInfo,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: chart),
            const SizedBox(height: 8),
            Text(
              'Estimated from daily closes',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CandleRange>(
                segments: const [
                  ButtonSegment(value: CandleRange.w1, label: Text('1W')),
                  ButtonSegment(value: CandleRange.m1, label: Text('1M')),
                  ButtonSegment(value: CandleRange.y1, label: Text('1Y')),
                ],
                selected: {_range},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
            ),
          ],
        ),
      ),
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
                BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
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
