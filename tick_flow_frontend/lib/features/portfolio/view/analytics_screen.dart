import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formats.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../core/widgets/symbol_logo.dart';
import '../../../data/markets/market_models.dart';
import '../../../data/markets/market_providers.dart';
import '../../../data/portfolio/portfolio_models.dart';
import '../viewmodel/portfolio_controller.dart';
import '../viewmodel/portfolio_value_series.dart';
import '../viewmodel/top_contributors.dart';
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
                  _TopContributors(holdings: s.holdings),
                  const SizedBox(height: 4),
                  _ValueChart(holdings: s.holdings),
                  const SizedBox(height: 12),
                  AllocationCard(summary: s),
                  const SizedBox(height: 12),
                  _QuickStatsCard(summary: s),
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
  int? _scrubIndex; // point under the finger while scrubbing, else null

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
    final points = reconstructValueSeries(widget.holdings, candlesBySymbol);
    final values = [for (final p in points) p.value];
    final rangeChange = (values.length >= 2 && values.first != 0)
        ? (values.last - values.first) / values.first * 100
        : null;

    // While scrubbing, the header shows the change-from-start and the date at
    // the touched point instead of the whole-range change.
    final scrub = (_scrubIndex != null && _scrubIndex! < points.length)
        ? points[_scrubIndex!]
        : null;
    final displayChange = scrub != null && points.first.value != 0
        ? (scrub.value - points.first.value) / points.first.value * 100
        : rangeChange;
    final displayDate = scrub != null
        ? DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(scrub.t))
        : null;

    final Widget chart;
    if (values.length >= 2) {
      chart = _line(values, market, theme);
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
        if (displayChange != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatPercent(displayChange),
                  style: tabularDigits(theme.textTheme.titleLarge!).copyWith(
                    color: displayChange >= 0 ? market.gain : market.loss,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (displayDate != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    displayDate,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
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
              onSelectionChanged: (s) => setState(() {
                _range = s.first;
                _scrubIndex = null;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(List<double> values, MarketColors market, ThemeData theme) {
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
        // Drag-to-scrub: track the touched point; the header reads it.
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            final spots = response?.lineBarSpots;
            if (!event.isInterestedForInteractions ||
                spots == null ||
                spots.isEmpty) {
              if (_scrubIndex != null) setState(() => _scrubIndex = null);
              return;
            }
            final idx = spots.first.spotIndex;
            if (idx != _scrubIndex) setState(() => _scrubIndex = idx);
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((_) => null).toList(),
          ),
          getTouchedSpotIndicator: (bar, spotIndexes) => [
            for (final _ in spotIndexes)
              TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, b, index) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeColor: theme.colorScheme.surface,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        // Faint dashed baseline at the range's starting value.
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: values.first,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: const [4, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: false,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false), // only the scrub dot shows
            belowBarData:
                BarAreaData(show: true, color: color.withValues(alpha: 0.14)),
          ),
        ],
      ),
    );
  }
}

/// Top and bottom contributors to P/L — who added and subtracted the most
/// dollars. The dollar amount is the headline; % is the supporting detail.
class _TopContributors extends StatelessWidget {
  const _TopContributors({required this.holdings});

  final List<HoldingValuation> holdings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = topContributors(holdings);
    if (c == null) return const SizedBox.shrink();
    final single = c.top.id == c.bottom.id;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top contributors', style: theme.textTheme.labelLarge),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ContribCell(holding: c.top)),
                  if (!single) ...[
                    const VerticalDivider(width: 28),
                    Expanded(child: _ContribCell(holding: c.bottom)),
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

class _ContribCell extends StatelessWidget {
  const _ContribCell({required this.holding});

  final HoldingValuation holding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final market = theme.extension<MarketColors>()!;
    final h = holding;
    final color = (h.gainLoss ?? 0) >= 0 ? market.gain : market.loss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SymbolLogo(symbol: h.symbol, size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                h.symbol,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatSignedMoney(h.gainLoss),
            style: tabularDigits(theme.textTheme.titleLarge!)
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatPercent(h.gainLossPercent),
          style: tabularDigits(theme.textTheme.bodyMedium!).copyWith(color: color),
        ),
      ],
    );
  }
}

/// At-a-glance portfolio stats: holdings count, largest position, asset mix.
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holdings = summary.holdings;
    if (holdings.isEmpty) return const SizedBox.shrink();

    final largest = summary.allocation.isEmpty ? null : summary.allocation.first;

    final counts = <AssetType, int>{};
    for (final h in holdings) {
      counts[h.assetType] = (counts[h.assetType] ?? 0) + 1;
    }
    final mix = [
      for (final t in AssetType.values)
        if ((counts[t] ?? 0) > 0) '${counts[t]} ${_typeLabel(t, counts[t]!)}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick stats', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _statRow(theme, 'Holdings', '${holdings.length}'),
            _statRow(
              theme,
              'Largest position',
              largest == null
                  ? '—'
                  : '${largest.symbol} · ${largest.percent.toStringAsFixed(1)}%',
            ),
            _statRow(theme, 'Asset mix', mix),
          ],
        ),
      ),
    );
  }

  String _typeLabel(AssetType t, int n) {
    if (n == 1 || t == AssetType.crypto) return t.label;
    return '${t.label}s';
  }

  Widget _statRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: tabularDigits(theme.textTheme.bodyMedium!)
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
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
